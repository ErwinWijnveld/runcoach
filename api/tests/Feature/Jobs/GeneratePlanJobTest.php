<?php

namespace Tests\Feature\Jobs;

use App\Ai\Agents\RunCoachAgent;
use App\Enums\PlanGenerationStatus;
use App\Enums\ProposalStatus;
use App\Enums\ProposalType;
use App\Jobs\GeneratePlan;
use App\Models\CoachProposal;
use App\Models\PlanGeneration;
use App\Models\User;
use App\Models\UserRunningProfile;
use App\Notifications\PlanGenerationCompleted;
use App\Notifications\PlanGenerationFailed;
use App\Services\OnboardingPlanGeneratorService;
use App\Services\ProposalService;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Mockery;
use RuntimeException;
use Tests\TestCase;

class GeneratePlanJobTest extends TestCase
{
    use LazilyRefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        // GeneratePlan emits push notifications via APNs on success/failure;
        // tests must fake them to avoid touching the (absent) .p8 key.
        Notification::fake();
    }

    public function test_marks_processing_then_completed_on_success(): void
    {
        $user = User::factory()->create();
        UserRunningProfile::factory()->for($user)->create();

        $row = PlanGeneration::factory()->for($user)->create([
            'status' => PlanGenerationStatus::Queued,
            'payload' => [
                'goal_type' => 'fitness',
                'days_per_week' => 3,
                'coach_style' => 'flexible',
            ],
        ]);

        RunCoachAgent::fake(['Plan ready.']);
        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Pending,
        ]);
        $this->instance(
            ProposalService::class,
            Mockery::mock(ProposalService::class, function ($mock) use ($proposal): void {
                $mock->shouldReceive('detectProposalFromConversation')->andReturn($proposal);
            })
        );

        (new GeneratePlan($row->id))->handle(app(OnboardingPlanGeneratorService::class));

        $row->refresh();
        $this->assertSame(PlanGenerationStatus::Completed, $row->status);
        $this->assertNotNull($row->started_at);
        $this->assertNotNull($row->completed_at);
        $this->assertSame($proposal->id, $row->proposal_id);
        $this->assertNotNull($row->conversation_id);

        Notification::assertSentTo(
            $user,
            PlanGenerationCompleted::class,
            fn (PlanGenerationCompleted $n) => $n->conversationId === $row->conversation_id,
        );
    }

    public function test_failed_callback_dispatches_failure_notification(): void
    {
        Notification::fake();

        $user = User::factory()->create();
        $row = PlanGeneration::factory()->for($user)->create([
            'status' => PlanGenerationStatus::Queued,
            'started_at' => null,
        ]);

        (new GeneratePlan($row->id))->failed(new RuntimeException('worker died'));

        Notification::assertSentTo($user, PlanGenerationFailed::class);
    }

    public function test_marks_failed_when_service_throws(): void
    {
        $user = User::factory()->create();
        $row = PlanGeneration::factory()->for($user)->create([
            'status' => PlanGenerationStatus::Queued,
            'payload' => [
                'goal_type' => 'fitness',
                'days_per_week' => 3,
                'coach_style' => 'flexible',
            ],
        ]);

        $this->instance(
            OnboardingPlanGeneratorService::class,
            Mockery::mock(OnboardingPlanGeneratorService::class, function ($mock): void {
                $mock->shouldReceive('generate')->andThrow(new RuntimeException('boom'));
            })
        );

        try {
            (new GeneratePlan($row->id))->handle(app(OnboardingPlanGeneratorService::class));
            $this->fail('Expected exception');
        } catch (RuntimeException) {
            // expected — handle() rethrows so Laravel records the failure
        }

        // Job's failed() callback runs separately when Laravel records the failure.
        (new GeneratePlan($row->id))->failed(new RuntimeException('boom'));

        $row->refresh();
        $this->assertSame(PlanGenerationStatus::Failed, $row->status);
        $this->assertSame('boom', $row->error_message);
        $this->assertNotNull($row->completed_at);
    }

    public function test_handle_is_noop_when_row_no_longer_in_flight(): void
    {
        $user = User::factory()->create();
        $row = PlanGeneration::factory()->for($user)->create([
            'status' => PlanGenerationStatus::Failed,
            'completed_at' => now(),
        ]);

        // Service should NOT be called.
        $this->instance(
            OnboardingPlanGeneratorService::class,
            Mockery::mock(OnboardingPlanGeneratorService::class, function ($mock): void {
                $mock->shouldNotReceive('generate');
            })
        );

        (new GeneratePlan($row->id))->handle(app(OnboardingPlanGeneratorService::class));

        $row->refresh();
        $this->assertSame(PlanGenerationStatus::Failed, $row->status);
    }

    public function test_handle_is_noop_when_row_was_deleted(): void
    {
        // Edge case: user deleted their account between dispatch and handle.
        // Cascade wipes the plan_generations row; the in-flight job should
        // handle this gracefully (no exception, no service call).
        // Mockery's shouldNotReceive verification at teardown IS the assertion.
        $this->instance(
            OnboardingPlanGeneratorService::class,
            Mockery::mock(OnboardingPlanGeneratorService::class, function ($mock): void {
                $mock->shouldNotReceive('generate');
            })
        );

        // No model exists for id 999. Should not throw.
        (new GeneratePlan(999))->handle(app(OnboardingPlanGeneratorService::class));
    }

    public function test_handle_is_noop_for_already_completed_row(): void
    {
        // Same job re-dispatched after success (e.g., manual retry, queue
        // reprocessing) should not re-run the agent loop.
        $user = User::factory()->create();
        $row = PlanGeneration::factory()->for($user)->create([
            'status' => PlanGenerationStatus::Completed,
            'conversation_id' => 'existing-uuid',
            'proposal_id' => null,
            'completed_at' => now(),
        ]);

        $this->instance(
            OnboardingPlanGeneratorService::class,
            Mockery::mock(OnboardingPlanGeneratorService::class, function ($mock): void {
                $mock->shouldNotReceive('generate');
            })
        );

        (new GeneratePlan($row->id))->handle(app(OnboardingPlanGeneratorService::class));

        $row->refresh();
        $this->assertSame(PlanGenerationStatus::Completed, $row->status);
        $this->assertSame('existing-uuid', $row->conversation_id);
    }

    public function test_failed_callback_is_noop_when_row_was_deleted(): void
    {
        // Worker fails AND row is gone (account deletion mid-flight).
        // Job's failed() must not crash trying to update a missing row.
        (new GeneratePlan(999))->failed(new RuntimeException('boom'));

        $this->expectNotToPerformAssertions();
    }

    public function test_failed_callback_works_when_started_at_is_null(): void
    {
        // Worker timeout that fires before the job's first DB write — row
        // is still queued, started_at is null. failed() should still mark
        // it failed cleanly without touching started_at.
        $user = User::factory()->create();
        $row = PlanGeneration::factory()->for($user)->create([
            'status' => PlanGenerationStatus::Queued,
            'started_at' => null,
        ]);

        (new GeneratePlan($row->id))->failed(new RuntimeException('worker died'));

        $row->refresh();
        $this->assertSame(PlanGenerationStatus::Failed, $row->status);
        $this->assertSame('worker died', $row->error_message);
        $this->assertNull($row->started_at);
        $this->assertNotNull($row->completed_at);
    }

    public function test_processing_status_persists_when_service_throws_mid_flight(): void
    {
        // Sanity check: handle() flips status to processing BEFORE calling the
        // service; if the service throws, the row should be in `processing`
        // (with started_at) until failed() runs and flips it to failed.
        $user = User::factory()->create();
        $row = PlanGeneration::factory()->for($user)->create([
            'status' => PlanGenerationStatus::Queued,
            'started_at' => null,
        ]);

        $this->instance(
            OnboardingPlanGeneratorService::class,
            Mockery::mock(OnboardingPlanGeneratorService::class, function ($mock): void {
                $mock->shouldReceive('generate')->andThrow(new RuntimeException('agent crashed'));
            })
        );

        try {
            (new GeneratePlan($row->id))->handle(app(OnboardingPlanGeneratorService::class));
        } catch (RuntimeException) {
            // expected
        }

        $row->refresh();
        $this->assertSame(PlanGenerationStatus::Processing, $row->status);
        $this->assertNotNull($row->started_at);
    }
}
