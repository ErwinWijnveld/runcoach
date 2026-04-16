<?php

namespace Tests\Feature;

use App\Ai\Agents\RunCoachAgent;
use App\Enums\ProposalStatus;
use App\Models\CoachProposal;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class CoachChatTest extends TestCase
{
    use LazilyRefreshDatabase;

    private function authUser(): array
    {
        $user = User::factory()->create();
        $token = $user->createToken('api')->plainTextToken;

        return [$user, ['Authorization' => "Bearer $token"]];
    }

    public function test_create_conversation(): void
    {
        RunCoachAgent::fake(['Hello! I\'m your running coach.']);

        [$user, $headers] = $this->authUser();

        $response = $this->postJson('/api/v1/coach/conversations', [
            'title' => 'Training Chat',
        ], $headers);

        $response->assertCreated();
        $response->assertJsonStructure(['data' => ['id', 'title']]);
    }

    public function test_accept_proposal(): void
    {
        [$user, $headers] = $this->authUser();
        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'payload' => [
                'goal_type' => 'race',
                'goal_name' => 'Test Goal',
                'distance' => 'half_marathon',
                'target_date' => now()->addMonths(3)->toDateString(),
                'schedule' => ['weeks' => []],
            ],
        ]);

        $response = $this->postJson("/api/v1/coach/proposals/{$proposal->id}/accept", [], $headers);

        $response->assertOk();
        $this->assertSame(ProposalStatus::Accepted, $proposal->fresh()->status);
        $this->assertDatabaseHas('goals', ['user_id' => $user->id, 'type' => 'race', 'name' => 'Test Goal']);
    }

    public function test_accept_proposal_for_general_fitness_goal_without_target_date(): void
    {
        [$user, $headers] = $this->authUser();
        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'payload' => [
                'goal_type' => 'general_fitness',
                'goal_name' => 'General fitness',
                'target_date' => null,
                'distance' => null,
                'goal_time_seconds' => null,
                'schedule' => [
                    'weeks' => [
                        [
                            'week_number' => 1,
                            'focus' => 'base',
                            'total_km' => 20,
                            'days' => [
                                [
                                    'day_of_week' => 1,
                                    'type' => 'easy',
                                    'title' => 'Easy Run',
                                    'description' => 'Test',
                                    'target_km' => 5,
                                    'target_pace_seconds_per_km' => 360,
                                    'target_heart_rate_zone' => 2,
                                ],
                            ],
                        ],
                    ],
                ],
            ],
        ]);

        $response = $this->postJson("/api/v1/coach/proposals/{$proposal->id}/accept", [], $headers);

        $response->assertOk();
        $this->assertSame(ProposalStatus::Accepted, $proposal->fresh()->status);
        $this->assertDatabaseHas('goals', ['user_id' => $user->id, 'type' => 'general_fitness', 'target_date' => null]);

        $goal = $user->goals()->where('type', 'general_fitness')->firstOrFail();
        $this->assertDatabaseHas('training_weeks', ['goal_id' => $goal->id, 'week_number' => 1]);
    }

    public function test_reject_proposal(): void
    {
        [$user, $headers] = $this->authUser();
        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
        ]);

        $response = $this->postJson("/api/v1/coach/proposals/{$proposal->id}/reject", [], $headers);

        $response->assertOk();
        $this->assertSame(ProposalStatus::Rejected, $proposal->fresh()->status);
    }
}
