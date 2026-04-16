<?php

namespace App\Ai\Tools;

use App\Models\User;
use App\Services\StravaSyncService;
use Carbon\Carbon;
use Illuminate\Contracts\JsonSchema\JsonSchema;
use Illuminate\Support\Collection;
use Laravel\Ai\Contracts\Tool;
use Laravel\Ai\Tools\Request;

class SearchStravaActivities implements Tool
{
    private const MAX_PAGES = 10;

    public function __construct(private User $user, private StravaSyncService $stravaSyncService) {}

    public function description(): string
    {
        return <<<'DESC'
        Query the runner's Strava account for running activities within a specific date range. Auto-paginates to fetch ALL runs in the period (up to 300). Returns both individual run details AND pre-computed aggregates (totals, averages, trends).

        USE THIS for date-bounded queries like:
        - "How was April last year?" → after_date: 2025-04-01, before_date: 2025-05-01
        - "Last week's runs" → after_date: 7 days ago, before_date: today
        - "Compare this month to last month" → call twice with different date ranges
        - "Am I getting faster?" → call for recent period and older period, compare avg_pace
        - "Weekly volume since January" → after_date: 2026-01-01, before_date: today

        DO NOT use this for "my last run" or "most recent runs" without an implied period — use get_recent_runs instead. That tool is unambiguous and faster.

        For trend analysis, make multiple calls with different date ranges and compare the aggregates.
        DESC;
    }

    public function schema(JsonSchema $schema): array
    {
        return [
            'after_date' => $schema->string()->required()->description('Start of date range (inclusive) in YYYY-MM-DD format'),
            'before_date' => $schema->string()->required()->description('End of date range (exclusive) in YYYY-MM-DD format'),
        ];
    }

    public function handle(Request $request): string
    {
        $token = $this->user->stravaToken;

        if (! $token) {
            return json_encode(['message' => 'No Strava connection found. The runner needs to connect their Strava account.']);
        }

        $afterDate = Carbon::parse($request['after_date']);
        $beforeDate = Carbon::parse($request['before_date']);

        try {
            $allRuns = $this->fetchAllRuns($token, $afterDate->timestamp, $beforeDate->timestamp);
        } catch (\Exception $e) {
            return json_encode(['error' => 'Failed to fetch from Strava: '.$e->getMessage()]);
        }

        if ($allRuns->isEmpty()) {
            return json_encode([
                'message' => 'No running activities found between '.$afterDate->format('Y-m-d').' and '.$beforeDate->format('Y-m-d').'.',
                'period' => ['from' => $afterDate->format('Y-m-d'), 'to' => $beforeDate->format('Y-m-d')],
            ]);
        }

        $aggregates = $this->computeAggregates($allRuns, $afterDate, $beforeDate);

        // For large result sets (>20 runs), only include aggregates to save tokens
        $includeRuns = $allRuns->count() <= 20;

        $response = [
            'period' => [
                'from' => $afterDate->format('Y-m-d'),
                'to' => $beforeDate->format('Y-m-d'),
                'days' => $afterDate->diffInDays($beforeDate),
                'weeks' => round($afterDate->diffInDays($beforeDate) / 7, 1),
            ],
            'aggregates' => $aggregates,
        ];

        if ($includeRuns) {
            $response['runs'] = $allRuns->map(fn ($run) => $this->formatRun($run))->values()->toArray();
        } else {
            $response['note'] = 'Individual runs omitted because there are '.$allRuns->count().' runs. Use a narrower date range to see individual runs.';
        }

        return json_encode($response);
    }

    private function fetchAllRuns(mixed $token, int $after, int $before): Collection
    {
        $allActivities = collect();

        for ($page = 1; $page <= self::MAX_PAGES; $page++) {
            $activities = $this->stravaSyncService->fetchActivities($token, $page, 30, $after, $before);

            if (empty($activities)) {
                break;
            }

            $allActivities = $allActivities->concat($activities);

            if (count($activities) < 30) {
                break;
            }
        }

        return $allActivities->filter(fn ($a) => ($a['type'] ?? '') === 'Run');
    }

    private function computeAggregates(Collection $runs, Carbon $from, Carbon $to): array
    {
        $weeks = max(1, round($from->diffInDays($to) / 7, 1));

        $distances = $runs->map(fn ($r) => ($r['distance'] ?? 0) / 1000);
        $paces = $runs->map(function ($r) {
            $km = ($r['distance'] ?? 0) / 1000;

            return $km > 0 ? ($r['moving_time'] ?? 0) / $km : 0;
        })->filter(fn ($p) => $p > 0);
        $heartRates = $runs->pluck('average_heartrate')->filter();
        $durations = $runs->pluck('moving_time')->filter();
        $elevations = $runs->pluck('total_elevation_gain')->filter();

        $totalKm = round($distances->sum(), 1);
        $avgPace = $paces->isNotEmpty() ? (int) round($paces->avg()) : null;
        $fastestPace = $paces->isNotEmpty() ? (int) round($paces->min()) : null;
        $slowestPace = $paces->isNotEmpty() ? (int) round($paces->max()) : null;

        // Weekly breakdown for trend analysis
        $weeklyBreakdown = $runs->groupBy(fn ($r) => Carbon::parse($r['start_date'])->startOfWeek()->format('Y-m-d'))
            ->map(function ($weekRuns, $weekStart) {
                $weekDistances = $weekRuns->map(fn ($r) => ($r['distance'] ?? 0) / 1000);
                $weekPaces = $weekRuns->map(function ($r) {
                    $km = ($r['distance'] ?? 0) / 1000;

                    return $km > 0 ? ($r['moving_time'] ?? 0) / $km : 0;
                })->filter(fn ($p) => $p > 0);
                $avgPace = $weekPaces->isNotEmpty() ? (int) round($weekPaces->avg()) : null;

                return [
                    'week_of' => $weekStart,
                    'runs' => $weekRuns->count(),
                    'total_km' => round($weekDistances->sum(), 1),
                    'avg_pace' => $avgPace ? $this->formatPace($avgPace) : null,
                ];
            })
            ->sortKeys()
            ->values()
            ->toArray();

        return [
            'total_runs' => $runs->count(),
            'total_km' => $totalKm,
            'total_duration_hours' => round($durations->sum() / 3600, 1),
            'total_elevation_m' => round($elevations->sum(), 0),
            'avg_km_per_week' => round($totalKm / $weeks, 1),
            'avg_runs_per_week' => round($runs->count() / $weeks, 1),
            'avg_km_per_run' => round($distances->avg(), 1),
            'avg_pace' => $avgPace ? $this->formatPace($avgPace) : null,
            'avg_pace_seconds' => $avgPace,
            'fastest_pace' => $fastestPace ? $this->formatPace($fastestPace) : null,
            'slowest_pace' => $slowestPace ? $this->formatPace($slowestPace) : null,
            'longest_run_km' => round($distances->max(), 1),
            'shortest_run_km' => round($distances->min(), 1),
            'avg_heart_rate' => $heartRates->isNotEmpty() ? round($heartRates->avg(), 0) : null,
            'avg_duration_minutes' => round($durations->avg() / 60, 1),
            'weekly_breakdown' => $weeklyBreakdown,
        ];
    }

    private function formatRun(array $activity): array
    {
        $distanceKm = round(($activity['distance'] ?? 0) / 1000, 1);
        $movingTime = $activity['moving_time'] ?? 0;
        $paceSeconds = $distanceKm > 0 ? (int) round($movingTime / $distanceKm) : 0;

        return [
            'id' => $activity['id'] ?? null,
            'date' => Carbon::parse($activity['start_date'])->format('Y-m-d'),
            'day' => Carbon::parse($activity['start_date'])->format('l'),
            'name' => $activity['name'] ?? 'Unknown',
            'distance_km' => $distanceKm,
            'pace' => $this->formatPace($paceSeconds),
            'pace_seconds_per_km' => $paceSeconds,
            'duration_minutes' => round($movingTime / 60, 1),
            'avg_heart_rate' => isset($activity['average_heartrate']) ? round($activity['average_heartrate'], 0) : null,
            'elevation_gain_m' => $activity['total_elevation_gain'] ?? null,
        ];
    }

    private function formatPace(int $seconds): string
    {
        return floor($seconds / 60).':'.str_pad($seconds % 60, 2, '0', STR_PAD_LEFT).'/km';
    }
}
