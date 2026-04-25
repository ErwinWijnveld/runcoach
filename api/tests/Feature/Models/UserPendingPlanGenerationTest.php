<?php

namespace Tests\Feature\Models;

use App\Enums\PlanGenerationStatus;
use App\Enums\ProposalStatus;
use App\Enums\ProposalType;
use App\Models\CoachProposal;
use App\Models\PlanGeneration;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class UserPendingPlanGenerationTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_returns_null_when_no_rows_exist(): void
    {
        $user = User::factory()->create();
        $this->assertNull($user->pendingPlanGeneration());
    }

    public function test_returns_in_flight_row(): void
    {
        $user = User::factory()->create();
        $row = PlanGeneration::factory()->for($user)->create([
            'status' => PlanGenerationStatus::Processing,
            'started_at' => now()->subSeconds(30),
        ]);

        $result = $user->pendingPlanGeneration();
        $this->assertNotNull($result);
        $this->assertSame($row->id, $result->id);
    }

    public function test_returns_failed_row(): void
    {
        $user = User::factory()->create();
        $row = PlanGeneration::factory()->for($user)->create([
            'status' => PlanGenerationStatus::Failed,
            'error_message' => 'Boom',
            'completed_at' => now(),
        ]);

        $this->assertSame($row->id, $user->pendingPlanGeneration()->id);
    }

    public function test_returns_completed_row_when_proposal_still_pending(): void
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
            'completed_at' => now(),
        ]);

        $this->assertSame($row->id, $user->pendingPlanGeneration()->id);
    }

    public function test_returns_null_when_completed_row_proposal_already_accepted(): void
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

        $this->assertNull($user->pendingPlanGeneration());
    }

    public function test_watchdog_auto_fails_stuck_processing_row(): void
    {
        $user = User::factory()->create();
        $row = PlanGeneration::factory()->for($user)->create([
            'status' => PlanGenerationStatus::Processing,
            'started_at' => now()->subMinutes(11),
        ]);

        $result = $user->pendingPlanGeneration();
        $this->assertSame(PlanGenerationStatus::Failed, $result->status);
        $this->assertSame('Generation timed out', $result->error_message);
        $this->assertNotNull($result->completed_at);

        $row->refresh();
        $this->assertSame(PlanGenerationStatus::Failed, $row->status);
    }

    public function test_watchdog_auto_fails_stuck_queued_row(): void
    {
        $user = User::factory()->create();
        $row = PlanGeneration::factory()->for($user)->create([
            'status' => PlanGenerationStatus::Queued,
            'created_at' => now()->subMinutes(11),
            'started_at' => null,
        ]);

        $result = $user->pendingPlanGeneration();
        $this->assertSame(PlanGenerationStatus::Failed, $result->status);
    }

    public function test_does_not_return_other_users_rows(): void
    {
        $other = User::factory()->create();
        PlanGeneration::factory()->for($other)->create([
            'status' => PlanGenerationStatus::Processing,
            'started_at' => now(),
        ]);

        $me = User::factory()->create();
        $this->assertNull($me->pendingPlanGeneration());
    }

    public function test_watchdog_does_not_false_positive_just_under_boundary(): void
    {
        $user = User::factory()->create();
        $row = PlanGeneration::factory()->for($user)->create([
            'status' => PlanGenerationStatus::Processing,
            'started_at' => now()->subMinutes(9),
        ]);

        $result = $user->pendingPlanGeneration();
        $this->assertSame(PlanGenerationStatus::Processing, $result->status);

        $row->refresh();
        $this->assertSame(PlanGenerationStatus::Processing, $row->status);
        $this->assertNull($row->error_message);
        $this->assertNull($row->completed_at);
    }

    public function test_watchdog_uses_created_at_when_started_at_is_null(): void
    {
        // queued row that was never picked up by a worker — started_at stays null,
        // we fall back to created_at to decide staleness.
        $user = User::factory()->create();
        $row = PlanGeneration::factory()->for($user)->create([
            'status' => PlanGenerationStatus::Queued,
            'started_at' => null,
        ]);
        // Bypass model timestamps to backdate created_at directly.
        $row->forceFill(['created_at' => now()->subMinutes(15)])->saveQuietly();

        $result = $user->pendingPlanGeneration();
        $this->assertSame(PlanGenerationStatus::Failed, $result->status);
        $this->assertSame('Generation timed out', $result->error_message);
    }

    public function test_returns_most_recent_row_when_user_has_multiple(): void
    {
        $user = User::factory()->create();

        // Older failed row should not shadow the newer queued one.
        $old = PlanGeneration::factory()->for($user)->create([
            'status' => PlanGenerationStatus::Failed,
            'completed_at' => now()->subDay(),
        ]);
        $newer = PlanGeneration::factory()->for($user)->create([
            'status' => PlanGenerationStatus::Queued,
            'started_at' => null,
        ]);

        $result = $user->pendingPlanGeneration();
        $this->assertSame($newer->id, $result->id);
        $this->assertNotSame($old->id, $result->id);
    }

    public function test_returns_null_when_completed_row_proposal_rejected(): void
    {
        $user = User::factory()->create();
        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Rejected,
        ]);
        PlanGeneration::factory()->for($user)->create([
            'status' => PlanGenerationStatus::Completed,
            'proposal_id' => $proposal->id,
            'completed_at' => now(),
        ]);

        // Rejected and accepted are both terminal-from-user-perspective; either
        // means we should NOT keep redirecting them.
        $this->assertNull($user->pendingPlanGeneration());
    }

    public function test_returns_null_when_completed_row_has_orphaned_proposal_id(): void
    {
        // Edge case: the proposal got deleted (FK nullOnDelete fires), so
        // proposal_id is now null on a row that says it's completed. Without
        // a proposal there's nothing to redirect to — treat as terminal.
        $user = User::factory()->create();
        PlanGeneration::factory()->for($user)->create([
            'status' => PlanGenerationStatus::Completed,
            'proposal_id' => null,
            'completed_at' => now(),
        ]);

        $this->assertNull($user->pendingPlanGeneration());
    }

    public function test_user_deletion_cascades_plan_generations(): void
    {
        $user = User::factory()->create();
        PlanGeneration::factory()->for($user)->create([
            'status' => PlanGenerationStatus::Processing,
            'started_at' => now(),
        ]);
        $this->assertSame(1, PlanGeneration::count());

        $user->delete();

        $this->assertSame(0, PlanGeneration::count());
    }

    public function test_proposal_deletion_nullifies_proposal_id(): void
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
            'completed_at' => now(),
        ]);

        $proposal->delete();
        $row->refresh();

        $this->assertNull($row->proposal_id);
    }
}
