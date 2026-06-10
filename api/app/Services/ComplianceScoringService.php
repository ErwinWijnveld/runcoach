<?php

namespace App\Services;

use App\Enums\GoalStatus;
use App\Enums\TrainingType;
use App\Models\TrainingDay;
use App\Models\TrainingResult;
use App\Models\User;
use App\Models\WearableActivity;
use App\Support\HeartRateZones;
use App\Support\Intervals\IntervalBlueprint;

class ComplianceScoringService
{
    /**
     * Interval scoring is a plausibility model over whole-session aggregates
     * (we ingest no splits or HR samples yet — see the 2026-06-10
     * interval-compliance-scoring spec). These knobs shape the full-score
     * bands; widen them before tightening if real sessions score unfairly.
     */
    public const INTERVAL_PACE_BAND_MARGIN_SECONDS = 90;

    public const INTERVAL_DISTANCE_OVERSHOOT_RATIO = 1.8;

    public const INTERVAL_DISTANCE_UNDERSHOOT_SLOPE = 15.0;

    public const INTERVAL_DISTANCE_OVERSHOOT_SLOPE = 7.5;

    public const INTERVAL_HR_TOUCH_ZONE_FALLBACK = 5;

    public function matchAndScore(User $user, WearableActivity $activity): ?TrainingResult
    {
        // If this activity is already matched to any training day (e.g. the
        // user manually matched before the webhook landed), don't create a
        // second result on a different day.
        if (TrainingResult::where('wearable_activity_id', $activity->id)->exists()) {
            return null;
        }

        $day = $this->findMatchingDay($user, $activity);

        if (! $day) {
            return null;
        }

        return $this->scoreDay($day, $activity);
    }

    /**
     * Score a wearable activity against an explicitly chosen training day and
     * persist the TrainingResult. Used by the ingestion path (via matchAndScore)
     * AND by the manual "Select activity" endpoint.
     *
     * Enforces that the activity belongs to the same user as the training
     * day — cheap runtime guard against programming errors in future callers.
     */
    public function scoreDay(TrainingDay $day, WearableActivity $activity): TrainingResult
    {
        $dayUserId = $day->trainingWeek?->goal?->user_id;
        if ($dayUserId !== null && $activity->user_id !== $dayUserId) {
            throw new \DomainException(
                "Cannot score an activity against another user's training day.",
            );
        }

        $paceScore = $this->calculatePaceScore($day, $activity);
        $distanceScore = $this->calculateDistanceScore($day, $activity);
        $heartRateScore = $this->calculateHeartRateScore($day, $activity);

        $overallScore = self::weightedOverall($distanceScore, $paceScore, $heartRateScore);

        return TrainingResult::updateOrCreate(
            ['training_day_id' => $day->id],
            [
                'wearable_activity_id' => $activity->id,
                'compliance_score' => round($overallScore, 1),
                'actual_km' => $activity->distanceInKm(),
                'actual_pace_seconds_per_km' => $activity->paceSecondsPerKm(),
                'actual_avg_heart_rate' => $activity->average_heartrate,
                'pace_score' => $paceScore !== null ? round($paceScore, 1) : null,
                'distance_score' => round($distanceScore, 1),
                'heart_rate_score' => $heartRateScore !== null ? round($heartRateScore, 1) : null,
                'matched_at' => now(),
            ]
        );
    }

    /**
     * Combine the three sub-scores using fixed canonical weights — but only
     * include components that produced a real score. Active weights are
     * renormalised so the result always lives on the same 0-10 scale,
     * regardless of which dimensions were unavailable.
     *
     * Canonical weights: distance 30%, pace 40%, HR 30%. Real-world
     * combinations after renormalisation:
     *  - all three:                30 / 40 / 30
     *  - no HR (no avg hr):        43 / 57 / —
     *  - no pace (interval days):  50 / —  / 50
     *  - distance only:            100 / — / —
     *
     * Public + static so seed data can compute the same number without
     * needing to instantiate the service or duplicate the formula. Single
     * source of truth — change weights here and seeded values follow.
     */
    public static function weightedOverall(float $distance, ?float $pace, ?float $hr): float
    {
        $components = [['score' => $distance, 'weight' => 0.3]];
        if ($pace !== null) {
            $components[] = ['score' => $pace, 'weight' => 0.4];
        }
        if ($hr !== null) {
            $components[] = ['score' => $hr, 'weight' => 0.3];
        }

        $totalWeight = array_sum(array_column($components, 'weight'));

        $weighted = 0.0;
        foreach ($components as $c) {
            $weighted += $c['score'] * $c['weight'];
        }

        return $totalWeight > 0 ? $weighted / $totalWeight : 0.0;
    }

    /**
     * Auto-match only when the run falls on a planned session's EXACT date.
     * Runs on any other day are intentionally left unmatched so they surface
     * as off-plan ("buiten schema") runs the user can manually link to a
     * session via POST /wearable/activities/{activity}/link-day.
     */
    private function findMatchingDay(User $user, WearableActivity $activity): ?TrainingDay
    {
        $candidates = TrainingDay::whereHas('trainingWeek.goal', function ($query) use ($user) {
            $query->where('user_id', $user->id)
                ->where('status', GoalStatus::Active);
        })
            ->whereDoesntHave('result')
            ->whereDate('date', $activity->start_date->toDateString())
            ->get();

        if ($candidates->isEmpty()) {
            return null;
        }

        // Rare: two planned sessions share the date — pick the closest by distance.
        return $candidates->sortBy(function ($day) use ($activity) {
            if (! $day->target_km) {
                return PHP_INT_MAX;
            }

            return abs($day->target_km - $activity->distanceInKm());
        })->first();
    }

    /**
     * Pace compliance, or null when we have no defensible target to compare
     * against. Interval days are scored against a blueprint-derived band for
     * the session AVERAGE (see intervalPaceScore) — their day-level
     * `target_pace_seconds_per_km` is null by design.
     */
    private function calculatePaceScore(TrainingDay $day, WearableActivity $activity): ?float
    {
        if ($day->type === TrainingType::Interval) {
            return $this->intervalPaceScore($day, $activity);
        }

        if (! $day->target_pace_seconds_per_km) {
            return null;
        }

        $actualPace = $activity->paceSecondsPerKm();
        $targetPace = $day->target_pace_seconds_per_km;
        $deviationPercent = abs($actualPace - $targetPace) / $targetPace * 100;

        return max(1.0, min(10.0, 10.0 - ($deviationPercent / 2.2)));
    }

    /**
     * A correctly executed interval session's whole-run average pace must
     * land between the work pace (faster = recoveries skipped / different
     * session) and the jog pace plus a generous margin (slower = no real
     * work happened — the margin exists because walking recoveries are
     * legitimate). Outside the band, the standard deviation penalty applies
     * against the nearest edge. Null when the blueprint carries no work
     * paces or the activity has no average pace.
     */
    private function intervalPaceScore(TrainingDay $day, WearableActivity $activity): ?float
    {
        $workAvg = $day->workSetAveragePaceSecondsPerKm();
        if ($workAvg === null || ! $activity->average_pace_seconds_per_km) {
            return null;
        }

        $bandMin = $workAvg;
        $bandMax = IntervalBlueprint::estimateJogPace($workAvg) + self::INTERVAL_PACE_BAND_MARGIN_SECONDS;

        $actualPace = $activity->paceSecondsPerKm();
        if ($actualPace >= $bandMin && $actualPace <= $bandMax) {
            return 10.0;
        }

        $nearestEdge = $actualPace < $bandMin ? $bandMin : $bandMax;
        $deviationPercent = abs($actualPace - $nearestEdge) / $nearestEdge * 100;

        return max(1.0, min(10.0, 10.0 - ($deviationPercent / 2.2)));
    }

    private function calculateDistanceScore(TrainingDay $day, WearableActivity $activity): float
    {
        if (! $day->target_km) {
            return 7.0;
        }

        if ($day->type === TrainingType::Interval) {
            $intervalScore = $this->intervalDistanceScore($day, $activity);
            if ($intervalScore !== null) {
                return $intervalScore;
            }
        }

        $actualKm = $activity->distanceInKm();
        $ratio = $actualKm / $day->target_km;
        $deviation = abs(1.0 - $ratio);

        return max(1.0, min(10.0, 10.0 - ($deviation * 15)));
    }

    /**
     * Asymmetric distance band for intervals. The blueprint's `target_km`
     * assumes a 120s-capped warmup and a short cooldown, but a real session
     * carries 10-15 minutes of each — overshooting the target is correct
     * execution, not non-compliance. So: full score from the work volume
     * (the floor below which the reps are demonstrably incomplete) up to
     * target × INTERVAL_DISTANCE_OVERSHOOT_RATIO; a steep penalty below,
     * a mild one above. Null when the blueprint yields no work distance —
     * the caller falls back to the symmetric formula.
     */
    private function intervalDistanceScore(TrainingDay $day, WearableActivity $activity): ?float
    {
        $workKm = IntervalBlueprint::workDistanceKm($day->intervals_json);
        if ($workKm === null) {
            return null;
        }

        $targetKm = (float) $day->target_km;
        $bandMin = min($workKm, $targetKm);
        $bandMax = $targetKm * self::INTERVAL_DISTANCE_OVERSHOOT_RATIO;

        $actualKm = $activity->distanceInKm();
        if ($actualKm >= $bandMin && $actualKm <= $bandMax) {
            return 10.0;
        }

        if ($actualKm < $bandMin) {
            $deviation = ($bandMin - $actualKm) / $bandMin;

            return max(1.0, min(10.0, 10.0 - ($deviation * self::INTERVAL_DISTANCE_UNDERSHOOT_SLOPE)));
        }

        $deviation = ($actualKm - $bandMax) / $targetKm;

        return max(1.0, min(10.0, 10.0 - ($deviation * self::INTERVAL_DISTANCE_OVERSHOOT_SLOPE)));
    }

    private function calculateHeartRateScore(TrainingDay $day, WearableActivity $activity): ?float
    {
        if ($day->type === TrainingType::Interval) {
            return $this->intervalHeartRateScore($day, $activity);
        }

        if (! $activity->average_heartrate || ! $day->target_heart_rate_zone) {
            return null;
        }

        $zone = HeartRateZones::zoneFor($activity->user, $day->target_heart_rate_zone);
        if ($zone === null) {
            return null;
        }

        $avgHr = (float) $activity->average_heartrate;
        $min = (float) $zone['min'];
        $max = (float) $zone['max'];

        // Zone 5's upper bound is -1 (open-ended) by convention.
        $insideZone = $avgHr >= $min && ($max < 0 || $avgHr <= $max);
        if ($insideZone) {
            return 10.0;
        }

        // Outside the target zone — penalise by bpm distance from the
        // nearest boundary. 5 bpm off == -1 score point, clamped to 1.0.
        $distanceBpm = $avgHr < $min ? ($min - $avgHr) : ($avgHr - $max);

        return max(1.0, 10.0 - ($distanceBpm / 5.0));
    }

    /**
     * Average HR over an interval session mixes warmup + recoveries +
     * cooldown, so comparing it to the Z5 work label punishes exactly the
     * runner who executed the session correctly. Instead: the session MAX
     * must have touched at least the zone below the day's target (Z5 day →
     * peaks reached Z4). No upper penalty — high peaks are the point of
     * intervals. Null when the activity has no max HR; the avg-HR
     * comparison deliberately does NOT kick in as a fallback.
     */
    private function intervalHeartRateScore(TrainingDay $day, WearableActivity $activity): ?float
    {
        if (! $activity->max_heartrate) {
            return null;
        }

        $touchZoneIndex = max(1, ($day->target_heart_rate_zone ?? self::INTERVAL_HR_TOUCH_ZONE_FALLBACK) - 1);
        $zone = HeartRateZones::zoneFor($activity->user, $touchZoneIndex);
        if ($zone === null) {
            return null;
        }

        $maxHr = (float) $activity->max_heartrate;
        $threshold = (float) $zone['min'];

        if ($maxHr >= $threshold) {
            return 10.0;
        }

        return max(1.0, 10.0 - (($threshold - $maxHr) / 5.0));
    }
}
