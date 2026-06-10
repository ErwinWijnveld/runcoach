<?php

namespace Tests\Feature\Console;

use App\Enums\GoalStatus;
use App\Enums\TrainingType;
use App\Models\Goal;
use App\Models\TrainingDay;
use App\Models\TrainingResult;
use App\Models\TrainingWeek;
use App\Models\User;
use App\Models\WearableActivity;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class RescoreIntervalComplianceTest extends TestCase
{
    use LazilyRefreshDatabase;

    /**
     * Interval day (5×800m @270, target_km 6.2 via the saving hook) plus a
     * correctly-executed activity, but with a STALE pre-2026-06-10 result
     * row (the old avg-HR-vs-Z5 + symmetric-distance scores).
     */
    private function createStaleIntervalResult(User $user): TrainingResult
    {
        $goal = Goal::factory()->create(['user_id' => $user->id, 'status' => GoalStatus::Active]);
        $week = TrainingWeek::factory()->create(['goal_id' => $goal->id, 'starts_at' => now()->startOfWeek()]);
        $day = TrainingDay::factory()->create([
            'training_week_id' => $week->id,
            'date' => now()->toDateString(),
            'type' => TrainingType::Interval,
            'target_pace_seconds_per_km' => null,
            'target_heart_rate_zone' => 5,
            'intervals_json' => [
                'warmup_seconds' => 60,
                'steps' => [
                    ['type' => 'block', 'reps' => 5, 'work_distance_m' => 800, 'work_duration_seconds' => null, 'work_pace_seconds_per_km' => 270, 'recovery_seconds' => 90],
                ],
                'cooldown_seconds' => 300,
            ],
        ]);
        $activity = WearableActivity::factory()->create([
            'user_id' => $user->id,
            'distance_meters' => 6200,
            'average_pace_seconds_per_km' => 360,
            'average_heartrate' => 152,
            'max_heartrate' => 178,
            'start_date' => now(),
        ]);

        return TrainingResult::create([
            'training_day_id' => $day->id,
            'wearable_activity_id' => $activity->id,
            'compliance_score' => 2.4,
            'actual_km' => 6.2,
            'actual_pace_seconds_per_km' => 360,
            'actual_avg_heart_rate' => 152,
            'pace_score' => null,
            'distance_score' => 3.1,
            'heart_rate_score' => 1.0,
            'matched_at' => now(),
        ]);
    }

    public function test_rescores_stale_interval_results(): void
    {
        $result = $this->createStaleIntervalResult(User::factory()->create());

        $this->artisan('compliance:rescore-intervals')->assertSuccessful();

        $fresh = $result->fresh();
        $this->assertEqualsWithDelta(10.0, (float) $fresh->compliance_score, 0.05);
        $this->assertEqualsWithDelta(10.0, (float) $fresh->pace_score, 0.05);
        $this->assertEqualsWithDelta(10.0, (float) $fresh->distance_score, 0.05);
        $this->assertEqualsWithDelta(10.0, (float) $fresh->heart_rate_score, 0.05);
    }

    public function test_leaves_non_interval_results_untouched(): void
    {
        $user = User::factory()->create();
        $goal = Goal::factory()->create(['user_id' => $user->id, 'status' => GoalStatus::Active]);
        $week = TrainingWeek::factory()->create(['goal_id' => $goal->id, 'starts_at' => now()->startOfWeek()]);
        $day = TrainingDay::factory()->create([
            'training_week_id' => $week->id,
            'date' => now()->toDateString(),
            'type' => TrainingType::Tempo,
            'target_km' => 8.0,
            'target_pace_seconds_per_km' => 285,
        ]);
        $activity = WearableActivity::factory()->create(['user_id' => $user->id, 'start_date' => now()]);
        $result = TrainingResult::create([
            'training_day_id' => $day->id,
            'wearable_activity_id' => $activity->id,
            'compliance_score' => 5.5,
            'actual_km' => 8.0,
            'actual_pace_seconds_per_km' => 285,
            'distance_score' => 5.5,
            'matched_at' => now(),
        ]);

        $this->artisan('compliance:rescore-intervals')->assertSuccessful();

        $this->assertEqualsWithDelta(5.5, (float) $result->fresh()->compliance_score, 0.01);
    }

    public function test_dry_run_reports_without_persisting(): void
    {
        $result = $this->createStaleIntervalResult(User::factory()->create());

        $this->artisan('compliance:rescore-intervals --dry-run')->assertSuccessful();

        $this->assertEqualsWithDelta(2.4, (float) $result->fresh()->compliance_score, 0.01);
    }
}
