<?php

namespace App\Ai\Tools;

use App\Enums\GoalStatus;
use App\Models\User;
use Illuminate\Contracts\JsonSchema\JsonSchema;
use Laravel\Ai\Contracts\Tool;
use Laravel\Ai\Tools\Request;

class ModifySchedule implements Tool
{
    public function __construct(private User $user) {}

    public function description(): string
    {
        return 'Modify specific days in an existing training schedule. Returns a proposal that the runner must approve. Can change workout type, distance, pace, or swap days.';
    }

    public function schema(JsonSchema $schema): array
    {
        return [
            'changes' => $schema->string()->required()->description('JSON array of changes: [{"training_day_id": 1, "type": "easy", "title": "Easy Run", "description": "...", "target_km": 5, "target_pace_seconds_per_km": 330, "target_heart_rate_zone": 2}]'),
        ];
    }

    public function handle(Request $request): string
    {
        $goal = $this->user->goals()->where('status', GoalStatus::Active)->latest()->first();

        return json_encode([
            'requires_approval' => true,
            'proposal_type' => 'modify_schedule',
            'payload' => [
                'goal_id' => $goal?->id,
                'changes' => json_decode($request['changes'], true) ?? [],
            ],
        ]);
    }
}
