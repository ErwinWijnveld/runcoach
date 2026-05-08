<?php

namespace App\Support\Onboarding;

use App\Enums\AmbitionLevel;

/**
 * Output of `PlanAmbitionAnalyzer`. Captures how realistic the runner's
 * goal looks given their fitness snapshot, plan length, and the volume
 * the builder can produce.
 *
 * Two consumers:
 * 1. `TrainingPlanBuilder` reads `peakVolumeMultiplier` to crank peak
 *    weekly volume up when the goal warrants more training stimulus.
 * 2. `BuildOnboardingPlan` exposes the assessment in `fitness_summary`
 *    so the `OnboardingAgent` can paraphrase a warning + suggestion in
 *    its reply.
 */
final readonly class AmbitionAssessment
{
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
        );
    }

    /**
     * @return array<string, mixed>
     */
    public function toFitnessSummary(): array
    {
        return [
            'level' => $this->level->value,
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
