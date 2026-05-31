<?php

namespace Tests\Feature\Jobs;

use App\Ai\Agents\ActivityFeedbackAgent;
use App\Ai\Agents\WeeklyInsightAgent;
use App\Jobs\GenerateActivityFeedback;
use App\Jobs\GenerateWeeklyInsight;
use App\Models\Goal;
use App\Models\TrainingDay;
use App\Models\TrainingResult;
use App\Models\TrainingWeek;
use App\Models\User;
use App\Models\WearableActivity;
use App\Notifications\WorkoutAnalyzed;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

class AiJobProGuardTest extends TestCase
{
    use LazilyRefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Notification::fake(); // WorkoutAnalyzed goes via APNs, fake it.
    }

    public function test_generate_activity_feedback_skips_for_non_pro_user(): void
    {
        $user = User::factory()->nonPro()->create();
        $result = $this->makeResultFor($user);

        ActivityFeedbackAgent::fake(['SHOULD NOT BE USED']);

        (new GenerateActivityFeedback($result->id))->handle();

        $result->refresh();
        $this->assertNull($result->ai_feedback);
        Notification::assertNothingSent();
    }

    public function test_generate_activity_feedback_runs_for_pro_user(): void
    {
        $user = User::factory()->create([
            'pro_active_until' => now()->addMonth(),
            'pro_product_id' => 'runcoach_pro_yearly',
        ]);
        $result = $this->makeResultFor($user);

        ActivityFeedbackAgent::fake(['Great session — your easy pace is right where it needs to be.']);

        (new GenerateActivityFeedback($result->id))->handle();

        $result->refresh();
        $this->assertNotNull($result->ai_feedback);
        Notification::assertSentTo($user, WorkoutAnalyzed::class);
    }

    public function test_generate_weekly_insight_skips_for_non_pro_user(): void
    {
        $user = User::factory()->nonPro()->create();
        $week = $this->makeWeekFor($user);

        WeeklyInsightAgent::fake(['SHOULD NOT BE USED']);

        (new GenerateWeeklyInsight($week->id))->handle();

        $week->refresh();
        $this->assertNull($week->coach_notes);
    }

    public function test_generate_weekly_insight_runs_for_pro_user(): void
    {
        $user = User::factory()->create([
            'pro_active_until' => now()->addMonth(),
            'pro_product_id' => 'runcoach_pro_yearly',
        ]);
        $week = $this->makeWeekFor($user);

        WeeklyInsightAgent::fake(['Solid week — compliance was high across the board.']);

        (new GenerateWeeklyInsight($week->id))->handle();

        $week->refresh();
        $this->assertNotNull($week->coach_notes);
    }

    private function makeResultFor(User $user): TrainingResult
    {
        $goal = Goal::factory()->for($user)->create();
        $week = TrainingWeek::factory()->for($goal)->create();
        $day = TrainingDay::factory()->for($week, 'trainingWeek')->create([
            'target_km' => 5,
            'target_pace_seconds_per_km' => 360,
        ]);
        $activity = WearableActivity::factory()->for($user)->create();

        return TrainingResult::factory()->create([
            'training_day_id' => $day->id,
            'wearable_activity_id' => $activity->id,
            'ai_feedback' => null,
            'pace_score' => 8.5,
            'distance_score' => 9,
            'heart_rate_score' => 7,
            'compliance_score' => 8.5,
        ]);
    }

    private function makeWeekFor(User $user): TrainingWeek
    {
        $goal = Goal::factory()->for($user)->create();
        $week = TrainingWeek::factory()->for($goal)->create(['coach_notes' => null]);
        $day = TrainingDay::factory()->for($week, 'trainingWeek')->create([
            'target_km' => 5,
        ]);
        TrainingResult::factory()->create([
            'training_day_id' => $day->id,
            'compliance_score' => 8.5,
            'actual_km' => 5.1,
        ]);

        return $week;
    }
}
