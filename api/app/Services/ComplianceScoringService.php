<?php

namespace App\Services;

use App\Enums\GoalStatus;
use App\Models\TrainingDay;
use App\Models\TrainingResult;
use App\Models\User;
use App\Models\WearableActivity;
use App\Support\HeartRateZones;

class ComplianceScoringService
{
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

    private function findMatchingDay(User $user, WearableActivity $activity): ?TrainingDay
    {
        $candidates = TrainingDay::whereHas('trainingWeek.goal', function ($query) use ($user) {
            $query->where('user_id', $user->id)
                ->where('status', GoalStatus::Active);
        })
            ->whereDoesntHave('result')
            ->whereBetween('date', [
                $activity->start_date->copy()->subDay()->toDateString(),
                $activity->start_date->copy()->addDay()->toDateString(),
            ])
            ->get();

        if ($candidates->isEmpty()) {
            return null;
        }

        $activityDate = $activity->start_date->toDateString();
        $exactMatch = $candidates->where('date', $activityDate);
        if ($exactMatch->isNotEmpty()) {
            $candidates = $exactMatch;
        }

        return $candidates->sortBy(function ($day) use ($activity) {
            if (! $day->target_km) {
                return PHP_INT_MAX;
            }

            return abs($day->target_km - $activity->distanceInKm());
        })->first();
    }

    /**
     * Pace compliance, or null when we have no defensible target to compare
     * against. Intervals fall in this bucket: their day-level
     * `target_pace_seconds_per_km` is null and an actual run's average
     * (which mixes work + recovery + warmup + cooldown) wouldn't be
     * meaningful to score against the work-segment target. Until segment
     * ingestion lands, intervals get distance + HR scoring only.
     */
    private function calculatePaceScore(TrainingDay $day, WearableActivity $activity): ?float
    {
        if (! $day->target_pace_seconds_per_km) {
            return null;
        }

        $actualPace = $activity->paceSecondsPerKm();
        $targetPace = $day->target_pace_seconds_per_km;
        $deviationPercent = abs($actualPace - $targetPace) / $targetPace * 100;

        return max(1.0, min(10.0, 10.0 - ($deviationPercent / 2.2)));
    }

    private function calculateDistanceScore(TrainingDay $day, WearableActivity $activity): float
    {
        if (! $day->target_km) {
            return 7.0;
        }

        $actualKm = $activity->distanceInKm();
        $ratio = $actualKm / $day->target_km;
        $deviation = abs(1.0 - $ratio);

        return max(1.0, min(10.0, 10.0 - ($deviation * 15)));
    }

    private function calculateHeartRateScore(TrainingDay $day, WearableActivity $activity): ?float
    {
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
}
