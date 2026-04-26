<?php

namespace App\Ai\Tools;

use App\Models\User;
use App\Models\WearableActivity;
use Carbon\Carbon;
use Illuminate\Contracts\JsonSchema\JsonSchema;
use Illuminate\Support\Collection;
use Laravel\Ai\Contracts\Tool;
use Laravel\Ai\Tools\Request;

class SearchActivities implements Tool
{
    public function __construct(private User $user) {}

    public function description(): string
    {
        return <<<'DESC'
        Query the runner's local activity history within a specific date range. Returns BOTH individual run details AND pre-computed aggregates (totals, averages, weekly breakdown, trends).

        USE THIS for date-bounded queries like:
        - "How was April last year?" → after_date: 2025-04-01, before_date: 2025-05-01
        - "Last week's runs" → after_date: 7 days ago, before_date: today
        - "Compare this month to last month" → call twice with different date ranges
        - "Am I getting faster?" → call for recent period and older period, compare avg_pace
        - "Weekly volume since January" → after_date: 2026-01-01, before_date: today

        DO NOT use for "my last run" or "most recent runs" without an implied period — use get_recent_runs instead.

        For trend analysis, make multiple calls with different date ranges and compare the aggregates.
        DESC;
    }

    public function schema(JsonSchema $schema): array
    {
        return [
            'after_date' => $schema->string()->required()->description('Start of date range (inclusive) in YYYY-MM-DD format, e.g. "2026-01-01".'),
            'before_date' => $schema->string()->required()->description('End of date range (exclusive) in YYYY-MM-DD format, e.g. "2026-04-01".'),
        ];
    }

    public function handle(Request $request): string
    {
        $afterDate = Carbon::parse($request['after_date']);
        $beforeDate = Carbon::parse($request['before_date']);

        $runs = WearableActivity::query()
            ->where('user_id', $this->user->id)
            ->whereIn('type', WearableActivity::RUN_TYPES)
            ->whereBetween('start_date', [$afterDate, $beforeDate])
            ->orderBy('start_date')
            ->get();

        if ($runs->isEmpty()) {
            return json_encode([
                'message' => 'No running activities found between '.$afterDate->format('Y-m-d').' and '.$beforeDate->format('Y-m-d').'.',
                'period' => ['from' => $afterDate->format('Y-m-d'), 'to' => $beforeDate->format('Y-m-d')],
            ]);
        }

        $aggregates = $this->computeAggregates($runs, $afterDate, $beforeDate);

        // 150 runs = ~7KB JSON ≈ ~2k tokens. Below that, hand the agent every
        // run so it can answer "fastest 5k ever?" / "longest run last year?"
        // / "show every run > 10km" without further drill-downs. Above 150,
        // tell it to narrow the window — almost no realistic query needs
        // individual visibility into >150 runs at once.
        $includeRuns = $runs->count() <= 150;

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
            $response['runs'] = $runs->map(fn (WearableActivity $r) => $this->formatRun($r))->values()->toArray();
        } else {
            $response['note'] = 'Individual runs omitted because there are '.$runs->count().' runs. Use a narrower date range to see individual runs.';
        }

        return json_encode($response);
    }

    private function computeAggregates(Collection $runs, Carbon $from, Carbon $to): array
    {
        $weeks = max(1, round($from->diffInDays($to) / 7, 1));

        $distancesKm = $runs->map(fn (WearableActivity $r) => $r->distance_meters / 1000);
        $paces = $runs->pluck('average_pace_seconds_per_km')->filter(fn ($p) => $p > 0);
        $heartRates = $runs->pluck('average_heartrate')->filter();
        $durations = $runs->pluck('duration_seconds')->filter();
        $elevations = $runs->pluck('elevation_gain_meters')->filter();

        $totalKm = round($distancesKm->sum(), 1);
        $avgPace = $paces->isNotEmpty() ? (int) round($paces->avg()) : null;
        $fastestPace = $paces->isNotEmpty() ? (int) round($paces->min()) : null;
        $slowestPace = $paces->isNotEmpty() ? (int) round($paces->max()) : null;

        // Weekly breakdown for trend analysis
        $weeklyBreakdown = $runs->groupBy(fn (WearableActivity $r) => $r->start_date->copy()->startOfWeek()->format('Y-m-d'))
            ->map(function (Collection $weekRuns, string $weekStart) {
                $weekDistances = $weekRuns->map(fn (WearableActivity $r) => $r->distance_meters / 1000);
                $weekPaces = $weekRuns->pluck('average_pace_seconds_per_km')->filter(fn ($p) => $p > 0);
                $weekAvgPace = $weekPaces->isNotEmpty() ? (int) round($weekPaces->avg()) : null;

                return [
                    'week_of' => $weekStart,
                    'runs' => $weekRuns->count(),
                    'total_km' => round($weekDistances->sum(), 1),
                    'avg_pace' => $weekAvgPace ? $this->formatPace($weekAvgPace) : null,
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
            'avg_km_per_run' => round($distancesKm->avg(), 1),
            'avg_pace' => $avgPace ? $this->formatPace($avgPace) : null,
            'avg_pace_seconds' => $avgPace,
            'fastest_pace' => $fastestPace ? $this->formatPace($fastestPace) : null,
            'slowest_pace' => $slowestPace ? $this->formatPace($slowestPace) : null,
            'longest_run_km' => round($distancesKm->max(), 1),
            'shortest_run_km' => round($distancesKm->min(), 1),
            'avg_heart_rate' => $heartRates->isNotEmpty() ? round($heartRates->avg(), 0) : null,
            'avg_duration_minutes' => round($durations->avg() / 60, 1),
            'weekly_breakdown' => $weeklyBreakdown,
        ];
    }

    private function formatRun(WearableActivity $run): array
    {
        return [
            'id' => $run->id,
            'date' => $run->start_date->format('Y-m-d'),
            'day' => $run->start_date->format('l'),
            'name' => $run->name ?? 'Run',
            'distance_km' => round($run->distance_meters / 1000, 1),
            'pace' => $this->formatPace($run->average_pace_seconds_per_km),
            'pace_seconds_per_km' => $run->average_pace_seconds_per_km,
            'duration_minutes' => round($run->duration_seconds / 60, 1),
            'avg_heart_rate' => $run->average_heartrate !== null ? round((float) $run->average_heartrate) : null,
            'elevation_gain_m' => $run->elevation_gain_meters,
        ];
    }

    private function formatPace(int $seconds): string
    {
        return floor($seconds / 60).':'.str_pad((string) ($seconds % 60), 2, '0', STR_PAD_LEFT).'/km';
    }
}
