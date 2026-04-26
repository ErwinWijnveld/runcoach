<?php

namespace Tests\Feature;

use App\Ai\Agents\RunCoachAgent;
use App\Enums\ProposalStatus;
use App\Models\CoachProposal;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
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
                                    // Pick today's weekday so the day never
                                    // lands in the past — applyCreateSchedule
                                    // drops past-dated days, and a week with
                                    // no surviving days is no longer persisted.
                                    'day_of_week' => now()->isoWeekday(),
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

    public function test_show_returns_tool_results_for_messages(): void
    {
        [$user, $headers] = $this->authUser();

        $convoId = (string) Str::uuid();
        DB::table('agent_conversations')->insert([
            'id' => $convoId, 'user_id' => $user->id, 'title' => 'Test',
            'created_at' => now(), 'updated_at' => now(),
        ]);
        $msgId = (string) Str::uuid();
        DB::table('agent_conversation_messages')->insert([
            'id' => $msgId,
            'conversation_id' => $convoId,
            'user_id' => $user->id,
            'agent' => 'RunCoachAgent',
            'role' => 'assistant',
            'content' => 'hi',
            'attachments' => '[]',
            'tool_calls' => '[]',
            'tool_results' => json_encode([
                ['tool' => 'present_running_stats', 'result' => [
                    'display' => 'stats_card',
                    'metrics' => ['weekly_avg_km' => 20.0],
                ]],
            ]),
            'usage' => '[]',
            'meta' => '',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $response = $this->getJson("/api/v1/coach/conversations/{$convoId}", $headers)->assertOk();

        $this->assertCount(1, $response->json('data.messages'));
        $this->assertEquals('stats_card',
            $response->json('data.messages.0.tool_results.0.result.display')
        );
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
