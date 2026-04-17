<?php

namespace App\Ai\Tools;

use App\Enums\GoalStatus;
use App\Models\User;
use Illuminate\Contracts\JsonSchema\JsonSchema;
use Laravel\Ai\Contracts\Tool;
use Laravel\Ai\Tools\Request;

class GetCurrentSchedule implements Tool
{
    public function __construct(private User $user) {}

    public function description(): string
    {
        return 'Get the user\'s active training schedule with all weeks, days, target paces/distances, and compliance results for completed sessions.';
    }

    public function schema(JsonSchema $schema): array
    {
        return [
            'goal_id' => $schema->integer()->required()->nullable()->description('Specific goal ID. Omit or pass null to get the active goal.'),
        ];
    }

    public function handle(Request $request): string
    {
        $goal = $request['goal_id']
            ? $this->user->goals()->find($request['goal_id'])
            : $this->user->goals()->where('status', GoalStatus::Active)->latest()->first();

        if (! $goal) {
            return json_encode(['message' => 'No active goal found.']);
        }

        $weeks = $goal->trainingWeeks()
            ->with('trainingDays.result')
            ->orderBy('week_number')
            ->get();

        $data = [
            'goal' => [
                'type' => $goal->type,
                'name' => $goal->name,
                'distance' => $goal->distance?->value,
                'target_date' => $goal->target_date?->toDateString(),
                'weeks_until_target_date' => $goal->weeksUntilTargetDate(),
            ],
            'weeks' => $weeks->map(fn ($week) => [
                'week_number' => $week->week_number,
                'starts_at' => $week->starts_at->toDateString(),
                'total_km' => $week->total_km,
                'focus' => $week->focus,
                'days' => $week->trainingDays->map(fn ($day) => [
                    'id' => $day->id,
                    'date' => $day->date->toDateString(),
                    'type' => $day->type->value,
                    'title' => $day->title,
                    'target_km' => $day->target_km,
                    'target_pace_seconds_per_km' => $day->target_pace_seconds_per_km,
                    'completed' => $day->result !== null,
                    'compliance_score' => $day->result?->compliance_score,
                ])->toArray(),
            ])->toArray(),
        ];

        return json_encode($data);
    }
}
