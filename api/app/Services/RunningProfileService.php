<?php

namespace App\Services;

use App\Models\User;
use App\Models\UserRunningProfile;
use App\Services\Strava\StravaClient;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;
use OpenAI\Contracts\ClientContract as OpenAIClient;

class RunningProfileService
{
    public function __construct(
        private readonly StravaClient $strava,
        private readonly OpenAIClient $openai,
    ) {}

    public function analyze(User $user): UserRunningProfile
    {
        $end = now();
        $start = now()->subYear();

        $activities = $this->strava->fetchActivitiesInRange($user, $start, $end);
        $runs = array_filter($activities, fn ($a) => ($a['type'] ?? '') === 'Run');

        $profile = $this->computeMetrics($user, array_values($runs));
        $profile->narrative_summary = $this->generateNarrative($profile->metrics);
        $profile->analyzed_at = now();
        $profile->data_start_date = $start;
        $profile->data_end_date = $end;
        $profile->save();

        return $profile;
    }

    public function computeMetrics(User $user, array $runs): UserRunningProfile
    {
        $metrics = $this->aggregate($runs);

        return UserRunningProfile::updateOrCreate(
            ['user_id' => $user->id],
            ['metrics' => $metrics],
        );
    }

    /**
     * @param  array<int, array<string, mixed>>  $runs
     * @return array<string, mixed>
     */
    private function aggregate(array $runs): array
    {
        $totalRuns = count($runs);
        $totalMeters = array_sum(array_column($runs, 'distance'));
        $totalSeconds = array_sum(array_column($runs, 'moving_time'));
        $totalKm = round($totalMeters / 1000, 1);

        $weeks = 52;
        $weeklyAvgKm = $totalRuns === 0 ? 0.0 : round($totalKm / $weeks, 1);
        $weeklyAvgRuns = $totalRuns === 0 ? 0 : (int) round($totalRuns / $weeks);

        $avgPace = $totalMeters === 0 ? 0 : (int) round($totalSeconds / ($totalMeters / 1000));
        $avgDuration = $totalRuns === 0 ? 0 : (int) round($totalSeconds / $totalRuns);

        $weeksWithRuns = [];
        foreach ($runs as $run) {
            $weeksWithRuns[Carbon::parse($run['start_date'])->format('o-W')] = true;
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
            'long_run_trend' => $this->trend($runs, fn ($r) => $r['distance']),
            'pace_trend' => $this->paceTrend($runs),
        ];
    }

    private function trend(array $runs, callable $metric): string
    {
        if (count($runs) < 10) {
            return 'flat';
        }

        $first = array_slice($runs, 0, (int) floor(count($runs) / 2));
        $last = array_slice($runs, (int) floor(count($runs) / 2));
        $avgFirst = array_sum(array_map($metric, $first)) / max(1, count($first));
        $avgLast = array_sum(array_map($metric, $last)) / max(1, count($last));

        if ($avgLast > $avgFirst * 1.05) {
            return 'improving';
        }
        if ($avgLast < $avgFirst * 0.95) {
            return 'declining';
        }

        return 'flat';
    }

    private function paceTrend(array $runs): string
    {
        if (count($runs) < 10) {
            return 'flat';
        }

        return $this->trend($runs, fn ($r) => $r['distance'] > 0 ? $r['moving_time'] / $r['distance'] : 0);
    }

    private function generateNarrative(array $metrics): string
    {
        try {
            $response = $this->openai->chat()->create([
                'model' => config('services.openai.narrative_model', 'gpt-4o-mini'),
                'temperature' => 0.4,
                'messages' => [
                    [
                        'role' => 'system',
                        'content' => 'You are a running coach summarising 12 months of activity in ONE short paragraph (max 3 sentences). Mention consistency, pace feel, and progression. Do NOT invent numbers — only refer to what is in the metrics.',
                    ],
                    [
                        'role' => 'user',
                        'content' => 'Metrics: '.json_encode($metrics),
                    ],
                ],
            ]);

            $text = trim($response->choices[0]->message->content ?? '');

            return $text !== '' ? $text : "Here's your last 12 months.";
        } catch (\Throwable $e) {
            Log::warning('Narrative generation failed', ['error' => $e->getMessage()]);

            return "Here's your last 12 months.";
        }
    }

    /** @internal — exposed for testing only */
    public function generateNarrativePublic(array $metrics): string
    {
        return $this->generateNarrative($metrics);
    }
}
