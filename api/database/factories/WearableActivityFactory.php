<?php

namespace Database\Factories;

use App\Models\User;
use App\Models\WearableActivity;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<WearableActivity>
 */
class WearableActivityFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $distance = fake()->numberBetween(2000, 42000);
        $duration = fake()->numberBetween(600, 18000);

        return [
            'user_id' => User::factory(),
            'source' => 'strava',
            'source_activity_id' => (string) fake()->unique()->randomNumber(9),
            'source_user_id' => null,
            'type' => 'Run',
            'name' => fake()->randomElement(['Morning Run', 'Evening Run', 'Lunch Run', 'Tempo Run', 'Long Run']),
            'distance_meters' => $distance,
            'duration_seconds' => $duration,
            'elapsed_seconds' => $duration + fake()->numberBetween(0, 200),
            'average_pace_seconds_per_km' => (int) round($duration / max(1, $distance / 1000)),
            'average_heartrate' => fake()->optional()->randomFloat(1, 120, 190),
            'max_heartrate' => null,
            'elevation_gain_meters' => fake()->optional()->numberBetween(0, 500),
            'calories_kcal' => fake()->optional()->numberBetween(150, 1200),
            'start_date' => fake()->dateTimeBetween('-2 months', 'now'),
            'end_date' => null,
            'raw_data' => [],
            'synced_at' => now(),
        ];
    }
}
