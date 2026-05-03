<?php

namespace App\Ai\Tools;

use App\Enums\GoalStatus;
use App\Models\TrainingDay;
use App\Models\User;
use App\Services\PlanOptimizerService;
use App\Services\ProposalService;
use Illuminate\Contracts\JsonSchema\JsonSchema;
use Laravel\Ai\Contracts\Tool;
use Laravel\Ai\Tools\Request;

/**
 * Edit THIS training day's targets only. Internally builds a single
 * `set_day` operation against the runner's active goal and delegates to
 * `EditSchedule`, so the proposal/approval pipeline is unchanged.
 *
 * Scoped narrower than EditSchedule on purpose — the workout agent should
 * never touch other days; multi-day work belongs to the full coach.
 */
class EditWorkout implements Tool
{
    public function __construct(
        private User $user,
        private TrainingDay $day,
        private PlanOptimizerService $optimizer,
        private ProposalService $proposals,
    ) {}

    public function description(): string
    {
        return <<<'DESC'
        Propose changes to THIS workout's distance, pace, type, intervals, HR zone, title, or description. Returns a proposal the runner approves before anything is written. The change applies to the runner's active training plan — only THIS day, no other days.

        `fields` is a JSON-encoded object. Allowed keys (omit any you don't want to change):
        - `type`: one of `easy`, `long_run`, `tempo`, `interval`, `threshold`
        - `target_km`: positive number
        - `target_pace_seconds_per_km`: integer 60-1800 (or null to clear)
        - `target_heart_rate_zone`: integer 1-5 (or null to clear)
        - `intervals`: array of segments (warmup/work/recovery/cooldown) — same shape `create_schedule` uses
        - `title`: short string, omit to let the server regenerate
        - `description`: free text

        Use this for direct asks like "make this 2km shorter", "change the pace to 5:00", "make it an easy run instead", "add a 5x400m interval set". Do NOT use for multi-day or goal-level changes — call `escalate_to_coach` for those.
        DESC;
    }

    public function schema(JsonSchema $schema): array
    {
        return [
            'fields' => $schema->string()->required()->description('JSON-encoded object of the day fields to change. See tool description for allowed keys.'),
        ];
    }

    public function handle(Request $request): string
    {
        $fieldsRaw = $request['fields'] ?? null;
        $fields = is_string($fieldsRaw) ? json_decode($fieldsRaw, true) : null;
        if (! is_array($fields) || count($fields) === 0) {
            return json_encode(['error' => 'fields must be a non-empty JSON-encoded object.']);
        }

        $day = $this->day->fresh(['trainingWeek.goal']);
        if ($day === null || $day->trainingWeek === null || $day->trainingWeek->goal === null) {
            return json_encode(['error' => 'Training day is not attached to a goal.']);
        }

        $goal = $day->trainingWeek->goal;
        if ($goal->status !== GoalStatus::Active) {
            return json_encode(['error' => 'The goal for this workout is not active — cannot edit.']);
        }

        if ($day->date === null) {
            return json_encode(['error' => 'Training day has no date.']);
        }

        // `day_of_week` in the plan payload is the TrainingDay's `order`
        // column (PlanPayload::fromGoal exposes it that way). Using the
        // date's ISO weekday would diverge whenever the day was rescheduled
        // without rewriting `order`.
        $weekNumber = (int) $day->trainingWeek->week_number;
        $dayOfWeek = (int) $day->order;

        $operations = [
            [
                'op' => 'set_day',
                'week' => $weekNumber,
                'day_of_week' => $dayOfWeek,
                'fields' => $fields,
            ],
        ];

        $editTool = new EditSchedule($this->user, $this->optimizer, $this->proposals);

        $editRequest = new Request([
            'proposal_id' => null,
            'goal_id' => $goal->id,
            'operations' => json_encode($operations),
        ]);

        return $editTool->handle($editRequest);
    }
}
