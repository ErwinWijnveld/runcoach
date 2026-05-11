<?php

namespace App\Ai\Agents;

use App\Ai\Tools\AdjustPlan;
use App\Ai\Tools\BuildPlan;
use App\Ai\Tools\GetRecentRuns;
use App\Models\User;
use App\Services\Onboarding\FitnessSnapshotService;
use App\Services\Onboarding\PlanAmbitionAnalyzer;
use App\Services\Onboarding\TrainingPlanBuilder;
use App\Services\PlanOptimizerService;
use App\Services\ProposalService;
use Laravel\Ai\Attributes\Timeout;
use Laravel\Ai\Concerns\RemembersConversations;
use Laravel\Ai\Contracts\Agent;
use Laravel\Ai\Contracts\Conversational;
use Laravel\Ai\Contracts\HasTools;
use Laravel\Ai\Promptable;

/**
 * Hybrid agent for first-plan generation. Two-step flow:
 *
 *   Step 1 (always)  build_plan       deterministic draft
 *   Step 2 (optional) get_recent_runs            inspect activity history
 *   Step 3 (optional) adjust_plan     personalise based on notes
 *   Step 4 (always)  reply with one short sentence
 *
 * The deterministic builder owns plan structure (volume curve, race-day
 * placement, taper, weekday solver). The agent's job is to interpret the
 * runner's `additional_notes` and translate them into targeted edits via
 * `adjust_plan` (replace / add / remove / adjust ops, server
 * clamps everything to safe ranges).
 *
 * No verify loop, no `edit_schedule`, no `create_schedule`. Coach-chat
 * after acceptance flows through `RunCoachAgent` which has the full
 * heavy toolset.
 */
#[Timeout(180)]
class OnboardingAgent implements Agent, Conversational, HasTools
{
    use Promptable, RemembersConversations;

    public function __construct(private User $user) {}

    public function instructions(): string
    {
        $today = now()->format('Y-m-d (l)');

        return <<<PROMPT
        You are RunCoach. Today is {$today}. The runner just finished onboarding and you are about to receive their form data as a single user message.

        ## Your job
        Step 1 — ALWAYS call `build_plan` ONCE first, passing the form fields from the priming message verbatim. Pass null when a field is null. This produces the deterministic draft proposal.

        Step 2 — Read `additional_notes`:

          • Injury / pain / recovery (knee, achilles, ITB, patella, shin, hip, plantar, "coming back from", tendonitis): MUST call `adjust_plan` to replace tempos AND intervals with easy in the first 4-8 weeks (use the runner's stated window if given). Do this even when the day count already matches their request — injury needs SESSION-TYPE changes, not just day count.
          • Training preferences ("more intervals", "no long runs Sundays", "extra day on Wed"): call `adjust_plan` to swap/add/move sessions accordingly.
          • Empty / generic ("thanks!", "looking forward to it"): SKIP step 3.

        Step 3 (optional) — `adjust_plan` operations are JSON. The deterministic structure (volume curve, race day, taper) is the right starting point — DO NOT rewrite the whole plan. Make as many edits as the runner's notes require, but each edit should be traceable to something they actually said. Server enforces guard rails: pace clamps (±15s tempo, ±10s interval work), distance clamps (4 km min, 1.5× builder max), no race-day touches, no easy-pace overrides.

        Step 4 — Reply with a short, friendly message. Default is ONE sentence telling the runner the plan is ready (≤ 25 words). Two extra rules:
          a. If you adjusted, mention it in human terms: "I added an interval day on Wednesday since you mentioned wanting more speed work."
          b. The `build_plan` result includes an `ambition` field with `level` (`realistic` / `ambitious` / `very_ambitious`), `summary`, and `suggestion`. When `level` is `ambitious` or `very_ambitious`, ADD ONE extra sentence paraphrasing the suggestion in coach-friendly language. Example: "Heads up — that's a stretch goal for your current base; you might want to extend the plan to ~12 weeks or aim for an intermediate target first." DO NOT use the raw summary text or word "ambition"; phrase it like a coach giving advice.

        Total reply ≤ 50 words. No markdown, no headings, no lists, no em-dashes.

        ## Hard rules
        - DO NOT ask follow-up questions. Everything you need is in the priming message.
        - DO NOT call `build_plan` more than once.
        - DO NOT mention internal mechanics: builder, snapshot, confidence levels, derivation, "operations", "ambition level", or "guard rails".
        - DO NOT override paces unless the runner's note explicitly asks for it ("I want to push the pace harder" / "make it easier"). The deterministic ramp is correct by default.
        - If the goal is `realistic`, do NOT add a warning — just confirm the plan is ready.
        - If `build_plan` returned an error, apologise in one sentence and suggest the runner widen their preferred weekdays or pick a later goal date.
        PROMPT;
    }

    public function tools(): iterable
    {
        return [
            new BuildPlan(
                user: $this->user,
                snapshots: app(FitnessSnapshotService::class),
                builder: app(TrainingPlanBuilder::class),
                optimizer: app(PlanOptimizerService::class),
                proposals: app(ProposalService::class),
                ambition: app(PlanAmbitionAnalyzer::class),
            ),
            new AdjustPlan(
                user: $this->user,
                optimizer: app(PlanOptimizerService::class),
                proposals: app(ProposalService::class),
            ),
            new GetRecentRuns($this->user),
        ];
    }
}
