<?php

namespace App\Ai\Tools;

use App\Enums\GoalDistance;
use App\Enums\GoalType;
use App\Enums\TrainingType;
use Illuminate\Contracts\JsonSchema\JsonSchema;
use Laravel\Ai\Contracts\Tool;
use Laravel\Ai\Tools\Request;

class CreateSchedule implements Tool
{
    public function description(): string
    {
        return <<<'DESC'
        Create a complete training goal and schedule for the runner. Returns a proposal the runner must approve.

        Goal types:
        - `race`: training for a specific race event (distance + target_date required)
        - `general_fitness`: improving overall fitness, no fixed race (distance and target_date may be null)
        - `pr_attempt`: attempting a personal record at a given distance (distance required, target_date optional)

        IMPORTANT: Before calling this tool, you should have already:
        1. Asked the runner about their goal (type, distance, date, target time where applicable)
        2. Fetched their recent Strava data with search_strava_activities
        3. Analyzed their fitness level and discussed your approach
        4. Gotten confirmation from the runner

        The schedule must be based on the runner's actual fitness data. Generate a realistic, week-by-week plan with specific sessions for each day. Use periodization, 80/20 rule, and progressive overload. Pace targets should be derived from their current running pace.

        The schedule parameter must be a valid JSON string containing the full plan structure.
        DESC;
    }

    public function schema(JsonSchema $schema): array
    {
        $trainingTypes = TrainingType::valuesAsPipe();

        return [
            'goal_type' => $schema->string()->enum(GoalType::values())->required()->description('Type of goal the runner is working toward.'),
            'goal_name' => $schema->string()->required()->description('Name of the goal (e.g. "Amsterdam Marathon 2026" or "Build base fitness")'),
            'distance' => $schema->string()->enum(GoalDistance::values())->required()->nullable()->description('Target distance, or null for general fitness goals without a specific distance.'),
            'goal_time_seconds' => $schema->integer()->required()->nullable()->description('Target finish time in seconds (e.g. 5400 for 1:30:00), or null if no specific goal'),
            'target_date' => $schema->string()->required()->nullable()->description('Goal date in YYYY-MM-DD format, or null for open-ended goals.'),
            'preferred_weekdays' => $schema->array()->items($schema->integer())->required()->nullable()->description('ISO weekdays the runner CAN run (1=Mon…7=Sun), e.g. [2,4,6] for Tue/Thu/Sat. Every training day in `schedule` MUST have `day_of_week` in this list. Null means any day works.'),
            'additional_notes' => $schema->string()->required()->nullable()->description('Optional extra context from the runner (injuries, schedule quirks, preferences). Factor in where reasonable, never violate hard constraints.'),
            'schedule' => $schema->string()->required()->description('Complete training schedule as JSON: {"weeks":[{"week_number":1,"focus":"base building","total_km":30.0,"days":[{"day_of_week":1,"type":"'.$trainingTypes.'","title":"Easy Run","description":"Keep conversational pace","target_km":5.0,"target_pace_seconds_per_km":390,"target_heart_rate_zone":2,"intervals":[{"kind":"warmup|work|recovery|cooldown","label":"Warm up","distance_m":1000,"duration_seconds":360,"target_pace_seconds_per_km":360}]}]}]}. day_of_week: 1=Monday through 7=Sunday. All entries are running sessions — the runner\'s rest days are simply the days of the week that have no entry. Most weeks should have 3-5 day entries. `intervals` is REQUIRED for `type: intervals` days (give warm-up, alternating work/recovery reps, cooldown). For other types `intervals` can be omitted. For each interval: kind (enum), label (short human name), distance_m (integer meters), duration_seconds (integer, may be null if distance-based), target_pace_seconds_per_km (integer, may be null for easy warm-up/cooldown).'),
        ];
    }

    public function handle(Request $request): string
    {
        $schedule = json_decode($request['schedule'], true);

        if (! $schedule || ! isset($schedule['weeks'])) {
            return json_encode(['error' => 'Invalid schedule JSON. Must contain a "weeks" array.']);
        }

        return json_encode([
            'requires_approval' => true,
            'proposal_type' => 'create_schedule',
            'payload' => [
                'goal_type' => $request['goal_type'],
                'goal_name' => $request['goal_name'],
                'distance' => $request['distance'],
                'goal_time_seconds' => $request['goal_time_seconds'],
                'target_date' => $request['target_date'],
                'preferred_weekdays' => $request['preferred_weekdays'] ?? null,
                'additional_notes' => $request['additional_notes'] ?? null,
                'schedule' => $schedule,
            ],
        ]);
    }
}
