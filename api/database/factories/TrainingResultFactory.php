<?php

namespace Database\Factories;

use App\Models\StravaActivity;
use App\Models\TrainingDay;
use App\Models\TrainingResult;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<TrainingResult>
 */
class TrainingResultFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'training_day_id' => TrainingDay::factory(),
            'strava_activity_id' => StravaActivity::factory(),
            'compliance_score' => fake()->randomFloat(1, 1, 10),
            'actual_km' => fake()->randomFloat(1, 2, 30),
            'actual_pace_seconds_per_km' => fake()->numberBetween(240, 420),
            'actual_avg_heart_rate' => fake()->optional()->randomFloat(1, 120, 190),
            'pace_score' => fake()->randomFloat(1, 1, 10),
            'distance_score' => fake()->randomFloat(1, 1, 10),
            'heart_rate_score' => fake()->optional()->randomFloat(1, 1, 10),
            'ai_feedback' => fake()->optional()->paragraph(),
            'matched_at' => now(),
        ];
    }
}
