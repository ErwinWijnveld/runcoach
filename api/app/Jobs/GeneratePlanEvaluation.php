<?php

namespace App\Jobs;

use App\Ai\Agents\PlanEvaluationAgent;
use App\Enums\PlanEvaluationStatus;
use App\Enums\ProposalStatus;
use App\Enums\ProposalType;
use App\Models\CoachProposal;
use App\Models\PlanEvaluation;
use App\Models\UserNotification;
use App\Notifications\PlanEvaluationReady;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\App;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Throwable;

final class GeneratePlanEvaluation implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(public int $evaluationId) {}

    public function handle(): void
    {
        $evaluation = PlanEvaluation::with('user', 'goal')->find($this->evaluationId);

        if (! $evaluation) {
            return;
        }

        // Idempotency: status flips to Processing in the transaction below.
        // A retry after that flip is a no-op until `failed()` resets it.
        if ($evaluation->status !== PlanEvaluationStatus::Pending) {
            return;
        }

        $user = $evaluation->user;
        if (! $user) {
            return;
        }

        // Queue worker context — no SetLocale middleware ran. Honour the
        // runner's stored locale so the agent's LanguageDirective resolves
        // correctly AND so the push notification copy uses the right language.
        App::setLocale($user->preferredLocale());

        // Pro gate — same rule as every other Anthropic-spending background
        // job. We leave status=Pending so a re-subscribe + next cron tick
        // picks the row up; an expired user keeps their backlog of pending
        // evaluations rather than losing them.
        if (! $user->isPro()) {
            Log::info('Skipping AI work for non-pro user', [
                'user_id' => $user->id,
                'job' => self::class,
            ]);

            return;
        }

        $proposalIdBefore = (int) CoachProposal::where('user_id', $user->id)->max('id');
        $conversationId = (string) Str::uuid();

        try {
            $this->createConversation($conversationId, $user->id);
            $evaluation->update([
                'status' => PlanEvaluationStatus::Processing,
                'triggered_at' => now(),
            ]);

            $response = PlanEvaluationAgent::make(user: $user)
                ->continue($conversationId, as: $user)
                ->prompt('Evaluate the last 2 weeks and write the report. Adjust the plan only if the data clearly warrants it.');
        } catch (Throwable $e) {
            $evaluation->update(['status' => PlanEvaluationStatus::Pending]);
            $this->dropConversationIfEmpty($conversationId);
            report($e);

            return;
        }

        $proposal = $this->detectFreshProposal($user->id, $proposalIdBefore);
        $hasProposal = $proposal !== null;

        $notification = UserNotification::create([
            'user_id' => $user->id,
            'type' => UserNotification::TYPE_PLAN_EVALUATION,
            'title' => __('notifications.plan_evaluation.title'),
            'body' => $hasProposal
                ? __('notifications.plan_evaluation.body_with_proposal')
                : __('notifications.plan_evaluation.body_no_change'),
            'action_data' => [
                'evaluation_id' => $evaluation->id,
            ],
            'status' => UserNotification::STATUS_PENDING,
        ]);

        $evaluation->update([
            'status' => $hasProposal
                ? PlanEvaluationStatus::Ready
                : PlanEvaluationStatus::NoChangeNeeded,
            'report_markdown' => $response->text,
            'proposal_id' => $proposal?->id,
            'notification_id' => $notification->id,
            'completed_at' => now(),
        ]);

        $user->notify(new PlanEvaluationReady(
            evaluationId: $evaluation->id,
            hasProposal: $hasProposal,
        ));
    }

    public function failed(Throwable $e): void
    {
        // Reset for retry on the next scheduled cron tick. We don't clean
        // up a partial proposal — AdjustPlan's persistPending supersedes
        // pending proposals on the next attempt, so the next run starts
        // clean. Same shape as other Anthropic-driven jobs in the codebase.
        PlanEvaluation::where('id', $this->evaluationId)
            ->update(['status' => PlanEvaluationStatus::Pending]);
    }

    /**
     * Mirrors the conversation-row pattern used by OnboardingPlanGeneratorService.
     * Stored under `context = 'plan_evaluation'` so it's filterable from analytics
     * dashboards.
     */
    private function createConversation(string $conversationId, int $userId): void
    {
        $now = now();
        DB::table('agent_conversations')->insert([
            'id' => $conversationId,
            'user_id' => $userId,
            'title' => 'Plan evaluation',
            'context' => 'plan_evaluation',
            'created_at' => $now,
            'updated_at' => $now,
        ]);
    }

    /**
     * If the agent throws before producing any message, the empty conversation
     * row would otherwise linger forever. Drop it ONLY when it has no messages
     * attached — never touch a conversation that has agent output we'd want to
     * inspect in the admin panel.
     */
    private function dropConversationIfEmpty(string $conversationId): void
    {
        $hasMessages = DB::table('agent_conversation_messages')
            ->where('conversation_id', $conversationId)
            ->exists();
        if ($hasMessages) {
            return;
        }
        DB::table('agent_conversations')->where('id', $conversationId)->delete();
    }

    /**
     * Look up any `EditActivePlan` proposal that `AdjustPlan` may have
     * created during this run. We scope by `id > $proposalIdBefore` (snapshot
     * taken BEFORE the agent runs) AND by `type = EditActivePlan` so a
     * parallel chat session creating a `CreateSchedule` proposal can never
     * confuse us. The user normally isn't chatting while a queue job runs,
     * so this is belt-and-braces.
     */
    private function detectFreshProposal(int $userId, int $proposalIdBefore): ?CoachProposal
    {
        return CoachProposal::where('user_id', $userId)
            ->where('id', '>', $proposalIdBefore)
            ->where('status', ProposalStatus::Pending)
            ->where('type', ProposalType::EditActivePlan)
            ->latest('id')
            ->first();
    }
}
