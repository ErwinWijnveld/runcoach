<?php

namespace Tests\Feature;

use App\Models\Race;
use App\Models\StravaActivity;
use App\Models\StravaToken;
use App\Models\TrainingDay;
use App\Models\TrainingResult;
use App\Models\TrainingWeek;
use App\Models\User;
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

    public function test_user_has_many_races(): void
    {
        $user = User::factory()->create();
        $race = Race::factory()->create(['user_id' => $user->id]);

        $this->assertTrue($user->races->contains($race));
        $this->assertTrue($race->user->is($user));
    }

    public function test_race_has_many_training_weeks(): void
    {
        $race = Race::factory()->create();
        $week = TrainingWeek::factory()->create(['race_id' => $race->id]);

        $this->assertTrue($race->trainingWeeks->contains($week));
        $this->assertTrue($week->race->is($race));
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

    public function test_user_has_many_strava_activities(): void
    {
        $user = User::factory()->create();
        $activity = StravaActivity::factory()->create(['user_id' => $user->id]);

        $this->assertTrue($user->stravaActivities->contains($activity));
        $this->assertTrue($activity->user->is($user));
    }

    public function test_training_result_belongs_to_strava_activity(): void
    {
        $activity = StravaActivity::factory()->create();
        $result = TrainingResult::factory()->create(['strava_activity_id' => $activity->id]);

        $this->assertTrue($result->stravaActivity->is($activity));
        $this->assertTrue($activity->trainingResults->contains($result));
    }
}
