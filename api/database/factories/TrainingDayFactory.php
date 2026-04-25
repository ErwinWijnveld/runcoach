<?php

namespace Database\Factories;

use App\Enums\TrainingType;
use App\Models\TrainingDay;
use App\Models\TrainingWeek;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<TrainingDay>
 */
class TrainingDayFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'training_week_id' => TrainingWeek::factory(),
            'date' => fake()->dateTimeBetween('+1 week', '+4 months'),
            'type' => fake()->randomElement(TrainingType::values()),
            'title' => fake()->randomElement(['Easy Run', 'Tempo Run', 'Threshold Run', 'Interval Session', 'Long Run']),
            'description' => fake()->optional()->sentence(),
            'target_km' => fake()->randomFloat(1, 3, 25),
            'target_pace_seconds_per_km' => fake()->numberBetween(240, 420),
            'target_heart_rate_zone' => fake()->numberBetween(1, 5),
            'intervals_json' => null,
            'order' => fake()->numberBetween(1, 7),
        ];
    }
}
