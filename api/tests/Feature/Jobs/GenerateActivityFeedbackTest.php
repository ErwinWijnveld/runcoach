<?php

namespace Tests\Feature\Jobs;

use App\Ai\Agents\ActivityFeedbackAgent;
use App\Jobs\GenerateActivityFeedback;
use App\Models\Goal;
use App\Models\StravaActivity;
use App\Models\StravaToken;
use App\Models\TrainingDay;
use App\Models\TrainingResult;
use App\Models\TrainingWeek;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class GenerateActivityFeedbackTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_builds_rich_prompt_and_stores_feedback(): void
    {
        ActivityFeedbackAgent::fake(['Generated feedback prose.']);

        $user = User::factory()->create();
        StravaToken::factory()->create(['user_id' => $user->id]);
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
        StravaActivity::factory()->count(3)->create([
            'user_id' => $user->id,
            'start_date' => now()->subDays(7),
        ]);

        $activity = StravaActivity::factory()->create([
            'user_id' => $user->id,
            'name' => 'Current run',
            'strava_id' => 42,
            'distance_meters' => 5050,   // <10 km → 50 m buckets
            'raw_data' => [],
        ]);

        // Fake Strava streams — dense enough that each 50m bucket has
        // multiple samples (Strava samples ~1/sec in reality).
        Http::fake([
            'strava.com/api/v3/activities/42/streams*' => Http::response([
                'time' => ['data' => [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60]],
                'distance' => ['data' => [0.0, 15.0, 30.0, 45.0, 60.0, 75.0, 90.0, 105.0, 120.0, 135.0, 150.0, 165.0, 180.0]],
                'heartrate' => ['data' => [140, 142, 145, 148, 150, 152, 155, 157, 158, 159, 160, 160, 160]],
            ], 200),
        ]);

        $result = TrainingResult::factory()->create([
            'training_day_id' => $day->id,
            'strava_activity_id' => $activity->id,
            'actual_km' => 5.05,
            'actual_pace_seconds_per_km' => 362,
            'ai_feedback' => null,
        ]);

        app()->call([new GenerateActivityFeedback($result->id), 'handle']);

        $this->assertSame('Generated feedback prose.', $result->fresh()->ai_feedback);

        ActivityFeedbackAgent::assertPrompted(
            fn ($prompt) => $prompt->contains('Easy 5k')
                && $prompt->contains('Actual: 5.1km')              // decimal:1 cast rounds 5.05
                && $prompt->contains('Splits:')                    // pace segments label
                && $prompt->contains('Recent runs')
                && ! $prompt->contains('Current run')              // current activity excluded
        );
    }

    public function test_skips_splits_when_no_strava_token_and_early_returns_when_done(): void
    {
        ActivityFeedbackAgent::fake(['x']);

        $user = User::factory()->create(); // no StravaToken
        $goal = Goal::factory()->create(['user_id' => $user->id]);
        $week = TrainingWeek::factory()->create(['goal_id' => $goal->id]);
        $day = TrainingDay::factory()->create(['training_week_id' => $week->id]);
        $activity = StravaActivity::factory()->create(['user_id' => $user->id]);
        $result = TrainingResult::factory()->create([
            'training_day_id' => $day->id,
            'strava_activity_id' => $activity->id,
            'ai_feedback' => null,
        ]);

        app()->call([new GenerateActivityFeedback($result->id), 'handle']);

        ActivityFeedbackAgent::assertPrompted(fn ($p) => ! $p->contains('Splits'));
        $this->assertSame('x', $result->fresh()->ai_feedback);

        // Second run with feedback already present — early-returns without
        // touching the agent or overwriting the stored text.
        app()->call([new GenerateActivityFeedback($result->id), 'handle']);
        $this->assertSame('x', $result->fresh()->ai_feedback);
    }
}
