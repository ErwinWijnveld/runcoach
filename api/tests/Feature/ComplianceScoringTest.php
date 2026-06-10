<?php

namespace Tests\Feature;

use App\Enums\GoalStatus;
use App\Enums\TrainingType;
use App\Models\Goal;
use App\Models\TrainingDay;
use App\Models\TrainingWeek;
use App\Models\User;
use App\Models\WearableActivity;
use App\Services\ComplianceScoringService;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class ComplianceScoringTest extends TestCase
{
    use LazilyRefreshDatabase;

    private ComplianceScoringService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = new ComplianceScoringService;
    }

    private function createUserWithPlan(array $dayOverrides = []): array
    {
        $user = User::factory()->create();
        $goal = Goal::factory()->create([
            'user_id' => $user->id,
            'status' => GoalStatus::Active,
        ]);
        $week = TrainingWeek::factory()->create([
            'goal_id' => $goal->id,
            'starts_at' => now()->startOfWeek(),
        ]);
        $day = TrainingDay::factory()->create(array_merge([
            'training_week_id' => $week->id,
            'date' => now()->toDateString(),
            'type' => TrainingType::Tempo,
            'target_km' => 8.0,
            'target_pace_seconds_per_km' => 285,
            'target_heart_rate_zone' => 3,
        ], $dayOverrides));

        return [$user, $day];
    }

    public function test_perfect_compliance_scores_10(): void
    {
        [$user, $day] = $this->createUserWithPlan();

        $activity = WearableActivity::factory()->create([
            'user_id' => $user->id,
            'distance_meters' => 8000,
            'duration_seconds' => 2280,
            'average_pace_seconds_per_km' => 285,
            'average_heartrate' => 160,
            'start_date' => now(),
        ]);

        $this->service->matchAndScore($user, $activity);

        $result = $day->fresh()->result;
        $this->assertNotNull($result);
        $this->assertGreaterThanOrEqual(9.0, (float) $result->compliance_score);
    }

    public function test_no_matching_day_creates_no_result(): void
    {
        $user = User::factory()->create();

        $activity = WearableActivity::factory()->create([
            'user_id' => $user->id,
            'start_date' => now(),
        ]);

        $this->service->matchAndScore($user, $activity);

        $this->assertDatabaseCount('training_results', 0);
    }

    public function test_run_one_day_off_does_not_auto_match(): void
    {
        // A run the day BEFORE a planned session no longer auto-matches — it's
        // left unmatched so it surfaces as an off-plan run the user can link
        // manually. (Previously a ±1-day window would have matched it.)
        [$user, $day] = $this->createUserWithPlan(); // planned day is today

        $activity = WearableActivity::factory()->create([
            'user_id' => $user->id,
            'distance_meters' => 8000,
            'duration_seconds' => 2280,
            'average_pace_seconds_per_km' => 285,
            'average_heartrate' => 160,
            'start_date' => now()->subDay(),
        ]);

        $result = $this->service->matchAndScore($user, $activity);

        $this->assertNull($result);
        $this->assertNull($day->fresh()->result);
        $this->assertDatabaseCount('training_results', 0);
    }

    public function test_missing_heart_rate_redistributes_weights(): void
    {
        [$user, $day] = $this->createUserWithPlan();

        $activity = WearableActivity::factory()->create([
            'user_id' => $user->id,
            'distance_meters' => 8000,
            'duration_seconds' => 2280,
            'average_pace_seconds_per_km' => 285,
            'average_heartrate' => null,
            'start_date' => now(),
        ]);

        $this->service->matchAndScore($user, $activity);

        $result = $day->fresh()->result;
        $this->assertNotNull($result);
        $this->assertNull($result->heart_rate_score);
        $this->assertGreaterThan(0, (float) $result->compliance_score);
    }

    public function test_hr_inside_user_zone_scores_full(): void
    {
        $user = User::factory()->create([
            'heart_rate_zones' => [
                ['min' => 0, 'max' => 120],
                ['min' => 120, 'max' => 145], // Zone 2 — we'll target this
                ['min' => 145, 'max' => 165],
                ['min' => 165, 'max' => 180],
                ['min' => 180, 'max' => -1],
            ],
        ]);

        [, $day] = $this->createUserWithPlanForUser($user, [
            'target_heart_rate_zone' => 2,
        ]);

        // 140 bpm — squarely within user's Z2 [120, 145]
        $activity = WearableActivity::factory()->create([
            'user_id' => $user->id,
            'distance_meters' => 8000,
            'duration_seconds' => 2280,
            'average_pace_seconds_per_km' => 285,
            'average_heartrate' => 140,
            'start_date' => now(),
        ]);

        $this->service->matchAndScore($user, $activity);

        $result = $day->fresh()->result;
        $this->assertNotNull($result);
        $this->assertEqualsWithDelta(10.0, (float) $result->heart_rate_score, 0.01);
    }

    public function test_hr_outside_zone_is_penalised(): void
    {
        $user = User::factory()->create([
            'heart_rate_zones' => [
                ['min' => 0, 'max' => 120],
                ['min' => 120, 'max' => 145],
                ['min' => 145, 'max' => 165],
                ['min' => 165, 'max' => 180],
                ['min' => 180, 'max' => -1],
            ],
        ]);

        [, $day] = $this->createUserWithPlanForUser($user, [
            'target_heart_rate_zone' => 2, // [120, 145]
        ]);

        // 160 bpm — 15 bpm above zone max → 10 - 15/5 = 7.0
        $activity = WearableActivity::factory()->create([
            'user_id' => $user->id,
            'distance_meters' => 8000,
            'duration_seconds' => 2280,
            'average_pace_seconds_per_km' => 285,
            'average_heartrate' => 160,
            'start_date' => now(),
        ]);

        $this->service->matchAndScore($user, $activity);

        $result = $day->fresh()->result;
        $this->assertEqualsWithDelta(7.0, (float) $result->heart_rate_score, 0.1);
    }

    public function test_falls_back_to_default_zones_when_user_has_none(): void
    {
        $user = User::factory()->create(['heart_rate_zones' => null]);

        [, $day] = $this->createUserWithPlanForUser($user, [
            'target_heart_rate_zone' => 2, // default Z2: [115, 152]
        ]);

        $activity = WearableActivity::factory()->create([
            'user_id' => $user->id,
            'distance_meters' => 8000,
            'duration_seconds' => 2280,
            'average_pace_seconds_per_km' => 285,
            'average_heartrate' => 140, // inside default Z2
            'start_date' => now(),
        ]);

        $this->service->matchAndScore($user, $activity);

        $this->assertEqualsWithDelta(10.0, (float) $day->fresh()->result->heart_rate_score, 0.01);
    }

    /**
     * Canonical grouped blueprint used by the interval scoring tests:
     * 5×800m @ 4:30/km (270 s/km), 90s recoveries, 60s warmup, 300s cooldown.
     * Derived values (asserted against below):
     *  - work volume    = 4.0 km
     *  - jog pace       = 370 s/km (work + 100) → pace band [270, 460]
     *  - target_km      = 6.2 (estimateTotalKm via the saving hook)
     *  - distance band  = [4.0, 6.2 × 1.8 = 11.16]
     */
    private const INTERVAL_BLUEPRINT = [
        'warmup_seconds' => 60,
        'steps' => [
            ['type' => 'block', 'reps' => 5, 'work_distance_m' => 800, 'work_duration_seconds' => null, 'work_pace_seconds_per_km' => 270, 'recovery_seconds' => 90],
        ],
        'cooldown_seconds' => 300,
    ];

    private function createIntervalPlan(array $dayOverrides = [], array $blueprint = self::INTERVAL_BLUEPRINT): array
    {
        return $this->createUserWithPlan(array_merge([
            'type' => TrainingType::Interval,
            'target_pace_seconds_per_km' => null,
            'target_heart_rate_zone' => 5,
            'intervals_json' => $blueprint,
        ], $dayOverrides));
    }

    public function test_interval_day_correct_execution_scores_full_compliance(): void
    {
        // The whole point of the 2026-06-10 scoring change: a session run
        // exactly as prescribed — reps done, peaks touched Z4, average pace
        // mid-band because recoveries/warmup/cooldown dilute it — must score
        // 10, where the old avg-HR-vs-Z5 + symmetric-distance model gave 2-4.
        [$user, $day] = $this->createIntervalPlan();

        $activity = WearableActivity::factory()->create([
            'user_id' => $user->id,
            'distance_meters' => 6200,
            'average_pace_seconds_per_km' => 360, // inside [270, 460]
            'average_heartrate' => 152, // session average — must NOT be compared to Z5
            'max_heartrate' => 178, // peaks touched default Z4 [171, 190]
            'start_date' => now(),
        ]);

        $this->service->matchAndScore($user, $activity);

        $result = $day->fresh()->result;
        $this->assertEqualsWithDelta(10.0, (float) $result->pace_score, 0.05);
        $this->assertEqualsWithDelta(10.0, (float) $result->distance_score, 0.05);
        $this->assertEqualsWithDelta(10.0, (float) $result->heart_rate_score, 0.05);
        $this->assertEqualsWithDelta(10.0, (float) $result->compliance_score, 0.05);
    }

    public function test_interval_day_pace_slower_than_band_is_penalised(): void
    {
        [$user, $day] = $this->createIntervalPlan();

        // Band max = jog (370) + 90 margin = 460. 520 is 60s over.
        $activity = WearableActivity::factory()->create([
            'user_id' => $user->id,
            'distance_meters' => 6200,
            'average_pace_seconds_per_km' => 520,
            'max_heartrate' => 178,
            'start_date' => now(),
        ]);

        $this->service->matchAndScore($user, $activity);

        $expected = 10 - ((520 - 460) / 460 * 100) / 2.2;
        $this->assertEqualsWithDelta(round($expected, 1), (float) $day->fresh()->result->pace_score, 0.05);
    }

    public function test_interval_day_pace_faster_than_work_pace_is_penalised(): void
    {
        // Faster than the work-set average means the recoveries were skipped
        // (or a different session entirely) — that's non-compliance too.
        [$user, $day] = $this->createIntervalPlan();

        $activity = WearableActivity::factory()->create([
            'user_id' => $user->id,
            'distance_meters' => 6200,
            'average_pace_seconds_per_km' => 240, // below band min 270
            'max_heartrate' => 178,
            'start_date' => now(),
        ]);

        $this->service->matchAndScore($user, $activity);

        $expected = 10 - ((270 - 240) / 270 * 100) / 2.2;
        $this->assertEqualsWithDelta(round($expected, 1), (float) $day->fresh()->result->pace_score, 0.05);
    }

    public function test_interval_day_pace_score_null_without_work_paces(): void
    {
        $blueprint = self::INTERVAL_BLUEPRINT;
        $blueprint['steps'][0]['work_pace_seconds_per_km'] = null;
        [$user, $day] = $this->createIntervalPlan(blueprint: $blueprint);

        $activity = WearableActivity::factory()->create([
            'user_id' => $user->id,
            'distance_meters' => 6200,
            'average_pace_seconds_per_km' => 360,
            'max_heartrate' => 178,
            'start_date' => now(),
        ]);

        $this->service->matchAndScore($user, $activity);

        $result = $day->fresh()->result;
        $this->assertNull($result->pace_score);
        $this->assertNotNull($result->distance_score);
        $this->assertNotNull($result->heart_rate_score);
    }

    public function test_interval_day_max_hr_touching_zone_below_target_scores_full(): void
    {
        // Z5 day → the peaks must have touched Z4 (default min 171). The
        // session AVERAGE is irrelevant — set it absurdly low to prove the
        // old avg-vs-Z5 comparison is gone.
        [$user, $day] = $this->createIntervalPlan();

        $activity = WearableActivity::factory()->create([
            'user_id' => $user->id,
            'distance_meters' => 6200,
            'average_pace_seconds_per_km' => 360,
            'average_heartrate' => 130,
            'max_heartrate' => 172,
            'start_date' => now(),
        ]);

        $this->service->matchAndScore($user, $activity);

        $this->assertEqualsWithDelta(10.0, (float) $day->fresh()->result->heart_rate_score, 0.05);
    }

    public function test_interval_day_max_hr_below_touch_zone_is_penalised(): void
    {
        [$user, $day] = $this->createIntervalPlan();

        // Default Z4 min = 171; max HR 156 is 15 bpm short → 10 − 15/5 = 7.0.
        $activity = WearableActivity::factory()->create([
            'user_id' => $user->id,
            'distance_meters' => 6200,
            'average_pace_seconds_per_km' => 360,
            'max_heartrate' => 156,
            'start_date' => now(),
        ]);

        $this->service->matchAndScore($user, $activity);

        $this->assertEqualsWithDelta(7.0, (float) $day->fresh()->result->heart_rate_score, 0.05);
    }

    public function test_interval_day_without_max_hr_scores_null_hr(): void
    {
        // No max HR → HR component drops out entirely. The avg-HR-vs-zone
        // comparison must NOT kick in as a fallback (avg is present here).
        [$user, $day] = $this->createIntervalPlan();

        $activity = WearableActivity::factory()->create([
            'user_id' => $user->id,
            'distance_meters' => 6200,
            'average_pace_seconds_per_km' => 360,
            'average_heartrate' => 160,
            'max_heartrate' => null,
            'start_date' => now(),
        ]);

        $this->service->matchAndScore($user, $activity);

        $result = $day->fresh()->result;
        $this->assertNull($result->heart_rate_score);
        // Distance + pace both perfect → renormalised overall stays 10.
        $this->assertEqualsWithDelta(10.0, (float) $result->compliance_score, 0.05);
    }

    public function test_interval_day_distance_overshoot_within_band_scores_full(): void
    {
        // target_km (6.2) assumes a 120s-capped warmup; a real 10-15 min
        // warmup + cooldown easily lands at 1.7× the target. Up to 1.8× is
        // correct execution, not non-compliance.
        [$user, $day] = $this->createIntervalPlan();

        $activity = WearableActivity::factory()->create([
            'user_id' => $user->id,
            'distance_meters' => 10500, // 10.5 km ≤ 6.2 × 1.8 = 11.16
            'average_pace_seconds_per_km' => 360,
            'max_heartrate' => 178,
            'start_date' => now(),
        ]);

        $this->service->matchAndScore($user, $activity);

        $this->assertEqualsWithDelta(10.0, (float) $day->fresh()->result->distance_score, 0.05);
    }

    public function test_interval_day_distance_under_work_volume_is_penalised(): void
    {
        // Below the work volume (5×800m = 4.0 km) the reps are demonstrably
        // incomplete — steep penalty relative to the work floor.
        [$user, $day] = $this->createIntervalPlan();

        $activity = WearableActivity::factory()->create([
            'user_id' => $user->id,
            'distance_meters' => 3000,
            'average_pace_seconds_per_km' => 360,
            'max_heartrate' => 178,
            'start_date' => now(),
        ]);

        $this->service->matchAndScore($user, $activity);

        $expected = 10 - ((4.0 - 3.0) / 4.0) * 15; // 6.25
        $this->assertEqualsWithDelta(round($expected, 1), (float) $day->fresh()->result->distance_score, 0.05);
    }

    public function test_interval_day_distance_far_overshoot_mildly_penalised(): void
    {
        [$user, $day] = $this->createIntervalPlan();

        $targetKm = (float) $day->fresh()->target_km; // 6.2
        $activity = WearableActivity::factory()->create([
            'user_id' => $user->id,
            'distance_meters' => 14300, // well past the 1.8× band edge
            'average_pace_seconds_per_km' => 360,
            'max_heartrate' => 178,
            'start_date' => now(),
        ]);

        $this->service->matchAndScore($user, $activity);

        $bandMax = $targetKm * 1.8;
        $expected = 10 - ((14.3 - $bandMax) / $targetKm) * 7.5;
        $this->assertEqualsWithDelta(round($expected, 1), (float) $day->fresh()->result->distance_score, 0.05);
    }

    private function createUserWithPlanForUser(User $user, array $dayOverrides = []): array
    {
        $goal = Goal::factory()->create([
            'user_id' => $user->id,
            'status' => GoalStatus::Active,
        ]);
        $week = TrainingWeek::factory()->create([
            'goal_id' => $goal->id,
            'starts_at' => now()->startOfWeek(),
        ]);
        $day = TrainingDay::factory()->create(array_merge([
            'training_week_id' => $week->id,
            'date' => now()->toDateString(),
            'type' => TrainingType::Tempo,
            'target_km' => 8.0,
            'target_pace_seconds_per_km' => 285,
        ], $dayOverrides));

        return [$user, $day];
    }
}
