<?php

namespace Tests\Feature\Services;

use App\Enums\TrainingType;
use App\Models\Goal;
use App\Models\TrainingDay;
use App\Models\TrainingResult;
use App\Models\TrainingWeek;
use App\Models\User;
use App\Models\UserNotification;
use App\Models\WearableActivity;
use App\Services\PaceAdjustmentEvaluator;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class PaceAdjustmentEvaluatorTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_creates_notification_when_pace_is_on_target_but_hr_clearly_above_zone(): void
    {
        $result = $this->resultWith(
            type: TrainingType::Easy,
            targetZone: 2,
            paceScore: 9.0,
            heartRateScore: 5.0,
            avgHr: 175.0,
        );

        $notification = app(PaceAdjustmentEvaluator::class)->evaluate($result);

        $this->assertNotNull($notification);
        $this->assertSame(UserNotification::TYPE_PACE_ADJUSTMENT, $notification->type);
        $this->assertSame('easy', $notification->action_data['training_type']);
        $this->assertSame($result->id, $notification->action_data['source_training_result_id']);
        $this->assertGreaterThan(1.0, $notification->action_data['pace_factor']);
    }

    public function test_creates_notification_when_hr_clearly_below_zone(): void
    {
        $result = $this->resultWith(
            type: TrainingType::Easy,
            targetZone: 3,
            paceScore: 9.5,
            heartRateScore: 6.0,
            avgHr: 130.0, // well below zone 3 (default 152-171)
        );

        $notification = app(PaceAdjustmentEvaluator::class)->evaluate($result);

        $this->assertNotNull($notification);
        $this->assertLessThan(1.0, $notification->action_data['pace_factor']);
    }

    public function test_skips_when_pace_score_below_floor(): void
    {
        $result = $this->resultWith(
            type: TrainingType::Easy,
            targetZone: 2,
            paceScore: 7.0,
            heartRateScore: 4.0,
            avgHr: 175.0,
        );

        $this->assertNull(app(PaceAdjustmentEvaluator::class)->evaluate($result));
    }

    public function test_skips_when_hr_score_inside_acceptable_range(): void
    {
        $result = $this->resultWith(
            type: TrainingType::Easy,
            targetZone: 2,
            paceScore: 9.0,
            heartRateScore: 8.5,
            avgHr: 155.0,
        );

        $this->assertNull(app(PaceAdjustmentEvaluator::class)->evaluate($result));
    }

    public function test_skips_intervals(): void
    {
        $result = $this->resultWith(
            type: TrainingType::Interval,
            targetZone: 4,
            paceScore: 9.0,
            heartRateScore: 5.0,
            avgHr: 195.0,
        );

        $this->assertNull(app(PaceAdjustmentEvaluator::class)->evaluate($result));
    }

    public function test_supersedes_prior_pending_for_same_type(): void
    {
        $result = $this->resultWith(
            type: TrainingType::Easy,
            targetZone: 2,
            paceScore: 9.0,
            heartRateScore: 5.0,
            avgHr: 175.0,
        );
        $user = $result->wearableActivity->user;

        UserNotification::factory()->create([
            'user_id' => $user->id,
            'action_data' => ['training_type' => 'easy', 'pace_factor' => 1.02],
        ]);

        app(PaceAdjustmentEvaluator::class)->evaluate($result);

        $pending = UserNotification::where('user_id', $user->id)
            ->where('status', UserNotification::STATUS_PENDING)
            ->get();

        $this->assertCount(1, $pending, 'old pending should be dismissed when a fresh one is created');
    }

    private function resultWith(
        TrainingType $type,
        int $targetZone,
        float $paceScore,
        float $heartRateScore,
        float $avgHr,
    ): TrainingResult {
        $user = User::factory()->create();
        $goal = Goal::factory()->create(['user_id' => $user->id]);
        $week = TrainingWeek::factory()->create(['goal_id' => $goal->id]);
        $day = TrainingDay::factory()->create([
            'training_week_id' => $week->id,
            'type' => $type,
            'target_pace_seconds_per_km' => 360,
            'target_heart_rate_zone' => $targetZone,
            'intervals_json' => null,
        ]);
        $activity = WearableActivity::factory()->create([
            'user_id' => $user->id,
            'average_heartrate' => $avgHr,
        ]);

        return TrainingResult::factory()->create([
            'training_day_id' => $day->id,
            'wearable_activity_id' => $activity->id,
            'pace_score' => $paceScore,
            'heart_rate_score' => $heartRateScore,
            'actual_avg_heart_rate' => $avgHr,
        ]);
    }
}
