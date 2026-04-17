<?php

namespace App\Services;

use App\Enums\GoalStatus;
use App\Models\StravaActivity;
use App\Models\TrainingDay;
use App\Models\TrainingResult;
use App\Models\User;

class ComplianceScoringService
{
    public function matchAndScore(User $user, StravaActivity $activity): ?TrainingResult
    {
        // If this activity is already matched to any training day (e.g. the
        // user manually matched before the webhook landed), don't create a
        // second result on a different day.
        if (TrainingResult::where('strava_activity_id', $activity->id)->exists()) {
            return null;
        }

        $day = $this->findMatchingDay($user, $activity);

        if (! $day) {
            return null;
        }

        return $this->scoreDay($day, $activity);
    }

    /**
     * Score a Strava activity against an explicitly chosen training day and
     * persist the TrainingResult. Used by the webhook path (via matchAndScore)
     * AND by the manual "Select Strava run" endpoint.
     *
     * Enforces that the activity belongs to the same user as the training
     * day — cheap runtime guard against programming errors in future callers.
     */
    public function scoreDay(TrainingDay $day, StravaActivity $activity): TrainingResult
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

        if ($heartRateScore !== null) {
            $overallScore = ($distanceScore * 0.3) + ($paceScore * 0.4) + ($heartRateScore * 0.3);
        } else {
            $overallScore = ($distanceScore * 0.45) + ($paceScore * 0.55);
        }

        return TrainingResult::updateOrCreate(
            ['training_day_id' => $day->id],
            [
                'strava_activity_id' => $activity->id,
                'compliance_score' => round($overallScore, 1),
                'actual_km' => $activity->distanceInKm(),
                'actual_pace_seconds_per_km' => $activity->paceSecondsPerKm(),
                'actual_avg_heart_rate' => $activity->average_heartrate,
                'pace_score' => round($paceScore, 1),
                'distance_score' => round($distanceScore, 1),
                'heart_rate_score' => $heartRateScore !== null ? round($heartRateScore, 1) : null,
                'matched_at' => now(),
            ]
        );
    }

    private function findMatchingDay(User $user, StravaActivity $activity): ?TrainingDay
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

    private function calculatePaceScore(TrainingDay $day, StravaActivity $activity): float
    {
        if (! $day->target_pace_seconds_per_km) {
            return 7.0;
        }

        $actualPace = $activity->paceSecondsPerKm();
        $targetPace = $day->target_pace_seconds_per_km;
        $deviationPercent = abs($actualPace - $targetPace) / $targetPace * 100;

        return max(1.0, min(10.0, 10.0 - ($deviationPercent / 2.2)));
    }

    private function calculateDistanceScore(TrainingDay $day, StravaActivity $activity): float
    {
        if (! $day->target_km) {
            return 7.0;
        }

        $actualKm = $activity->distanceInKm();
        $ratio = $actualKm / $day->target_km;
        $deviation = abs(1.0 - $ratio);

        return max(1.0, min(10.0, 10.0 - ($deviation * 15)));
    }

    private function calculateHeartRateScore(TrainingDay $day, StravaActivity $activity): ?float
    {
        if (! $activity->average_heartrate || ! $day->target_heart_rate_zone) {
            return null;
        }

        $zones = $this->zonesFor($activity->user);
        $targetIndex = $day->target_heart_rate_zone - 1;
        if (! isset($zones[$targetIndex])) {
            return null;
        }

        $avgHr = (float) $activity->average_heartrate;
        $min = (float) $zones[$targetIndex]['min'];
        $max = (float) $zones[$targetIndex]['max'];

        // Zone 5's upper bound is -1 (open-ended) in Strava's representation.
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
     * Standard Strava-style HR zones used when the runner hasn't connected
     * Strava yet or we couldn't fetch their custom zones. Matches Strava's
     * default thresholds for an untrained athlete.
     */
    private const DEFAULT_HR_ZONES = [
        ['min' => 0, 'max' => 115],
        ['min' => 115, 'max' => 152],
        ['min' => 152, 'max' => 171],
        ['min' => 171, 'max' => 190],
        ['min' => 190, 'max' => -1],
    ];

    /**
     * Resolve the zone table for a user. Prefers their Strava-fetched zones
     * (stored on `users.heart_rate_zones`), falls back to defaults.
     *
     * @return array<int, array{min:int|float, max:int|float}>
     */
    private function zonesFor(?User $user): array
    {
        $stored = $user?->heart_rate_zones;
        if (is_array($stored) && count($stored) >= 5) {
            return array_values($stored);
        }

        return self::DEFAULT_HR_ZONES;
    }
}
