<?php

namespace Tests\Feature\Http;

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

class TrainingDayMatchTest extends TestCase
{
    use LazilyRefreshDatabase;

    private function authUser(): array
    {
        $user = User::factory()->create();
        $token = $user->createToken('api')->plainTextToken;

        return [$user, ['Authorization' => "Bearer $token"]];
    }

    private function scheduleDay(User $user, array $dayAttrs = []): TrainingDay
    {
        $goal = Goal::factory()->create(['user_id' => $user->id]);
        $week = TrainingWeek::factory()->create(['goal_id' => $goal->id]);

        return TrainingDay::factory()->create(array_merge([
            'training_week_id' => $week->id,
            'date' => now()->toDateString(),
            'target_km' => 5.0,
            'target_pace_seconds_per_km' => 390,
            'target_heart_rate_zone' => 2,
        ], $dayAttrs));
    }

    public function test_available_activities_lists_recent_runs_with_sync_flag(): void
    {
        [$user, $headers] = $this->authUser();
        StravaToken::factory()->create(['user_id' => $user->id]);

        $day = $this->scheduleDay($user);

        // One run will be "already synced" to a different day; the other free.
        $otherDay = $this->scheduleDay($user, ['date' => now()->subDays(3)->toDateString()]);
        $synced = StravaActivity::factory()->create([
            'user_id' => $user->id,
            'strava_id' => 9001,
        ]);
        TrainingResult::factory()->create([
            'training_day_id' => $otherDay->id,
            'strava_activity_id' => $synced->id,
        ]);

        Http::fake([
            'strava.com/api/v3/athlete/activities*' => Http::response([
                [
                    'id' => 9001, // already synced
                    'type' => 'Run',
                    'name' => 'Already synced run',
                    'distance' => 5200,
                    'moving_time' => 1800,
                    'start_date' => now()->subDays(3)->toIso8601String(),
                ],
                [
                    'id' => 9002, // free
                    'type' => 'Run',
                    'name' => 'Today easy',
                    'distance' => 4800,
                    'moving_time' => 1650,
                    'start_date' => now()->toIso8601String(),
                    'average_heartrate' => 142,
                ],
                [
                    'id' => 9003, // non-run, filtered out
                    'type' => 'Ride',
                    'name' => 'Bike commute',
                    'distance' => 10000,
                    'moving_time' => 1200,
                    'start_date' => now()->toIso8601String(),
                ],
            ], 200),
        ]);

        $response = $this->getJson("/api/v1/training-days/{$day->id}/available-activities", $headers);

        $response->assertOk();
        $data = $response->json('data');

        $this->assertCount(2, $data, 'Non-run activities are filtered out');

        $syncedEntry = collect($data)->firstWhere('strava_activity_id', 9001);
        $this->assertSame($otherDay->id, $syncedEntry['matched_training_day_id']);

        $freeEntry = collect($data)->firstWhere('strava_activity_id', 9002);
        $this->assertNull($freeEntry['matched_training_day_id']);
        $this->assertSame(4.8, $freeEntry['distance_km']);
        $this->assertSame(344, $freeEntry['average_pace_seconds_per_km']);
    }

    public function test_match_activity_creates_result_and_scores_it(): void
    {
        [$user, $headers] = $this->authUser();
        StravaToken::factory()->create(['user_id' => $user->id]);

        $day = $this->scheduleDay($user, [
            'target_km' => 5.0,
            'target_pace_seconds_per_km' => 360,
            'target_heart_rate_zone' => 2,
        ]);

        Http::fake([
            'strava.com/api/v3/activities/7777' => Http::response([
                'id' => 7777,
                'type' => 'Run',
                'name' => 'Matched manually',
                'distance' => 5050,
                'moving_time' => 1830,
                'elapsed_time' => 1900,
                'average_speed' => 2.76,
                'start_date' => now()->toIso8601String(),
                'average_heartrate' => 140,
                'map' => ['summary_polyline' => null],
            ], 200),
        ]);

        $response = $this->postJson(
            "/api/v1/training-days/{$day->id}/match-activity",
            ['strava_activity_id' => 7777],
            $headers,
        );

        $response->assertOk();
        $this->assertDatabaseHas('training_results', [
            'training_day_id' => $day->id,
        ]);

        $result = TrainingResult::where('training_day_id', $day->id)->first();
        $this->assertNotNull($result->compliance_score);
        $this->assertEqualsWithDelta(5.05, (float) $result->actual_km, 0.1);
    }

    public function test_match_activity_refuses_when_already_bound_to_another_day(): void
    {
        [$user, $headers] = $this->authUser();
        StravaToken::factory()->create(['user_id' => $user->id]);

        $dayA = $this->scheduleDay($user);
        $dayB = $this->scheduleDay($user);

        // Pre-existing result on dayA with strava id 8888.
        $activity = StravaActivity::factory()->create([
            'user_id' => $user->id,
            'strava_id' => 8888,
        ]);
        TrainingResult::factory()->create([
            'training_day_id' => $dayA->id,
            'strava_activity_id' => $activity->id,
        ]);

        Http::fake([
            'strava.com/api/v3/activities/8888' => Http::response([
                'id' => 8888,
                'type' => 'Run',
                'name' => 'Already taken',
                'distance' => 5000,
                'moving_time' => 1800,
                'elapsed_time' => 1850,
                'average_speed' => 2.77,
                'start_date' => now()->toIso8601String(),
                'map' => ['summary_polyline' => null],
            ], 200),
        ]);

        $response = $this->postJson(
            "/api/v1/training-days/{$dayB->id}/match-activity",
            ['strava_activity_id' => 8888],
            $headers,
        );

        $response->assertStatus(409);
    }

    public function test_match_activity_rejects_non_run(): void
    {
        [$user, $headers] = $this->authUser();
        StravaToken::factory()->create(['user_id' => $user->id]);
        $day = $this->scheduleDay($user);

        Http::fake([
            'strava.com/api/v3/activities/6666' => Http::response([
                'id' => 6666,
                'type' => 'Ride',
                'name' => 'Bike',
                'distance' => 20000,
                'moving_time' => 3600,
                'elapsed_time' => 3600,
                'average_speed' => 5.5,
                'start_date' => now()->toIso8601String(),
                'map' => ['summary_polyline' => null],
            ], 200),
        ]);

        $response = $this->postJson(
            "/api/v1/training-days/{$day->id}/match-activity",
            ['strava_activity_id' => 6666],
            $headers,
        );

        $response->assertStatus(422);
    }

    public function test_cannot_match_another_users_day(): void
    {
        [$victim] = $this->authUser();
        $victimDay = $this->scheduleDay($victim);

        [, $attackerHeaders] = $this->authUser();

        $response = $this->postJson(
            "/api/v1/training-days/{$victimDay->id}/match-activity",
            ['strava_activity_id' => 1],
            $attackerHeaders,
        );

        $response->assertNotFound();
    }

    public function test_match_activity_refuses_when_athlete_id_differs(): void
    {
        [$user, $headers] = $this->authUser();
        $user->forceFill(['strava_athlete_id' => 111])->save();
        StravaToken::factory()->create(['user_id' => $user->id]);

        $day = $this->scheduleDay($user);

        Http::fake([
            'strava.com/api/v3/activities/5555' => Http::response([
                'id' => 5555,
                'type' => 'Run',
                'name' => 'Stolen run',
                'distance' => 5000,
                'moving_time' => 1800,
                'elapsed_time' => 1800,
                'average_speed' => 2.77,
                'start_date' => now()->toIso8601String(),
                'athlete' => ['id' => 222], // different athlete!
                'map' => ['summary_polyline' => null],
            ], 200),
        ]);

        $response = $this->postJson(
            "/api/v1/training-days/{$day->id}/match-activity",
            ['strava_activity_id' => 5555],
            $headers,
        );

        $response->assertStatus(403);
        $this->assertDatabaseMissing('training_results', ['training_day_id' => $day->id]);
    }

    public function test_match_activity_accepts_trail_and_virtual_runs(): void
    {
        [$user, $headers] = $this->authUser();
        StravaToken::factory()->create(['user_id' => $user->id]);
        $day = $this->scheduleDay($user);

        Http::fake([
            'strava.com/api/v3/activities/3333' => Http::response([
                'id' => 3333,
                'type' => 'TrailRun',
                'name' => 'Forest trail',
                'distance' => 5000,
                'moving_time' => 1800,
                'elapsed_time' => 1900,
                'average_speed' => 2.77,
                'start_date' => now()->toIso8601String(),
                'map' => ['summary_polyline' => null],
            ], 200),
        ]);

        $response = $this->postJson(
            "/api/v1/training-days/{$day->id}/match-activity",
            ['strava_activity_id' => 3333],
            $headers,
        );

        $response->assertOk();
    }

    public function test_unlink_deletes_training_result_but_keeps_activity(): void
    {
        [$user, $headers] = $this->authUser();
        $day = $this->scheduleDay($user);

        $activity = StravaActivity::factory()->create([
            'user_id' => $user->id,
            'strava_id' => 4242,
        ]);
        TrainingResult::factory()->create([
            'training_day_id' => $day->id,
            'strava_activity_id' => $activity->id,
        ]);

        $response = $this->deleteJson(
            "/api/v1/training-days/{$day->id}/match-activity",
            [],
            $headers,
        );

        $response->assertOk();
        $this->assertDatabaseMissing('training_results', ['training_day_id' => $day->id]);
        $this->assertDatabaseHas('strava_activities', ['strava_id' => 4242]);
    }

    public function test_unlink_is_idempotent_when_no_result_exists(): void
    {
        [$user, $headers] = $this->authUser();
        $day = $this->scheduleDay($user);

        $response = $this->deleteJson(
            "/api/v1/training-days/{$day->id}/match-activity",
            [],
            $headers,
        );

        $response->assertOk();
    }

    public function test_unlink_cannot_touch_another_users_day(): void
    {
        [$victim] = $this->authUser();
        $victimDay = $this->scheduleDay($victim);

        [, $attackerHeaders] = $this->authUser();

        $response = $this->deleteJson(
            "/api/v1/training-days/{$victimDay->id}/match-activity",
            [],
            $attackerHeaders,
        );

        $response->assertNotFound();
    }

    public function test_available_activities_returns_disconnected_error_on_strava_401(): void
    {
        [$user, $headers] = $this->authUser();
        StravaToken::factory()->create(['user_id' => $user->id]);
        $day = $this->scheduleDay($user);

        Http::fake([
            'strava.com/oauth/token' => Http::response(['error' => 'invalid_refresh'], 401),
            'strava.com/api/v3/athlete/activities*' => Http::response(['message' => 'Bad token'], 401),
        ]);

        $response = $this->getJson("/api/v1/training-days/{$day->id}/available-activities", $headers);

        $response->assertOk();
        $response->assertJson([
            'data' => [],
            'error' => 'strava_disconnected',
        ]);
    }
}
