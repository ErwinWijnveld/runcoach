<?php

namespace App\Services;

use App\Models\User;
use App\Models\UserRunningProfile;
use App\Models\WearableActivity;
use Illuminate\Support\Collection;

class RunningProfileService
{
    public function analyze(User $user): UserRunningProfile
    {
        $end = now();
        $start = now()->subYear();

        $runs = WearableActivity::query()
            ->where('user_id', $user->id)
            ->whereIn('type', WearableActivity::RUN_TYPES)
            ->whereBetween('start_date', [$start, $end])
            ->orderBy('start_date')
            ->get();

        $profile = $this->computeMetrics($user, $runs);
        $profile->narrative_summary = $this->buildNarrative($profile->metrics);
        $profile->analyzed_at = now();
        $profile->data_start_date = $start;
        $profile->data_end_date = $end;
        $profile->save();

        return $profile;
    }

    /**
     * Returns a cached profile when one exists, otherwise analyzes from the
     * user's local activities. Returns null when the user has no activities
     * synced yet (the app hasn't pushed any HealthKit workouts).
     */
    public function getOrAnalyze(User $user): ?UserRunningProfile
    {
        $existing = $user->runningProfile()->first();

        if ($existing) {
            return $existing;
        }

        if (! $user->wearableActivities()->exists()) {
            return null;
        }

        return $this->analyze($user);
    }

    /**
     * @param  Collection<int, WearableActivity>  $runs
     */
    public function computeMetrics(User $user, Collection $runs): UserRunningProfile
    {
        $metrics = $this->aggregate($runs);

        return UserRunningProfile::updateOrCreate(
            ['user_id' => $user->id],
            ['metrics' => $metrics],
        );
    }

    /**
     * @param  Collection<int, WearableActivity>  $runs
     * @return array<string, mixed>
     */
    private function aggregate(Collection $runs): array
    {
        $totalRuns = $runs->count();
        $totalMeters = $runs->sum('distance_meters');
        $totalSeconds = $runs->sum('duration_seconds');
        $totalKm = round($totalMeters / 1000, 1);

        $weeks = 52;
        $weeklyAvgKm = $totalRuns === 0 ? 0.0 : round($totalKm / $weeks, 1);
        // 1-decimal float so users with <1 run/week don't see "0 runs/week"
        // (a runner with 20 runs/year ≈ 0.4/week, not 0).
        $weeklyAvgRuns = $totalRuns === 0 ? 0.0 : round($totalRuns / $weeks, 1);

        $avgPace = $totalMeters === 0 ? 0 : (int) round($totalSeconds / ($totalMeters / 1000));
        $avgDuration = $totalRuns === 0 ? 0 : (int) round($totalSeconds / $totalRuns);

        $weeksWithRuns = [];
        foreach ($runs as $run) {
            $weeksWithRuns[$run->start_date->format('o-W')] = true;
        }
        $consistency = (int) round(count($weeksWithRuns) / $weeks * 100);

        return [
            'weekly_avg_km' => $weeklyAvgKm,
            'weekly_avg_runs' => $weeklyAvgRuns,
            'avg_pace_seconds_per_km' => $avgPace,
            'session_avg_duration_seconds' => $avgDuration,
            'total_runs_12mo' => $totalRuns,
            'total_distance_km_12mo' => $totalKm,
            'consistency_score' => $consistency,
            'long_run_trend' => $this->trend($runs, fn (WearableActivity $r) => $r->distance_meters),
            'pace_trend' => $this->paceTrend($runs),
        ];
    }

    private function trend(Collection $runs, callable $metric): string
    {
        if ($runs->count() < 10) {
            return 'flat';
        }

        $half = (int) floor($runs->count() / 2);
        $first = $runs->slice(0, $half);
        $last = $runs->slice($half);
        $avgFirst = $first->sum($metric) / max(1, $first->count());
        $avgLast = $last->sum($metric) / max(1, $last->count());

        if ($avgLast > $avgFirst * 1.05) {
            return 'improving';
        }
        if ($avgLast < $avgFirst * 0.95) {
            return 'declining';
        }

        return 'flat';
    }

    private function paceTrend(Collection $runs): string
    {
        if ($runs->count() < 10) {
            return 'flat';
        }

        $paceMetric = fn (WearableActivity $r) => $r->average_pace_seconds_per_km;

        $half = (int) floor($runs->count() / 2);
        $first = $runs->slice(0, $half);
        $last = $runs->slice($half);
        $avgFirst = $first->sum($paceMetric) / max(1, $first->count());
        $avgLast = $last->sum($paceMetric) / max(1, $last->count());

        if ($avgLast < $avgFirst * 0.95) {
            return 'improving';
        }
        if ($avgLast > $avgFirst * 1.05) {
            return 'declining';
        }

        return 'flat';
    }

    /**
     * @param  array<string, mixed>  $metrics
     */
    private function buildNarrative(array $metrics): string
    {
        $totalRuns = (int) ($metrics['total_runs_12mo'] ?? 0);

        if ($totalRuns === 0) {
            return "No running activities in the past 12 months yet, we'll build from the ground up.";
        }

        $totalKm = (float) ($metrics['total_distance_km_12mo'] ?? 0);
        $weeklyKm = (float) ($metrics['weekly_avg_km'] ?? 0);
        $weeklyRuns = (int) ($metrics['weekly_avg_runs'] ?? 0);
        $consistency = (int) ($metrics['consistency_score'] ?? 0);
        $paceSec = (int) ($metrics['avg_pace_seconds_per_km'] ?? 0);
        $longRunTrend = (string) ($metrics['long_run_trend'] ?? 'flat');
        $paceTrend = (string) ($metrics['pace_trend'] ?? 'flat');

        $volumeTier = match (true) {
            $weeklyKm < 5 => 'a light weekly rhythm',
            $weeklyKm < 15 => 'a modest weekly base',
            $weeklyKm < 30 => 'solid weekly mileage',
            $weeklyKm < 50 => 'serious weekly volume',
            default => 'high-volume training',
        };

        $consistencyLine = match (true) {
            $consistency >= 85 => "You've barely missed a week. Your consistency score is {$consistency}.",
            $consistency >= 65 => "You've been pretty consistent, with a consistency score of {$consistency}.",
            $consistency >= 40 => "Your routine has been on-and-off, with a consistency score of {$consistency}.",
            default => "Running has been sporadic lately, with a consistency score of {$consistency}.",
        };

        $lines = [
            sprintf(
                "Over the past 12 months you've logged %d runs covering %s km at a typical pace of %s/km.",
                $totalRuns,
                $this->formatKm($totalKm),
                $this->formatPace($paceSec),
            ),
            sprintf(
                "That's about %s a week at %s km, %s.",
                $weeklyRuns <= 0 ? 'less than one run' : ($weeklyRuns === 1 ? '1 run' : "{$weeklyRuns} runs"),
                rtrim(rtrim(number_format($weeklyKm, 1), '0'), '.'),
                $volumeTier,
            ),
            $consistencyLine,
        ];

        $trendLine = $this->buildTrendLine($longRunTrend, $paceTrend);
        if ($trendLine !== null) {
            $lines[] = $trendLine;
        }

        return implode(' ', $lines);
    }

    private function buildTrendLine(string $longRun, string $pace): ?string
    {
        return match (true) {
            $longRun === 'improving' && $pace === 'improving' => 'Both your distances and pace are trending up, a strong recent trajectory.',
            $longRun === 'declining' && $pace === 'declining' => 'Both distance and pace have slipped over the last few months.',
            $longRun === 'improving' && $pace === 'declining' => 'Your long runs have stretched out, though pace has eased off a touch.',
            $longRun === 'declining' && $pace === 'improving' => "You've pulled back on distance, but your pace has sharpened.",
            $longRun === 'improving' => 'Your long runs have been getting longer.',
            $longRun === 'declining' => 'Your long runs have shortened recently.',
            $pace === 'improving' => 'Your pace has been getting faster.',
            $pace === 'declining' => 'Your pace has slowed a bit recently.',
            default => null,
        };
    }

    private function formatPace(int $seconds): string
    {
        if ($seconds <= 0) {
            return '-';
        }

        return sprintf('%d:%02d', intdiv($seconds, 60), $seconds % 60);
    }

    private function formatKm(float $km): string
    {
        if ($km >= 1000) {
            return number_format($km, 0);
        }

        return rtrim(rtrim(number_format($km, 1), '0'), '.');
    }
}
