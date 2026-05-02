<?php

namespace Tests\Feature;

use App\Models\Goal;
use App\Models\TrainingDay;
use App\Models\TrainingResult;
use App\Models\TrainingWeek;
use App\Models\User;
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
