<?php

namespace App\Services;

use App\Enums\TrainingType;
use App\Models\TrainingResult;
use App\Models\UserNotification;
use App\Support\HeartRateZones;

/**
 * After a wearable run is scored, decide whether the runner's heart rate
 * was so far outside the planned zone (despite the pace being on target)
 * that we should suggest slowing down — or speeding up — every upcoming
 * run of the same type. The user accepts/rejects the suggestion through
 * the notifications inbox; on accept we shift each remaining day's
 * `target_pace_seconds_per_km` by the computed factor.
 */
class PaceAdjustmentEvaluator
{
    /**
     * pace_score must be at least this for the trigger to fire — the run
     * has to demonstrate that the runner CAN hold the planned pace, so
     * the HR mismatch points to mis-calibrated zones rather than a poor
     * pacing job.
     */
    private const PACE_SCORE_FLOOR = 8.0;

    /**
     * heart_rate_score at-or-below this is "clearly outside the zone".
     * Score 7 means HR was ~15 bpm beyond the zone boundary (5 bpm per
     * point in `ComplianceScoringService::calculateHeartRateScore`).
     */
    private const HR_SCORE_CEILING = 7.0;

    /**
     * Skip when the resulting pace adjustment is too small to bother the
     * user with. 3% on a 5:00/km run = 9 sec/km.
     */
    private const MIN_FACTOR_DELTA = 0.03;

    /**
     * Empirical pace ↔ HR coupling at aerobic intensities. %ΔHR ≈ 0.85 ×
     * %Δpace in steady-state running (Karvonen-derived; conservative).
     * Lower coefficient = larger pace change per unit HR change.
     */
    private const PACE_HR_COUPLING = 0.85;

    private const FACTOR_MIN = 0.85;

    private const FACTOR_MAX = 1.20;

    public function evaluate(TrainingResult $result): ?UserNotification
    {
        $day = $result->trainingDay;
        $activity = $result->wearableActivity;
        $user = $activity?->user;

        if (! $day || ! $activity || ! $user) {
            return null;
        }

        // Intervals naturally swing across multiple zones — pace-vs-HR
        // mismatch isn't a signal there.
        if ($day->type === TrainingType::Interval) {
            return null;
        }

        if (! $day->target_pace_seconds_per_km || ! $day->target_heart_rate_zone) {
            return null;
        }

        if ($result->pace_score === null || $result->heart_rate_score === null) {
            return null;
        }

        if ((float) $result->pace_score < self::PACE_SCORE_FLOOR) {
            return null;
        }

        if ((float) $result->heart_rate_score > self::HR_SCORE_CEILING) {
            return null;
        }

        $zoneMid = HeartRateZones::zoneMidpoint($user, $day->target_heart_rate_zone);
        if ($zoneMid === null) {
            return null;
        }

        $actualHr = (float) $activity->average_heartrate;
        if ($actualHr <= 0) {
            return null;
        }

        $factor = $this->paceFactor($actualHr, $zoneMid);
        if (abs($factor - 1.0) < self::MIN_FACTOR_DELTA) {
            return null;
        }

        // One pending notification per training type at a time — replace
        // an older suggestion if a newer run for the same type confirms
        // the pattern.
        UserNotification::where('user_id', $user->id)
            ->where('type', UserNotification::TYPE_PACE_ADJUSTMENT)
            ->where('status', UserNotification::STATUS_PENDING)
            ->whereJsonContains('action_data->training_type', $day->type->value)
            ->update([
                'status' => UserNotification::STATUS_DISMISSED,
                'acted_at' => now(),
            ]);

        return UserNotification::create([
            'user_id' => $user->id,
            'type' => UserNotification::TYPE_PACE_ADJUSTMENT,
            'title' => $this->title($day->type, $factor),
            'body' => $this->body($day->type, $factor, $day->target_pace_seconds_per_km),
            'action_data' => [
                'source_training_result_id' => $result->id,
                'training_type' => $day->type->value,
                'pace_factor' => round($factor, 4),
            ],
            'status' => UserNotification::STATUS_PENDING,
        ]);
    }

    /**
     * Convert HR error (actual vs zone midpoint) into a pace multiplier.
     * Slowing pace lowers HR; the coupling factor reflects that the
     * relationship isn't 1:1.
     */
    private function paceFactor(float $actualHr, float $zoneMid): float
    {
        $hrDelta = ($actualHr - $zoneMid) / $zoneMid;
        $factor = 1.0 + ($hrDelta / self::PACE_HR_COUPLING);

        return max(self::FACTOR_MIN, min(self::FACTOR_MAX, $factor));
    }

    private function title(TrainingType $type, float $factor): string
    {
        $direction = $factor > 1.0 ? 'too hard' : 'too easy';

        return "Your {$type->label()} runs are {$direction}";
    }

    private function body(TrainingType $type, float $factor, int $currentPace): string
    {
        $newPace = (int) round($currentPace * $factor);
        $delta = abs($newPace - $currentPace);
        $verb = $factor > 1.0 ? 'slowing' : 'picking up';
        $arrow = $factor > 1.0 ? "+{$delta}s/km" : "−{$delta}s/km";
        $label = strtolower($type->label());

        return "Your heart rate sat outside the planned zone — try {$verb} every upcoming {$label} run by {$arrow}.";
    }
}
