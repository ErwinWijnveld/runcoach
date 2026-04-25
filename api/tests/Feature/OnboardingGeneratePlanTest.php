<?php

namespace Tests\Feature;

use App\Enums\PlanGenerationStatus;
use App\Enums\ProposalStatus;
use App\Enums\ProposalType;
use App\Jobs\GeneratePlan;
use App\Models\CoachProposal;
use App\Models\PlanGeneration;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

class OnboardingGeneratePlanTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_creates_row_and_dispatches_job_for_race_goal(): void
    {
        Queue::fake();
        $user = User::factory()->create();

        $response = $this->actingAs($user)->postJson('/api/v1/onboarding/generate-plan', [
            'goal_type' => 'race',
            'goal_name' => 'Rotterdam Half',
            'distance_meters' => 21097,
            'target_date' => now()->addMonths(4)->toDateString(),
            'goal_time_seconds' => 6300,
            'days_per_week' => 4,
            'coach_style' => 'balanced',
        ]);

        $response->assertStatus(202)
            ->assertJsonStructure(['id', 'status', 'conversation_id', 'proposal_id', 'error_message']);

        $this->assertDatabaseCount('plan_generations', 1);
        $row = PlanGeneration::firstOrFail();
        $this->assertSame($user->id, $row->user_id);
        $this->assertSame(PlanGenerationStatus::Queued, $row->status);
        $this->assertSame('race', $row->payload['goal_type']);

        Queue::assertPushed(GeneratePlan::class, fn ($job) => $job->planGenerationId === $row->id);
    }

    public function test_returns_existing_row_when_in_flight(): void
    {
        Queue::fake();
        $user = User::factory()->create();
        $existing = PlanGeneration::factory()->for($user)->create([
            'status' => PlanGenerationStatus::Processing,
            'started_at' => now()->subSeconds(20),
        ]);

        $response = $this->actingAs($user)->postJson('/api/v1/onboarding/generate-plan', [
            'goal_type' => 'fitness',
            'days_per_week' => 3,
            'coach_style' => 'flexible',
        ]);

        $response->assertStatus(202)->assertJsonPath('id', $existing->id);
        $this->assertDatabaseCount('plan_generations', 1);
        Queue::assertNotPushed(GeneratePlan::class);
    }

    public function test_creates_new_row_after_previous_failed(): void
    {
        Queue::fake();
        $user = User::factory()->create();
        PlanGeneration::factory()->for($user)->create([
            'status' => PlanGenerationStatus::Failed,
            'completed_at' => now()->subMinute(),
        ]);

        $this->actingAs($user)->postJson('/api/v1/onboarding/generate-plan', [
            'goal_type' => 'fitness',
            'days_per_week' => 3,
            'coach_style' => 'flexible',
        ])->assertStatus(202);

        $this->assertDatabaseCount('plan_generations', 2);
        Queue::assertPushed(GeneratePlan::class);
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

    public function test_rejects_unauthenticated(): void
    {
        $this->postJson('/api/v1/onboarding/generate-plan', [
            'goal_type' => 'fitness',
            'days_per_week' => 3,
            'coach_style' => 'flexible',
        ])->assertUnauthorized();
    }

    public function test_get_latest_returns_pending_row(): void
    {
        $user = User::factory()->create();
        $row = PlanGeneration::factory()->for($user)->create([
            'status' => PlanGenerationStatus::Processing,
            'started_at' => now(),
        ]);

        $this->actingAs($user)
            ->getJson('/api/v1/onboarding/plan-generation/latest')
            ->assertOk()
            ->assertJsonPath('id', $row->id)
            ->assertJsonPath('status', 'processing');
    }

    public function test_get_latest_returns_204_when_nothing_pending(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user)
            ->getJson('/api/v1/onboarding/plan-generation/latest')
            ->assertNoContent();
    }

    public function test_post_returns_existing_row_when_queued(): void
    {
        // Same dedup as test_returns_existing_row_when_in_flight, but for
        // a row that's still `queued` (job not picked up yet). Both states
        // count as in-flight.
        Queue::fake();
        $user = User::factory()->create();
        $existing = PlanGeneration::factory()->for($user)->create([
            'status' => PlanGenerationStatus::Queued,
        ]);

        $response = $this->actingAs($user)->postJson('/api/v1/onboarding/generate-plan', [
            'goal_type' => 'fitness',
            'days_per_week' => 3,
            'coach_style' => 'flexible',
        ]);

        $response->assertStatus(202)
            ->assertJsonPath('id', $existing->id)
            ->assertJsonPath('status', 'queued');
        $this->assertDatabaseCount('plan_generations', 1);
        Queue::assertNotPushed(GeneratePlan::class);
    }

    public function test_post_creates_new_row_when_latest_is_completed_with_pending_proposal(): void
    {
        // Edge case: a previous generation completed and the proposal is still
        // sitting in the chat unaccepted. The user goes "back to form" and
        // submits again — we should create a fresh row and let the next
        // OnboardingPlanGeneratorService run reject the stale proposal.
        Queue::fake();
        $user = User::factory()->create();
        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Pending,
        ]);
        PlanGeneration::factory()->for($user)->create([
            'status' => PlanGenerationStatus::Completed,
            'proposal_id' => $proposal->id,
            'completed_at' => now()->subMinutes(5),
        ]);

        $this->actingAs($user)->postJson('/api/v1/onboarding/generate-plan', [
            'goal_type' => 'fitness',
            'days_per_week' => 3,
            'coach_style' => 'flexible',
        ])->assertStatus(202);

        $this->assertDatabaseCount('plan_generations', 2);
        Queue::assertPushed(GeneratePlan::class);
    }

    public function test_post_does_not_dedup_against_other_users_in_flight_row(): void
    {
        Queue::fake();
        $other = User::factory()->create();
        PlanGeneration::factory()->for($other)->create([
            'status' => PlanGenerationStatus::Processing,
            'started_at' => now(),
        ]);

        $me = User::factory()->create();
        $this->actingAs($me)->postJson('/api/v1/onboarding/generate-plan', [
            'goal_type' => 'fitness',
            'days_per_week' => 3,
            'coach_style' => 'flexible',
        ])->assertStatus(202);

        $this->assertDatabaseCount('plan_generations', 2);
        Queue::assertPushed(GeneratePlan::class, 1);
    }

    public function test_post_serializes_status_as_lowercase_string(): void
    {
        Queue::fake();
        $user = User::factory()->create();

        $this->actingAs($user)
            ->postJson('/api/v1/onboarding/generate-plan', [
                'goal_type' => 'fitness',
                'days_per_week' => 3,
                'coach_style' => 'flexible',
            ])
            ->assertStatus(202)
            ->assertJsonPath('status', 'queued')
            ->assertJsonPath('conversation_id', null)
            ->assertJsonPath('proposal_id', null)
            ->assertJsonPath('error_message', null);
    }

    public function test_post_persists_full_form_payload(): void
    {
        // The payload column powers retry-after-failure — verify the full
        // validated input survives the round trip.
        Queue::fake();
        $user = User::factory()->create();

        $this->actingAs($user)->postJson('/api/v1/onboarding/generate-plan', [
            'goal_type' => 'race',
            'goal_name' => 'Berlin Marathon — 2026 🏃',
            'distance_meters' => 42195,
            'target_date' => now()->addMonths(6)->toDateString(),
            'goal_time_seconds' => 14400,
            'days_per_week' => 5,
            'preferred_weekdays' => [1, 3, 5, 6, 7],
            'coach_style' => 'analytical',
            'additional_notes' => 'Returning from injury — knee was iffy in March.',
        ])->assertStatus(202);

        $row = PlanGeneration::firstOrFail();
        $this->assertSame('race', $row->payload['goal_type']);
        $this->assertSame('Berlin Marathon — 2026 🏃', $row->payload['goal_name']);
        $this->assertSame([1, 3, 5, 6, 7], $row->payload['preferred_weekdays']);
        $this->assertSame('analytical', $row->payload['coach_style']);
        $this->assertStringContainsString('injury', $row->payload['additional_notes']);
    }

    public function test_get_latest_unauthenticated_returns_401(): void
    {
        $this->getJson('/api/v1/onboarding/plan-generation/latest')->assertUnauthorized();
    }

    public function test_get_latest_applies_watchdog_to_stuck_row(): void
    {
        // GET /latest hits User::pendingPlanGeneration() which auto-fails
        // stuck rows. The response should reflect the post-watchdog state
        // (failed), not the stale processing status.
        $user = User::factory()->create();
        $row = PlanGeneration::factory()->for($user)->create([
            'status' => PlanGenerationStatus::Processing,
            'started_at' => now()->subMinutes(15),
        ]);

        $this->actingAs($user)
            ->getJson('/api/v1/onboarding/plan-generation/latest')
            ->assertOk()
            ->assertJsonPath('id', $row->id)
            ->assertJsonPath('status', 'failed')
            ->assertJsonPath('error_message', 'Generation timed out');

        $row->refresh();
        $this->assertSame(PlanGenerationStatus::Failed, $row->status);
    }

    public function test_get_latest_returns_completed_row_with_pending_proposal(): void
    {
        $user = User::factory()->create();
        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Pending,
        ]);
        $row = PlanGeneration::factory()->for($user)->create([
            'status' => PlanGenerationStatus::Completed,
            'proposal_id' => $proposal->id,
            'conversation_id' => 'cid-abc',
            'completed_at' => now(),
        ]);

        $this->actingAs($user)
            ->getJson('/api/v1/onboarding/plan-generation/latest')
            ->assertOk()
            ->assertJsonPath('id', $row->id)
            ->assertJsonPath('status', 'completed')
            ->assertJsonPath('conversation_id', 'cid-abc')
            ->assertJsonPath('proposal_id', $proposal->id);
    }

    public function test_get_latest_returns_204_when_completed_and_proposal_accepted(): void
    {
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
            'completed_at' => now(),
        ]);

        $this->actingAs($user)
            ->getJson('/api/v1/onboarding/plan-generation/latest')
            ->assertNoContent();
    }
}
