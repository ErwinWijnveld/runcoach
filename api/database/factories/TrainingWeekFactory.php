<?php

namespace Database\Factories;

use App\Models\Goal;
use App\Models\TrainingWeek;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<TrainingWeek>
 */
class TrainingWeekFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'goal_id' => Goal::factory(),
            'week_number' => fake()->numberBetween(1, 16),
            'starts_at' => fake()->dateTimeBetween('+1 week', '+4 months'),
            'total_km' => fake()->randomFloat(1, 15, 80),
            'focus' => fake()->randomElement(['base building', 'tempo development', 'speed work', 'race prep', 'taper', 'recovery']),
            'coach_notes' => null,
        ];
    }
}
