<?php

namespace App\Ai\Tools;

use App\Models\User;
use App\Models\WearableActivity;
use Illuminate\Contracts\JsonSchema\JsonSchema;
use Illuminate\Support\Collection;
use Laravel\Ai\Contracts\Tool;
use Laravel\Ai\Tools\Request;

class GetRecentRuns implements Tool
{
    private const DEFAULT_LIMIT = 10;

    private const MAX_LIMIT = 50;

    public function __construct(private User $user) {}

    public function description(): string
    {
        return <<<'DESC'
        Fetch the runner's most recent runs from their synced activity history, ordered newest-first. No date input required.

        USE THIS for queries like:
        - "How was my last run?"
        - "Tell me about my recent runs"
        - "Show me my last 5 runs"
        - "What did I run this morning?" (still just "most recent")

        DO NOT use for date-range queries like "last week", "April 2025", "since January" — use search_activities instead.

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
        $limit = (int) ($request['limit'] ?? self::DEFAULT_LIMIT);
        $limit = max(1, min($limit, self::MAX_LIMIT));

        $runs = WearableActivity::query()
            ->where('user_id', $this->user->id)
            ->whereIn('type', WearableActivity::RUN_TYPES)
            ->orderByDesc('start_date')
            ->limit($limit)
            ->get();

        if ($runs->isEmpty()) {
            return json_encode([
                'message' => 'No running activities synced yet. The runner needs to connect Apple Health (or another wearable) and complete a few runs first.',
            ]);
        }

        return json_encode([
            'count' => $runs->count(),
            'aggregates' => $this->computeAggregates($runs),
            'runs' => $runs->map(fn (WearableActivity $r) => $this->formatRun($r))->values()->toArray(),
        ]);
    }

    private function computeAggregates(Collection $runs): array
    {
        $distancesKm = $runs->map(fn (WearableActivity $r) => $r->distance_meters / 1000);
        $paces = $runs->pluck('average_pace_seconds_per_km')->filter(fn ($p) => $p > 0);
        $avgPace = $paces->isNotEmpty() ? (int) round($paces->avg()) : null;

        return [
            'total_km' => round($distancesKm->sum(), 1),
            'avg_km_per_run' => round($distancesKm->avg(), 1),
            'avg_pace' => $avgPace ? $this->formatPace($avgPace) : null,
            'longest_run_km' => round($distancesKm->max(), 1),
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
