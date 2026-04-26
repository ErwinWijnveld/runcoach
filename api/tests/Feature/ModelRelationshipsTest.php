<?php

namespace Tests\Feature;

use App\Models\Goal;
use App\Models\StravaToken;
use App\Models\TrainingDay;
use App\Models\TrainingResult;
use App\Models\TrainingWeek;
use App\Models\User;
use App\Models\WearableActivity;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class ModelRelationshipsTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_user_has_one_strava_token(): void
    {
        $user = User::factory()->create();
        $token = StravaToken::factory()->create(['user_id' => $user->id]);

        $this->assertTrue($user->stravaToken->is($token));
        $this->assertTrue($token->user->is($user));
    }

    public function test_user_has_many_goals(): void
    {
        $user = User::factory()->create();
        $goal = Goal::factory()->create(['user_id' => $user->id]);

        $this->assertTrue($user->goals->contains($goal));
        $this->assertTrue($goal->user->is($user));
    }

    public function test_goal_has_many_training_weeks(): void
    {
        $goal = Goal::factory()->create();
        $week = TrainingWeek::factory()->create(['goal_id' => $goal->id]);

        $this->assertTrue($goal->trainingWeeks->contains($week));
        $this->assertTrue($week->goal->is($goal));
    }

    public function test_training_week_has_many_training_days(): void
    {
        $week = TrainingWeek::factory()->create();
        $day = TrainingDay::factory()->create(['training_week_id' => $week->id]);

        $this->assertTrue($week->trainingDays->contains($day));
        $this->assertTrue($day->trainingWeek->is($week));
    }

    public function test_training_day_has_one_result(): void
    {
        $day = TrainingDay::factory()->create();
        $result = TrainingResult::factory()->create(['training_day_id' => $day->id]);

        $this->assertTrue($day->result->is($result));
        $this->assertTrue($result->trainingDay->is($day));
    }

    public function test_user_has_many_wearable_activities(): void
    {
        $user = User::factory()->create();
        $activity = WearableActivity::factory()->create(['user_id' => $user->id]);

        $this->assertTrue($user->wearableActivities->contains($activity));
        $this->assertTrue($activity->user->is($user));
    }

    public function test_training_result_belongs_to_wearable_activity(): void
    {
        $activity = WearableActivity::factory()->create();
        $result = TrainingResult::factory()->create(['wearable_activity_id' => $activity->id]);

        $this->assertTrue($result->wearableActivity->is($activity));
        $this->assertTrue($activity->trainingResults->contains($result));
    }
}
