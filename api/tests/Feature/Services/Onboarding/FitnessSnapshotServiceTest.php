<?php

namespace Tests\Feature\Services\Onboarding;

use App\Enums\PaceConfidence;
use App\Enums\PaceDerivation;
use App\Models\User;
use App\Models\WearableActivity;
use App\Services\Onboarding\FitnessSnapshotService;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class FitnessSnapshotServiceTest extends TestCase
{
    use LazilyRefreshDatabase;

    /**
     * Tanaka-derived zones at age 35 give Z5 lower around 168 bpm
     * (190 max × 0.9 = 171; close enough). We bake the zones in
     * directly so tests don't depend on age inference.
     *
     * @return array<int, array{min:int, max:int}>
     */
    private function defaultZones(): array
    {
        return [
            ['min' => 0, 'max' => 114],
            ['min' => 114, 'max' => 133],
            ['min' => 133, 'max' => 152],
            ['min' => 152, 'max' => 171],
            ['min' => 171, 'max' => -1],
        ];
    }

    private function userWithZones(): User
    {
        return User::factory()->create([
            'heart_rate_zones' => $this->defaultZones(),
            'heart_rate_zones_source' => 'derived_age',
        ]);
    }

    public function test_tier1_recent_threshold_effort_wins_over_zone_mining(): void
    {
        $user = $this->userWithZones();

        // A clear tempo: 30 min, avg HR 165 (≥ 85% of derived max 190),
        // 6 km, 5:00/km pace, 5 days ago. Should be picked as Tier 1.
        WearableActivity::factory()->create([
            'user_id' => $user->id,
            'type' => 'Run',
            'distance_meters' => 6000,
            'duration_seconds' => 1800,
            'average_pace_seconds_per_km' => 300,
            'average_heartrate' => 165.0,
            'start_date' => now()->subDays(5),
        ]);

        // Some Z2 noise to make sure Tier 1 still wins.
        WearableActivity::factory()->count(5)->create([
            'user_id' => $user->id,
            'type' => 'Run',
            'distance_meters' => 8000,
            'duration_seconds' => 2880,
            'average_pace_seconds_per_km' => 360,
            'average_heartrate' => 130.0,
            'start_date' => now()->subDays(20),
        ]);

        $snapshot = app(FitnessSnapshotService::class)->snapshot($user);

        $this->assertSame(PaceConfidence::High, $snapshot->confidence);
        $this->assertSame(PaceDerivation::RecentThresholdEffort, $snapshot->derivation);
        $this->assertSame(300, $snapshot->thresholdPaceSecondsPerKm);
        $this->assertSame(300 + 75, $snapshot->easyPaceSecondsPerKm);
        $this->assertSame(300 - 20, $snapshot->vo2maxPaceSecondsPerKm);
        $this->assertTrue($snapshot->hasIntensityHistory);
    }

    public function test_tier2_hr_zone_mining_finds_anchors_per_zone(): void
    {
        $user = $this->userWithZones();

        // Six Z2 runs (HR 120) at 6:00/km — easy anchor candidate.
        WearableActivity::factory()->count(6)->create([
            'user_id' => $user->id,
            'type' => 'Run',
            'distance_meters' => 8000,
            'duration_seconds' => 2880,
            'average_pace_seconds_per_km' => 360,
            'average_heartrate' => 120.0,
            'start_date' => fn () => now()->subDays(rand(5, 25)),
        ]);

        // Three Z4 runs (HR 160) at 5:00/km — threshold anchor.
        WearableActivity::factory()->count(3)->create([
            'user_id' => $user->id,
            'type' => 'Run',
            'distance_meters' => 6000,
            'duration_seconds' => 1800,
            'average_pace_seconds_per_km' => 300,
            'average_heartrate' => 160.0,
            // Just outside the Tier 1 30-day window so Tier 2 fires.
            'start_date' => fn () => now()->subDays(rand(45, 60)),
        ]);

        $snapshot = app(FitnessSnapshotService::class)->snapshot($user);

        $this->assertSame(PaceConfidence::Medium, $snapshot->confidence);
        $this->assertSame(PaceDerivation::HrZonePace, $snapshot->derivation);
        $this->assertNotNull($snapshot->thresholdPaceSecondsPerKm);
        // Threshold ≈ 300 + staleness penalty (5 sec for 30-60d window).
        $this->assertEqualsWithDelta(305, $snapshot->thresholdPaceSecondsPerKm, 1);
        // Easy anchor ≈ 360 (Z2).
        $this->assertEqualsWithDelta(360, $snapshot->easyPaceSecondsPerKm, 1);
    }

    public function test_tier2_orders_anchors_so_easy_never_faster_than_threshold(): void
    {
        // Pathological: all Z2 runs, plus a single Z4 run at WORSE pace
        // than the Z2 average (e.g. an injured runner who bricked a tempo).
        // The service must still produce a sensible easy > threshold ordering.
        $user = $this->userWithZones();

        WearableActivity::factory()->count(6)->create([
            'user_id' => $user->id,
            'type' => 'Run',
            'distance_meters' => 8000,
            'duration_seconds' => 2400,
            'average_pace_seconds_per_km' => 300, // Z2 at 5:00 (improbable but possible)
            'average_heartrate' => 120.0,
            'start_date' => fn () => now()->subDays(rand(40, 60)),
        ]);

        WearableActivity::factory()->count(3)->create([
            'user_id' => $user->id,
            'type' => 'Run',
            'distance_meters' => 6000,
            'duration_seconds' => 2400,
            'average_pace_seconds_per_km' => 400, // bricked Z4
            'average_heartrate' => 160.0,
            'start_date' => fn () => now()->subDays(rand(40, 60)),
        ]);

        $snapshot = app(FitnessSnapshotService::class)->snapshot($user);

        $this->assertSame(PaceDerivation::HrZonePace, $snapshot->derivation);
        $this->assertGreaterThan(
            $snapshot->thresholdPaceSecondsPerKm,
            $snapshot->easyPaceSecondsPerKm,
            'easy pace should be slower (higher number) than threshold',
        );
        $this->assertLessThan(
            $snapshot->thresholdPaceSecondsPerKm,
            $snapshot->vo2maxPaceSecondsPerKm,
            'vo2max pace should be faster (lower number) than threshold',
        );
    }

    public function test_tier3_recent_average_when_no_hr_data(): void
    {
        $user = $this->userWithZones();

        WearableActivity::factory()->count(4)->create([
            'user_id' => $user->id,
            'type' => 'Run',
            'distance_meters' => 5000,
            'duration_seconds' => 1800,
            'average_pace_seconds_per_km' => 360, // 6:00/km
            'average_heartrate' => null,
            'start_date' => fn () => now()->subDays(rand(5, 25)),
        ]);

        $snapshot = app(FitnessSnapshotService::class)->snapshot($user);

        $this->assertSame(PaceConfidence::Low, $snapshot->confidence);
        $this->assertSame(PaceDerivation::RecentAverage, $snapshot->derivation);
        $this->assertSame(360, $snapshot->easyPaceSecondsPerKm);
        $this->assertSame(330, $snapshot->thresholdPaceSecondsPerKm);
        $this->assertSame(310, $snapshot->vo2maxPaceSecondsPerKm);
        $this->assertFalse($snapshot->hasIntensityHistory);
    }

    public function test_tier4_fallback_when_no_runs(): void
    {
        $user = $this->userWithZones();

        $snapshot = app(FitnessSnapshotService::class)->snapshot($user);

        $this->assertSame(PaceConfidence::None, $snapshot->confidence);
        $this->assertSame(PaceDerivation::Fallback, $snapshot->derivation);
        $this->assertSame(360, $snapshot->easyPaceSecondsPerKm);
        $this->assertSame(300, $snapshot->thresholdPaceSecondsPerKm);
        $this->assertSame(270, $snapshot->vo2maxPaceSecondsPerKm);
        $this->assertSame(0.0, $snapshot->weeklyKmRecent4Weeks);
        $this->assertFalse($snapshot->hasIntensityHistory);
    }

    public function test_recency_penalty_applies_to_stale_zone_anchor(): void
    {
        $user = $this->userWithZones();

        // Z4 run was very stale (90 days ago) — should add the 10s penalty.
        WearableActivity::factory()->count(3)->create([
            'user_id' => $user->id,
            'type' => 'Run',
            'distance_meters' => 6000,
            'duration_seconds' => 1800,
            'average_pace_seconds_per_km' => 300,
            'average_heartrate' => 160.0,
            'start_date' => fn () => now()->subDays(85),
        ]);

        // Plus easy anchor.
        WearableActivity::factory()->count(4)->create([
            'user_id' => $user->id,
            'type' => 'Run',
            'distance_meters' => 8000,
            'duration_seconds' => 2880,
            'average_pace_seconds_per_km' => 360,
            'average_heartrate' => 125.0,
            'start_date' => fn () => now()->subDays(rand(60, 80)),
        ]);

        $snapshot = app(FitnessSnapshotService::class)->snapshot($user);

        $this->assertSame(PaceDerivation::HrZonePace, $snapshot->derivation);
        // 300 + 10s stale-penalty (60-90d bracket).
        $this->assertSame(310, $snapshot->thresholdPaceSecondsPerKm);
    }

    public function test_volume_window_uses_last_4_weeks(): void
    {
        $user = $this->userWithZones();

        // Three runs of 10km each in the last 4 weeks.
        WearableActivity::factory()->count(3)->create([
            'user_id' => $user->id,
            'type' => 'Run',
            'distance_meters' => 10000,
            'duration_seconds' => 3000,
            'average_pace_seconds_per_km' => 300,
            'average_heartrate' => 130.0,
            'start_date' => fn () => now()->subDays(rand(1, 27)),
        ]);

        // Plus old runs that should be ignored.
        WearableActivity::factory()->count(20)->create([
            'user_id' => $user->id,
            'type' => 'Run',
            'distance_meters' => 10000,
            'duration_seconds' => 3000,
            'average_pace_seconds_per_km' => 300,
            'average_heartrate' => 130.0,
            'start_date' => fn () => now()->subDays(rand(60, 89)),
        ]);

        $snapshot = app(FitnessSnapshotService::class)->snapshot($user);

        // 30 km total in 4 weeks → 7.5 km/week.
        $this->assertEqualsWithDelta(7.5, $snapshot->weeklyKmRecent4Weeks, 0.1);
    }

    public function test_intensity_history_requires_two_distinct_hard_days(): void
    {
        $user = $this->userWithZones();

        // Two Z4 runs on two different days in last 60d.
        WearableActivity::factory()->create([
            'user_id' => $user->id,
            'type' => 'Run',
            'distance_meters' => 5000,
            'duration_seconds' => 1500,
            'average_pace_seconds_per_km' => 300,
            'average_heartrate' => 160.0,
            'start_date' => now()->subDays(40),
        ]);
        WearableActivity::factory()->create([
            'user_id' => $user->id,
            'type' => 'Run',
            'distance_meters' => 5000,
            'duration_seconds' => 1500,
            'average_pace_seconds_per_km' => 300,
            'average_heartrate' => 162.0,
            'start_date' => now()->subDays(50),
        ]);

        $snapshot = app(FitnessSnapshotService::class)->snapshot($user);

        $this->assertTrue($snapshot->hasIntensityHistory);
    }
}
