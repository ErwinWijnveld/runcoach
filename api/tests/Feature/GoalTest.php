<?php

namespace Tests\Feature;

use App\Enums\GoalStatus;
use App\Models\Goal;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class GoalTest extends TestCase
{
    use LazilyRefreshDatabase;

    private function authUser(): array
    {
        $user = User::factory()->create();
        $token = $user->createToken('api')->plainTextToken;

        return [$user, ['Authorization' => "Bearer $token"]];
    }

    public function test_list_goals(): void
    {
        [$user, $headers] = $this->authUser();
        Goal::factory()->count(3)->create(['user_id' => $user->id]);

        $response = $this->getJson('/api/v1/goals', $headers);

        $response->assertOk();
        $this->assertCount(3, $response->json('data'));
    }

    public function test_create_goal(): void
    {
        [$user, $headers] = $this->authUser();

        $response = $this->postJson('/api/v1/goals', [
            'type' => 'race',
            'name' => 'Amsterdam Marathon',
            'distance' => 'marathon',
            'goal_time_seconds' => 12600,
            'target_date' => now()->addMonths(3)->format('Y-m-d'),
        ], $headers);

        $response->assertCreated();
        $this->assertDatabaseHas('goals', ['name' => 'Amsterdam Marathon', 'type' => 'race']);
    }

    public function test_create_general_fitness_goal_without_distance_or_date(): void
    {
        [$user, $headers] = $this->authUser();

        $response = $this->postJson('/api/v1/goals', [
            'type' => 'general_fitness',
            'name' => 'Build base fitness',
        ], $headers);

        $response->assertCreated();
        $this->assertDatabaseHas('goals', [
            'name' => 'Build base fitness',
            'type' => 'general_fitness',
            'distance' => null,
            'target_date' => null,
        ]);
    }

    public function test_show_goal(): void
    {
        [$user, $headers] = $this->authUser();
        $goal = Goal::factory()->create(['user_id' => $user->id]);

        $response = $this->getJson("/api/v1/goals/{$goal->id}", $headers);

        $response->assertOk();
        $response->assertJsonFragment(['name' => $goal->name]);
    }

    public function test_update_goal(): void
    {
        [$user, $headers] = $this->authUser();
        $goal = Goal::factory()->create(['user_id' => $user->id]);

        $response = $this->putJson("/api/v1/goals/{$goal->id}", [
            'name' => 'Updated Goal Name',
        ], $headers);

        $response->assertOk();
        $this->assertDatabaseHas('goals', ['name' => 'Updated Goal Name']);
    }

    public function test_cancel_goal(): void
    {
        [$user, $headers] = $this->authUser();
        $goal = Goal::factory()->create(['user_id' => $user->id]);

        $response = $this->deleteJson("/api/v1/goals/{$goal->id}", [], $headers);

        $response->assertOk();
        $this->assertDatabaseHas('goals', ['id' => $goal->id, 'status' => 'cancelled']);
    }

    public function test_activate_goal_pauses_other_active_goals(): void
    {
        [$user, $headers] = $this->authUser();
        $previouslyActive = Goal::factory()->create([
            'user_id' => $user->id,
            'status' => GoalStatus::Active,
        ]);
        $target = Goal::factory()->create([
            'user_id' => $user->id,
            'status' => GoalStatus::Paused,
        ]);

        $response = $this->postJson("/api/v1/goals/{$target->id}/activate", [], $headers);

        $response->assertOk();
        $this->assertDatabaseHas('goals', ['id' => $target->id, 'status' => 'active']);
        $this->assertDatabaseHas('goals', ['id' => $previouslyActive->id, 'status' => 'paused']);
    }

    public function test_activate_is_scoped_to_current_user(): void
    {
        [, $headers] = $this->authUser();
        $otherGoal = Goal::factory()->create(['status' => GoalStatus::Paused]);

        $response = $this->postJson("/api/v1/goals/{$otherGoal->id}/activate", [], $headers);

        $response->assertForbidden();
    }

    public function test_cannot_access_other_users_goal(): void
    {
        [$user, $headers] = $this->authUser();
        $otherGoal = Goal::factory()->create();

        $response = $this->getJson("/api/v1/goals/{$otherGoal->id}", $headers);

        $response->assertForbidden();
    }
}
