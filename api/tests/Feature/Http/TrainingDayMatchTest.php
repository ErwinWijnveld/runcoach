<?php

namespace Tests\Feature\Http;

use App\Jobs\GenerateActivityFeedback;
use App\Models\Goal;
use App\Models\TrainingDay;
use App\Models\TrainingResult;
use App\Models\TrainingWeek;
use App\Models\User;
use App\Models\WearableActivity;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\Queue;
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

    public function test_available_activities_lists_recent_runs_with_match_flag(): void
    {
        [$user, $headers] = $this->authUser();

        $day = $this->scheduleDay($user);

        // One run will already be matched to a different day; the other free.
        $otherDay = $this->scheduleDay($user, ['date' => now()->subDays(3)->toDateString()]);
        $matched = WearableActivity::factory()->create([
            'user_id' => $user->id,
            'source' => 'apple_health',
            'name' => 'Already matched run',
            'start_date' => now()->subDays(3),
        ]);
        TrainingResult::factory()->create([
            'training_day_id' => $otherDay->id,
            'wearable_activity_id' => $matched->id,
        ]);

        $free = WearableActivity::factory()->create([
            'user_id' => $user->id,
            'source' => 'apple_health',
            'name' => 'Today easy',
            'start_date' => now(),
            'distance_meters' => 4800,
            'duration_seconds' => 1650,
            'average_pace_seconds_per_km' => 344,
            'average_heartrate' => 142,
        ]);

        // Non-run, should be filtered out.
        WearableActivity::factory()->create([
            'user_id' => $user->id,
            'type' => 'Ride',
            'start_date' => now(),
        ]);

        $response = $this->getJson("/api/v1/training-days/{$day->id}/available-activities", $headers);

        $response->assertOk();
        $data = $response->json('data');

        $this->assertCount(2, $data, 'Non-run activities are filtered out');

        $matchedEntry = collect($data)->firstWhere('wearable_activity_id', $matched->id);
        $this->assertSame($otherDay->id, $matchedEntry['matched_training_day_id']);

        $freeEntry = collect($data)->firstWhere('wearable_activity_id', $free->id);
        $this->assertNull($freeEntry['matched_training_day_id']);
        $this->assertSame(4.8, $freeEntry['distance_km']);
        $this->assertSame(344, $freeEntry['average_pace_seconds_per_km']);
    }

    public function test_match_activity_creates_result_and_scores_it(): void
    {
        [$user, $headers] = $this->authUser();

        $day = $this->scheduleDay($user, [
            'target_km' => 5.0,
            'target_pace_seconds_per_km' => 360,
            'target_heart_rate_zone' => 2,
        ]);

        $activity = WearableActivity::factory()->create([
            'user_id' => $user->id,
            'distance_meters' => 5050,
            'duration_seconds' => 1830,
            'average_pace_seconds_per_km' => 362,
            'average_heartrate' => 140,
            'start_date' => now(),
        ]);

        $response = $this->postJson(
            "/api/v1/training-days/{$day->id}/match-activity",
            ['wearable_activity_id' => $activity->id],
            $headers,
        );

        $response->assertOk();
        $this->assertDatabaseHas('training_results', [
            'training_day_id' => $day->id,
            'wearable_activity_id' => $activity->id,
        ]);

        $result = TrainingResult::where('training_day_id', $day->id)->first();
        $this->assertNotNull($result->compliance_score);
        $this->assertEqualsWithDelta(5.05, (float) $result->actual_km, 0.1);
    }

    public function test_match_activity_refuses_when_already_bound_to_another_day(): void
    {
        [$user, $headers] = $this->authUser();

        $dayA = $this->scheduleDay($user);
        $dayB = $this->scheduleDay($user);

        $activity = WearableActivity::factory()->create(['user_id' => $user->id]);
        TrainingResult::factory()->create([
            'training_day_id' => $dayA->id,
            'wearable_activity_id' => $activity->id,
        ]);

        $response = $this->postJson(
            "/api/v1/training-days/{$dayB->id}/match-activity",
            ['wearable_activity_id' => $activity->id],
            $headers,
        );

        $response->assertStatus(409);
    }

    public function test_match_activity_rejects_non_run(): void
    {
        [$user, $headers] = $this->authUser();
        $day = $this->scheduleDay($user);

        $activity = WearableActivity::factory()->create([
            'user_id' => $user->id,
            'type' => 'Ride',
        ]);

        $response = $this->postJson(
            "/api/v1/training-days/{$day->id}/match-activity",
            ['wearable_activity_id' => $activity->id],
            $headers,
        );

        $response->assertStatus(422);
    }

    public function test_cannot_match_another_users_day(): void
    {
        [$victim] = $this->authUser();
        $victimDay = $this->scheduleDay($victim);

        [, $attackerHeaders] = $this->authUser();
        $attackerActivity = WearableActivity::factory()->create();

        $response = $this->postJson(
            "/api/v1/training-days/{$victimDay->id}/match-activity",
            ['wearable_activity_id' => $attackerActivity->id],
            $attackerHeaders,
        );

        $response->assertNotFound();
    }

    public function test_match_activity_refuses_to_use_another_users_activity(): void
    {
        [$user, $headers] = $this->authUser();
        $day = $this->scheduleDay($user);

        $strangerActivity = WearableActivity::factory()->create();

        $response = $this->postJson(
            "/api/v1/training-days/{$day->id}/match-activity",
            ['wearable_activity_id' => $strangerActivity->id],
            $headers,
        );

        $response->assertNotFound();
    }

    public function test_match_activity_accepts_trail_and_virtual_runs(): void
    {
        [$user, $headers] = $this->authUser();
        $day = $this->scheduleDay($user);

        $activity = WearableActivity::factory()->create([
            'user_id' => $user->id,
            'type' => 'TrailRun',
        ]);

        $response = $this->postJson(
            "/api/v1/training-days/{$day->id}/match-activity",
            ['wearable_activity_id' => $activity->id],
            $headers,
        );

        $response->assertOk();
    }

    public function test_unlink_deletes_training_result_but_keeps_activity(): void
    {
        [$user, $headers] = $this->authUser();
        $day = $this->scheduleDay($user);

        $activity = WearableActivity::factory()->create([
            'user_id' => $user->id,
            'source' => 'apple_health',
            'source_activity_id' => 'kept-after-unlink',
        ]);
        TrainingResult::factory()->create([
            'training_day_id' => $day->id,
            'wearable_activity_id' => $activity->id,
        ]);

        $response = $this->deleteJson(
            "/api/v1/training-days/{$day->id}/match-activity",
            [],
            $headers,
        );

        $response->assertOk();
        $this->assertDatabaseMissing('training_results', ['training_day_id' => $day->id]);
        $this->assertDatabaseHas('wearable_activities', [
            'source' => 'apple_health',
            'source_activity_id' => 'kept-after-unlink',
        ]);
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

    public function test_match_dispatches_feedback_generation(): void
    {
        Queue::fake();

        [$user, $headers] = $this->authUser();
        $day = $this->scheduleDay($user);

        $activity = WearableActivity::factory()->create([
            'user_id' => $user->id,
            'distance_meters' => 5050,
            'duration_seconds' => 1830,
            'average_pace_seconds_per_km' => 362,
            'start_date' => now(),
        ]);

        $this->postJson(
            "/api/v1/training-days/{$day->id}/match-activity",
            ['wearable_activity_id' => $activity->id],
            $headers,
        )->assertOk();

        Queue::assertPushed(GenerateActivityFeedback::class);
    }
}
