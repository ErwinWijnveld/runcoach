<?php

namespace Tests\Feature\Support;

use App\Enums\HeartRateZonesSource;
use App\Models\User;
use App\Models\WearableActivity;
use App\Support\HeartRateZoneDeriver;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class HeartRateZoneDeriverTest extends TestCase
{
    use LazilyRefreshDatabase;

    private HeartRateZoneDeriver $deriver;

    protected function setUp(): void
    {
        parent::setUp();
        $this->deriver = app(HeartRateZoneDeriver::class);
    }

    public function test_falls_back_to_default_without_age(): void
    {
        $user = User::factory()->create();

        $result = $this->deriver->derive($user, age: null, restingHeartRate: null);

        $this->assertSame(HeartRateZonesSource::Default, $result->source);
        $this->assertNull($result->maxHeartRate);
        $this->assertSame(0, $result->sampleCount);
    }

    public function test_age_only_uses_tanaka_percent_of_max(): void
    {
        $user = User::factory()->create();

        $result = $this->deriver->derive($user, age: 40, restingHeartRate: null);

        $this->assertSame(HeartRateZonesSource::DerivedAge, $result->source);
        // Tanaka: 208 - 0.7 * 40 = 180
        $this->assertSame(180, $result->maxHeartRate);
        // %max-HR Z4 upper = 0.90 * 180 = 162
        $this->assertSame(162, $result->zones[3]['max']);
        $this->assertNull($result->restingHeartRate);
    }

    public function test_age_and_resting_uses_karvonen(): void
    {
        $user = User::factory()->create();

        $result = $this->deriver->derive($user, age: 40, restingHeartRate: 50);

        $this->assertSame(HeartRateZonesSource::DerivedAge, $result->source);
        $this->assertSame(180, $result->maxHeartRate);
        // Karvonen: HRR = 130, Z4 upper = 50 + 0.90*130 = 167
        $this->assertSame(167, $result->zones[3]['max']);
        $this->assertSame(50, $result->restingHeartRate);
    }

    public function test_zones_are_contiguous_and_open_ended(): void
    {
        $user = User::factory()->create();

        $result = $this->deriver->derive($user, age: 30, restingHeartRate: null);

        $zones = $result->zones;
        $this->assertCount(5, $zones);
        $this->assertSame(0, $zones[0]['min']);
        $this->assertSame(-1, $zones[4]['max']);
        for ($i = 1; $i < 5; $i++) {
            $this->assertSame($zones[$i - 1]['max'], $zones[$i]['min']);
        }
    }

    public function test_implausible_age_falls_through_to_default(): void
    {
        $user = User::factory()->create();

        $result = $this->deriver->derive($user, age: 200, restingHeartRate: null);

        $this->assertSame(HeartRateZonesSource::Default, $result->source);
    }

    public function test_implausible_resting_hr_is_ignored_but_age_survives(): void
    {
        $user = User::factory()->create();

        $result = $this->deriver->derive($user, age: 30, restingHeartRate: 5);

        $this->assertSame(HeartRateZonesSource::DerivedAge, $result->source);
        $this->assertNull($result->restingHeartRate);
    }

    /* ---------- Upward correction (Garmin-style) ---------- */

    public function test_normal_training_does_not_drag_max_downward(): void
    {
        // The bug we're guarding against: runner observed 171 max in their
        // last 12 runs (none of them all-out). Tanaka with age 35 gives
        // 184. Empirical-as-primary would have set max to 171. Upward-only
        // correction must NOT touch this — observed is below Tanaka.
        $user = User::factory()->create();
        for ($i = 0; $i < 12; $i++) {
            $this->makeRun($user, maxHr: 171, daysAgo: $i + 1);
        }

        $result = $this->deriver->derive($user, age: 35, restingHeartRate: null);

        // Tanaka: 208 - 0.7 * 35 = 183.5 → 184
        $this->assertSame(184, $result->maxHeartRate);
    }

    public function test_genuine_max_effort_corrects_upward(): void
    {
        // Three race-day or all-out interval observations clearly above
        // Tanaka. Upward correction kicks in.
        $user = User::factory()->create();
        // Tanaka for age 35 = 184. Threshold = 184 + 5 = 189.
        $this->makeRun($user, maxHr: 195, daysAgo: 3);  // race PB
        $this->makeRun($user, maxHr: 193, daysAgo: 14); // VO2max session
        $this->makeRun($user, maxHr: 191, daysAgo: 30); // hard tempo
        // A bunch of normal training runs (well below threshold) — must
        // not affect anything.
        for ($i = 0; $i < 10; $i++) {
            $this->makeRun($user, maxHr: 165, daysAgo: 50 + $i);
        }

        $result = $this->deriver->derive($user, age: 35, restingHeartRate: null);

        // Median of [195, 193, 191] = 193
        $this->assertSame(193, $result->maxHeartRate);
    }

    public function test_two_high_observations_is_not_enough_to_correct(): void
    {
        $user = User::factory()->create();
        // Only 2 observations above threshold — needs ≥3.
        $this->makeRun($user, maxHr: 195, daysAgo: 3);
        $this->makeRun($user, maxHr: 193, daysAgo: 14);
        for ($i = 0; $i < 10; $i++) {
            $this->makeRun($user, maxHr: 165, daysAgo: 30 + $i);
        }

        $result = $this->deriver->derive($user, age: 35, restingHeartRate: null);

        // Tanaka prior survives.
        $this->assertSame(184, $result->maxHeartRate);
    }

    public function test_one_glitch_in_upward_observations_is_absorbed(): void
    {
        // 5 high observations, one is a sensor glitch at 218 (still under
        // MAX_PHYSIO_HR=220). Median-of-top-5 absorbs it instead of
        // letting it dominate.
        $user = User::factory()->create();
        $this->makeRun($user, maxHr: 218, daysAgo: 3);
        $this->makeRun($user, maxHr: 195, daysAgo: 14);
        $this->makeRun($user, maxHr: 194, daysAgo: 20);
        $this->makeRun($user, maxHr: 193, daysAgo: 28);
        $this->makeRun($user, maxHr: 192, daysAgo: 40);

        $result = $this->deriver->derive($user, age: 35, restingHeartRate: null);

        // Median of [218, 195, 194, 193, 192] = 194
        $this->assertSame(194, $result->maxHeartRate);
    }

    public function test_upward_correction_filters_out_of_range_max(): void
    {
        // Glitches above MAX_PHYSIO_HR are excluded from the candidate
        // pool entirely — they don't even contribute to sample count.
        $user = User::factory()->create();
        $this->makeRun($user, maxHr: 250, daysAgo: 3); // physiologically impossible
        $this->makeRun($user, maxHr: 240, daysAgo: 14);
        // Two genuine highs but only 2 — under threshold count.
        $this->makeRun($user, maxHr: 195, daysAgo: 30);
        $this->makeRun($user, maxHr: 193, daysAgo: 45);

        $result = $this->deriver->derive($user, age: 35, restingHeartRate: null);

        // Both 250 and 240 are filtered → only 2 valid → no correction.
        $this->assertSame(184, $result->maxHeartRate);
    }

    public function test_upward_correction_filters_recovery_jogs(): void
    {
        $user = User::factory()->create();
        // High max readings but average HR is recovery-pace — must NOT
        // count toward the high-effort signal even if max momentarily spiked.
        $this->makeRun($user, maxHr: 195, daysAgo: 3, avgHr: 110);
        $this->makeRun($user, maxHr: 193, daysAgo: 14, avgHr: 115);
        $this->makeRun($user, maxHr: 191, daysAgo: 28, avgHr: 105);

        $result = $this->deriver->derive($user, age: 35, restingHeartRate: null);

        $this->assertSame(184, $result->maxHeartRate);
    }

    public function test_upward_correction_filters_too_short_runs(): void
    {
        $user = User::factory()->create();
        // Five high readings but all under 10 min — sprint-only sessions
        // or aborted runs. Don't count.
        for ($i = 0; $i < 5; $i++) {
            $this->makeRun($user, maxHr: 195, daysAgo: $i * 7 + 1, durationSec: 300);
        }

        $result = $this->deriver->derive($user, age: 35, restingHeartRate: null);

        $this->assertSame(184, $result->maxHeartRate);
    }

    public function test_upward_correction_excludes_non_running(): void
    {
        $user = User::factory()->create();
        // Cycling efforts can hit higher HR (different muscle group, etc.)
        // — must not contaminate running zones.
        for ($i = 0; $i < 5; $i++) {
            $this->makeRun($user, maxHr: 200, daysAgo: $i * 7 + 1, type: 'Ride');
        }

        $result = $this->deriver->derive($user, age: 35, restingHeartRate: null);

        $this->assertSame(184, $result->maxHeartRate);
    }

    public function test_correction_with_resting_hr_uses_karvonen(): void
    {
        // Combined: high observations bump max, RHR drives Karvonen
        // bounds. Verifies correction + RHR play together correctly.
        $user = User::factory()->create();
        $this->makeRun($user, maxHr: 195, daysAgo: 3);
        $this->makeRun($user, maxHr: 193, daysAgo: 14);
        $this->makeRun($user, maxHr: 191, daysAgo: 28);

        $result = $this->deriver->derive($user, age: 35, restingHeartRate: 50);

        // Median of [195, 193, 191] = 193, HRR = 143, Z4 upper = 50 + 0.9*143 = 178.7 → 179
        $this->assertSame(193, $result->maxHeartRate);
        $this->assertSame(179, $result->zones[3]['max']);
    }

    private function makeRun(
        User $user,
        int $maxHr,
        int $daysAgo,
        int $durationSec = 1800,
        float $avgHr = 150.0,
        string $type = 'Run',
    ): WearableActivity {
        return WearableActivity::factory()->create([
            'user_id' => $user->id,
            'type' => $type,
            'max_heartrate' => $maxHr,
            'average_heartrate' => $avgHr,
            'duration_seconds' => $durationSec,
            'start_date' => now()->subDays($daysAgo),
        ]);
    }
}
