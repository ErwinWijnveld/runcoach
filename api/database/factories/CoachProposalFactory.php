<?php

namespace Database\Factories;

use App\Models\CoachProposal;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<CoachProposal>
 */
class CoachProposalFactory extends Factory
{
    public function definition(): array
    {
        return [
            'agent_message_id' => fake()->uuid(),
            'user_id' => User::factory(),
            'type' => 'create_schedule',
            'payload' => ['weeks' => []],
            'status' => 'pending',
            'applied_at' => null,
        ];
    }
}
