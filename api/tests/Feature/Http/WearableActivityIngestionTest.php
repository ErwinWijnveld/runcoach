<?php

namespace Tests\Feature\Http;

use App\Enums\GoalStatus;
use App\Jobs\GenerateActivityFeedback;
use App\Jobs\ProcessWearableActivity;
use App\Models\Goal;
use App\Models\TrainingDay;
use App\Models\TrainingResult;
use App\Models\TrainingWeek;
use App\Models\User;
use App\Models\UserRunningProfile;
use App\Models\WearableActivity;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

class WearableActivityIngestionTest extends TestCase
{
    use LazilyRefreshDatabase;

    private function authUser(): array
    {
        $user = User::factory()->create();
        $token = $user->createToken('api')->plainTextToken;

        return [$user, ['Authorization' => "Bearer $token"]];
    }

    private function payload(array $overrides = []): array
    {
        return array_merge([
            'source' => 'apple_health',
            'source_activity_id' => 'hk-uuid-001',
            'source_user_id' => 'com.apple.health',
            'type' => 'Run',
            'name' => 'Morning Run',
            'distance_meters' => 5050,
            'duration_seconds' => 1820,
            'elapsed_seconds' => 1900,
            'average_heartrate' => 152.4,
            'max_heartrate' => 178.0,
            'elevation_gain_meters' => 32,
            'calories_kcal' => 410,
            'start_date' => '2026-04-26T07:14:00Z',
            'end_date' => '2026-04-26T07:44:20Z',
            'raw_data' => ['splits' => []],
        ], $overrides);
    }

    /**
     * Seed an active goal so the controller's "skip dispatch when no plan"
     * guard doesn't suppress the ProcessWearableActivity jobs the dispatch
     * tests need to assert on.
     */
    private function giveUserAnActivePlan(User $user): void
    {
        Goal::factory()->create([
            'user_id' => $user->id,
            'status' => GoalStatus::Active,
        ]);
    }

    public function test_unauthenticated_request_is_rejected(): void
    {
        $this->postJson('/api/v1/wearable/activities', ['activities' => [$this->payload()]])
            ->assertStatus(401);
    }

    public function test_creates_a_new_activity(): void
    {
        Queue::fake();
        [$user, $headers] = $this->authUser();
        $this->giveUserAnActivePlan($user);

        $response = $this->postJson(
            '/api/v1/wearable/activities',
            ['activities' => [$this->payload()]],
            $headers,
        );

        $response->assertStatus(201);
        $response->assertJson(['created' => 1, 'updated' => 0]);
        $this->assertDatabaseHas('wearable_activities', [
            'user_id' => $user->id,
            'source' => 'apple_health',
            'source_activity_id' => 'hk-uuid-001',
            'distance_meters' => 5050,
            'duration_seconds' => 1820,
        ]);

        // Pace was computed: 1820 / 5.05 ≈ 360
        $this->assertSame(360, WearableActivity::first()->average_pace_seconds_per_km);

        Queue::assertPushed(ProcessWearableActivity::class);
    }

    public function test_skips_processing_jobs_when_user_has_no_active_plan(): void
    {
        // 75 historical workouts on first sign-in used to spawn 75 no-op
        // jobs (no plan exists yet to match against). Skip dispatch entirely
        // until the user has an active goal.
        Queue::fake();
        [, $headers] = $this->authUser();

        $this->postJson('/api/v1/wearable/activities', [
            'activities' => [
                $this->payload(['source_activity_id' => 'a']),
                $this->payload(['source_activity_id' => 'b']),
                $this->payload(['source_activity_id' => 'c']),
            ],
        ], $headers)->assertStatus(201)->assertJson(['created' => 3]);

        Queue::assertNotPushed(ProcessWearableActivity::class);
    }

    public function test_is_idempotent_on_source_activity_id(): void
    {
        [$user, $headers] = $this->authUser();
        Queue::fake();

        $payload = $this->payload();

        $this->postJson('/api/v1/wearable/activities', ['activities' => [$payload]], $headers)
            ->assertStatus(201)
            ->assertJson(['created' => 1, 'updated' => 0]);

        // Re-push the same activity — should update, not create.
        $this->postJson('/api/v1/wearable/activities', ['activities' => [$payload]], $headers)
            ->assertStatus(201)
            ->assertJson(['created' => 0, 'updated' => 1]);

        $this->assertSame(1, WearableActivity::count());
    }

    public function test_validates_required_fields(): void
    {
        [, $headers] = $this->authUser();

        $this->postJson(
            '/api/v1/wearable/activities',
            ['activities' => [['source' => 'apple_health']]],
            $headers,
        )->assertStatus(422);
    }

    public function test_dispatches_processing_job_per_new_activity(): void
    {
        Queue::fake();
        [$user, $headers] = $this->authUser();
        $this->giveUserAnActivePlan($user);

        $this->postJson('/api/v1/wearable/activities', [
            'activities' => [
                $this->payload(['source_activity_id' => 'a']),
                $this->payload(['source_activity_id' => 'b']),
                $this->payload(['source_activity_id' => 'c']),
            ],
        ], $headers)->assertStatus(201);

        Queue::assertPushed(ProcessWearableActivity::class, 3);
    }

    public function test_process_job_matches_to_training_day_and_dispatches_feedback(): void
    {
        Queue::fake();
        [$user, $headers] = $this->authUser();

        $goal = Goal::factory()->create([
            'user_id' => $user->id,
            'status' => GoalStatus::Active,
        ]);
        $week = TrainingWeek::factory()->create(['goal_id' => $goal->id]);
        TrainingDay::factory()->create([
            'training_week_id' => $week->id,
            'date' => now()->toDateString(),
            'target_km' => 5.0,
            'target_pace_seconds_per_km' => 360,
        ]);

        $payload = $this->payload(['start_date' => now()->toIso8601String()]);
        $this->postJson('/api/v1/wearable/activities', ['activities' => [$payload]], $headers)
            ->assertStatus(201);

        // Run the queued ProcessWearableActivity job synchronously.
        $activity = WearableActivity::first();
        Queue::assertPushed(ProcessWearableActivity::class, function ($job) use ($activity) {
            return $job->wearableActivityId === $activity->id;
        });

        // Manually invoke the handler to assert the downstream pipeline.
        Queue::fake();
        app()->call([new ProcessWearableActivity($activity->id), 'handle']);

        $this->assertDatabaseHas('training_results', [
            'wearable_activity_id' => $activity->id,
        ]);
        Queue::assertPushed(GenerateActivityFeedback::class);
    }

    public function test_index_returns_paginated_user_activities(): void
    {
        [$user, $headers] = $this->authUser();
        WearableActivity::factory()->count(3)->create(['user_id' => $user->id]);
        WearableActivity::factory()->count(2)->create(); // other users — must not leak

        $response = $this->getJson('/api/v1/wearable/activities', $headers);

        $response->assertOk();
        $this->assertCount(3, $response->json('data'));
    }

    public function test_re_pushing_same_activity_does_not_dispatch_a_second_job(): void
    {
        Queue::fake();
        [$user, $headers] = $this->authUser();
        $this->giveUserAnActivePlan($user);

        $payload = $this->payload();

        $this->postJson('/api/v1/wearable/activities', ['activities' => [$payload]], $headers);
        Queue::assertPushed(ProcessWearableActivity::class, 1);

        // Re-push: row updates, but no new job — match+score is idempotent
        // and the work was already done on the first push.
        Queue::fake();
        $this->postJson('/api/v1/wearable/activities', ['activities' => [$payload]], $headers);
        Queue::assertNotPushed(ProcessWearableActivity::class);
    }

    public function test_two_users_can_have_the_same_source_activity_id(): void
    {
        // The unique constraint is per-user, so HKWorkout uuid collisions
        // (theoretical with HealthKit, possible with manually-crafted ids)
        // don't let user A's row get overwritten by user B's push.
        Queue::fake();
        $victim = User::factory()->create();
        $attacker = User::factory()->create();
        $this->assertNotSame($victim->id, $attacker->id);

        $sharedId = 'collision-uuid-007';
        $this->actingAs($victim, 'sanctum')
            ->postJson('/api/v1/wearable/activities', [
                'activities' => [$this->payload([
                    'source_activity_id' => $sharedId,
                    'distance_meters' => 5050,
                    'name' => "Victim's run",
                ])],
            ])
            ->assertStatus(201)
            ->assertJson(['created' => 1]);

        $this->actingAs($attacker, 'sanctum')
            ->postJson('/api/v1/wearable/activities', [
                'activities' => [$this->payload([
                    'source_activity_id' => $sharedId,
                    'distance_meters' => 9999,
                    'name' => "Attacker's run",
                ])],
            ])
            ->assertStatus(201)
            ->assertJson(['created' => 1]);

        $this->assertSame(2, WearableActivity::count());
        $this->assertDatabaseHas('wearable_activities', [
            'user_id' => $victim->id,
            'source_activity_id' => $sharedId,
            'name' => "Victim's run",
            'distance_meters' => 5050,
        ]);
        $this->assertDatabaseHas('wearable_activities', [
            'user_id' => $attacker->id,
            'source_activity_id' => $sharedId,
            'distance_meters' => 9999,
        ]);
    }

    public function test_pushing_new_activities_invalidates_cached_running_profile(): void
    {
        Queue::fake();
        [$user, $headers] = $this->authUser();

        // Pretend the profile was analyzed at some earlier point.
        UserRunningProfile::factory()->for($user)->create([
            'metrics' => ['weekly_avg_km' => 1.8],
            'narrative_summary' => 'stale',
        ]);

        $this->postJson(
            '/api/v1/wearable/activities',
            ['activities' => [$this->payload()]],
            $headers,
        )->assertStatus(201);

        $this->assertNull($user->runningProfile()->first());
    }

    public function test_response_surfaces_created_runs_with_metadata(): void
    {
        // The Flutter app uses created_runs to drive the per-run "analyzing"
        // chip + analysis-status polling. Each entry must include the row id
        // and a `will_analyze` flag so the app knows whether to expect a push.
        Queue::fake();
        [$user, $headers] = $this->authUser();
        $this->giveUserAnActivePlan($user);

        $response = $this->postJson('/api/v1/wearable/activities', [
            'activities' => [
                $this->payload(['source_activity_id' => 'a', 'name' => 'Run A']),
                $this->payload(['source_activity_id' => 'b', 'name' => 'Run B']),
            ],
        ], $headers);

        $response->assertStatus(201);
        $createdRuns = $response->json('created_runs');
        $this->assertCount(2, $createdRuns);
        foreach ($createdRuns as $entry) {
            $this->assertArrayHasKey('id', $entry);
            $this->assertArrayHasKey('distance_meters', $entry);
            $this->assertArrayHasKey('start_date', $entry);
            $this->assertTrue($entry['will_analyze']);
        }
    }

    public function test_response_marks_will_analyze_false_when_user_has_no_active_plan(): void
    {
        Queue::fake();
        [, $headers] = $this->authUser();

        $response = $this->postJson('/api/v1/wearable/activities', [
            'activities' => [$this->payload()],
        ], $headers);

        $response->assertStatus(201);
        $this->assertCount(1, $response->json('created_runs'));
        $this->assertFalse($response->json('created_runs.0.will_analyze'));
    }

    public function test_analysis_status_returns_pending_for_unmatched_activity(): void
    {
        [$user, $headers] = $this->authUser();
        $activity = WearableActivity::factory()->create(['user_id' => $user->id]);

        $this->getJson(
            "/api/v1/wearable/activities/{$activity->id}/analysis",
            $headers,
        )
            ->assertOk()
            ->assertJson([
                'status' => 'pending',
                'wearable_activity_id' => $activity->id,
            ]);
    }

    public function test_analysis_status_returns_matched_when_result_exists_without_feedback(): void
    {
        [$user, $headers] = $this->authUser();
        $goal = Goal::factory()->create([
            'user_id' => $user->id,
            'status' => GoalStatus::Active,
        ]);
        $week = TrainingWeek::factory()->create(['goal_id' => $goal->id]);
        $day = TrainingDay::factory()->create(['training_week_id' => $week->id]);
        $activity = WearableActivity::factory()->create(['user_id' => $user->id]);
        TrainingResult::factory()->create([
            'training_day_id' => $day->id,
            'wearable_activity_id' => $activity->id,
            'compliance_score' => 8.4,
            'ai_feedback' => null,
        ]);

        $this->getJson(
            "/api/v1/wearable/activities/{$activity->id}/analysis",
            $headers,
        )
            ->assertOk()
            ->assertJson([
                'status' => 'matched',
                'training_day_id' => $day->id,
            ]);
    }

    public function test_analysis_status_returns_analyzed_when_feedback_is_set(): void
    {
        [$user, $headers] = $this->authUser();
        $goal = Goal::factory()->create([
            'user_id' => $user->id,
            'status' => GoalStatus::Active,
        ]);
        $week = TrainingWeek::factory()->create(['goal_id' => $goal->id]);
        $day = TrainingDay::factory()->create(['training_week_id' => $week->id]);
        $activity = WearableActivity::factory()->create(['user_id' => $user->id]);
        TrainingResult::factory()->create([
            'training_day_id' => $day->id,
            'wearable_activity_id' => $activity->id,
            'compliance_score' => 8.4,
            'ai_feedback' => 'Great pacing on the descents.',
        ]);

        $this->getJson(
            "/api/v1/wearable/activities/{$activity->id}/analysis",
            $headers,
        )
            ->assertOk()
            ->assertJson([
                'status' => 'analyzed',
                'training_day_id' => $day->id,
                'ai_feedback' => 'Great pacing on the descents.',
            ]);
    }

    public function test_analysis_status_404s_for_other_users_activity(): void
    {
        [, $headers] = $this->authUser();
        $other = User::factory()->create();
        $activity = WearableActivity::factory()->create(['user_id' => $other->id]);

        $this->getJson(
            "/api/v1/wearable/activities/{$activity->id}/analysis",
            $headers,
        )->assertStatus(404);
    }

    public function test_re_pushing_existing_activities_keeps_running_profile_cache(): void
    {
        // No new rows = no profile re-analysis, since regenerating the
        // narrative costs ~1k LLM tokens and adds latency.
        Queue::fake();
        [$user, $headers] = $this->authUser();

        $this->postJson(
            '/api/v1/wearable/activities',
            ['activities' => [$this->payload()]],
            $headers,
        );

        $profile = UserRunningProfile::factory()->for($user)->create([
            'metrics' => ['weekly_avg_km' => 1.8],
            'narrative_summary' => 'should-survive',
        ]);

        $this->postJson(
            '/api/v1/wearable/activities',
            ['activities' => [$this->payload()]], // same id → update only
            $headers,
        )->assertStatus(201)->assertJson(['created' => 0, 'updated' => 1]);

        $this->assertSame('should-survive', $profile->fresh()->narrative_summary);
    }
}
