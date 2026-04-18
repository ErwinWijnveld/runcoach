<?php

namespace Tests\Feature;

use App\Ai\Agents\OnboardingPlanAgent;
use App\Enums\ProposalStatus;
use App\Enums\ProposalType;
use App\Models\User;
use App\Models\UserRunningProfile;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class OnboardingGeneratePlanTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_generates_plan_for_race_goal(): void
    {
        $user = User::factory()->create();
        UserRunningProfile::factory()->for($user)->create();

        OnboardingPlanAgent::fake([
            json_encode([
                'weeks' => [
                    [
                        'week_number' => 1,
                        'total_km' => 25,
                        'focus' => 'Base building',
                        'days' => [
                            [
                                'day_of_week' => 6,
                                'type' => 'easy',
                                'title' => 'Easy run',
                                'description' => 'Conversational pace.',
                                'target_km' => 6,
                                'target_pace_seconds_per_km' => 360,
                                'target_heart_rate_zone' => 'Z2',
                            ],
                        ],
                    ],
                ],
            ]),
        ]);

        $response = $this->actingAs($user)->postJson('/api/v1/onboarding/generate-plan', [
            'goal_type' => 'race',
            'goal_name' => 'Rotterdam Half',
            'distance_meters' => 21097,
            'target_date' => now()->addMonths(4)->toDateString(),
            'goal_time_seconds' => 6300,
            'days_per_week' => 4,
            'coach_style' => 'balanced',
        ]);

        $response->assertOk()
            ->assertJsonStructure(['conversation_id', 'proposal_id', 'weeks'])
            ->assertJsonPath('weeks', 1);

        $this->assertDatabaseHas('coach_proposals', [
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule->value,
            'status' => ProposalStatus::Pending->value,
        ]);

        $this->assertDatabaseHas('agent_conversations', [
            'user_id' => $user->id,
            'context' => 'onboarding',
        ]);

        $message = DB::table('agent_conversation_messages')
            ->where('user_id', $user->id)
            ->where('role', 'assistant')
            ->first();

        $this->assertNotNull($message);
        $this->assertStringContainsString('Based on your performance', $message->content);

        $toolResults = json_decode($message->tool_results, true);
        $this->assertSame('create_schedule', $toolResults[0]['tool_name'] ?? null);
        $this->assertTrue($toolResults[0]['result']['requires_approval'] ?? false);
    }

    public function test_generates_plan_for_fitness_goal(): void
    {
        $user = User::factory()->create();
        UserRunningProfile::factory()->for($user)->create();

        OnboardingPlanAgent::fake([
            json_encode([
                'weeks' => [
                    ['week_number' => 1, 'total_km' => 15, 'focus' => 'Build', 'days' => []],
                ],
            ]),
        ]);

        $this->actingAs($user)->postJson('/api/v1/onboarding/generate-plan', [
            'goal_type' => 'fitness',
            'days_per_week' => 3,
            'coach_style' => 'flexible',
        ])->assertOk();
    }

    public function test_rejects_race_without_target_date(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user)
            ->postJson('/api/v1/onboarding/generate-plan', [
                'goal_type' => 'race',
                'distance_meters' => 10000,
                'days_per_week' => 4,
                'coach_style' => 'balanced',
            ])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['target_date']);
    }

    public function test_rejects_pr_without_goal_time(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user)
            ->postJson('/api/v1/onboarding/generate-plan', [
                'goal_type' => 'pr',
                'distance_meters' => 10000,
                'days_per_week' => 4,
                'coach_style' => 'balanced',
            ])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['goal_time_seconds']);
    }

    public function test_rejects_unauthenticated(): void
    {
        $this->postJson('/api/v1/onboarding/generate-plan', [
            'goal_type' => 'fitness',
            'days_per_week' => 3,
            'coach_style' => 'flexible',
        ])->assertUnauthorized();
    }

    public function test_surfaces_error_on_invalid_agent_json(): void
    {
        $user = User::factory()->create();
        UserRunningProfile::factory()->for($user)->create();

        OnboardingPlanAgent::fake(['not json at all']);

        $this->actingAs($user)
            ->postJson('/api/v1/onboarding/generate-plan', [
                'goal_type' => 'fitness',
                'days_per_week' => 3,
                'coach_style' => 'flexible',
            ])
            ->assertStatus(500);
    }
}
