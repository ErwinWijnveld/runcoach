<?php

namespace App\Support\Onboarding;

use App\Enums\PaceConfidence;
use App\Enums\PaceDerivation;

/**
 * Immutable snapshot of the runner's CURRENT fitness, as seen by the
 * onboarding plan builder. Replaces the 12-month aggregate that
 * `RunningProfileService` produces for the dashboard / coach narrative.
 *
 * Every pace anchor is in seconds-per-km (matches `target_pace_seconds_per_km`
 * and the rest of the codebase) and may be null when the derivation chain
 * found no signal — the builder falls back to safe defaults in that case.
 */
final readonly class FitnessSnapshot
{
    /**
     * @param  int|null  $thresholdPaceSecondsPerKm  Steady-state lactate-threshold
     *                                               pace (~1-hour race effort).
     * @param  int|null  $easyPaceSecondsPerKm  Conversational / Z2 pace.
     * @param  int|null  $vo2maxPaceSecondsPerKm  Hard interval / Z5 work pace.
     * @param  PaceConfidence  $confidence  How much to trust the paces.
     * @param  PaceDerivation  $derivation  Which tier of the cascade fired.
     * @param  float  $weeklyKmRecent4Weeks  Avg km/week over last 4 weeks.
     * @param  float  $weeklyRunsRecent4Weeks  Avg runs/week over last 4 weeks.
     * @param  float  $longestRunRecent8Weeks  Longest single run in km, last 8 weeks.
     * @param  int|null  $maxHeartRate  From users.heart_rate_zones (Tanaka or Karvonen prior).
     * @param  bool  $hasIntensityHistory  Drives whether the builder ramps quality aggressively.
     */
    public function __construct(
        public ?int $thresholdPaceSecondsPerKm,
        public ?int $easyPaceSecondsPerKm,
        public ?int $vo2maxPaceSecondsPerKm,
        public PaceConfidence $confidence,
        public PaceDerivation $derivation,
        public float $weeklyKmRecent4Weeks,
        public float $weeklyRunsRecent4Weeks,
        public float $longestRunRecent8Weeks,
        public ?int $maxHeartRate,
        public bool $hasIntensityHistory,
    ) {}

    /**
     * Compact, JSON-serialisable summary surfaced to the agent's tool
     * response so it can phrase a one-line reply ("Built around your
     * ~5:35 easy pace from the last 4 weeks…") without hallucinating.
     *
     * @return array<string, mixed>
     */
    public function toFitnessSummary(): array
    {
        return [
            'confidence' => $this->confidence->value,
            'derivation' => $this->derivation->value,
            'easy_pace_label' => self::formatPace($this->easyPaceSecondsPerKm),
            'threshold_pace_label' => self::formatPace($this->thresholdPaceSecondsPerKm),
            'vo2max_pace_label' => self::formatPace($this->vo2maxPaceSecondsPerKm),
            'weekly_km_recent' => round($this->weeklyKmRecent4Weeks, 1),
            'weekly_runs_recent' => round($this->weeklyRunsRecent4Weeks, 1),
            'longest_run_recent' => round($this->longestRunRecent8Weeks, 1),
            'has_intensity_history' => $this->hasIntensityHistory,
        ];
    }

    /**
     * Format a seconds-per-km pace as "M:SS/km" for human display, or
     * null when the underlying pace is unknown.
     */
    private static function formatPace(?int $seconds): ?string
    {
        if ($seconds === null || $seconds <= 0) {
            return null;
        }

        return sprintf('%d:%02d/km', intdiv($seconds, 60), $seconds % 60);
    }
}
