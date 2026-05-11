<?php

namespace App\Ai\Tools;

use App\Enums\GoalType;
use App\Enums\ProposalType;
use App\Models\User;
use App\Services\Onboarding\FitnessSnapshotService;
use App\Services\Onboarding\PlanAmbitionAnalyzer;
use App\Services\Onboarding\TrainingPlanBuilder;
use App\Services\PlanOptimizerService;
use App\Services\ProposalService;
use App\Support\Onboarding\FitnessSnapshot;
use App\Support\Onboarding\OnboardingFormInput;
use App\Support\PlanPayload;
use Carbon\CarbonImmutable;
use Illuminate\Contracts\JsonSchema\JsonSchema;
use Laravel\Ai\Contracts\Tool;
use Laravel\Ai\Tools\Request;

/**
 * Universal plan-builder tool — used by BOTH `OnboardingAgent` (first
 * plan from form) AND `RunCoachAgent` (chat-driven full rebuilds when
 * the runner switches goal type / race got cancelled / etc).
 *
 * Wraps the deterministic plan-build pipeline:
 *
 *   FitnessSnapshotService.snapshot(user)
 *     ↓
 *   PlanAmbitionAnalyzer.analyze (two-pass: extension based on level)
 *     ↓
 *   TrainingPlanBuilder.build(snapshot, formInput, assessment)
 *     ↓
 *   PlanOptimizerService.optimize(payload, user)
 *     ↓
 *   ProposalService.persistPending → CoachProposal row
 *
 * No JSON authoring by the LLM, no verify loop. The agent's job is to
 * gather the form fields (in onboarding: from the priming message; in
 * coach-chat: via a few clarifying questions or `offer_choices` chips),
 * call this tool ONCE, then say one short friendly sentence after the
 * tool returns. Use `adjust_plan` for tweaks; reserve `build_plan` for
 * fundamental restructures.
 */
class BuildPlan implements Tool
{
    public function __construct(
        private User $user,
        private FitnessSnapshotService $snapshots,
        private TrainingPlanBuilder $builder,
        private PlanOptimizerService $optimizer,
        private ProposalService $proposals,
        private PlanAmbitionAnalyzer $ambition,
    ) {}

    public function description(): string
    {
        return <<<'DESC'
        Build a complete training plan from goal + days/week + preferences. Use for:
        - The runner's FIRST plan (onboarding flow — call once with form fields).
        - A FUNDAMENTAL REBUILD in chat (different goal_type, race cancelled and starting fresh, original goal complete and starting a new cycle, switching from race to PR attempt, etc).

        DO NOT use for tweaks ("change Tuesday's pace", "add a tempo on Wed", "shorten the long runs", "race date moved 2 weeks") — call `adjust_plan` instead. `build_plan` regenerates the entire schedule and is much more expensive than a targeted edit.

        Deterministic builder — pace baselines come from the runner's recent activity history (HR-zone-anchored), session mix scales with days_per_week, volume curve + plan length adapt to ambition (longer for stretch goals). The runner's coach_style is persisted on the user model.

        When called from coach-chat with an active goal: the resulting `CreateSchedule` proposal will, on acceptance, supersede the active goal (old goal goes to Completed status; the new plan becomes Active).

        Returns { requires_approval, proposal_id, plan_structure, fitness_summary, ambition }. Reply with one short, friendly sentence after this returns. If `ambition.level` is `ambitious` or `very_ambitious`, paraphrase `ambition.suggestion` in coach-friendly language. Do NOT mention the builder, snapshot, confidence, or any internal mechanics.
        DESC;
    }

    public function schema(JsonSchema $schema): array
    {
        return [
            'goal_type' => $schema->string()
                ->enum(['race', 'pr', 'pr_attempt', 'fitness', 'general_fitness', 'weight_loss'])
                ->required()
                ->description('Type of goal: "race" / "pr" (PR attempt) / "fitness" (general fitness).'),
            'goal_name' => $schema->string()
                ->required()
                ->nullable()
                ->description('Human name for the goal (e.g. "Amsterdam Half Marathon"). Null falls back to a default per goal_type.'),
            'distance_meters' => $schema->integer()
                ->required()
                ->nullable()
                ->description('Target race distance in metres (5000 / 10000 / 21097 / 42195) or null for open-ended general fitness.'),
            'target_date' => $schema->string()
                ->required()
                ->nullable()
                ->description('Goal date in YYYY-MM-DD, or null when open-ended.'),
            'goal_time_seconds' => $schema->integer()
                ->required()
                ->nullable()
                ->description('Target finish time in seconds (e.g. 5400 for 1:30:00), or null.'),
            'pr_current_seconds' => $schema->integer()
                ->required()
                ->nullable()
                ->description('Current PR in seconds for PR-attempt goals, or null.'),
            'days_per_week' => $schema->integer()
                ->required()
                ->description('Number of training days per week (1-7).'),
            'preferred_weekdays' => $schema->array()
                ->items($schema->integer())
                ->required()
                ->nullable()
                ->description('ISO weekdays the runner can train on (1=Mon..7=Sun), e.g. [2,4,6]. Null = any day.'),
            'coach_style' => $schema->string()
                ->enum(['motivational', 'analytical', 'balanced', 'strict', 'flexible'])
                ->required()
                ->description('Preferred coaching tone.'),
            'additional_notes' => $schema->string()
                ->required()
                ->nullable()
                ->description('Free-text constraints (injuries, schedule quirks, prefs) or null.'),
            'run_type_preferences' => $schema->array()
                ->items($schema->string()->enum(['easy', 'tempo', 'interval', 'long_run']))
                ->required()
                ->nullable()
                ->description('Optional ordered ranking of training types (gold → last). Index 0 is the runner\'s favourite. Null when the runner did not rank.'),
        ];
    }

    public function handle(Request $request): string
    {
        $form = OnboardingFormInput::fromArray([
            'goal_type' => $request['goal_type'],
            'goal_name' => $request['goal_name'] ?? null,
            'distance_meters' => $request['distance_meters'] ?? null,
            'target_date' => $request['target_date'] ?? null,
            'goal_time_seconds' => $request['goal_time_seconds'] ?? null,
            'pr_current_seconds' => $request['pr_current_seconds'] ?? null,
            'days_per_week' => $request['days_per_week'],
            'preferred_weekdays' => $request['preferred_weekdays'] ?? null,
            'coach_style' => $request['coach_style'] ?? null,
            'additional_notes' => $request['additional_notes'] ?? null,
            'run_type_preferences' => $request['run_type_preferences'] ?? null,
        ]);

        // Persist coach_style on the user (matches the existing onboarding
        // flow's behaviour — coach_style is a runner preference, not a
        // per-plan field). Other onboarding-form fields stay on the
        // proposal payload only.
        if ($this->user->coach_style !== $form->coachStyle) {
            $this->user->coach_style = $form->coachStyle;
            $this->user->save();
        }

        $snapshot = $this->snapshots->snapshot($this->user);

        // Two-pass ambition analysis so the plan length adapts to how
        // stretched the goal is:
        //
        //   Pass 1 — assess ambition with the BASE weeks count (defaults
        //            per distance + goal type). This gives us the level
        //            (realistic / ambitious / very_ambitious) needed to
        //            decide a weeks extension (0 / 4 / 8).
        //
        //   Pass 2 — re-assess with the EXTENDED weeks count. The level
        //            may downgrade (longer plan = more realistic
        //            improvement rate); the suggestion text reflects
        //            "we extended your plan to N weeks because…".
        //
        // When `target_date` is set the runner committed to a date, so
        // we never extend — pass 2 simply uses the same weeks as pass 1
        // and the suggestion talks about adjusting the goal time.
        $baseWeeks = $this->estimatePlanWeeks($form);
        $candidatePeak = $this->estimateCandidatePeak($snapshot, $form);

        $initial = $this->ambition->analyze($snapshot, $form, $baseWeeks, $candidatePeak);
        $extension = $form->targetDate === null
            ? $this->ambition->suggestedWeeksExtension($initial->level)
            : 0;
        $finalWeeks = max(
            TrainingPlanBuilder::MIN_WEEKS,
            min(TrainingPlanBuilder::MAX_WEEKS, $baseWeeks + $extension),
        );

        $assessment = $this->ambition->analyze(
            $snapshot,
            $form,
            $finalWeeks,
            $candidatePeak,
            $extension,
        );

        $payload = $this->builder->build($snapshot, $form, $assessment);
        $payload = $this->optimizer->optimize($payload, $this->user);

        // Empty plan defence: an over-constrained input (e.g. 0 weekdays
        // overlap with required preferred_weekdays AND no target_date)
        // can produce an empty schedule. Bail with an error string the
        // agent can apologise about, instead of persisting a hollow
        // proposal.
        if (empty($payload['schedule']['weeks'] ?? [])) {
            return json_encode([
                'error' => 'Could not build a plan with the given constraints. Ask the runner to widen preferred_weekdays or pick a goal date further out.',
            ]);
        }

        $proposal = $this->proposals->persistPending(
            $this->user,
            ProposalType::CreateSchedule,
            $payload,
        );

        return json_encode([
            'requires_approval' => true,
            'proposal_type' => ProposalType::CreateSchedule->value,
            'proposal_id' => $proposal->id,
            'plan_structure' => PlanPayload::weekStructure($payload),
            'fitness_summary' => $snapshot->toFitnessSummary(),
            'ambition' => $assessment->toFitnessSummary(),
            'goal_type' => $form->goalType->value,
            'goal_name' => $form->goalName,
        ]);
    }

    /**
     * Pre-build estimate of plan weeks. Mirrors `TrainingPlanBuilder::resolveWeeksCount`
     * but cheap to call before the actual build — the ambition analyzer
     * needs the weeks count to compute improvement-per-month.
     */
    private function estimatePlanWeeks(OnboardingFormInput $form): int
    {
        if ($form->targetDate !== null) {
            $diffDays = (int) max(0, CarbonImmutable::now()->startOfWeek()->diffInDays($form->targetDate));
            $weeks = (int) ceil(($diffDays + 1) / 7);
        } else {
            $key = $this->goalKeyForEstimate($form);
            $defaults = $form->goalType === GoalType::PrAttempt
                ? TrainingPlanBuilder::DEFAULT_WEEKS_FOR_PR_ATTEMPT
                : TrainingPlanBuilder::DEFAULT_WEEKS_FOR_GOAL;
            $weeks = $defaults[$key]
                ?? TrainingPlanBuilder::DEFAULT_WEEKS_FOR_GOAL[$key]
                ?? TrainingPlanBuilder::DEFAULT_WEEKS_FOR_GOAL['general_fitness'];
        }

        return max(TrainingPlanBuilder::MIN_WEEKS, min(TrainingPlanBuilder::MAX_WEEKS, $weeks));
    }

    /**
     * Pre-build candidate peak. Uses the default 1.6× cap (so the
     * analyzer's volume-ratio reflects the *unboosted* peak — the boost
     * is what we're trying to decide). The actual build may end up at
     * 1.7× / 1.8× if the analyzer says the goal is ambitious.
     */
    private function estimateCandidatePeak(FitnessSnapshot $snapshot, OnboardingFormInput $form): float
    {
        $baseline = max(0.0, $snapshot->weeklyKmRecent4Weeks);
        $key = $this->goalKeyForEstimate($form);
        $preferred = TrainingPlanBuilder::PEAK_KM_FOR_DISTANCE[$key] ?? null;
        if ($preferred === null) {
            $preferred = max(
                $baseline * TrainingPlanBuilder::GENERAL_FITNESS_BUMP_RATIO,
                TrainingPlanBuilder::GENERAL_FITNESS_FLOOR_KM,
            );
        }
        $maxPeak = $baseline > 0
            ? $baseline * TrainingPlanBuilder::MAX_PEAK_VS_BASELINE_RATIO
            : $preferred;

        return min($preferred, $maxPeak);
    }

    private function goalKeyForEstimate(OnboardingFormInput $form): string
    {
        return match ($form->distanceMeters) {
            5000 => '5k',
            10000 => '10k',
            21097 => 'half_marathon',
            42195 => 'marathon',
            default => $form->goalType === GoalType::PrAttempt ? 'pr_attempt' : 'general_fitness',
        };
    }
}
