<?php

namespace Tests\Feature;

use App\Models\Goal;
use App\Models\TrainingDay;
use App\Models\TrainingResult;
use App\Models\TrainingWeek;
use App\Models\User;
use App\Models\WearableActivity;
use App\Support\Intervals\IntervalBlueprint;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class TrainingScheduleTest extends TestCase
{
    use LazilyRefreshDatabase;

    private function authUser(): array
    {
        $user = User::factory()->create();
        $token = $user->createToken('api')->plainTextToken;

        return [$user, ['Authorization' => "Bearer $token"]];
    }

    public function test_get_full_schedule(): void
    {
        [$user, $headers] = $this->authUser();
        $goal = Goal::factory()->create(['user_id' => $user->id]);
        $week = TrainingWeek::factory()->create(['goal_id' => $goal->id, 'week_number' => 1]);
        TrainingDay::factory()->count(7)->create(['training_week_id' => $week->id]);

        $response = $this->getJson("/api/v1/goals/{$goal->id}/schedule", $headers);

        $response->assertOk();
        $this->assertCount(1, $response->json('data'));
        $this->assertCount(7, $response->json('data.0.training_days'));
    }

    public function test_schedule_includes_off_plan_runs_in_their_week(): void
    {
        [$user, $headers] = $this->authUser();
        $goal = Goal::factory()->create(['user_id' => $user->id]);
        $week = TrainingWeek::factory()->create([
            'goal_id' => $goal->id,
            'week_number' => 1,
            'starts_at' => now()->startOfWeek()->toDateString(),
        ]);
        TrainingDay::factory()->create([
            'training_week_id' => $week->id,
            'date' => now()->startOfWeek()->addDay()->toDateString(),
        ]);

        // An unmatched run inside the week → surfaces as off-plan.
        $offPlan = WearableActivity::factory()->create([
            'user_id' => $user->id,
            'type' => 'Run',
            'start_date' => now()->startOfWeek()->addDays(3),
        ]);

        // A run that already has a result → must NOT appear as off-plan.
        $matchedDay = TrainingDay::factory()->create([
            'training_week_id' => $week->id,
            'date' => now()->startOfWeek()->addDays(4)->toDateString(),
        ]);
        $matchedRun = WearableActivity::factory()->create([
            'user_id' => $user->id,
            'type' => 'Run',
            'start_date' => now()->startOfWeek()->addDays(4),
        ]);
        TrainingResult::factory()->create([
            'training_day_id' => $matchedDay->id,
            'wearable_activity_id' => $matchedRun->id,
        ]);

        $response = $this->getJson("/api/v1/goals/{$goal->id}/schedule", $headers);

        $response->assertOk();
        $runs = $response->json('data.0.unplanned_runs');
        $this->assertIsArray($runs);
        $this->assertCount(1, $runs);
        $this->assertSame($offPlan->id, $runs[0]['id']);
    }

    public function test_get_current_week(): void
    {
        [$user, $headers] = $this->authUser();
        $goal = Goal::factory()->create(['user_id' => $user->id]);

        TrainingWeek::factory()->create([
            'goal_id' => $goal->id,
            'week_number' => 1,
            'starts_at' => now()->subWeeks(2)->startOfWeek(),
        ]);

        $currentWeek = TrainingWeek::factory()->create([
            'goal_id' => $goal->id,
            'week_number' => 2,
            'starts_at' => now()->startOfWeek(),
        ]);
        TrainingDay::factory()->count(7)->create([
            'training_week_id' => $currentWeek->id,
            'date' => now(),
        ]);

        $response = $this->getJson("/api/v1/goals/{$goal->id}/schedule/current", $headers);

        $response->assertOk();
        $this->assertEquals($currentWeek->id, $response->json('data.id'));
    }

    public function test_get_training_day_detail(): void
    {
        [$user, $headers] = $this->authUser();
        $goal = Goal::factory()->create(['user_id' => $user->id]);
        $week = TrainingWeek::factory()->create(['goal_id' => $goal->id]);
        $day = TrainingDay::factory()->create(['training_week_id' => $week->id]);

        $response = $this->getJson("/api/v1/training-days/{$day->id}", $headers);

        $response->assertOk();
        $response->assertJsonFragment(['title' => $day->title]);
        // The Flutter watch auto-sync compares this against a locally-stored
        // lastSyncedAt map to decide which days to re-ship on foreground.
        // Default Eloquent serialization includes it — this assertion pins
        // the contract so a future `$hidden` rule can't silently break it.
        $this->assertNotNull($response->json('data.updated_at'));
    }

    public function test_get_training_result(): void
    {
        [$user, $headers] = $this->authUser();
        $goal = Goal::factory()->create(['user_id' => $user->id]);
        $week = TrainingWeek::factory()->create(['goal_id' => $goal->id]);
        $day = TrainingDay::factory()->create(['training_week_id' => $week->id]);
        $result = TrainingResult::factory()->create(['training_day_id' => $day->id]);

        $response = $this->getJson("/api/v1/training-days/{$day->id}/result", $headers);

        $response->assertOk();
        $response->assertJsonFragment(['compliance_score' => $result->compliance_score]);
    }

    public function test_training_day_without_result_returns_null(): void
    {
        [$user, $headers] = $this->authUser();
        $goal = Goal::factory()->create(['user_id' => $user->id]);
        $week = TrainingWeek::factory()->create(['goal_id' => $goal->id]);
        $day = TrainingDay::factory()->create(['training_week_id' => $week->id]);

        $response = $this->getJson("/api/v1/training-days/{$day->id}/result", $headers);

        $response->assertOk();
        $this->assertNull($response->json('data'));
    }

    public function test_update_day_reassigns_to_matching_week(): void
    {
        [$user, $headers] = $this->authUser();
        $goal = Goal::factory()->create([
            'user_id' => $user->id,
            'target_date' => now()->addWeeks(8)->toDateString(),
        ]);
        $weekA = TrainingWeek::factory()->create([
            'goal_id' => $goal->id,
            'week_number' => 1,
            'starts_at' => now()->startOfDay()->toDateString(),
        ]);
        $weekB = TrainingWeek::factory()->create([
            'goal_id' => $goal->id,
            'week_number' => 2,
            'starts_at' => now()->addDays(7)->startOfDay()->toDateString(),
        ]);
        $day = TrainingDay::factory()->create([
            'training_week_id' => $weekA->id,
            'date' => now()->addDays(2)->toDateString(),
        ]);

        $newDate = now()->addDays(9)->toDateString();
        $response = $this->patchJson(
            "/api/v1/training-days/{$day->id}",
            ['date' => $newDate],
            $headers,
        );

        $response->assertOk();
        $this->assertEquals($newDate, substr($response->json('data.date'), 0, 10));
        $this->assertEquals($weekB->id, $response->json('data.training_week_id'));
    }

    public function test_update_day_edits_distance_and_pace_in_place(): void
    {
        [$user, $headers] = $this->authUser();
        $goal = Goal::factory()->create(['user_id' => $user->id, 'target_date' => null]);
        $week = TrainingWeek::factory()->create(['goal_id' => $goal->id]);
        $day = TrainingDay::factory()->create([
            'training_week_id' => $week->id,
            'type' => 'easy',
            'target_km' => 8.0,
            'target_pace_seconds_per_km' => 360,
        ]);

        $response = $this->patchJson(
            "/api/v1/training-days/{$day->id}",
            ['target_km' => 3, 'target_pace_seconds_per_km' => 300],
            $headers,
        );

        $response->assertOk();
        $day->refresh();
        $this->assertEquals(3.0, (float) $day->target_km);
        $this->assertEquals(300, $day->target_pace_seconds_per_km);
    }

    public function test_update_day_never_stores_day_pace_on_interval(): void
    {
        [$user, $headers] = $this->authUser();
        $goal = Goal::factory()->create(['user_id' => $user->id, 'target_date' => null]);
        $week = TrainingWeek::factory()->create(['goal_id' => $goal->id]);
        $day = TrainingDay::factory()->create([
            'training_week_id' => $week->id,
            'type' => 'interval',
            'target_pace_seconds_per_km' => null,
        ]);

        $response = $this->patchJson(
            "/api/v1/training-days/{$day->id}",
            ['target_pace_seconds_per_km' => 240],
            $headers,
        );

        $response->assertOk();
        $this->assertNull($day->fresh()->target_pace_seconds_per_km);
    }

    public function test_update_day_stores_intervals_and_derives_distance(): void
    {
        [$user, $headers] = $this->authUser();
        $goal = Goal::factory()->create(['user_id' => $user->id, 'target_date' => null]);
        $week = TrainingWeek::factory()->create(['goal_id' => $goal->id]);
        $day = TrainingDay::factory()->create([
            'training_week_id' => $week->id,
            'type' => 'interval',
            'target_km' => 5.0,
            'target_pace_seconds_per_km' => null,
            'intervals_json' => null,
        ]);

        $blueprint = [
            'warmup_seconds' => 60,
            'steps' => [['type' => 'block', 'reps' => 4, 'work_distance_m' => 800, 'work_duration_seconds' => null, 'work_pace_seconds_per_km' => 270, 'recovery_seconds' => 90]],
            'cooldown_seconds' => 300,
        ];

        $response = $this->patchJson(
            "/api/v1/training-days/{$day->id}",
            ['intervals' => $blueprint],
            $headers,
        );

        $response->assertOk();
        $day->refresh();
        $this->assertSame(4, $day->intervals_json['steps'][0]['reps']);
        $this->assertSame(800, $day->intervals_json['steps'][0]['work_distance_m']);
        // Distance is derived from the stored blueprint (saving hook), and
        // the response carries the fresh value so the app can render it.
        $expectedKm = IntervalBlueprint::estimateTotalKm($blueprint);
        $this->assertSame($expectedKm, (float) $day->target_km);
        $this->assertSame($expectedKm, (float) $response->json('data.target_km'));
    }

    public function test_update_day_rejects_intervals_on_non_interval_day(): void
    {
        [$user, $headers] = $this->authUser();
        $goal = Goal::factory()->create(['user_id' => $user->id, 'target_date' => null]);
        $week = TrainingWeek::factory()->create(['goal_id' => $goal->id]);
        $day = TrainingDay::factory()->create([
            'training_week_id' => $week->id,
            'type' => 'easy',
            'intervals_json' => null,
        ]);

        $response = $this->patchJson(
            "/api/v1/training-days/{$day->id}",
            ['intervals' => ['steps' => [['type' => 'block', 'reps' => 4, 'work_distance_m' => 400, 'recovery_seconds' => 90]]]],
            $headers,
        );

        $response->assertStatus(422);
        $this->assertNull($day->fresh()->intervals_json);
    }

    public function test_update_day_rejects_empty_or_garbage_intervals(): void
    {
        [$user, $headers] = $this->authUser();
        $goal = Goal::factory()->create(['user_id' => $user->id, 'target_date' => null]);
        $week = TrainingWeek::factory()->create(['goal_id' => $goal->id]);
        $original = [
            'warmup_seconds' => 60,
            'steps' => [['type' => 'block', 'reps' => 4, 'work_distance_m' => 800, 'work_duration_seconds' => null, 'work_pace_seconds_per_km' => 270, 'recovery_seconds' => 90]],
            'cooldown_seconds' => 300,
        ];
        $day = TrainingDay::factory()->create([
            'training_week_id' => $week->id,
            'type' => 'interval',
            'intervals_json' => $original,
        ]);

        $this->patchJson("/api/v1/training-days/{$day->id}", ['intervals' => ['steps' => []]], $headers)
            ->assertStatus(422);
        $this->patchJson("/api/v1/training-days/{$day->id}", ['intervals' => ['totally' => 'wrong']], $headers)
            ->assertStatus(422);

        // Nothing was overwritten by the rejected bodies.
        $this->assertSame(4, $day->fresh()->intervals_json['steps'][0]['reps']);
    }

    public function test_update_day_clamps_interval_values(): void
    {
        [$user, $headers] = $this->authUser();
        $goal = Goal::factory()->create(['user_id' => $user->id, 'target_date' => null]);
        $week = TrainingWeek::factory()->create(['goal_id' => $goal->id]);
        $day = TrainingDay::factory()->create([
            'training_week_id' => $week->id,
            'type' => 'interval',
            'intervals_json' => null,
        ]);

        $response = $this->patchJson("/api/v1/training-days/{$day->id}", [
            'intervals' => [
                'warmup_seconds' => 999,
                'steps' => [['type' => 'block', 'reps' => 100, 'work_distance_m' => 400, 'recovery_seconds' => 5]],
                'cooldown_seconds' => 30,
            ],
        ], $headers);

        $response->assertOk();
        $stored = $day->fresh()->intervals_json;
        $this->assertSame(120, $stored['warmup_seconds']);
        $this->assertSame(60, $stored['steps'][0]['reps']);
        $this->assertSame(15, $stored['steps'][0]['recovery_seconds']);
        $this->assertSame(60, $stored['cooldown_seconds']);
    }

    public function test_update_day_preserves_rep_and_rest_steps(): void
    {
        [$user, $headers] = $this->authUser();
        $goal = Goal::factory()->create(['user_id' => $user->id, 'target_date' => null]);
        $week = TrainingWeek::factory()->create(['goal_id' => $goal->id]);
        $day = TrainingDay::factory()->create([
            'training_week_id' => $week->id,
            'type' => 'interval',
            'intervals_json' => null,
        ]);

        // Coach-authored pyramid shape: block + standalone rep + rest. The
        // app editor sends these back untouched — order must survive.
        $response = $this->patchJson("/api/v1/training-days/{$day->id}", [
            'intervals' => [
                'warmup_seconds' => null,
                'steps' => [
                    ['type' => 'block', 'reps' => 3, 'work_distance_m' => 400, 'work_pace_seconds_per_km' => 270, 'recovery_seconds' => 60],
                    ['type' => 'rep', 'work_distance_m' => 1000, 'work_pace_seconds_per_km' => 280],
                    ['type' => 'rest', 'duration_seconds' => 120],
                ],
                'cooldown_seconds' => 300,
            ],
        ], $headers);

        $response->assertOk();
        $steps = $day->fresh()->intervals_json['steps'];
        $this->assertSame(['block', 'rep', 'rest'], array_column($steps, 'type'));
        $this->assertSame(1000, $steps[1]['work_distance_m']);
        $this->assertSame(120, $steps[2]['duration_seconds']);
    }

    public function test_update_day_rejects_past_date(): void
    {
        [$user, $headers] = $this->authUser();
        $goal = Goal::factory()->create(['user_id' => $user->id]);
        $week = TrainingWeek::factory()->create(['goal_id' => $goal->id]);
        $day = TrainingDay::factory()->create(['training_week_id' => $week->id]);

        $response = $this->patchJson(
            "/api/v1/training-days/{$day->id}",
            ['date' => now()->subDays(1)->toDateString()],
            $headers,
        );

        $response->assertStatus(422);
        $response->assertJsonValidationErrors('date');
    }

    public function test_update_day_rejects_when_result_exists(): void
    {
        [$user, $headers] = $this->authUser();
        $goal = Goal::factory()->create(['user_id' => $user->id]);
        $week = TrainingWeek::factory()->create(['goal_id' => $goal->id]);
        $day = TrainingDay::factory()->create(['training_week_id' => $week->id]);
        TrainingResult::factory()->create(['training_day_id' => $day->id]);

        $response = $this->patchJson(
            "/api/v1/training-days/{$day->id}",
            ['date' => now()->addDays(1)->toDateString()],
            $headers,
        );

        $response->assertStatus(422);
    }

    public function test_update_day_rejects_moving_the_race_day(): void
    {
        [$user, $headers] = $this->authUser();
        $raceDate = now()->addWeeks(8)->startOfDay();
        $goal = Goal::factory()->create([
            'user_id' => $user->id,
            'target_date' => $raceDate->toDateString(),
        ]);
        $week = TrainingWeek::factory()->create(['goal_id' => $goal->id]);
        $raceDay = TrainingDay::factory()->create([
            'training_week_id' => $week->id,
            'date' => $raceDate->toDateString(),
        ]);

        $response = $this->patchJson(
            "/api/v1/training-days/{$raceDay->id}",
            ['date' => $raceDate->copy()->subDays(2)->toDateString()],
            $headers,
        );

        $response->assertStatus(422);
    }

    public function test_update_day_rejects_other_users_day(): void
    {
        [, $headers] = $this->authUser();
        $otherUser = User::factory()->create();
        $goal = Goal::factory()->create(['user_id' => $otherUser->id]);
        $week = TrainingWeek::factory()->create(['goal_id' => $goal->id]);
        $day = TrainingDay::factory()->create(['training_week_id' => $week->id]);

        $response = $this->patchJson(
            "/api/v1/training-days/{$day->id}",
            ['date' => now()->addDays(1)->toDateString()],
            $headers,
        );

        $response->assertNotFound();
    }
}
