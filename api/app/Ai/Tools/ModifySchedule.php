<?php

namespace App\Ai\Tools;

use App\Enums\GoalStatus;
use App\Enums\ProposalType;
use App\Enums\TrainingType;
use App\Models\User;
use Illuminate\Contracts\JsonSchema\JsonSchema;
use Laravel\Ai\Contracts\Tool;
use Laravel\Ai\Tools\Request;

class ModifySchedule implements Tool
{
    public function __construct(private User $user) {}

    public function description(): string
    {
        return <<<'DESC'
        Modify specific days in the runner's ACTIVE (already-accepted) training plan. Returns a proposal that the runner must approve.

        USE THIS only for an active plan (a Goal with status=active and persisted TrainingDay rows). Not for editing a pending or rejected proposal - use `edit_schedule` for that. If the runner has no active plan, this tool cannot do anything.

        Changes use `training_day_id` which only exists after a plan is accepted.
        DESC;
    }

    public function schema(JsonSchema $schema): array
    {
        $trainingTypes = TrainingType::activeValuesAsPipe();

        return [
            'changes' => $schema->string()->required()->description('JSON array of changes: [{"training_day_id": 1, "type": "'.$trainingTypes.'", "title": "Easy Run", "description": "...", "target_km": 5, "target_pace_seconds_per_km": 330, "target_heart_rate_zone": 2}]'),
        ];
    }

    public function handle(Request $request): string
    {
        $goal = $this->user->goals()->where('status', GoalStatus::Active)->latest()->first();

        return json_encode([
            'requires_approval' => true,
            'proposal_type' => ProposalType::ModifySchedule->value,
            'payload' => [
                'goal_id' => $goal?->id,
                'changes' => json_decode($request['changes'], true) ?? [],
            ],
        ]);
    }
}
