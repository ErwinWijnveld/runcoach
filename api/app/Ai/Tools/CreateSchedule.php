<?php

namespace App\Ai\Tools;

use App\Enums\GoalDistance;
use App\Enums\GoalType;
use App\Enums\ProposalType;
use App\Enums\TrainingType;
use App\Models\User;
use App\Services\PlanOptimizerService;
use App\Services\ProposalService;
use App\Support\PlanPayload;
use Illuminate\Contracts\JsonSchema\JsonSchema;
use Illuminate\Support\Facades\Cache;
use Laravel\Ai\Contracts\Tool;
use Laravel\Ai\Tools\Request;

class CreateSchedule implements Tool
{
    public function __construct(
        private User $user,
        private PlanOptimizerService $optimizer,
        private ProposalService $proposals,
    ) {}

    public function description(): string
    {
        $race = GoalType::Race->value;
        $generalFitness = GoalType::GeneralFitness->value;
        $prAttempt = GoalType::PrAttempt->value;

        return <<<DESC
        Create a complete training goal and schedule for the runner. Returns a proposal the runner must approve.

        Goal types:
        - `{$race}`: training for a specific race event (distance + target_date required)
        - `{$generalFitness}`: improving overall fitness, no fixed race (distance and target_date may be null)
        - `{$prAttempt}`: attempting a personal record at a given distance (distance required, target_date optional)

        IMPORTANT: Before calling this tool, you should have already:
        1. Asked the runner about their goal (type, distance, date, target time where applicable)
        2. Fetched their recent Strava data with search_strava_activities
        3. Analyzed their fitness level and discussed your approach
        4. Gotten confirmation from the runner

        The schedule must be based on the runner's actual fitness data. Generate a realistic, week-by-week plan with specific sessions for each day. Use periodization, 80/20 rule, and progressive overload.

        Leave `target_pace_seconds_per_km` NULL on easy and long_run days — the server fills those from the runner's Strava baseline.

        ON QUALITY DAYS (tempo / threshold / interval) you MUST set `target_pace_seconds_per_km` and progress it across the plan toward the runner's goal pace. The goal pace is `goal_time_seconds / distance_km`. Typical ramp (tune to the runner's gap between baseline and goal):
         - Early build weeks: goal pace + ~25-30s (moderately hard but well inside capability).
         - Mid plan: goal pace + ~15s.
         - Final 2-3 weeks before race: goal pace + 5-10s or AT goal pace.
        Use the SAME progression for `target_pace_seconds_per_km` on interval `work` segments. `warmup` / `cooldown` / `recovery` segments leave null — server defaults them. The progression is the whole point of quality work — do not set every tempo at the same pace.

        Day titles and weekly km totals are always computed server-side — leave them out.

        The schedule parameter must be a valid JSON string containing the full plan structure.
        DESC;
    }

    public function schema(JsonSchema $schema): array
    {
        $trainingTypes = TrainingType::activeValuesAsPipe();

        return [
            'goal_type' => $schema->string()->enum(GoalType::values())->required()->description('Type of goal the runner is working toward.'),
            'goal_name' => $schema->string()->required()->description('Name of the goal (e.g. "Amsterdam Marathon 2026" or "Build base fitness")'),
            'distance' => $schema->string()->enum(GoalDistance::values())->required()->nullable()->description('Target distance, or null for general fitness goals without a specific distance.'),
            'goal_time_seconds' => $schema->integer()->required()->nullable()->description('Target finish time in seconds (e.g. 5400 for 1:30:00), or null if no specific goal'),
            'target_date' => $schema->string()->required()->nullable()->description('Goal date in YYYY-MM-DD format, or null for open-ended goals. Will be automatically aligned to the final training day of the plan.'),
            'preferred_weekdays' => $schema->array()->items($schema->integer())->required()->nullable()->description('ISO weekdays the runner CAN run (1=Mon…7=Sun), e.g. [2,4,6] for Tue/Thu/Sat. Every training day in `schedule` MUST have `day_of_week` in this list. Null means any day works.'),
            'additional_notes' => $schema->string()->required()->nullable()->description('Optional extra context from the runner (injuries, schedule quirks, preferences). Factor in where reasonable, never violate hard constraints.'),
            'schedule' => $schema->string()->required()->description('Complete training schedule as JSON: {"weeks":[{"week_number":1,"focus":"base building","days":[{"day_of_week":1,"type":"'.$trainingTypes.'","target_km":5.0,"target_pace_seconds_per_km":null,"description":"Keep conversational pace","target_heart_rate_zone":2,"intervals":[{"kind":"warmup|work|recovery|cooldown","label":"Warm up","distance_m":1000,"duration_seconds":360,"target_pace_seconds_per_km":null}]}]}]}. day_of_week: 1=Monday through 7=Sunday. Unscheduled days are rest days — do NOT emit rest-day entries. Most weeks have 3-5 day entries. `intervals` is REQUIRED for `type: interval` days (warm-up, alternating work/recovery reps, cooldown); optional otherwise. Per-interval fields: kind (enum), label (short human name), distance_m (integer meters), duration_seconds (integer, may be null if distance-based), target_pace_seconds_per_km (set on `work` segments with the progressive goal-pace ramp, null on warmup/cooldown/recovery). Day-level `target_pace_seconds_per_km` is REQUIRED on tempo/threshold/interval days (progress toward goal pace across the plan) and NULL on easy/long_run days. Do NOT set `title` or `total_km` — server computes those.'),
        ];
    }

    public function handle(Request $request): string
    {
        $schedule = json_decode($request['schedule'], true);

        if (! $schedule || ! isset($schedule['weeks'])) {
            return json_encode(['error' => 'Invalid schedule JSON. Must contain a "weeks" array.']);
        }

        $payload = [
            'goal_type' => $request['goal_type'],
            'goal_name' => $request['goal_name'],
            'distance' => $request['distance'],
            'goal_time_seconds' => $request['goal_time_seconds'],
            'target_date' => $request['target_date'],
            'preferred_weekdays' => $request['preferred_weekdays'] ?? null,
            'additional_notes' => $request['additional_notes'] ?? null,
            'schedule' => $schedule,
        ];

        $payload = $this->optimizer->optimize($payload, $this->user);

        $proposal = $this->proposals->persistPending(
            $this->user,
            ProposalType::CreateSchedule,
            $payload,
        );

        // A fresh create_schedule starts a new "verify session" — reset
        // the per-user verify cycle counter so edit→verify loops inside
        // this generation cap properly at MAX_CYCLES.
        Cache::forget(VerifyPlan::cycleCacheKey($this->user->id));

        // Don't echo the full plan JSON back in the tool response — for a
        // 9-week plan with intervals that's 15-20 kB, and every subsequent
        // turn re-sends the whole conversation history to Anthropic. Two
        // or three create/edit cycles are enough to blow past the 30k-tokens-per-minute
        // rate limit. The agent doesn't need the full payload in its
        // context: `verify_plan` re-reads the plan from the DB, and if the
        // agent needs details for a follow-up edit it can call
        // `get_current_proposal`. `plan_structure` carries the (week,
        // day_of_week) map — enough to compose valid `edit_schedule` ops.
        return json_encode([
            'requires_approval' => true,
            'proposal_type' => ProposalType::CreateSchedule->value,
            'proposal_id' => $proposal->id,
            'plan_structure' => PlanPayload::weekStructure($payload),
        ]);
    }
}
