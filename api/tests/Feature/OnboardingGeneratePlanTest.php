<?php

namespace Tests\Feature;

use App\Ai\Agents\RunCoachAgent;
use App\Enums\ProposalStatus;
use App\Enums\ProposalType;
use App\Models\CoachProposal;
use App\Models\User;
use App\Models\UserRunningProfile;
use App\Services\ProposalService;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Mockery;
use Tests\TestCase;

class OnboardingGeneratePlanTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_generates_plan_for_race_goal(): void
    {
        $user = User::factory()->create();
        UserRunningProfile::factory()->for($user)->create();

        RunCoachAgent::fake(['Plan is ready — take a look below.']);
        $this->stubProposalDetection($user);

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
            ->assertJsonStructure(['conversation_id', 'proposal_id', 'weeks']);

        $this->assertDatabaseHas('agent_conversations', [
            'user_id' => $user->id,
            'context' => 'onboarding',
        ]);
    }

    public function test_generates_plan_for_fitness_goal(): void
    {
        $user = User::factory()->create();
        UserRunningProfile::factory()->for($user)->create();

        RunCoachAgent::fake(['Plan is ready.']);
        $this->stubProposalDetection($user);

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

    public function test_fails_when_agent_produces_no_proposal(): void
    {
        $user = User::factory()->create();
        UserRunningProfile::factory()->for($user)->create();

        RunCoachAgent::fake(['I gave up.']);

        // ProposalService returns null → onboarding throws → 500.
        $this->instance(
            ProposalService::class,
            Mockery::mock(ProposalService::class, function ($mock): void {
                $mock->shouldReceive('detectProposalFromConversation')->andReturn(null);
            })
        );

        $this->actingAs($user)
            ->postJson('/api/v1/onboarding/generate-plan', [
                'goal_type' => 'fitness',
                'days_per_week' => 3,
                'coach_style' => 'flexible',
            ])
            ->assertStatus(500);
    }

    /**
     * ProposalService inspects the agent's tool_results to find a pending
     * proposal. With a faked agent the tool_results are empty, so we stub
     * the service to return a pre-baked CoachProposal instead — the
     * onboarding flow is agnostic to how the proposal was produced, only
     * that detectProposalFromConversation surfaces one.
     */
    private function stubProposalDetection(User $user): CoachProposal
    {
        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Pending,
            'payload' => [
                'goal_type' => 'race',
                'goal_name' => 'Sample',
                'schedule' => [
                    'weeks' => [
                        ['week_number' => 1, 'focus' => 'base', 'total_km' => 20, 'days' => []],
                    ],
                ],
            ],
        ]);

        $this->instance(
            ProposalService::class,
            Mockery::mock(ProposalService::class, function ($mock) use ($proposal): void {
                $mock->shouldReceive('detectProposalFromConversation')->andReturn($proposal);
            })
        );

        return $proposal;
    }
}
