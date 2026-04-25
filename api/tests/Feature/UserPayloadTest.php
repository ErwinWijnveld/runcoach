<?php

namespace Tests\Feature;

use App\Enums\PlanGenerationStatus;
use App\Enums\ProposalStatus;
use App\Enums\ProposalType;
use App\Models\CoachProposal;
use App\Models\PlanGeneration;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class UserPayloadTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_profile_includes_pending_plan_generation_when_in_flight(): void
    {
        $user = User::factory()->create();
        $row = PlanGeneration::factory()->for($user)->create([
            'status' => PlanGenerationStatus::Processing,
            'started_at' => now(),
        ]);

        $this->actingAs($user)
            ->getJson('/api/v1/profile')
            ->assertOk()
            ->assertJsonPath('user.pending_plan_generation.id', $row->id)
            ->assertJsonPath('user.pending_plan_generation.status', 'processing');
    }

    public function test_profile_pending_plan_generation_is_null_when_none(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user)
            ->getJson('/api/v1/profile')
            ->assertOk()
            ->assertJsonPath('user.pending_plan_generation', null);
    }

    public function test_profile_pending_plan_generation_includes_all_fields(): void
    {
        $user = User::factory()->create();
        $row = PlanGeneration::factory()->for($user)->create([
            'status' => PlanGenerationStatus::Failed,
            'error_message' => 'Anthropic 503',
            'completed_at' => now(),
        ]);

        $this->actingAs($user)
            ->getJson('/api/v1/profile')
            ->assertOk()
            ->assertJsonStructure([
                'user' => [
                    'id', 'name', 'email', 'coach_style', 'has_completed_onboarding',
                    'pending_plan_generation' => [
                        'id', 'status', 'conversation_id', 'proposal_id', 'error_message',
                    ],
                ],
            ])
            ->assertJsonPath('user.pending_plan_generation.id', $row->id)
            ->assertJsonPath('user.pending_plan_generation.status', 'failed')
            ->assertJsonPath('user.pending_plan_generation.error_message', 'Anthropic 503');
    }

    public function test_profile_applies_watchdog_to_stuck_row(): void
    {
        // Same logic as the GET /latest watchdog test, but routed through
        // /profile. Both endpoints share the same User method, so a single
        // round-trip should also flip the row.
        $user = User::factory()->create();
        $row = PlanGeneration::factory()->for($user)->create([
            'status' => PlanGenerationStatus::Processing,
            'started_at' => now()->subMinutes(15),
        ]);

        $this->actingAs($user)
            ->getJson('/api/v1/profile')
            ->assertJsonPath('user.pending_plan_generation.status', 'failed');

        $row->refresh();
        $this->assertSame(PlanGenerationStatus::Failed, $row->status);
    }

    public function test_profile_pending_is_null_after_proposal_accepted(): void
    {
        // Once user accepts the proposal in the chat, the user payload
        // should stop redirecting them — confirming the routing
        // contract documented in the design.
        $user = User::factory()->create();
        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Accepted,
            'applied_at' => now(),
        ]);
        PlanGeneration::factory()->for($user)->create([
            'status' => PlanGenerationStatus::Completed,
            'proposal_id' => $proposal->id,
            'completed_at' => now()->subMinute(),
        ]);

        $this->actingAs($user)
            ->getJson('/api/v1/profile')
            ->assertJsonPath('user.pending_plan_generation', null);
    }
}
