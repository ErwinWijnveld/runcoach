<?php

namespace Tests\Feature\Services;

use App\Models\User;
use App\Models\UserRunningProfile;
use App\Services\RunningProfileService;
use App\Services\Strava\StravaClient;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Mockery;
use Tests\TestCase;

class RunningProfileServiceTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_analyze_computes_metrics_from_strava_activities(): void
    {
        $user = User::factory()->create();

        // Fake 52 weeks, 3 runs per week, 10km each at 5:00/km pace
        $activities = [];
        for ($week = 0; $week < 52; $week++) {
            for ($run = 0; $run < 3; $run++) {
                $activities[] = [
                    'type' => 'Run',
                    'distance' => 10_000,
                    'moving_time' => 3000,
                    'start_date' => now()->subWeeks(52 - $week)->subDays($run)->toIso8601String(),
                    'elapsed_time' => 3000,
                ];
            }
        }

        $client = Mockery::mock(StravaClient::class);

        $service = new RunningProfileService($client);
        $profile = $service->computeMetrics($user, $activities);

        $this->assertInstanceOf(UserRunningProfile::class, $profile);
        $this->assertEquals(30.0, $profile->metrics['weekly_avg_km']);
        $this->assertEquals(3, $profile->metrics['weekly_avg_runs']);
        $this->assertEquals(300, $profile->metrics['avg_pace_seconds_per_km']);
        $this->assertEquals(3000, $profile->metrics['session_avg_duration_seconds']);
        $this->assertEquals(156, $profile->metrics['total_runs_12mo']);
        $this->assertEquals(1560.0, $profile->metrics['total_distance_km_12mo']);
        $this->assertEquals(100, $profile->metrics['consistency_score']);
    }

    public function test_analyze_handles_zero_activities(): void
    {
        $user = User::factory()->create();

        $client = Mockery::mock(StravaClient::class);

        $service = new RunningProfileService($client);
        $profile = $service->computeMetrics($user, []);

        $this->assertEquals(0, $profile->metrics['total_runs_12mo']);
        $this->assertEquals(0.0, $profile->metrics['weekly_avg_km']);
        $this->assertEquals(0, $profile->metrics['consistency_score']);
    }
}
