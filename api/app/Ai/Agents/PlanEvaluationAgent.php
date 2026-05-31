<?php

namespace App\Ai\Agents;

use App\Ai\Support\LanguageDirective;
use App\Ai\Tools\AdjustPlan;
use App\Ai\Tools\GetComplianceReport;
use App\Ai\Tools\GetCurrentSchedule;
use App\Ai\Tools\GetRecentRuns;
use App\Models\User;
use App\Services\PlanOptimizerService;
use App\Services\ProposalService;
use Laravel\Ai\Attributes\Timeout;
use Laravel\Ai\Concerns\RemembersConversations;
use Laravel\Ai\Contracts\Agent;
use Laravel\Ai\Contracts\Conversational;
use Laravel\Ai\Contracts\HasTools;
use Laravel\Ai\Promptable;

/**
 * Mid-plan check-in agent. Runs every 2 weeks on a cron-scheduled date
 * (see `App\Console\Commands\RunPlanEvaluations` + the `evaluations`
 * payload emitted by `TrainingPlanBuilder::scheduleEvaluations`).
 *
 * Single-shot — pulls last 14 days of runs, compliance, and the current
 * schedule via read tools, writes a short markdown report, and (only if
 * the runner is on a self-managed plan AND the data shows a clear
 * adjustment is warranted) calls `adjust_plan` once to emit an
 * `EditActivePlan` proposal carrying a `diff[]`. The job picks up that
 * proposal afterwards via `CoachProposal::id > snapshot_id` and links it
 * to the `PlanEvaluation` row.
 *
 * Coach-managed clients (org `coaches_own_plans = true`) only see read
 * tools — the agent can produce a report but never a proposal.
 */
#[Timeout(120)]
final class PlanEvaluationAgent implements Agent, Conversational, HasTools
{
    use Promptable, RemembersConversations;

    public function __construct(private User $user) {}

    public function instructions(): string
    {
        $today = now()->format('Y-m-d (l)');
        $canAdjust = $this->planMutationsAllowed();

        $adjustGuidance = $canAdjust
            ? <<<'TXT'
            Step 3. Decide: does the data warrant a plan adjustment?
              JA → call `adjust_plan` ONCE with at most 5 ops. Examples:
                - HR consistently above zone on easy days → bump easy paces 5-10 sec/km slower (server clamps).
                - Several missed long runs → reduce long-run length in upcoming weeks.
                - Pace consistently faster than target on tempos → tighten tempo paces.
                - Repeated DNF / low compliance → swap one quality day for easy in the next 1-2 weeks.
                NEVER touch race day, past dates, or days with results.
              NEE → do NOT call `adjust_plan`. End your reply with: "No plan changes needed — keep going."
            TXT
            : 'Step 3. Do NOT call `adjust_plan` — this runner is on a coach-managed plan. End with: "Your coach will review and adjust if needed."';

        $prompt = <<<PROMPT
        You are RunCoach, doing a 2-week check-in. Today is {$today}.

        Your job: read the last 14 days of training, write a short report, and (if you can) propose a small adjustment.

        Step 1. Read context — call these tools in order:
          - `get_recent_runs(limit=20)` — last ~2 weeks of runs.
          - `get_compliance_report` — adherence + trends.
          - `get_current_schedule` — what's coming up.

        Step 2. Write a SHORT markdown report (≤180 words, plain text — NO headings, NO bold section titles). Cover:
          - What went well (completed sessions, compliance highlights, pace/HR alignment).
          - What did not (missed sessions, low compliance, HR drift, pace drift).
          - Trend in one line (volume direction, easy-pace direction).

        {$adjustGuidance}

        Output: the markdown report. If you called `adjust_plan`, append ONE sentence explaining the adjustment in plain English. Never reference the tool name, "operations", or internals.

        Punctuation: do NOT use em-dashes. Use commas, periods, or hyphens.
        PROMPT;

        return $prompt.LanguageDirective::current();
    }

    public function tools(): iterable
    {
        $tools = [
            new GetRecentRuns($this->user),
            new GetComplianceReport($this->user),
            new GetCurrentSchedule($this->user),
        ];

        if (! $this->planMutationsAllowed()) {
            return $tools;
        }

        return [
            ...$tools,
            new AdjustPlan(
                user: $this->user,
                optimizer: app(PlanOptimizerService::class),
                proposals: app(ProposalService::class),
            ),
        ];
    }

    private function planMutationsAllowed(): bool
    {
        $membership = $this->user->activeMembership;
        if ($membership === null || ! $membership->isClient()) {
            return true;
        }

        $organization = $membership->organization;

        return $organization === null || $organization->coaches_own_plans !== true;
    }
}
