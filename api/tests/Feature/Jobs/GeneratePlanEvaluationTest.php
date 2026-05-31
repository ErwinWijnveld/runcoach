<?php

namespace Tests\Feature\Jobs;

use App\Ai\Agents\PlanEvaluationAgent;
use App\Enums\GoalStatus;
use App\Enums\PlanEvaluationStatus;
use App\Enums\ProposalStatus;
use App\Enums\ProposalType;
use App\Jobs\GeneratePlanEvaluation;
use App\Models\CoachProposal;
use App\Models\Goal;
use App\Models\PlanEvaluation;
use App\Models\User;
use App\Notifications\PlanEvaluationReady;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

class GeneratePlanEvaluationTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_no_change_path_records_report_without_proposal(): void
    {
        Notification::fake();
        PlanEvaluationAgent::fake(['Things are going well — no plan changes needed.']);

        [$user, $eval] = $this->setupEvaluation();

        app()->call([new GeneratePlanEvaluation($eval->id), 'handle']);

        $eval->refresh();
        $this->assertSame(PlanEvaluationStatus::NoChangeNeeded, $eval->status);
        $this->assertSame('Things are going well — no plan changes needed.', $eval->report_markdown);
        $this->assertNull($eval->proposal_id);
        $this->assertNotNull($eval->notification_id);
        $this->assertNotNull($eval->triggered_at);
        $this->assertNotNull($eval->completed_at);

        Notification::assertSentTo(
            $user,
            PlanEvaluationReady::class,
            fn (PlanEvaluationReady $n) => $n->evaluationId === $eval->id && $n->hasProposal === false,
        );
    }

    public function test_pre_existing_pending_proposal_is_not_linked(): void
    {
        // Pre-existing pending EditActivePlan proposals from earlier sessions
        // must never be linked to a fresh evaluation. We verify this by
        // pre-creating one and confirming the evaluation ends up in
        // NoChangeNeeded (the agent didn't itself emit a new proposal).
        Notification::fake();
        PlanEvaluationAgent::fake(['No adjustments needed this cycle.']);

        [$user, $eval, $goal] = $this->setupEvaluation();

        $stale = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::EditActivePlan,
            'status' => ProposalStatus::Pending,
            'payload' => ['goal_id' => $goal->id, 'schedule' => ['weeks' => []]],
        ]);

        app()->call([new GeneratePlanEvaluation($eval->id), 'handle']);

        $eval->refresh();
        $this->assertSame(PlanEvaluationStatus::NoChangeNeeded, $eval->status);
        $this->assertNull($eval->proposal_id, 'stale pending proposal must not be linked');
        $this->assertNotEquals($stale->id, $eval->proposal_id);
    }

    public function test_pro_gate_skips_non_pro_users(): void
    {
        Notification::fake();
        PlanEvaluationAgent::fake(['should not run']);

        [$user, $eval] = $this->setupEvaluation();
        $user->update(['pro_active_until' => null]);

        app()->call([new GeneratePlanEvaluation($eval->id), 'handle']);

        $eval->refresh();
        $this->assertSame(PlanEvaluationStatus::Pending, $eval->status, 'status untouched so next cron retries');
        $this->assertNull($eval->report_markdown);
        $this->assertNull($eval->notification_id);

        Notification::assertNothingSent();
    }

    public function test_already_processed_evaluation_is_a_noop(): void
    {
        Notification::fake();
        PlanEvaluationAgent::fake(['ignored']);

        [$user, $eval] = $this->setupEvaluation(status: PlanEvaluationStatus::Accepted);

        app()->call([new GeneratePlanEvaluation($eval->id), 'handle']);

        $eval->refresh();
        // Status untouched; no notification dispatched.
        $this->assertSame(PlanEvaluationStatus::Accepted, $eval->status);
        $this->assertNull($eval->notification_id);
        Notification::assertNothingSent();
    }

    public function test_creates_conversation_row_with_plan_evaluation_context(): void
    {
        Notification::fake();
        PlanEvaluationAgent::fake(['note']);

        [, $eval] = $this->setupEvaluation();

        app()->call([new GeneratePlanEvaluation($eval->id), 'handle']);

        $this->assertTrue(
            DB::table('agent_conversations')
                ->where('context', 'plan_evaluation')
                ->exists(),
            'job inserts a conversation row tagged plan_evaluation',
        );
    }

    /**
     * @return array{0: User, 1: PlanEvaluation, 2: Goal}
     */
    private function setupEvaluation(
        PlanEvaluationStatus $status = PlanEvaluationStatus::Pending,
    ): array {
        $user = User::factory()->create([
            'pro_active_until' => now()->addMonths(1),
        ]);
        $goal = Goal::factory()->create([
            'user_id' => $user->id,
            'status' => GoalStatus::Active,
            'target_date' => now()->addWeeks(8),
        ]);
        $eval = PlanEvaluation::factory()->create([
            'user_id' => $user->id,
            'goal_id' => $goal->id,
            'scheduled_for' => now()->subDay()->toDateString(),
            'status' => $status,
        ]);

        return [$user, $eval, $goal];
    }
}
