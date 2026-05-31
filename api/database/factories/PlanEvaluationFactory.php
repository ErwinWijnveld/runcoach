<?php

namespace Database\Factories;

use App\Enums\PlanEvaluationStatus;
use App\Models\Goal;
use App\Models\PlanEvaluation;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<PlanEvaluation>
 */
class PlanEvaluationFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'goal_id' => Goal::factory(),
            'training_week_id' => null,
            'scheduled_for' => now()->addWeeks(2)->toDateString(),
            'status' => PlanEvaluationStatus::Pending,
            'report_markdown' => null,
            'proposal_id' => null,
            'notification_id' => null,
            'triggered_at' => null,
            'completed_at' => null,
        ];
    }
}
