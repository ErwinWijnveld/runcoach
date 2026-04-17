<?php

namespace App\Ai\Tools;

use App\Enums\GoalStatus;
use App\Models\TrainingResult;
use App\Models\User;
use Illuminate\Contracts\JsonSchema\JsonSchema;
use Laravel\Ai\Contracts\Tool;
use Laravel\Ai\Tools\Request;

class GetGoalInfo implements Tool
{
    public function __construct(private User $user) {}

    public function description(): string
    {
        return 'Get details about the user\'s active or specific goal: type (race / general fitness / PR attempt), name, distance, target date, goal time, weeks remaining, completion rate, and readiness assessment.';
    }

    public function schema(JsonSchema $schema): array
    {
        return [
            'goal_id' => $schema->integer()->required()->nullable()->description('Specific goal ID, or null for the active goal.'),
        ];
    }

    public function handle(Request $request): string
    {
        $goal = $request['goal_id']
            ? $this->user->goals()->find($request['goal_id'])
            : $this->user->goals()->where('status', GoalStatus::Active)->latest()->first();

        if (! $goal) {
            return json_encode(['message' => 'No active goal found. The runner has not set up a training goal yet.']);
        }

        $totalDays = $goal->trainingWeeks()->withCount('trainingDays')->get()->sum('training_days_count');
        $completedResults = TrainingResult::whereHas('trainingDay.trainingWeek', fn ($q) => $q->where('goal_id', $goal->id))->get();
        $completionRate = $totalDays > 0 ? round($completedResults->count() / $totalDays * 100, 1) : 0;

        return json_encode([
            'type' => $goal->type,
            'name' => $goal->name,
            'distance' => $goal->distance?->value,
            'goal_time_seconds' => $goal->goal_time_seconds,
            'target_date' => $goal->target_date?->toDateString(),
            'weeks_until_target_date' => $goal->weeksUntilTargetDate(),
            'status' => $goal->status->value,
            'completion_rate_percent' => $completionRate,
            'sessions_completed' => $completedResults->count(),
            'sessions_planned' => $totalDays,
            'avg_compliance' => $completedResults->count() > 0 ? round($completedResults->avg('compliance_score'), 1) : null,
        ]);
    }
}
