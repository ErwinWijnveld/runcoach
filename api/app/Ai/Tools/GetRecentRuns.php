<?php

namespace App\Ai\Tools;

use App\Models\User;
use App\Services\StravaSyncService;
use Carbon\Carbon;
use Illuminate\Contracts\JsonSchema\JsonSchema;
use Illuminate\Support\Collection;
use Laravel\Ai\Contracts\Tool;
use Laravel\Ai\Tools\Request;

class GetRecentRuns implements Tool
{
    private const DEFAULT_LIMIT = 10;

    private const MAX_LIMIT = 50;

    private const FETCH_PAGE_SIZE = 30;

    private const MAX_PAGES = 3;

    public function __construct(private User $user, private StravaSyncService $stravaSyncService) {}

    public function description(): string
    {
        return <<<'DESC'
        Fetch the runner's most recent runs from Strava, ordered newest-first. No date input required.

        USE THIS for queries like:
        - "How was my last run?"
        - "Tell me about my recent runs"
        - "Show me my last 5 runs"
        - "What did I run this morning?" (still just "most recent")

        DO NOT use for date-range queries like "last week", "April 2025", "since January" — use search_strava_activities instead.

        Returns individual run details plus lightweight aggregates (total_km, avg_pace).
        DESC;
    }

    public function schema(JsonSchema $schema): array
    {
        return [
            'limit' => $schema->integer()
                ->required()
                ->nullable()
                ->description('How many most recent runs to return. Default 10 if null. Max 50.'),
        ];
    }

    public function handle(Request $request): string
    {
        $token = $this->user->stravaToken;

        if (! $token) {
            return json_encode(['message' => 'No Strava connection found. The runner needs to connect their Strava account.']);
        }

        $limit = (int) ($request['limit'] ?? self::DEFAULT_LIMIT);
        $limit = max(1, min($limit, self::MAX_LIMIT));

        try {
            $runs = $this->collectRecentRuns($token, $limit);
        } catch (\Exception $e) {
            return json_encode(['error' => 'Failed to fetch from Strava: '.$e->getMessage()]);
        }

        if ($runs->isEmpty()) {
            return json_encode([
                'message' => 'No running activities found in the last '.self::MAX_PAGES * self::FETCH_PAGE_SIZE.' Strava activities. The runner may be doing other sports (cycling, strength, etc.) lately. Try search_strava_activities with a wider date range to find older runs.',
            ]);
        }

        return json_encode([
            'count' => $runs->count(),
            'aggregates' => $this->computeAggregates($runs),
            'runs' => $runs->map(fn ($run) => $this->formatRun($run))->values()->toArray(),
        ]);
    }

    private function collectRecentRuns(mixed $token, int $limit): Collection
    {
        $runs = collect();

        for ($page = 1; $page <= self::MAX_PAGES; $page++) {
            $activities = $this->stravaSyncService->fetchActivities($token, $page, self::FETCH_PAGE_SIZE);

            if (empty($activities)) {
                break;
            }

            $runs = $runs->concat(
                collect($activities)->filter(fn ($a) => ($a['type'] ?? '') === 'Run')
            );

            if ($runs->count() >= $limit) {
                break;
            }

            if (count($activities) < self::FETCH_PAGE_SIZE) {
                break;
            }
        }

        return $runs->take($limit)->values();
    }

    private function computeAggregates(Collection $runs): array
    {
        $distances = $runs->map(fn ($r) => ($r['distance'] ?? 0) / 1000);
        $paces = $runs->map(function ($r) {
            $km = ($r['distance'] ?? 0) / 1000;

            return $km > 0 ? ($r['moving_time'] ?? 0) / $km : 0;
        })->filter(fn ($p) => $p > 0);

        $avgPace = $paces->isNotEmpty() ? (int) round($paces->avg()) : null;

        return [
            'total_km' => round($distances->sum(), 1),
            'avg_km_per_run' => round($distances->avg(), 1),
            'avg_pace' => $avgPace ? $this->formatPace($avgPace) : null,
            'longest_run_km' => round($distances->max(), 1),
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
