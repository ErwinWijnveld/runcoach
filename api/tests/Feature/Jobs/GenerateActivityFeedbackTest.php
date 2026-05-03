<?php

namespace Tests\Feature\Jobs;

use App\Ai\Agents\ActivityFeedbackAgent;
use App\Jobs\GenerateActivityFeedback;
use App\Models\Goal;
use App\Models\TrainingDay;
use App\Models\TrainingResult;
use App\Models\TrainingWeek;
use App\Models\User;
use App\Models\UserNotification;
use App\Models\WearableActivity;
use App\Notifications\WorkoutAnalyzed;
use App\Services\PaceAdjustmentEvaluator;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

class GenerateActivityFeedbackTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_builds_prompt_and_stores_feedback(): void
    {
        ActivityFeedbackAgent::fake(['Generated feedback prose.']);

        $user = User::factory()->create();
        $goal = Goal::factory()->create(['user_id' => $user->id]);
        $week = TrainingWeek::factory()->create(['goal_id' => $goal->id]);
        $day = TrainingDay::factory()->create([
            'training_week_id' => $week->id,
            'title' => 'Easy 5k',
            'type' => 'easy',
            'target_km' => 5.0,
            'target_pace_seconds_per_km' => 360,
            'target_heart_rate_zone' => 2,
        ]);

        // 3 prior runs — should show up in "Recent runs".
        WearableActivity::factory()->count(3)->create([
            'user_id' => $user->id,
            'start_date' => now()->subDays(7),
        ]);

        $activity = WearableActivity::factory()->create([
            'user_id' => $user->id,
            'name' => 'Current run',
            'distance_meters' => 5050,
        ]);

        $result = TrainingResult::factory()->create([
            'training_day_id' => $day->id,
            'wearable_activity_id' => $activity->id,
            'actual_km' => 5.05,
            'actual_pace_seconds_per_km' => 362,
            'ai_feedback' => null,
        ]);

        app()->call([new GenerateActivityFeedback($result->id), 'handle']);

        $this->assertSame('Generated feedback prose.', $result->fresh()->ai_feedback);

        ActivityFeedbackAgent::assertPrompted(
            fn ($prompt) => $prompt->contains('Easy 5k')
                && $prompt->contains('Actual: 5.1km')              // decimal:1 cast rounds 5.05
                && $prompt->contains('Recent runs')
                && ! $prompt->contains('Current run')              // current activity excluded
        );
    }

    public function test_early_returns_when_feedback_already_present(): void
    {
        ActivityFeedbackAgent::fake(['x']);

        $user = User::factory()->create();
        $goal = Goal::factory()->create(['user_id' => $user->id]);
        $week = TrainingWeek::factory()->create(['goal_id' => $goal->id]);
        $day = TrainingDay::factory()->create(['training_week_id' => $week->id]);
        $activity = WearableActivity::factory()->create(['user_id' => $user->id]);
        $result = TrainingResult::factory()->create([
            'training_day_id' => $day->id,
            'wearable_activity_id' => $activity->id,
            'ai_feedback' => null,
        ]);

        app()->call([new GenerateActivityFeedback($result->id), 'handle']);
        $this->assertSame('x', $result->fresh()->ai_feedback);

        // Second invocation with feedback already present — early-returns
        // without overwriting.
        app()->call([new GenerateActivityFeedback($result->id), 'handle']);
        $this->assertSame('x', $result->fresh()->ai_feedback);
    }

    public function test_dispatches_workout_analyzed_push_after_feedback_is_written(): void
    {
        Notification::fake();
        ActivityFeedbackAgent::fake(['Solid run.']);

        $user = User::factory()->create();
        $goal = Goal::factory()->create(['user_id' => $user->id]);
        $week = TrainingWeek::factory()->create(['goal_id' => $goal->id]);
        $day = TrainingDay::factory()->create(['training_week_id' => $week->id]);
        $activity = WearableActivity::factory()->create(['user_id' => $user->id]);
        $result = TrainingResult::factory()->create([
            'training_day_id' => $day->id,
            'wearable_activity_id' => $activity->id,
            'ai_feedback' => null,
        ]);

        app()->call([new GenerateActivityFeedback($result->id), 'handle']);

        Notification::assertSentTo(
            $user,
            WorkoutAnalyzed::class,
            fn (WorkoutAnalyzed $n) => $n->trainingResultId === $result->id,
        );
    }

    public function test_interval_prompt_uses_work_set_avg_and_omits_full_run_pace_target(): void
    {
        ActivityFeedbackAgent::fake(['Solid intervals.']);

        $user = User::factory()->create();
        $goal = Goal::factory()->create(['user_id' => $user->id]);
        $week = TrainingWeek::factory()->create(['goal_id' => $goal->id]);
        $day = TrainingDay::factory()->create([
            'training_week_id' => $week->id,
            'title' => '6×400m intervals',
            'type' => 'interval',
            'target_km' => 5.0,
            'target_pace_seconds_per_km' => null, // canonical for intervals
            'target_heart_rate_zone' => 4,
            'intervals_json' => [
                ['kind' => 'warmup', 'distance_m' => null, 'duration_seconds' => 60, 'target_pace_seconds_per_km' => null],
                ['kind' => 'work', 'distance_m' => 400, 'duration_seconds' => null, 'target_pace_seconds_per_km' => 270],
                ['kind' => 'recovery', 'distance_m' => null, 'duration_seconds' => 90, 'target_pace_seconds_per_km' => null],
                ['kind' => 'work', 'distance_m' => 400, 'duration_seconds' => null, 'target_pace_seconds_per_km' => 270],
                ['kind' => 'cooldown', 'distance_m' => null, 'duration_seconds' => 300, 'target_pace_seconds_per_km' => null],
            ],
        ]);

        $activity = WearableActivity::factory()->create(['user_id' => $user->id]);
        $result = TrainingResult::factory()->create([
            'training_day_id' => $day->id,
            'wearable_activity_id' => $activity->id,
            // Pace score is null on intervals — prompt must NOT print
            // "pace null/10" and must include the work-set-avg label.
            'pace_score' => null,
            'distance_score' => 9.0,
            'heart_rate_score' => 8.5,
            'ai_feedback' => null,
        ]);

        app()->call([new GenerateActivityFeedback($result->id), 'handle']);

        ActivityFeedbackAgent::assertPrompted(
            fn ($prompt) => $prompt->contains('4:30/km work-set avg')
                && ! $prompt->contains('pace null/10')
                && $prompt->contains('interval session')
                && $prompt->contains('do NOT compare it directly')
        );
    }

    public function test_push_still_fires_when_pace_evaluator_throws(): void
    {
        // Critical correctness test: the AI feedback save + push notify
        // must NOT be vulnerable to errors in the opportunistic
        // pace-adjustment evaluator. If they were, a single brittle
        // evaluator edge case could indefinitely silence workout-analysis
        // pushes for affected users (the job's early-return on existing
        // ai_feedback means a retry is also a no-op).
        Notification::fake();
        ActivityFeedbackAgent::fake(['Solid run.']);

        $this->app->bind(PaceAdjustmentEvaluator::class, function () {
            return new class extends PaceAdjustmentEvaluator
            {
                public function evaluate($result): ?UserNotification
                {
                    throw new \RuntimeException('boom');
                }
            };
        });

        $user = User::factory()->create();
        $goal = Goal::factory()->create(['user_id' => $user->id]);
        $week = TrainingWeek::factory()->create(['goal_id' => $goal->id]);
        $day = TrainingDay::factory()->create(['training_week_id' => $week->id]);
        $activity = WearableActivity::factory()->create(['user_id' => $user->id]);
        $result = TrainingResult::factory()->create([
            'training_day_id' => $day->id,
            'wearable_activity_id' => $activity->id,
            'ai_feedback' => null,
        ]);

        // The job must complete without re-throwing the evaluator error.
        app()->call([new GenerateActivityFeedback($result->id), 'handle']);

        // ai_feedback got saved + push got sent — both critical paths
        // ran to completion despite the evaluator's blow-up.
        $this->assertSame('Solid run.', $result->fresh()->ai_feedback);
        Notification::assertSentTo($user, WorkoutAnalyzed::class);
    }

    public function test_does_not_resend_push_when_feedback_already_present(): void
    {
        Notification::fake();
        ActivityFeedbackAgent::fake(['Initial.']);

        $user = User::factory()->create();
        $goal = Goal::factory()->create(['user_id' => $user->id]);
        $week = TrainingWeek::factory()->create(['goal_id' => $goal->id]);
        $day = TrainingDay::factory()->create(['training_week_id' => $week->id]);
        $activity = WearableActivity::factory()->create(['user_id' => $user->id]);
        $result = TrainingResult::factory()->create([
            'training_day_id' => $day->id,
            'wearable_activity_id' => $activity->id,
            'ai_feedback' => 'Already done.',
        ]);

        app()->call([new GenerateActivityFeedback($result->id), 'handle']);

        Notification::assertNothingSent();
    }
}
