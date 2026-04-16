<?php

namespace Database\Factories;

use App\Models\Goal;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Goal>
 */
class GoalFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'type' => 'race',
            'name' => fake()->city().' '.fake()->randomElement(['Marathon', 'Half Marathon', '10K', '5K']),
            'distance' => fake()->randomElement(['5k', '10k', 'half_marathon', 'marathon']),
            'custom_distance_meters' => null,
            'goal_time_seconds' => fake()->numberBetween(900, 14400),
            'target_date' => fake()->dateTimeBetween('+1 month', '+6 months'),
            'status' => 'planning',
        ];
    }
}
