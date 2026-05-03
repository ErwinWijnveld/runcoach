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

    public function test_interval_day_returns_null_pace_score(): void
    {
        // Interval days have no day-level target_pace_seconds_per_km — the
        // work pace lives per segment in `intervals_json`. The actual run's
        // full-run avg pace mixes work + recovery + warmup + cooldown so
        // we explicitly DO NOT score it. Compliance falls back to
        // distance + HR.
        [$user, $day] = $this->createUserWithPlan([
            'type' => TrainingType::Interval,
            'target_pace_seconds_per_km' => null,
            'intervals_json' => [
                ['kind' => 'warmup', 'label' => 'Warm', 'distance_m' => null, 'duration_seconds' => 60, 'target_pace_seconds_per_km' => null],
                ['kind' => 'work', 'label' => '400m', 'distance_m' => 400, 'duration_seconds' => null, 'target_pace_seconds_per_km' => 270],
                ['kind' => 'recovery', 'label' => 'Rec', 'distance_m' => null, 'duration_seconds' => 90, 'target_pace_seconds_per_km' => null],
                ['kind' => 'work', 'label' => '400m', 'distance_m' => 400, 'duration_seconds' => null, 'target_pace_seconds_per_km' => 270],
                ['kind' => 'cooldown', 'label' => 'Cool', 'distance_m' => null, 'duration_seconds' => 300, 'target_pace_seconds_per_km' => null],
            ],
        ]);

        $activity = WearableActivity::factory()->create([
            'user_id' => $user->id,
            'distance_meters' => 8000,
            // Full-run avg pace — intentionally far off the work-set target
            // (270s/km) because it includes the warmup/recovery/cooldown.
            // The scoring service must NOT penalise this; pace_score → null.
            'average_pace_seconds_per_km' => 360,
            'average_heartrate' => 160,
            'start_date' => now(),
        ]);

        $this->service->matchAndScore($user, $activity);

        $result = $day->fresh()->result;
        $this->assertNotNull($result);
        $this->assertNull($result->pace_score, 'interval days must not produce a pace score');
        $this->assertNotNull($result->distance_score);
        $this->assertNotNull($result->heart_rate_score);
    }

    public function test_interval_day_overall_uses_distance_and_hr_only(): void
    {
        [$user, $day] = $this->createUserWithPlan([
            'type' => TrainingType::Interval,
            'target_km' => 5.0,
            'target_pace_seconds_per_km' => null,
            'target_heart_rate_zone' => 4,
            'intervals_json' => [
                ['kind' => 'work', 'label' => '400m', 'distance_m' => 400, 'duration_seconds' => null, 'target_pace_seconds_per_km' => 270],
            ],
        ]);

        // Distance perfect + HR perfect → overall must be ~10.0 even though
        // pace_score is null. Under the previous weighting an interval
        // session would have inherited the bogus 7.0 pace default and
        // dragged compliance down (~8.2). Now it sits at 10.0.
        $activity = WearableActivity::factory()->create([
            'user_id' => $user->id,
            'distance_meters' => 5000,
            'average_pace_seconds_per_km' => 360, // anything — must not matter
            'average_heartrate' => 175, // squarely in default Z4 [171-190]
            'start_date' => now(),
        ]);

        $this->service->matchAndScore($user, $activity);

        $result = $day->fresh()->result;
        $this->assertEqualsWithDelta(10.0, (float) $result->compliance_score, 0.05);
    }

    public function test_interval_day_without_hr_falls_back_to_distance_only(): void
    {
        [$user, $day] = $this->createUserWithPlan([
            'type' => TrainingType::Interval,
            'target_km' => 5.0,
            'target_pace_seconds_per_km' => null,
            'intervals_json' => [
                ['kind' => 'work', 'label' => '400m', 'distance_m' => 400, 'duration_seconds' => null, 'target_pace_seconds_per_km' => 270],
            ],
        ]);

        $activity = WearableActivity::factory()->create([
            'user_id' => $user->id,
            'distance_meters' => 5000, // perfect
            'average_pace_seconds_per_km' => 360,
            'average_heartrate' => null,
            'start_date' => now(),
        ]);

        $this->service->matchAndScore($user, $activity);

        $result = $day->fresh()->result;
        $this->assertNull($result->pace_score);
        $this->assertNull($result->heart_rate_score);
        $this->assertEqualsWithDelta(10.0, (float) $result->compliance_score, 0.05);
    }

    public function test_interval_day_distance_off_drops_compliance_proportionally(): void
    {
        [$user, $day] = $this->createUserWithPlan([
            'type' => TrainingType::Interval,
            'target_km' => 5.0,
            'target_pace_seconds_per_km' => null,
            'target_heart_rate_zone' => 4, // default Z4 = [171, 190]
            'intervals_json' => [
                ['kind' => 'work', 'label' => '400m', 'distance_m' => 400, 'duration_seconds' => null, 'target_pace_seconds_per_km' => 270],
            ],
        ]);

        // Distance 4km vs target 5km = 20% short → distance score ~7.0
        // (10 - 0.2 * 15 = 7.0). HR perfect = 10. Weighted 50/50 = 8.5.
        $activity = WearableActivity::factory()->create([
            'user_id' => $user->id,
            'distance_meters' => 4000,
            'average_pace_seconds_per_km' => 360,
            'average_heartrate' => 175,
            'start_date' => now(),
        ]);

        $this->service->matchAndScore($user, $activity);

        $result = $day->fresh()->result;
        $this->assertEqualsWithDelta(7.0, (float) $result->distance_score, 0.05);
        $this->assertEqualsWithDelta(10.0, (float) $result->heart_rate_score, 0.05);
        // (7 * 0.3 + 10 * 0.3) / 0.6 = 8.5
        $this->assertEqualsWithDelta(8.5, (float) $result->compliance_score, 0.05);
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
