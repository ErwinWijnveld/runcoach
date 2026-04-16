<?php

namespace App\Services;

use App\Enums\GoalStatus;
use App\Enums\TrainingType;
use App\Models\StravaActivity;
use App\Models\TrainingDay;
use App\Models\TrainingResult;
use App\Models\User;

class ComplianceScoringService
{
    private const NON_MATCHABLE_TYPES = [
        TrainingType::Rest,
        TrainingType::Mobility,
    ];

    public function matchAndScore(User $user, StravaActivity $activity): void
    {
        $day = $this->findMatchingDay($user, $activity);

        if (! $day) {
            return;
        }

        $paceScore = $this->calculatePaceScore($day, $activity);
        $distanceScore = $this->calculateDistanceScore($day, $activity);
        $heartRateScore = $this->calculateHeartRateScore($day, $activity);

        if ($heartRateScore !== null) {
            $overallScore = ($distanceScore * 0.3) + ($paceScore * 0.4) + ($heartRateScore * 0.3);
        } else {
            $overallScore = ($distanceScore * 0.45) + ($paceScore * 0.55);
        }

        TrainingResult::updateOrCreate(
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
            ->whereNotIn('type', array_map(fn ($t) => $t->value, self::NON_MATCHABLE_TYPES))
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

        $zoneMidpoints = [1 => 120, 2 => 140, 3 => 155, 4 => 170, 5 => 185];
        $targetHr = $zoneMidpoints[$day->target_heart_rate_zone] ?? 150;
        $deviationPercent = abs($activity->average_heartrate - $targetHr) / $targetHr * 100;

        return max(1.0, min(10.0, 10.0 - ($deviationPercent / 1.5)));
    }
}
