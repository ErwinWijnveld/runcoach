<?php

namespace Database\Factories;

use App\Models\StravaActivity;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<StravaActivity>
 */
class StravaActivityFactory extends Factory
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
            'strava_id' => fake()->unique()->randomNumber(9),
            'type' => 'Run',
            'name' => fake()->randomElement(['Morning Run', 'Evening Run', 'Lunch Run', 'Tempo Run', 'Long Run']),
            'distance_meters' => fake()->numberBetween(2000, 42000),
            'moving_time_seconds' => fake()->numberBetween(600, 18000),
            'elapsed_time_seconds' => fake()->numberBetween(600, 20000),
            'average_heartrate' => fake()->optional()->randomFloat(1, 120, 190),
            'average_speed' => fake()->randomFloat(2, 2.0, 5.5),
            'start_date' => fake()->dateTimeBetween('-2 months', 'now'),
            'summary_polyline' => null,
            'raw_data' => [],
            'synced_at' => now(),
        ];
    }
}
