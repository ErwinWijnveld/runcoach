<?php

namespace App\Services\Onboarding;

use App\Enums\AmbitionLevel;
use App\Enums\GoalDistance;
use App\Support\Onboarding\AmbitionAssessment;
use App\Support\Onboarding\EffectiveAmbitionLevel;
use App\Support\Onboarding\FitnessSnapshot;
use App\Support\Onboarding\OnboardingFormInput;

/**
 * Compares the runner's stated goal against a baseline of "what's
 * realistic" — pace improvement rate (sec/km/month) plus volume capacity
 * relative to typical race-prep weekly km — and returns an
 * `AmbitionAssessment`. Read by:
 *
 * - `TrainingPlanBuilder` to set the peak-volume multiplier (1.6× → 1.8×
 *   when the goal is ambitious enough to justify a faster ramp).
 * - `BuildOnboardingPlan` to surface a coach-readable summary +
 *   suggestion so the `OnboardingAgent` can warn the runner in its reply.
 *
 * Heuristics tuned on coaching literature: realistic pace improvement
 * for intermediate runners is ~10-15 sec/km per month over a race-prep
 * cycle (Daniels, Pfitzinger). Below ~25 km/week peak you can't
 * reasonably support a 5k race effort. The numbers are guidelines, not
 * absolutes — the assessment is advisory, not blocking.
 */
class PlanAmbitionAnalyzer
{
    /**
     * Realistic pace-improvement rate for an intermediate runner over
     * a focused training cycle. Goals under this rate are realistic;
     * 1.5× this is "ambitious"; 2× is "very ambitious".
     */
    public const REALISTIC_IMPROVEMENT_PER_MONTH = 12.0;

    /**
     * Recommended peak weekly km for race-prep at each distance. When
     * the builder's peak falls well below this, the runner doesn't
     * have the aerobic base to hit their stated goal pace on race day.
     *
     * @var array<string, float>
     */
    public const MIN_VOLUME_FOR_RACE_PREP = [
        GoalDistance::FiveK->value => 25.0,
        GoalDistance::TenK->value => 35.0,
        GoalDistance::HalfMarathon->value => 50.0,
        GoalDistance::Marathon->value => 65.0,
    ];

    /**
     * 5k race pace ≈ threshold − 30 sec/km. Tuned per distance.
     * Used as fallback when `pr_current_seconds` isn't set.
     *
     * @var array<string, int>
     */
    public const RACE_PACE_DELTA_FROM_THRESHOLD = [
        GoalDistance::FiveK->value => 30,
        GoalDistance::TenK->value => 15,
        GoalDistance::HalfMarathon->value => 0,
        GoalDistance::Marathon->value => -15,
    ];

    /**
     * Suggested plan-length extension (weeks) for a given ambition level.
     * Applied when `target_date` is null so the runner gets a longer
     * buildup for ambitious goals — and a tighter plan for realistic
     * ones.
     */
    public function suggestedWeeksExtension(AmbitionLevel $level): int
    {
        return match ($level) {
            AmbitionLevel::Realistic => 0,
            AmbitionLevel::Ambitious => 4,
            AmbitionLevel::VeryAmbitious => 8,
        };
    }

    public function analyze(
        FitnessSnapshot $snapshot,
        OnboardingFormInput $form,
        int $weeksCount,
        float $candidatePeakKm,
        int $weeksExtension = 0,
    ): AmbitionAssessment {
        $goalPace = $this->goalPace($form);
        if ($goalPace === null) {
            return AmbitionAssessment::realistic();
        }

        $currentRacePace = $this->resolveCurrentRacePace($snapshot, $form);
        if ($currentRacePace === null) {
            return AmbitionAssessment::realistic();
        }

        $paceGap = $currentRacePace - $goalPace;
        if ($paceGap <= 0) {
            // Goal slower than current capability — trivially realistic.
            return AmbitionAssessment::realistic();
        }

        $monthsInPlan = max(1.0, $weeksCount / 4.0);
        $improvementPerMonth = $paceGap / $monthsInPlan;

        $distanceKey = $this->distanceKey($form);
        $minVolume = $distanceKey !== null
            ? (self::MIN_VOLUME_FOR_RACE_PREP[$distanceKey] ?? null)
            : null;
        $volumeRatio = $minVolume !== null && $minVolume > 0
            ? $candidatePeakKm / $minVolume
            : null;

        $level = $this->classify($improvementPerMonth, $volumeRatio);
        $effectiveLevel = EffectiveAmbitionLevel::fromAmbitionLevel($level);

        return new AmbitionAssessment(
            level: $level,
            paceGapSecondsPerKm: $paceGap,
            improvementPerMonthSeconds: $improvementPerMonth,
            volumeRatio: $volumeRatio,
            peakVolumeMultiplier: $effectiveLevel->peakVolumeMultiplier(),
            weeksExtension: $weeksExtension,
            summary: $this->buildSummary($level, $improvementPerMonth, $volumeRatio, $snapshot, $form),
            suggestion: $this->buildSuggestion($level, $form, $weeksCount, $paceGap, $currentRacePace, $weeksExtension),
            effectiveLevel: $effectiveLevel,
            weeklyGrowthRatio: $effectiveLevel->weeklyGrowthRatio(),
            qualityPaceRampGain: $effectiveLevel->qualityPaceRampGain(),
        );
    }

    private function classify(float $improvementPerMonth, ?float $volumeRatio): AmbitionLevel
    {
        // Pace component: 1.0 at REALISTIC threshold, 2.0 at unrealistic.
        $paceScore = $improvementPerMonth / self::REALISTIC_IMPROVEMENT_PER_MONTH;

        // Volume component: 1.0 when peak is at 0.6× recommended, 2.0 at 0.3×.
        $volumeScore = $volumeRatio === null
            ? 0.0
            : max(0.0, (1.0 - $volumeRatio) / 0.3);

        $composite = $paceScore + $volumeScore;

        return match (true) {
            $composite >= 2.5 => AmbitionLevel::VeryAmbitious,
            $composite >= 1.3 => AmbitionLevel::Ambitious,
            default => AmbitionLevel::Realistic,
        };
    }

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
     * Best estimate of the runner's CURRENT race pace at the goal
     * distance. Prefers the runner's stated PR (most accurate); falls
     * back to threshold pace + a distance-appropriate delta.
     */
    private function resolveCurrentRacePace(FitnessSnapshot $snapshot, OnboardingFormInput $form): ?int
    {
        if ($form->prCurrentSeconds !== null && $form->distanceMeters !== null) {
            $km = $form->distanceMeters / 1000;
            if ($km > 0) {
                return (int) round($form->prCurrentSeconds / $km);
            }
        }

        if ($snapshot->thresholdPaceSecondsPerKm === null) {
            return null;
        }

        $distanceKey = $this->distanceKey($form);
        $delta = $distanceKey !== null
            ? (self::RACE_PACE_DELTA_FROM_THRESHOLD[$distanceKey] ?? 0)
            : 0;

        return $snapshot->thresholdPaceSecondsPerKm - $delta;
    }

    private function distanceKey(OnboardingFormInput $form): ?string
    {
        return match ($form->distanceMeters) {
            5000 => GoalDistance::FiveK->value,
            10000 => GoalDistance::TenK->value,
            21097 => GoalDistance::HalfMarathon->value,
            42195 => GoalDistance::Marathon->value,
            default => null,
        };
    }

    private function buildSummary(
        AmbitionLevel $level,
        float $improvementPerMonth,
        ?float $volumeRatio,
        FitnessSnapshot $snapshot,
        OnboardingFormInput $form,
    ): ?string {
        if ($level === AmbitionLevel::Realistic) {
            return null;
        }

        $parts = [];
        $parts[] = sprintf(
            'goal needs %s sec/km/month improvement (%s for intermediate runners is %s sec/km/month)',
            round($improvementPerMonth, 1),
            $level === AmbitionLevel::VeryAmbitious ? 'realistic' : 'typical',
            (int) self::REALISTIC_IMPROVEMENT_PER_MONTH,
        );

        if ($volumeRatio !== null && $volumeRatio < 0.8) {
            $parts[] = sprintf(
                'peak volume is %s of typical race-prep mileage',
                round($volumeRatio * 100).'%',
            );
        }

        return implode('; ', $parts);
    }

    private function buildSuggestion(
        AmbitionLevel $level,
        OnboardingFormInput $form,
        int $weeksCount,
        int $paceGap,
        int $currentRacePace,
        int $weeksExtension,
    ): ?string {
        if ($level === AmbitionLevel::Realistic) {
            return null;
        }

        // Auto-extension already applied — tell the runner what we did,
        // and only suggest further action if the goal is still a stretch.
        if ($weeksExtension > 0) {
            if ($level === AmbitionLevel::VeryAmbitious) {
                return sprintf(
                    'extended the plan to %d weeks for a safer build — but this is still a big stretch, consider an intermediate goal first',
                    $weeksCount,
                );
            }

            return sprintf(
                'extended the plan to %d weeks for a safer build, given how stretched the goal is from your current fitness',
                $weeksCount,
            );
        }

        // Race date locked in — extension isn't an option, only goal time.
        if ($form->targetDate !== null) {
            $realisticPace = $currentRacePace - (int) round(self::REALISTIC_IMPROVEMENT_PER_MONTH * ($weeksCount / 4.0));
            $realisticTimeSec = $form->distanceMeters !== null
                ? (int) round($realisticPace * ($form->distanceMeters / 1000))
                : null;

            return $realisticTimeSec !== null
                ? sprintf(
                    'race date is fixed — consider a more realistic goal time around %s',
                    $this->formatTime($realisticTimeSec),
                )
                : 'race date is fixed — consider a more conservative goal time';
        }

        // Fallback — shouldn't trigger because extension applies when
        // target_date is null, but defensive.
        return 'consider an intermediate goal first';
    }

    private function formatTime(int $seconds): string
    {
        if ($seconds <= 0) {
            return '—';
        }
        $h = intdiv($seconds, 3600);
        $m = intdiv($seconds % 3600, 60);
        $s = $seconds % 60;
        if ($h > 0) {
            return sprintf('%d:%02d:%02d', $h, $m, $s);
        }

        return sprintf('%d:%02d', $m, $s);
    }
}
