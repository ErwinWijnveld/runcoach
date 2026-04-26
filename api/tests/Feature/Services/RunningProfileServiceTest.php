<?php

namespace Tests\Feature\Services;

use App\Models\User;
use App\Models\UserRunningProfile;
use App\Models\WearableActivity;
use App\Services\RunningProfileService;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class RunningProfileServiceTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_analyze_computes_metrics_from_wearable_activities(): void
    {
        $user = User::factory()->create();

        // 50 weeks of synced runs (well inside the 52-week analysis window),
        // 3 runs per week, 10km each at 5:00/km pace.
        $now = now();
        for ($week = 1; $week <= 50; $week++) {
            for ($run = 0; $run < 3; $run++) {
                WearableActivity::factory()->create([
                    'user_id' => $user->id,
                    'type' => 'Run',
                    'distance_meters' => 10_000,
                    'duration_seconds' => 3000,
                    'average_pace_seconds_per_km' => 300,
                    'start_date' => $now->copy()->subWeeks($week)->subDays($run),
                ]);
            }
        }

        $profile = app(RunningProfileService::class)->analyze($user);

        $this->assertInstanceOf(UserRunningProfile::class, $profile);
        $this->assertEquals(150, $profile->metrics['total_runs_12mo']);
        $this->assertEquals(1500.0, $profile->metrics['total_distance_km_12mo']);
        $this->assertEquals(300, $profile->metrics['avg_pace_seconds_per_km']);
        $this->assertEquals(3000, $profile->metrics['session_avg_duration_seconds']);
        // 1500 km / 52 analysis weeks ≈ 28.8
        $this->assertEqualsWithDelta(28.8, $profile->metrics['weekly_avg_km'], 0.1);
        $this->assertEquals(3, $profile->metrics['weekly_avg_runs']);
    }

    public function test_get_or_analyze_returns_null_when_no_activities(): void
    {
        $user = User::factory()->create();

        $profile = app(RunningProfileService::class)->getOrAnalyze($user);

        $this->assertNull($profile);
    }

    public function test_get_or_analyze_returns_cached_profile_when_present(): void
    {
        $user = User::factory()->create();
        UserRunningProfile::factory()->for($user)->create([
            'metrics' => ['weekly_avg_km' => 99.9],
            'narrative_summary' => 'cached',
        ]);

        $profile = app(RunningProfileService::class)->getOrAnalyze($user);

        $this->assertSame('cached', $profile->narrative_summary);
        $this->assertEquals(99.9, $profile->metrics['weekly_avg_km']);
    }
}
