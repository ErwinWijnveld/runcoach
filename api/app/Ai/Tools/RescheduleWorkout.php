<?php

namespace App\Ai\Tools;

use App\Models\TrainingDay;
use App\Models\User;
use Illuminate\Contracts\JsonSchema\JsonSchema;
use Illuminate\Support\Carbon;
use Laravel\Ai\Contracts\Tool;
use Laravel\Ai\Tools\Request;

/**
 * Move the currently-bound training day to a different calendar date.
 * Mirrors the validation in TrainingScheduleController::updateDay so the
 * agent can't perform any reschedule the manual UI would refuse.
 */
class RescheduleWorkout implements Tool
{
    public function __construct(
        private User $user,
        private TrainingDay $day,
    ) {}

    public function description(): string
    {
        return <<<'DESC'
        Move THIS training day to a different date. Re-assigns it to the matching training week automatically. Refuses (a) days that already have a result logged, (b) the goal/race day itself, and (c) dates outside `[today, goal.target_date]`.

        Use this for direct asks like "move this to Friday", "push this to tomorrow", "I can't run today, shift it".

        Do NOT use to move other days in the schedule — escalate_to_coach handles broader plan changes.
        DESC;
    }

    public function schema(JsonSchema $schema): array
    {
        return [
            'date' => $schema->string()->required()->description('New date in YYYY-MM-DD, e.g. "2026-05-08". Must be today or later AND on/before the goal target_date when set.'),
        ];
    }

    public function handle(Request $request): string
    {
        $rawDate = (string) ($request['date'] ?? '');
        if (! preg_match('/^\d{4}-\d{2}-\d{2}$/', $rawDate)) {
            return json_encode(['error' => 'date must be YYYY-MM-DD']);
        }

        $day = $this->day->fresh(['trainingWeek.goal', 'result']);
        if ($day === null) {
            return json_encode(['error' => 'Training day not found.']);
        }

        if ($day->result()->exists()) {
            return json_encode(['error' => 'Cannot reschedule a day that already has a result. Tell the runner to unlink the activity from this day first.']);
        }

        $goal = $day->trainingWeek?->goal;
        if ($goal === null) {
            return json_encode(['error' => 'Training day is not attached to a goal.']);
        }

        if (
            $goal->target_date !== null
            && $day->date !== null
            && $goal->target_date->toDateString() === Carbon::parse($day->date)->toDateString()
        ) {
            return json_encode(['error' => 'This is the goal/race day — it has to stay on the goal date. Tell the runner to edit the goal date instead, or escalate_to_coach.']);
        }

        $newDate = Carbon::parse($rawDate)->startOfDay();
        $today = now()->startOfDay();
        if ($newDate->lt($today)) {
            return json_encode(['error' => 'Cannot move a workout into the past.']);
        }
        if ($goal->target_date !== null && $newDate->gt($goal->target_date)) {
            return json_encode(['error' => "New date is after the goal target date ({$goal->target_date->toDateString()}). Out of range."]);
        }

        $matchingWeek = $goal->trainingWeeks()
            ->where('starts_at', '<=', $newDate->toDateString())
            ->where('starts_at', '>', $newDate->copy()->subDays(7)->toDateString())
            ->orderByDesc('starts_at')
            ->first();

        $day->update([
            'date' => $newDate->toDateString(),
            'training_week_id' => $matchingWeek?->id ?? $day->training_week_id,
        ]);

        return json_encode([
            // `display: plan_mutated` is the streaming-layer signal that the
            // server just changed plan data outside the proposal pipeline,
            // so the client should bust its plan cache (planVersion bump).
            // Without it the schedule overview keeps showing the pre-move
            // date until the next manual refresh.
            'display' => 'plan_mutated',
            'rescheduled' => true,
            'training_day_id' => $day->id,
            'date' => $newDate->toDateString(),
            'week_number' => $matchingWeek?->week_number,
        ]);
    }
}
