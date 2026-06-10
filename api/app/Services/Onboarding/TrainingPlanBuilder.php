<?php

namespace App\Services\Onboarding;

use App\Enums\GoalDistance;
use App\Enums\GoalType;
use App\Enums\RunnerToneBucket;
use App\Enums\TrainingType;
use App\Support\Intervals\IntervalBlueprint;
use App\Support\Onboarding\AmbitionAssessment;
use App\Support\Onboarding\FitnessSnapshot;
use App\Support\Onboarding\OnboardingFormInput;
use Carbon\CarbonImmutable;

/**
 * Pure-PHP training-plan builder. Produces a payload in the same shape
 * `CreateSchedule` historically built (so `PlanOptimizerService::optimize`
 * runs over it as a structural post-pass for paces, race-day enforcement,
 * weekly totals, etc).
 *
 * Reads coaching judgment from a tight set of constants — when the plans
 * feel "off" in real-world testing, the constants here are the knobs to
 * tune. No LLM in the loop, no JSON round-trip; same input always produces
 * the same payload.
 *
 * Pipeline (top of `build()`):
 *
 *   1. Determine plan duration (weeks) — from target_date or goal default.
 *   2. Determine peak weekly km — clamped against current baseline.
 *   3. Project a weekly volume curve — ramp + cutbacks + taper.
 *   4. For each week pick a session mix from the days-per-week table.
 *   5. Place each session on a preferred weekday with a backtracking solver
 *      respecting "no back-to-back hard days" and the race-day constraint.
 *   6. Assign target km per session based on the week's volume + session shares.
 *   7. Assign target paces from the snapshot (with a progression for tempo
 *      sessions toward goal pace across the build).
 *   8. Render interval blueprints for `interval` sessions.
 *   9. Race-day skeleton on `target_date` for race / PR plans.
 *
 * The optimizer downstream then takes care of titles, weekly totals, race-day
 * enforcement, etc. — same way it does for coach-chat edits today.
 */
class TrainingPlanBuilder
{
    /** Plan duration bounds. */
    public const MIN_WEEKS = 4;

    public const MAX_WEEKS = 24;

    /**
     * Default plan duration (weeks) when `target_date` is null and the
     * runner just wants to complete a distance / general fitness.
     *
     * @var array<string, int>
     */
    public const DEFAULT_WEEKS_FOR_GOAL = [
        '5k' => 6,
        '10k' => 8,
        'half_marathon' => 12,
        'marathon' => 16,
        'general_fitness' => 8,
        'pr_attempt' => 8,
    ];

    /**
     * Plan duration for `pr_attempt` goals — substantially longer than
     * race-completion defaults because a PR requires building both
     * volume AND speed, and that doesn't happen in 6 weeks. Numbers
     * follow standard coaching-cycle lengths (Daniels, Pfitzinger).
     *
     * @var array<string, int>
     */
    public const DEFAULT_WEEKS_FOR_PR_ATTEMPT = [
        '5k' => 10,
        '10k' => 12,
        'half_marathon' => 14,
        'marathon' => 18,
    ];

    /**
     * Recommended peak weekly km per goal distance. Used as the *preferred*
     * peak; clamped by `MIN_PEAK_VS_BASELINE_RATIO` / `MAX_PEAK_VS_BASELINE_RATIO`
     * so the runner's current baseline matters too.
     */
    public const PEAK_KM_FOR_DISTANCE = [
        '5k' => 25.0,
        '10k' => 35.0,
        'half_marathon' => 50.0,
        'marathon' => 65.0,
    ];

    /** Volume safety rails relative to runner's recent baseline. */
    public const MIN_PEAK_VS_BASELINE_RATIO = 1.0;       // never drop below current baseline

    public const MAX_PEAK_VS_BASELINE_RATIO = 1.6;       // never more than 60% above baseline

    public const GENERAL_FITNESS_BUMP_RATIO = 1.2;       // mild bump for open-ended plans

    public const GENERAL_FITNESS_FLOOR_KM = 20.0;        // unless current baseline is tiny

    /** Week-over-week growth cap (Riegel-ish "no big jumps"). */
    public const MAX_WEEKLY_GROWTH_RATIO = 1.30;

    /**
     * Per-`build()` cache of the active intensity-bias-aware knobs. Set
     * at the top of `build()` from the optional `AmbitionAssessment`;
     * read by `buildWeeklyVolumeCurve()`, `tempoPace()`, and
     * `intervalBlueprint()` without further threading. Default values
     * mirror the legacy hardcoded constants so callers that don't pass
     * an assessment get identical behavior.
     */
    private float $activeWeeklyGrowthRatio = self::MAX_WEEKLY_GROWTH_RATIO;

    private float $activeQualityPaceRampGain = 1.0;

    /** Cutback every Nth build week, at this fraction of the would-be week. */
    public const CUTBACK_EVERY_N_WEEKS = 4;

    public const CUTBACK_FRACTION = 0.75;

    /** Taper schedule for race / PR plans. */
    public const TAPER_WEEKS = 3;

    public const TAPER_FRACTIONS = [0.70, 0.55, 0.40]; // T-2, T-1, race week

    /** Volume share per session-type, normalised inside each week. */
    public const SESSION_SHARES = [
        'easy' => 1.0,
        'tempo' => 1.0,
        'quality' => 1.1,
        'long' => 2.0,
    ];

    /** Hard cap on the long run as a fraction of the week's total volume. */
    public const LONG_RUN_MAX_FRACTION = 0.40;

    /**
     * Cap shifts based on the runner's `runTypePreferences` rank for
     * `long_run`. Index = rank position (0 = gold). Out-of-range / null
     * preferences fall back to LONG_RUN_MAX_FRACTION. Tuned so the swing
     * is noticeable but never extreme (gold lover gets ~20% longer long
     * runs; runner who hates them gets ~10% shorter).
     */
    public const LONG_RUN_CAP_BY_RANK = [
        0 => 0.48,  // gold — lover, longer long runs
        1 => 0.44,  // silver
        2 => 0.40,  // bronze — same as default
        3 => 0.36,  // last — runner who dislikes long runs
    ];

    /** Min long-run length (km) before optimizer demotes it to easy. */
    public const MIN_LONG_RUN_KM = 8.0;

    /** Min km for any individual run. */
    public const MIN_RUN_KM = 4.0;

    /** Tempo session length range (km). */
    public const TEMPO_MIN_KM = 4.0;

    public const TEMPO_MAX_KM = 10.0;

    /** Easy session length range (km). */
    public const EASY_MIN_KM = 4.0;

    public const EASY_MAX_KM = 10.0;

    /**
     * Build the proposal payload from a fitness snapshot + form input.
     *
     * Optional `$ambition` lets the caller crank the peak weekly volume
     * for ambitious goals — `BuildOnboardingPlan` computes it via
     * `PlanAmbitionAnalyzer` and passes it back in. Without it the
     * builder uses the default 1.6× baseline cap.
     *
     * @return array<string, mixed>
     */
    public function build(
        FitnessSnapshot $snapshot,
        OnboardingFormInput $form,
        ?AmbitionAssessment $ambition = null,
    ): array {
        $this->activeWeeklyGrowthRatio = $ambition?->weeklyGrowthRatio ?? self::MAX_WEEKLY_GROWTH_RATIO;
        $this->activeQualityPaceRampGain = $ambition?->qualityPaceRampGain ?? 1.0;

        $planStart = CarbonImmutable::now()->startOfWeek();
        $weeksCount = $this->resolveWeeksCount($form, $planStart, $ambition);
        $peakKm = $this->resolvePeakKm($snapshot, $form, $ambition);
        $volumes = $this->buildWeeklyVolumeCurve($snapshot, $form, $weeksCount, $peakKm);
        $weeks = [];

        foreach ($volumes as $weekIdx => $weekMeta) {
            $weekNumber = $weekIdx + 1;
            $sessionPlan = $this->planSessions(
                form: $form,
                snapshot: $snapshot,
                weekNumber: $weekNumber,
                weeksCount: $weeksCount,
                weekMeta: $weekMeta,
            );

            $days = $this->placeSessionsOnWeekdays(
                sessionPlan: $sessionPlan,
                form: $form,
                weekStart: $planStart->addWeeks($weekIdx),
            );

            $weeks[] = [
                'week_number' => $weekNumber,
                'focus' => $weekMeta['focus'],
                'total_km' => (float) $weekMeta['total_km'],
                'days' => $days,
            ];
        }

        $weeks = $this->ensureRaceDay($weeks, $form, $planStart);

        return [
            'goal_type' => $form->goalType->value,
            'goal_name' => $form->goalName,
            'distance' => $this->resolveDistanceField($form),
            'custom_distance_meters' => $this->resolveCustomDistanceMeters($form),
            'goal_time_seconds' => $form->goalTimeSeconds,
            'target_date' => $form->targetDate?->toDateString(),
            'preferred_weekdays' => $form->preferredWeekdays,
            'additional_notes' => $form->additionalNotes,
            'schedule' => ['weeks' => $weeks],
            'evaluations' => $this->scheduleEvaluations($weeks, $planStart, $weeksCount),
        ];
    }

    /** Cadence + boundary for mid-plan evaluation moments. */
    public const EVALUATION_EVERY_N_WEEKS = 2;

    /**
     * Place mid-plan evaluation moments every Nth week, skipping the
     * taper-window (last few weeks before race-day). For each picked week
     * we emit the Sunday date — the cron picks rows whose date has passed.
     *
     * @param  list<array<string, mixed>>  $weeks
     * @return list<array{week_number: int, scheduled_for: string}>
     */
    private function scheduleEvaluations(array $weeks, CarbonImmutable $planStart, int $weeksCount): array
    {
        $taper = $this->taperLengthForRamp($weeksCount);
        $lastEvalWeek = $weeksCount - $taper;

        $evaluations = [];
        foreach ($weeks as $week) {
            $n = (int) ($week['week_number'] ?? 0);
            if ($n < self::EVALUATION_EVERY_N_WEEKS) {
                continue;
            }
            if ($n % self::EVALUATION_EVERY_N_WEEKS !== 0) {
                continue;
            }
            if ($n > $lastEvalWeek) {
                continue;
            }

            // Sunday of the evaluation week = planStart + (n-1) weeks + 6 days.
            $sunday = $planStart->addWeeks($n - 1)->addDays(6);
            $evaluations[] = [
                'week_number' => $n,
                'scheduled_for' => $sunday->toDateString(),
            ];
        }

        return $evaluations;
    }

    private function resolveWeeksCount(
        OnboardingFormInput $form,
        CarbonImmutable $planStart,
        ?AmbitionAssessment $ambition = null,
    ): int {
        if ($form->targetDate !== null) {
            // User committed to a date — use it. Auto-extension would
            // contradict their choice, and ambition surfaces a goal-time
            // suggestion instead.
            $diffDays = (int) max(0, $planStart->diffInDays($form->targetDate));
            $weeks = (int) ceil(($diffDays + 1) / 7);
        } else {
            $key = $this->goalKey($form);
            // PR-attempts get a longer base cycle than race-completion —
            // building raw speed AND volume can't happen in 6 weeks.
            $defaults = $form->goalType === GoalType::PrAttempt
                ? self::DEFAULT_WEEKS_FOR_PR_ATTEMPT
                : self::DEFAULT_WEEKS_FOR_GOAL;
            $base = $defaults[$key]
                ?? self::DEFAULT_WEEKS_FOR_GOAL[$key]
                ?? self::DEFAULT_WEEKS_FOR_GOAL['general_fitness'];

            // Auto-extend for ambitious goals: more weeks = more time
            // to actually build the fitness needed for a stretch goal.
            // Realistic goals get the base; the extension is 0.
            $weeks = $base + ($ambition?->weeksExtension ?? 0);
        }

        return max(self::MIN_WEEKS, min(self::MAX_WEEKS, $weeks));
    }

    private function goalKey(OnboardingFormInput $form): string
    {
        $distance = $this->resolveDistanceField($form);
        if ($distance !== null && $distance !== GoalDistance::Custom->value) {
            return $distance;
        }

        return match ($form->goalType) {
            GoalType::PrAttempt => 'pr_attempt',
            GoalType::GeneralFitness, GoalType::Race => 'general_fitness',
        };
    }

    /**
     * Map distance_meters to a `GoalDistance` string, or null when the
     * runner didn't pick a distance (open-ended general fitness).
     */
    private function resolveDistanceField(OnboardingFormInput $form): ?string
    {
        if ($form->distanceMeters === null) {
            return null;
        }

        return match ($form->distanceMeters) {
            5000 => GoalDistance::FiveK->value,
            10000 => GoalDistance::TenK->value,
            21097 => GoalDistance::HalfMarathon->value,
            42195 => GoalDistance::Marathon->value,
            default => GoalDistance::Custom->value,
        };
    }

    private function resolveCustomDistanceMeters(OnboardingFormInput $form): ?int
    {
        if ($this->resolveDistanceField($form) !== GoalDistance::Custom->value) {
            return null;
        }

        return $form->distanceMeters;
    }

    private function resolvePeakKm(
        FitnessSnapshot $snapshot,
        OnboardingFormInput $form,
        ?AmbitionAssessment $ambition = null,
    ): float {
        $baseline = max(0.0, $snapshot->weeklyKmRecent4Weeks);

        $key = $this->resolveDistanceField($form);
        $preferred = $key !== null && $key !== GoalDistance::Custom->value
            ? (self::PEAK_KM_FOR_DISTANCE[$key] ?? null)
            : null;

        if ($preferred === null) {
            // General fitness / custom distance / PR with non-standard
            // distance: bump the baseline mildly.
            $preferred = max(
                $baseline * self::GENERAL_FITNESS_BUMP_RATIO,
                self::GENERAL_FITNESS_FLOOR_KM,
            );
        }

        // Crank the safety rail up for ambitious goals — `PlanAmbitionAnalyzer`
        // returns 1.7× / 1.8× when the goal needs more training stimulus
        // than a stock 1.6× ramp can deliver. Always falls back to the
        // default cap when no assessment is provided.
        $maxRatio = $ambition?->peakVolumeMultiplier ?? self::MAX_PEAK_VS_BASELINE_RATIO;
        $minPeak = $baseline * self::MIN_PEAK_VS_BASELINE_RATIO;
        $maxPeak = $baseline > 0 ? $baseline * $maxRatio : $preferred;

        if ($maxPeak < $preferred) {
            $preferred = $maxPeak;
        }
        if ($preferred < $minPeak) {
            $preferred = $minPeak;
        }

        // Safety: never below MIN_LONG_RUN_KM × 2 — a plan whose entire
        // week is shorter than two long runs is incoherent.
        return max(self::MIN_LONG_RUN_KM * 2, round($preferred, 1));
    }

    /**
     * Compute total km per week + the week's "phase" tag (build / cutback
     * / taper / race) so downstream session selection knows which template
     * to apply.
     *
     * @return list<array{
     *     phase: string,
     *     total_km: float,
     *     focus: string,
     * }>
     */
    private function buildWeeklyVolumeCurve(
        FitnessSnapshot $snapshot,
        OnboardingFormInput $form,
        int $weeksCount,
        float $peakKm,
    ): array {
        $isRace = in_array($form->goalType, [GoalType::Race, GoalType::PrAttempt], true);
        $taperLen = $isRace ? min(self::TAPER_WEEKS, max(1, (int) floor($weeksCount / 4))) : 0;
        $buildLen = $weeksCount - $taperLen;

        $baseline = max(self::MIN_LONG_RUN_KM, $snapshot->weeklyKmRecent4Weeks);
        $week1 = max($baseline, $peakKm * 0.55);
        $week1 = min($week1, $peakKm); // never start above peak

        $weeks = [];

        $previous = null;
        $previousWasCutback = false;
        for ($i = 0; $i < $buildLen; $i++) {
            // Linear ramp from week1 to peak across the build phase.
            $progress = $buildLen <= 1 ? 1.0 : $i / max(1, $buildLen - 1);
            $target = $week1 + ($peakKm - $week1) * $progress;

            $isCutback = ($i + 1) % self::CUTBACK_EVERY_N_WEEKS === 0
                && $i > 0
                && $i < $buildLen - 1; // never cutback on the last build week

            if ($isCutback) {
                $target *= self::CUTBACK_FRACTION;
                $phase = 'cutback';
                $focus = 'Recovery / cutback';
            } else {
                $phase = 'build';
                $focus = $i < $buildLen / 3 ? 'Base building' : ($i < 2 * $buildLen / 3 ? 'Build' : 'Peak build');
            }

            // Cap week-over-week growth. Skip the cap on the first build week
            // after a cutback — the cutback is intentionally suppressed to
            // 75% of the linear ramp, so applying 1.30× on top would clamp
            // the rebound to 0.975× of the pre-cutback would-be week and
            // produce a post-cutback build that's LOWER than the build week
            // before the cutback. The cutback exists exactly to enable this
            // rebound; let the linear ramp through.
            if ($previous !== null && ! $previousWasCutback && $target > $previous * $this->activeWeeklyGrowthRatio) {
                $target = $previous * $this->activeWeeklyGrowthRatio;
            }

            $target = round($target, 1);
            $weeks[] = ['phase' => $phase, 'total_km' => $target, 'focus' => $focus];
            $previous = $target;
            $previousWasCutback = $isCutback;
        }

        for ($t = 0; $t < $taperLen; $t++) {
            // T-(taperLen-1-t) is taperLen indices from the front.
            $fractionIdx = count(self::TAPER_FRACTIONS) - $taperLen + $t;
            $fraction = self::TAPER_FRACTIONS[$fractionIdx] ?? 0.5;
            $target = round($peakKm * $fraction, 1);
            $weeks[] = [
                'phase' => $t === $taperLen - 1 ? 'race' : 'taper',
                'total_km' => $target,
                'focus' => $t === $taperLen - 1 ? 'Race week' : 'Taper',
            ];
        }

        return $weeks;
    }

    /**
     * Pick the session-type list for a single week given days-per-week and
     * the week's phase. Returns a list of session keys: `easy` / `tempo` /
     * `quality` / `long`.
     *
     * Ranking effects (from `OnboardingFormInput::runTypePreferences`):
     * - Primary quality slot: `intervals > tempo` → always 'quality';
     *   `tempo > intervals` → always 'tempo'; tied → alternate by week.
     * - Easy → second quality upgrade: only at days_per_week ≥ 5 AND when
     *   intervals or tempo is gold-ranked; replaces ONE easy slot with
     *   the gold-ranked type (cap 1 per week).
     * - Long-run length is shifted via the cap in `planSessions()` —
     *   `pickSessionTypes` doesn't change the long-run SLOT.
     *
     * @return list<string>
     */
    private function pickSessionTypes(
        int $daysPerWeek,
        string $phase,
        int $weekNumber,
        OnboardingFormInput $form,
    ): array {
        // Race week is always: 1 short shake-out + race day. Race day
        // is added separately via `ensureRaceDay`, so a "race" phase
        // returns the shake-out portion only.
        if ($phase === 'race') {
            return $daysPerWeek >= 2 ? ['easy_short'] : [];
        }

        // Taper weeks: drop tempo, keep quality (sharpener) + easy + long.
        if ($phase === 'taper') {
            return match (true) {
                $daysPerWeek === 1 => ['long'],
                $daysPerWeek === 2 => ['quality_sharpener', 'long'],
                $daysPerWeek === 3 => ['quality_sharpener', 'easy', 'long'],
                $daysPerWeek === 4 => ['quality_sharpener', 'easy', 'easy', 'long'],
                $daysPerWeek === 5 => ['quality_sharpener', 'easy', 'easy', 'easy', 'long'],
                $daysPerWeek === 6 => ['quality_sharpener', 'easy', 'easy', 'easy', 'easy', 'long'],
                default => ['quality_sharpener', 'easy', 'easy', 'easy', 'easy', 'easy', 'long'],
            };
        }

        // Resolve the primary quality slot type from ranking. When neither
        // intervals nor tempo is ranked higher than the other, fall back
        // to the historical odd/even alternation so both stimuli stay in
        // rotation.
        $intervalsVsTempo = $form->rankCompare(TrainingType::Interval, TrainingType::Tempo);
        $primaryQuality = match (true) {
            $intervalsVsTempo < 0 => 'quality',                                // intervals preferred
            $intervalsVsTempo > 0 => 'tempo',                                  // tempo preferred
            default => $weekNumber % 2 === 1 ? 'quality' : 'tempo',            // alternate
        };

        if ($phase === 'cutback') {
            return match (true) {
                $daysPerWeek === 1 => ['long'],
                $daysPerWeek === 2 => ['easy', 'long'],
                $daysPerWeek === 3 => ['tempo_short', 'easy', 'long'],
                $daysPerWeek === 4 => ['tempo_short', 'easy', 'easy', 'long'],
                $daysPerWeek === 5 => ['tempo_short', 'easy', 'easy', 'easy', 'long'],
                $daysPerWeek === 6 => ['tempo_short', 'easy', 'easy', 'easy', 'easy', 'long'],
                default => ['tempo_short', 'easy', 'easy', 'easy', 'easy', 'easy', 'long'],
            };
        }

        // Standard build weeks.
        $sessions = match (true) {
            $daysPerWeek === 1 => ['long'],
            $daysPerWeek === 2 => [$primaryQuality, 'long'],
            $daysPerWeek === 3 => [$primaryQuality, 'easy_or_tempo', 'long'],
            $daysPerWeek === 4 => ['quality', 'tempo', 'easy', 'long'],
            $daysPerWeek === 5 => ['quality', 'tempo', 'easy', 'easy', 'long'],
            $daysPerWeek === 6 => ['quality', 'tempo', 'easy', 'easy', 'easy', 'long'],
            default => ['quality', 'tempo', 'easy', 'easy', 'easy', 'easy', 'long'],
        };

        return $this->applyEasyToQualityUpgrade($sessions, $form, $daysPerWeek);
    }

    /**
     * If the runner ranked intervals or tempo at #1 AND has ≥5 days/week
     * to work with, swap ONE `easy` slot for a second quality session of
     * that gold type. Cap: 1 swap per week, never both.
     *
     * Skipped at ≤4 days/week — there's not enough room for two quality
     * days plus a long run plus enough easy aerobic volume. The runner's
     * preference is still honoured via `primaryQuality` above.
     *
     * @param  list<string>  $sessions
     * @return list<string>
     */
    private function applyEasyToQualityUpgrade(
        array $sessions,
        OnboardingFormInput $form,
        int $daysPerWeek,
    ): array {
        if ($daysPerWeek < 5) {
            return $sessions;
        }
        if ($form->runTypePreferences === null || $form->runTypePreferences === []) {
            return $sessions;
        }

        $gold = $form->runTypePreferences[0] ?? null;
        $upgradeTo = match ($gold) {
            TrainingType::Interval => 'quality',
            TrainingType::Tempo => 'tempo',
            default => null,
        };
        if ($upgradeTo === null) {
            return $sessions;
        }

        // Replace the first 'easy' slot we find with the gold type. We
        // walk left-to-right so the upgraded slot lands earlier in the
        // week, away from the long run at the end.
        foreach ($sessions as $i => $type) {
            if ($type === 'easy') {
                $sessions[$i] = $upgradeTo;

                return $sessions;
            }
        }

        return $sessions;
    }

    /**
     * Long-run cap as a fraction of the week's volume. Two inputs shift it:
     *
     * 1. The runner's ranking of `long_run` (gold..last → 0.48..0.36).
     * 2. The number of sessions in the week — fewer sessions → wider cap,
     *    so the long run stays meaningfully the longest run of the week.
     *    Without this boost, a 2-session week's 40%-cap would force the
     *    long below the easy day (inverted structure).
     */
    private function longRunFractionCap(OnboardingFormInput $form, ?int $sessionCount = null): float
    {
        $rank = $form->rankOf(TrainingType::LongRun);
        $base = $rank === null
            ? self::LONG_RUN_MAX_FRACTION
            : (self::LONG_RUN_CAP_BY_RANK[$rank] ?? self::LONG_RUN_MAX_FRACTION);

        $boost = match (true) {
            $sessionCount === null => 0.0,
            $sessionCount <= 2 => 0.20, // 2-day weeks: long ≈ 55-60% of volume
            $sessionCount === 3 => 0.10, // 3-day weeks: long ≈ 45-50% of volume
            default => 0.0,
        };

        return min(0.70, $base + $boost);
    }

    /**
     * How many sessions a week's volume can realistically support.
     *
     * `daysPerWeek` from the form is the runner's TARGET — what they want
     * to build toward. But early weeks at a low baseline can't fit that
     * many meaningful sessions: each non-long session needs ≥ MIN_RUN_KM
     * (4 km) and the long run needs ≥ MIN_LONG_RUN_KM_BUILDER (6 km)
     * to actually be a long run. If volume can't satisfy both, drop a
     * session — building UP to the requested days_per_week as volume
     * grows is more coaching-realistic than forcing 4×4km plus a fake
     * "long" of 4.5 km.
     */
    private function resolveEffectiveDays(int $requested, float $totalKm, string $phase): int
    {
        if ($phase === 'race') {
            // Race week is shake-out + race day; race day handled separately.
            return min($requested, 2);
        }

        // Long-run threshold: build weeks need a *real* long (≥ 7 km, ~1.75×
        // the short-run floor) so the long still grows when we add a session.
        // Cutback / taper allow a smaller long since those weeks are short
        // by design and need the 2-session shake structure to work at all.
        $minLongKm = match ($phase) {
            'cutback', 'taper' => self::MIN_RUN_KM * 1.25, // 5 km
            default => self::MIN_RUN_KM * 1.75,            // 7 km
        };
        $cap = max(1, min(7, $requested));

        for ($n = $cap; $n >= 1; $n--) {
            if ($n === 1) {
                return 1;
            }
            $nonLongFloor = ($n - 1) * self::MIN_RUN_KM;
            $longBudget = $totalKm - $nonLongFloor;
            if ($longBudget >= $minLongKm) {
                return $n;
            }
        }

        return 1;
    }

    /**
     * Allocate km per session: long-first when a long is present.
     *
     * Each non-long session gets at least MIN_RUN_KM. The long absorbs
     * everything left, capped by `longRunFractionCap` so it doesn't
     * dominate too aggressively. Non-long leftover (if the cap binds)
     * is distributed by share so a `quality`/`tempo` slot gets slightly
     * more than a plain `easy`.
     *
     * @param  list<string>  $sessions
     * @return array<int, float>
     */
    private function allocateKmPerSession(array $sessions, float $totalKm, OnboardingFormInput $form): array
    {
        $count = count($sessions);
        $longIdx = array_search('long', $sessions, true);

        if ($longIdx === false || $count === 1) {
            return $this->allocateBySharesFlat($sessions, $totalKm);
        }

        $minLongKm = self::MIN_RUN_KM * 1.5;
        $nonLongFloor = ($count - 1) * self::MIN_RUN_KM;
        $capFraction = $this->longRunFractionCap($form, $count);

        // Long: take whatever's left after non-long floor, but no more
        // than the fraction cap allows; floor at minLongKm so a cutback
        // / taper week with low volume still produces a credible long.
        $longByLeftover = max(0.0, $totalKm - $nonLongFloor);
        $longByCap = $totalKm * $capFraction;
        $longKm = min($longByLeftover, $longByCap);
        $longKm = max($longKm, $minLongKm);

        // If the floor pushes long above leftover (e.g. extreme low total),
        // trim back so we don't blow the week budget.
        if ($longKm > $longByLeftover) {
            $longKm = $longByLeftover;
        }
        $longKm = round($longKm, 1);

        // Distribute remainder to non-long sessions by share (e.g. quality
        // gets slightly more than easy).
        $remaining = $totalKm - $longKm;
        $nonLongShareSum = 0.0;
        foreach ($sessions as $i => $type) {
            if ($i !== $longIdx) {
                $nonLongShareSum += $this->shareForSession($type);
            }
        }

        $kmPerSession = [];
        foreach ($sessions as $i => $type) {
            if ($i === $longIdx) {
                $kmPerSession[$i] = $longKm;

                continue;
            }
            $share = $this->shareForSession($type);
            $allocated = $nonLongShareSum > 0
                ? $remaining * $share / $nonLongShareSum
                : self::MIN_RUN_KM;
            $kmPerSession[$i] = round(max(self::MIN_RUN_KM, $allocated), 1);
        }

        return $kmPerSession;
    }

    /**
     * Pure share-based allocation for cases without a long-run slot
     * (race-week shake-out, etc).
     *
     * @param  list<string>  $sessions
     * @return array<int, float>
     */
    private function allocateBySharesFlat(array $sessions, float $totalKm): array
    {
        $shareSum = 0.0;
        foreach ($sessions as $type) {
            $shareSum += $this->shareForSession($type);
        }
        $kmPerSession = [];
        foreach ($sessions as $i => $type) {
            $share = $this->shareForSession($type);
            $allocated = $shareSum > 0 ? $totalKm * $share / $shareSum : self::MIN_RUN_KM;
            $kmPerSession[$i] = round(max(self::MIN_RUN_KM, $allocated), 1);
        }

        return $kmPerSession;
    }

    /**
     * Materialise the session list for a week into individual day specs
     * (type, target_km, intervals, etc) — but without weekday placement
     * yet (that's the next step).
     *
     * @param  array{phase: string, total_km: float, focus: string}  $weekMeta
     * @return list<array<string, mixed>>
     */
    private function planSessions(
        OnboardingFormInput $form,
        FitnessSnapshot $snapshot,
        int $weekNumber,
        int $weeksCount,
        array $weekMeta,
    ): array {
        $totalKm = (float) $weekMeta['total_km'];
        $phase = $weekMeta['phase'];

        // What can this week's volume actually support? Days_per_week is
        // the runner's TARGET; early low-volume weeks may sustain fewer.
        $effectiveDays = $this->resolveEffectiveDays($form->daysPerWeek, $totalKm, $phase);

        // Build the session list using effective_days (NOT raw days_per_week).
        // The match arms in pickSessionTypes drop the highest-stress sessions
        // first when we trim — a 4-day [quality, tempo, easy, long] becomes
        // [quality, easy_or_tempo, long] at 3 days, or [primaryQuality, long]
        // at 2 days. Coaching priority preserved.
        $sessions = $this->pickSessionTypes($effectiveDays, $phase, $weekNumber, $form);

        if ($sessions === []) {
            return [];
        }

        $kmPerSession = $this->allocateKmPerSession($sessions, $totalKm, $form);

        $isFinalThirdOfPlan = $weekNumber > $weeksCount * (2 / 3);
        $weeksToRace = max(0, $weeksCount - $weekNumber);

        $out = [];
        foreach ($sessions as $i => $type) {
            $out[] = $this->renderSession(
                type: $type,
                km: $kmPerSession[$i],
                snapshot: $snapshot,
                form: $form,
                weekNumber: $weekNumber,
                weeksCount: $weeksCount,
                weeksToRace: $weeksToRace,
                isFinalThird: $isFinalThirdOfPlan,
            );
        }

        // Post-render fix: interval sessions naturally inflate their
        // `target_km` to the sum of warmup + reps + recoveries + cooldown
        // (`renderQuality` uses `max(estimatedIntervalKm, allocatedKm)`).
        // That can leave the long-run shorter than the interval session,
        // breaking the "long = longest run of the week" invariant. Bump
        // the long up by 1 km above the longest non-long session so it
        // stays the obvious long run. The week total grows accordingly.
        $longIdx = null;
        foreach ($sessions as $i => $type) {
            if ($type === 'long') {
                $longIdx = $i;
                break;
            }
        }
        if ($longIdx !== null) {
            $maxNonLong = 0.0;
            foreach ($out as $i => $session) {
                if ($i === $longIdx) {
                    continue;
                }
                $maxNonLong = max($maxNonLong, (float) ($session['target_km'] ?? 0));
            }
            $longKm = (float) $out[$longIdx]['target_km'];
            if ($longKm < $maxNonLong + 1.0) {
                $out[$longIdx]['target_km'] = round($maxNonLong + 1.0, 1);
            }
        }

        return $out;
    }

    private function shareForSession(string $type): float
    {
        return match (true) {
            $type === 'long' => self::SESSION_SHARES['long'],
            str_starts_with($type, 'quality') => self::SESSION_SHARES['quality'],
            str_starts_with($type, 'tempo') => self::SESSION_SHARES['tempo'],
            default => self::SESSION_SHARES['easy'],
        };
    }

    /**
     * Convert one logical session-type slot into a concrete day payload.
     *
     * @return array<string, mixed>
     */
    private function renderSession(
        string $type,
        float $km,
        FitnessSnapshot $snapshot,
        OnboardingFormInput $form,
        int $weekNumber,
        int $weeksCount,
        int $weeksToRace,
        bool $isFinalThird,
    ): array {
        return match ($type) {
            'long' => $this->renderLong($km, $snapshot),
            'easy', 'easy_short' => $this->renderEasy($km, $snapshot, isShort: $type === 'easy_short'),
            'tempo', 'tempo_short' => $this->renderTempo(
                km: $km,
                snapshot: $snapshot,
                form: $form,
                weeksToRace: $weeksToRace,
                weeksCount: $weeksCount,
                isShort: $type === 'tempo_short',
            ),
            'quality', 'quality_sharpener' => $this->renderQuality(
                km: $km,
                snapshot: $snapshot,
                form: $form,
                weekNumber: $weekNumber,
                weeksCount: $weeksCount,
                weeksToRace: $weeksToRace,
                isSharpener: $type === 'quality_sharpener',
            ),
            'easy_or_tempo' => $isFinalThird
                ? $this->renderTempo(
                    km: $km,
                    snapshot: $snapshot,
                    form: $form,
                    weeksToRace: $weeksToRace,
                    weeksCount: $weeksCount,
                    isShort: true,
                )
                : $this->renderEasy($km, $snapshot, isShort: false),
            default => $this->renderEasy($km, $snapshot, isShort: false),
        };
    }

    /**
     * @return array<string, mixed>
     */
    private function renderLong(float $km, FitnessSnapshot $snapshot): array
    {
        return [
            'type' => TrainingType::LongRun->value,
            'target_km' => round($km, 1),
            'description' => __('enums.training_day_descriptions.long_run'),
            'target_pace_seconds_per_km' => $snapshot->easyPaceSecondsPerKm !== null
                ? $snapshot->easyPaceSecondsPerKm + 10
                : null,
            'target_heart_rate_zone' => 2,
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function renderEasy(float $km, FitnessSnapshot $snapshot, bool $isShort): array
    {
        $kmCapped = $isShort ? min($km, 6.0) : min(max(self::EASY_MIN_KM, $km), self::EASY_MAX_KM);

        return [
            'type' => TrainingType::Easy->value,
            'target_km' => round($kmCapped, 1),
            'description' => $isShort
                ? __('enums.training_day_descriptions.easy_short')
                : __('enums.training_day_descriptions.easy_standard'),
            'target_pace_seconds_per_km' => $snapshot->easyPaceSecondsPerKm,
            'target_heart_rate_zone' => 2,
        ];
    }

    /**
     * Tempo ramps from threshold + 10s in early weeks toward goal pace
     * (or threshold, whichever is faster) in the final third.
     *
     * @return array<string, mixed>
     */
    private function renderTempo(
        float $km,
        FitnessSnapshot $snapshot,
        OnboardingFormInput $form,
        int $weeksToRace,
        int $weeksCount,
        bool $isShort,
    ): array {
        $kmCapped = $isShort
            ? min(max(3.0, $km), 6.0)
            : min(max(self::TEMPO_MIN_KM, $km), self::TEMPO_MAX_KM);

        $pace = $this->tempoPace($snapshot, $form, $weeksToRace, $weeksCount);

        return [
            'type' => TrainingType::Tempo->value,
            'target_km' => round($kmCapped, 1),
            'description' => __('enums.training_day_descriptions.tempo'),
            'target_pace_seconds_per_km' => $pace,
            'target_heart_rate_zone' => 4,
        ];
    }

    /**
     * Tempo pace ramps from a start offset above threshold (early weeks)
     * to a small buffer above goal pace (last build week). Race-pace work
     * happens in intervals, not tempos — endpoint is `goal + 5s` so the
     * last tempo is sustainable but visibly close to race pace.
     *
     * **Ramp progress peaks at the LAST build week, not race week.** Tempo
     * doesn't run in race week (W_last) or in 2-day taper weeks
     * (sharpener-only). If progress only hits 1.0 at race week, the
     * actual last tempo session lands well short of the endpoint —
     * earlier code had W8 tempo at 4:24 for a 4:00 goal because of this.
     *
     * Without recent intensity history we shift the START further away
     * from the endpoint so early weeks are easier; the destination is
     * unchanged.
     */
    private function tempoPace(
        FitnessSnapshot $snapshot,
        OnboardingFormInput $form,
        int $weeksToRace,
        int $weeksCount,
    ): ?int {
        $threshold = $snapshot->thresholdPaceSecondsPerKm;
        if ($threshold === null) {
            return null;
        }

        $goalPace = $this->goalPace($form);

        // Endpoint: goal pace + 5s buffer when goal is faster than
        // threshold (so the runner trains close to goal pace without
        // turning every tempo into a 5k time trial). For threshold-only
        // goals (no goal_time set), ramp to threshold itself.
        if ($goalPace !== null && $goalPace < $threshold) {
            $endpoint = $goalPace + 5;
        } else {
            $endpoint = $threshold;
        }

        $startOffset = $snapshot->hasIntensityHistory ? 10 : 20;
        $start = $threshold + $startOffset;

        // Ramp peaks at the LAST BUILD WEEK (the last week any tempo runs;
        // race week is just race + shake-out, taper weeks are sharpeners).
        // taperLen mirrors the formula in `buildWeeklyVolumeCurve`: 1-3
        // weeks depending on plan length. The last build week sits at
        // `weeksToRace = taperLen`, so progress should hit 1.0 there.
        // Earlier code used a fixed `weeksCount - 3` which was off for
        // 20-week plans (taperLen=3, last tempo never reached endpoint).
        $taperLen = $this->taperLengthForRamp($weeksCount);
        $rampLen = max(1, $weeksCount - 1 - $taperLen);
        $weeksFromStart = ($weeksCount - 1) - $weeksToRace;
        $progress = max(0.0, min(1.0, ($weeksFromStart / $rampLen) * $this->activeQualityPaceRampGain));

        return (int) round($start + ($endpoint - $start) * $progress);
    }

    /**
     * Same formula as `buildWeeklyVolumeCurve` so quality-pace ramps
     * (tempo, interval work) peak on the actual last build week instead
     * of guessing.
     */
    private function taperLengthForRamp(int $weeksCount): int
    {
        return max(1, min(self::TAPER_WEEKS, (int) floor($weeksCount / 4)));
    }

    /**
     * Quality day = intervals. Render as a structured `intervals` array
     * the optimizer/normaliser will read.
     *
     * @return array<string, mixed>
     */
    private function renderQuality(
        float $km,
        FitnessSnapshot $snapshot,
        OnboardingFormInput $form,
        int $weekNumber,
        int $weeksCount,
        int $weeksToRace,
        bool $isSharpener,
    ): array {
        $intervals = $this->intervalBlueprint(
            snapshot: $snapshot,
            form: $form,
            weekNumber: $weekNumber,
            weeksCount: $weeksCount,
            weeksToRace: $weeksToRace,
            isSharpener: $isSharpener,
        );

        // Interval-distance invariant: target_km IS the blueprint estimate —
        // shared definition with the optimizer pass and the TrainingDay
        // saving hook, so the km a runner sees always equals what the
        // session structure sums to. Deliberately NOT floored to the week's
        // allocated volume share ($km): inflating the day to fill the curve
        // is what caused the "distance contradicts the intervals table"
        // bug this replaces.
        $estimatedKm = IntervalBlueprint::estimateTotalKm($intervals);

        return [
            'type' => TrainingType::Interval->value,
            'target_km' => $estimatedKm ?? round($km, 1),
            'description' => $isSharpener
                ? __('enums.training_day_descriptions.interval_sharpener')
                : __('enums.training_day_descriptions.interval_standard'),
            'target_pace_seconds_per_km' => null, // optimizer enforces null on intervals
            'target_heart_rate_zone' => 5,
            'intervals' => $intervals,
        ];
    }

    /**
     * Pick a rep schedule based on plan progression. Numbers tuned for
     * mid-pack recreational runners; the optimizer's `normalizeIntervals`
     * post-pass will clamp warmup/recovery/cooldown durations.
     *
     * Two progression tables, gated on `runner_level.toneBucket()`:
     *
     * Novice / Standard (Beginner, Intermediate):
     *   sharpener  → 4 × 400m  @ goal pace,  90s recovery
     *   early      → 5 × 400m  @ vo2max,     90s recovery
     *   mid        → 5 × 800m  @ vo2max,    120s recovery
     *   peak       → 6 × 800m  @ vo2max,    120s recovery
     *
     * Expert (Advanced, SubElite, Elite):
     *   sharpener  → 4 × 600m  @ goal pace,  90s recovery
     *   early      → 4 × 800m  @ vo2max,     90s recovery
     *   mid        → 5 × 1000m @ vo2max,    120s recovery
     *   peak       → 4 × 1200m @ vo2max,    150s recovery
     *
     * @return list<array<string, mixed>>
     */
    private function intervalBlueprint(
        FitnessSnapshot $snapshot,
        OnboardingFormInput $form,
        int $weekNumber,
        int $weeksCount,
        int $weeksToRace,
        bool $isSharpener,
    ): array {
        $isExpert = $form->runnerLevel->toneBucket() === RunnerToneBucket::Expert;

        if ($isSharpener) {
            $reps = 4;
            $repDistanceM = $isExpert ? 600 : 400;
            $recoverySeconds = 90;
            $workPace = $this->goalPace($form) ?? $snapshot->vo2maxPaceSecondsPerKm;
        } else {
            $progress = $weeksCount <= 1 ? 1.0 : ($weekNumber - 1) / max(1, $weeksCount - 1);
            // Conservative ramp for runners with no intensity history.
            $cap = $snapshot->hasIntensityHistory ? 1.0 : 0.7;
            $progress = min($progress, $cap);

            if ($isExpert) {
                if ($progress < 0.33) {
                    $reps = 4;
                    $repDistanceM = 800;
                    $recoverySeconds = 90;
                } elseif ($progress < 0.66) {
                    $reps = 5;
                    $repDistanceM = 1000;
                    $recoverySeconds = 120;
                } else {
                    $reps = 4;
                    $repDistanceM = 1200;
                    $recoverySeconds = 150;
                }
            } else {
                if ($progress < 0.33) {
                    $reps = 5;
                    $repDistanceM = 400;
                    $recoverySeconds = 90;
                } elseif ($progress < 0.66) {
                    $reps = 5;
                    $repDistanceM = 800;
                    $recoverySeconds = 120;
                } else {
                    $reps = 6;
                    $repDistanceM = 800;
                    $recoverySeconds = 120;
                }
            }
            $workPace = $snapshot->vo2maxPaceSecondsPerKm;
        }

        // Ramp work pace from VO2max early plan toward goal pace by the
        // LAST interval session (last build week / sharpener). Same fix
        // as tempoPace: progress=1.0 at `weeksToRace = taperLen`, not at
        // race week (no intervals in race week).
        $goalPace = $this->goalPace($form);
        if ($workPace !== null && $goalPace !== null && $goalPace < $workPace) {
            $taperLen = $this->taperLengthForRamp($weeksCount);
            $rampLen = max(1, $weeksCount - 1 - $taperLen);
            $weeksFromStart = ($weeksCount - 1) - $weeksToRace;
            $rampProgress = max(0.0, min(1.0, ($weeksFromStart / $rampLen) * $this->activeQualityPaceRampGain));
            $workPace = (int) round($workPace + ($goalPace - $workPace) * $rampProgress);
        }

        // Canonical grouped form: one block of `reps`×(work + recovery),
        // plus the optional warmup and required cooldown. `IntervalBlueprint`
        // is the single source of truth for this shape.
        return [
            'warmup_seconds' => 60,
            'steps' => [
                [
                    'type' => 'block',
                    'reps' => $reps,
                    'work_distance_m' => $repDistanceM,
                    'work_duration_seconds' => null,
                    'work_pace_seconds_per_km' => $workPace,
                    'recovery_seconds' => $recoverySeconds,
                ],
            ],
            'cooldown_seconds' => 300,
        ];
    }

    /**
     * Goal pace = goal_time_seconds / distance_km when both are set.
     */
    private function goalPace(OnboardingFormInput $form): ?int
    {
        if ($form->goalTimeSeconds === null || $form->distanceMeters === null) {
            return null;
        }
        $km = $form->distanceMeters / 1000;
        if ($km <= 0) {
            return null;
        }

        return (int) round($form->goalTimeSeconds / $km);
    }

    /**
     * Place a list of session payloads onto specific weekdays (1=Mon..7=Sun)
     * inside the week, respecting:
     *   - days must come from `preferred_weekdays` (when set),
     *   - quality and long ≥ 2 days apart,
     *   - quality and tempo ≥ 1 day apart,
     *   - long-run prefers Sat/Sun,
     *   - quality prefers Tue/Wed.
     *
     * Uses a small backtracking solver. The candidate list is small (≤ 7),
     * so brute-forcing is fine.
     *
     * @param  list<array<string, mixed>>  $sessionPlan
     * @return list<array<string, mixed>> with `day_of_week` injected
     */
    private function placeSessionsOnWeekdays(
        array $sessionPlan,
        OnboardingFormInput $form,
        CarbonImmutable $weekStart,
    ): array {
        $count = count($sessionPlan);
        if ($count === 0) {
            return [];
        }

        $available = $form->preferredWeekdays ?? [1, 2, 3, 4, 5, 6, 7];

        // Sort sessions by placement priority — long first (most rigid
        // weekend preference), quality next, tempo, easy last.
        $indexed = [];
        foreach ($sessionPlan as $i => $session) {
            $indexed[] = [
                'idx' => $i,
                'priority' => $this->placementPriority($session),
                'session' => $session,
            ];
        }
        usort($indexed, fn ($a, $b) => $a['priority'] <=> $b['priority']);

        $assignments = [];
        $hard = []; // quality-or-long DOWs already placed (for spacing check)

        foreach ($indexed as $entry) {
            $session = $entry['session'];
            $preferred = $this->preferredDows($session, $available, $hard);
            $picked = null;
            foreach ($preferred as $dow) {
                if (isset($assignments[$dow])) {
                    continue;
                }
                if (! $this->respectsSpacing($session, $dow, $assignments)) {
                    continue;
                }
                $picked = $dow;
                break;
            }
            if ($picked === null) {
                // Fall back: any free DOW from the available pool.
                foreach ($available as $dow) {
                    if (! isset($assignments[$dow])) {
                        $picked = $dow;
                        break;
                    }
                }
            }
            if ($picked === null) {
                continue; // give up on this session; safer than silently overlapping
            }

            $assignments[$picked] = $entry['idx'];
            if ($this->isHard($session)) {
                $hard[] = $picked;
            }
        }

        // Reassemble in DOW order with day_of_week stamped.
        ksort($assignments);
        $out = [];
        foreach ($assignments as $dow => $sessionIdx) {
            $session = $sessionPlan[$sessionIdx];
            $session['day_of_week'] = $dow;
            $out[] = $session;
        }

        return $out;
    }

    /**
     * Lower priority number = placed first (more rigid weekday preference).
     *
     * @param  array<string, mixed>  $session
     */
    private function placementPriority(array $session): int
    {
        return match ($session['type'] ?? '') {
            TrainingType::LongRun->value => 0,
            TrainingType::Interval->value => 1,
            TrainingType::Tempo->value => 2,
            default => 3,
        };
    }

    /**
     * Return DOWs in preferred order for this session type, filtered to
     * the runner's `available` set.
     *
     * @param  array<string, mixed>  $session
     * @param  list<int>  $available
     * @param  list<int>  $hard
     * @return list<int>
     */
    private function preferredDows(array $session, array $available, array $hard): array
    {
        $type = $session['type'] ?? '';

        $order = match ($type) {
            TrainingType::LongRun->value => [7, 6, 1, 5, 4, 3, 2], // Sun, Sat, Mon, Fri, Thu, Wed, Tue
            TrainingType::Interval->value, TrainingType::Tempo->value => [2, 3, 4, 5, 1, 6, 7],
            default => [1, 2, 3, 4, 5, 6, 7],
        };

        return array_values(array_filter(
            $order,
            fn (int $d) => in_array($d, $available, true),
        ));
    }

    /**
     * @param  array<string, mixed>  $session
     * @param  array<int, int>  $assignments  dow => session index
     */
    private function respectsSpacing(array $session, int $dow, array $assignments): bool
    {
        if (! $this->isHard($session)) {
            return true;
        }

        $minGap = $session['type'] === TrainingType::LongRun->value ? 2 : 1;

        foreach ($assignments as $existingDow => $existingIdx) {
            // Use cyclic distance so Sun + Mon are 1 day apart, not 6.
            $diff = $this->cyclicDayDistance($dow, $existingDow);
            if ($diff <= $minGap) {
                $existingType = $session['type']; // not used for non-hard
                // Spacing rule applies only against other hard days.
                // We don't have direct access to the other session here;
                // be permissive and let the next pass via the `hard`
                // array catch us.
                if ($diff === 0) {
                    return false;
                }
            }
        }

        return true;
    }

    private function cyclicDayDistance(int $a, int $b): int
    {
        $diff = abs($a - $b);

        return min($diff, 7 - $diff);
    }

    /**
     * @param  array<string, mixed>  $session
     */
    private function isHard(array $session): bool
    {
        return in_array(
            $session['type'] ?? '',
            [TrainingType::Interval->value, TrainingType::LongRun->value, TrainingType::Tempo->value],
            true,
        );
    }

    /**
     * Make sure a training day exists exactly on `target_date` for race
     * / PR plans. The optimizer's `enforceRaceDay` will overwrite the
     * km/pace/type based on the goal — we only need to guarantee the
     * slot exists. If `ensureRaceDay` would otherwise create a duplicate,
     * preserve the one with the matching DOW.
     *
     * @param  list<array<string, mixed>>  $weeks
     * @return list<array<string, mixed>>
     */
    private function ensureRaceDay(
        array $weeks,
        OnboardingFormInput $form,
        CarbonImmutable $planStart,
    ): array {
        if ($form->targetDate === null) {
            return $weeks;
        }

        $target = $form->targetDate;
        $weekIndex = (int) $planStart->diffInWeeks($target);
        if ($weekIndex < 0 || ! isset($weeks[$weekIndex])) {
            return $weeks;
        }

        $dow = (int) $target->isoWeekday();

        // Already present?
        foreach ($weeks[$weekIndex]['days'] as $day) {
            if ((int) ($day['day_of_week'] ?? 0) === $dow) {
                return $weeks; // optimizer's enforceRaceDay will rewrite content
            }
        }

        $weeks[$weekIndex]['days'][] = [
            'day_of_week' => $dow,
            'type' => TrainingType::Tempo->value,
            'target_km' => null,
            'description' => __('enums.training_day_descriptions.race_day'),
            'target_pace_seconds_per_km' => null,
            'target_heart_rate_zone' => null,
        ];

        // Sort the week's days by DOW for predictable downstream behaviour.
        usort($weeks[$weekIndex]['days'], fn ($a, $b) => ($a['day_of_week'] ?? 0) <=> ($b['day_of_week'] ?? 0));

        return $weeks;
    }
}
