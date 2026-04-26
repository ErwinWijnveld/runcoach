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
        // 150 runs / 52 weeks ≈ 2.9 — float now (was int-rounded which hid
        // sub-1-run/week values like "0" for casual runners with 20 runs/yr).
        $this->assertEqualsWithDelta(2.9, $profile->metrics['weekly_avg_runs'], 0.1);
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

    public function test_aggregates_heart_rate_and_derives_personalized_zones(): void
    {
        $user = User::factory()->create(['heart_rate_zones' => null]);
        $now = now();

        // 5 runs with HR samples, 2 without — averages should ignore the
        // null-HR runs and personalized zones should derive from observed
        // max HR (185).
        for ($i = 0; $i < 5; $i++) {
            WearableActivity::factory()->create([
                'user_id' => $user->id,
                'type' => 'Run',
                'distance_meters' => 5000,
                'duration_seconds' => 1500,
                'average_pace_seconds_per_km' => 300,
                'average_heartrate' => 150 + $i,
                'max_heartrate' => 175 + ($i * 2),
                'start_date' => $now->copy()->subDays($i + 1),
            ]);
        }
        // Manual / third-party imports without HR — must not skew averages.
        WearableActivity::factory()->count(2)->create([
            'user_id' => $user->id,
            'average_heartrate' => null,
            'max_heartrate' => null,
            'start_date' => $now->copy()->subDays(60),
        ]);

        $profile = app(RunningProfileService::class)->analyze($user);

        $this->assertSame(152, $profile->metrics['avg_heart_rate']);
        $this->assertSame(183, $profile->metrics['max_heart_rate']);
        $this->assertSame(5, $profile->metrics['hr_runs_count']);

        // Zones: 60/70/80/90% of 183 = 110/128/146/165, Z5 max = -1.
        $zones = $user->fresh()->heart_rate_zones;
        $this->assertNotNull($zones);
        $this->assertCount(5, $zones);
        $this->assertSame(110, $zones[0]['max']);
        $this->assertSame(165, $zones[3]['max']);
        $this->assertSame(-1, $zones[4]['max']);
    }

    public function test_skips_zone_derivation_when_user_has_manual_zones(): void
    {
        $manual = [
            ['min' => 0, 'max' => 100],
            ['min' => 100, 'max' => 130],
            ['min' => 130, 'max' => 150],
            ['min' => 150, 'max' => 170],
            ['min' => 170, 'max' => -1],
        ];
        $user = User::factory()->create(['heart_rate_zones' => $manual]);

        WearableActivity::factory()->count(5)->create([
            'user_id' => $user->id,
            'average_heartrate' => 150,
            'max_heartrate' => 200,
        ]);

        app(RunningProfileService::class)->analyze($user);

        $this->assertSame($manual, $user->fresh()->heart_rate_zones,
            "Don't clobber zones the user (or a future settings UI) set explicitly");
    }
}
