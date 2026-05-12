<?php

namespace App\Support\Onboarding;

use App\Enums\AmbitionLevel;
use App\Enums\IntensityBias;
use App\Services\Onboarding\PlanAmbitionAnalyzer;

/**
 * Output of `PlanAmbitionAnalyzer`. Captures how realistic the runner's
 * goal looks given their fitness snapshot, plan length, and the volume
 * the builder can produce.
 *
 * After `applyBias()`, also carries the post-bias effective level plus
 * three builder knobs (peak volume, weekly growth, quality pace ramp).
 *
 * Two consumers:
 * 1. `TrainingPlanBuilder` reads `peakVolumeMultiplier`,
 *    `weeklyGrowthRatio`, and `qualityPaceRampGain` to shape the
 *    weekly volume curve + pace-progression speed.
 * 2. `BuildOnboardingPlan` exposes the assessment in `fitness_summary`
 *    so the `OnboardingAgent` can paraphrase a warning + suggestion in
 *    its reply.
 */
final readonly class AmbitionAssessment
{
    public const PACE_WEIGHT = 0.6;

    public const VOLUME_WEIGHT = 0.4;

    public const ZONE_OK_MIN_PCT = 70;

    public const ZONE_STRETCH_MIN_PCT = 40;

    public function __construct(
        public AmbitionLevel $level,
        public ?int $paceGapSecondsPerKm,
        public ?float $improvementPerMonthSeconds,
        public ?float $volumeRatio,
        public float $peakVolumeMultiplier,
        /**
         * Weeks added to the base plan length to make the goal achievable.
         * 0 for realistic goals or when `target_date` is locked in
         * (the runner committed to a date — extension isn't an option).
         */
        public int $weeksExtension,
        public ?string $summary,
        public ?string $suggestion,
        public EffectiveAmbitionLevel $effectiveLevel = EffectiveAmbitionLevel::Ambitious,
        public float $weeklyGrowthRatio = 1.30,
        public float $qualityPaceRampGain = 1.00,
    ) {}

    public static function realistic(): self
    {
        return new self(
            level: AmbitionLevel::Realistic,
            paceGapSecondsPerKm: null,
            improvementPerMonthSeconds: null,
            volumeRatio: null,
            peakVolumeMultiplier: 1.6,
            weeksExtension: 0,
            summary: null,
            suggestion: null,
            effectiveLevel: EffectiveAmbitionLevel::Realistic,
            weeklyGrowthRatio: EffectiveAmbitionLevel::Realistic->weeklyGrowthRatio(),
            qualityPaceRampGain: EffectiveAmbitionLevel::Realistic->qualityPaceRampGain(),
        );
    }

    public function withWeeksExtension(int $extension): self
    {
        return new self(
            level: $this->level,
            paceGapSecondsPerKm: $this->paceGapSecondsPerKm,
            improvementPerMonthSeconds: $this->improvementPerMonthSeconds,
            volumeRatio: $this->volumeRatio,
            peakVolumeMultiplier: $this->peakVolumeMultiplier,
            weeksExtension: $extension,
            summary: $this->summary,
            suggestion: $this->suggestion,
            effectiveLevel: $this->effectiveLevel,
            weeklyGrowthRatio: $this->weeklyGrowthRatio,
            qualityPaceRampGain: $this->qualityPaceRampGain,
        );
    }

    /**
     * Apply the runner's intensity-bias slider to the assessment.
     * Shifts the effective level by ±1 within the five-tier table
     * (Conservative through AllIn) and recomputes the three builder
     * knobs from that level. The original auto-detected `level` is
     * retained for diagnostics; the builder reads `effectiveLevel`.
     */
    public function applyBias(IntensityBias $bias): self
    {
        $shift = match ($bias) {
            IntensityBias::TakeItEasy => -1,
            IntensityBias::Standard => 0,
            IntensityBias::PushMeHarder => +1,
        };

        if ($shift === 0) {
            return $this;
        }

        $effective = EffectiveAmbitionLevel::shiftFrom($this->level, $shift);

        return new self(
            level: $this->level,
            paceGapSecondsPerKm: $this->paceGapSecondsPerKm,
            improvementPerMonthSeconds: $this->improvementPerMonthSeconds,
            volumeRatio: $this->volumeRatio,
            peakVolumeMultiplier: $effective->peakVolumeMultiplier(),
            weeksExtension: $this->weeksExtension,
            summary: $this->summary,
            suggestion: $this->suggestion,
            effectiveLevel: $effective,
            weeklyGrowthRatio: $effective->weeklyGrowthRatio(),
            qualityPaceRampGain: $effective->qualityPaceRampGain(),
        );
    }

    /**
     * Wire-shape consumed by the Flutter plan-details modal. Null when
     * there's no measurable goal (no pace gap) — the section is skipped
     * in that case. Numbers are pre-aggregated to integers so the app
     * never has to do arithmetic.
     *
     * @return array<string, mixed>|null
     */
    public function toFeasibilityPayload(): ?array
    {
        if ($this->paceGapSecondsPerKm === null || $this->improvementPerMonthSeconds === null) {
            return null;
        }

        $paceFeasibility = min(
            1.0,
            PlanAmbitionAnalyzer::REALISTIC_IMPROVEMENT_PER_MONTH
                / max($this->improvementPerMonthSeconds, 0.01),
        );
        $volumeFeasibility = $this->volumeRatio === null
            ? 1.0
            : max(0.0, min(1.0, $this->volumeRatio));

        $feasibility01 = $paceFeasibility * self::PACE_WEIGHT
            + $volumeFeasibility * self::VOLUME_WEIGHT;

        $feasibilityPct = (int) round($feasibility01 * 100);
        $zone = match (true) {
            $feasibilityPct >= self::ZONE_OK_MIN_PCT => 'ok',
            $feasibilityPct >= self::ZONE_STRETCH_MIN_PCT => 'stretch',
            default => 'unrealistic',
        };

        return [
            'feasibility_pct' => $feasibilityPct,
            'pace_score_pct' => (int) round($paceFeasibility * 100),
            'volume_score_pct' => (int) round($volumeFeasibility * 100),
            'verdict_zone' => $zone,
            'verdict_label' => $this->verdictLabel($zone),
            'detail' => $this->verdictDetail($zone, $this->improvementPerMonthSeconds, $volumeFeasibility),
            'pace_gap_seconds_per_km' => $this->paceGapSecondsPerKm,
            'required_improvement_per_month_seconds' => (int) round($this->improvementPerMonthSeconds),
            'adjust_prefill' => $this->adjustPrefill(),
        ];
    }

    private function verdictLabel(string $zone): string
    {
        return match ($zone) {
            'ok' => 'Goed haalbaar',
            'stretch' => 'Pittig maar haalbaar',
            'unrealistic' => 'Te ambitieus voor dit plan',
            default => '',
        };
    }

    private function verdictDetail(string $zone, float $improvementPerMonth, float $volumeFeasibility): string
    {
        $rate = (int) round($improvementPerMonth);
        $volPct = (int) round($volumeFeasibility * 100);

        return match ($zone) {
            'ok' => sprintf(
                '%d sec/km per maand verbetering nodig — binnen normaal voor jouw volume.',
                $rate,
            ),
            'stretch' => sprintf(
                'Vraagt %d sec/km per maand — bijna 2× wat realistisch is. Volume %d%% van aanbevolen.',
                $rate,
                $volPct,
            ),
            'unrealistic' => sprintf(
                'Vraagt %d sec/km per maand — ruim boven realistische verbeteringsrate. Volume %d%% van aanbevolen.',
                $rate,
                $volPct,
            ),
            default => '',
        };
    }

    private function adjustPrefill(): string
    {
        return 'Mijn doel voelt te ambitieus voor dit plan — kun je een realistischer tijd voorstellen?';
    }

    /**
     * @return array<string, mixed>
     */
    public function toFitnessSummary(): array
    {
        return [
            'level' => $this->level->value,
            'effective_level' => $this->effectiveLevel->value,
            'pace_gap_seconds_per_km' => $this->paceGapSecondsPerKm,
            'improvement_per_month_seconds' => $this->improvementPerMonthSeconds === null
                ? null
                : round($this->improvementPerMonthSeconds, 1),
            'volume_ratio' => $this->volumeRatio === null ? null : round($this->volumeRatio, 2),
            'weeks_extension' => $this->weeksExtension,
            'summary' => $this->summary,
            'suggestion' => $this->suggestion,
        ];
    }
}
