<?php

namespace Database\Factories;

use App\Models\User;
use App\Models\UserRunningProfile;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<UserRunningProfile>
 */
class UserRunningProfileFactory extends Factory
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
            'analyzed_at' => now(),
            'data_start_date' => now()->subYear()->toDateString(),
            'data_end_date' => now()->toDateString(),
            'metrics' => [
                'weekly_avg_km' => 32.5,
                'weekly_avg_runs' => 4,
                'avg_pace_seconds_per_km' => 305,
                'session_avg_duration_seconds' => 3600,
                'total_runs_12mo' => 208,
                'total_distance_km_12mo' => 1690.0,
                'consistency_score' => 85,
                'long_run_trend' => 'improving',
                'pace_trend' => 'flat',
            ],
            'narrative_summary' => 'Consistent weekly mileage with a steady pace.',
        ];
    }
}
