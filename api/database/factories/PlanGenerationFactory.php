<?php

namespace Database\Factories;

use App\Enums\PlanGenerationStatus;
use App\Models\PlanGeneration;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<PlanGeneration>
 */
class PlanGenerationFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'status' => PlanGenerationStatus::Queued,
            'payload' => [
                'goal_type' => 'fitness',
                'days_per_week' => 3,
                'coach_style' => 'flexible',
            ],
            'conversation_id' => null,
            'proposal_id' => null,
            'error_message' => null,
            'started_at' => null,
            'completed_at' => null,
        ];
    }
}
