<?php

namespace App\Ai\Tools;

use App\Models\User;
use App\Models\WearableActivity;
use Illuminate\Contracts\JsonSchema\JsonSchema;
use Laravel\Ai\Contracts\Tool;
use Laravel\Ai\Tools\Request;

class GetActivityDetails implements Tool
{
    public function __construct(private User $user) {}

    public function description(): string
    {
        return <<<'DESC'
        Fetch detailed data for a single run from the runner's synced history — summary stats plus any per-segment splits the source supplied (Apple HealthKit pushes 1km splits when the workout was recorded with the Workout app on Apple Watch).

        USE THIS for queries like:
        - "Show me the pace progression of my last run"
        - "What was my HR curve?"
        - "How were my splits on Saturday?"
        - "Did I negative split?"
        - "Break down the laps on my interval session"

        WORKFLOW: First call get_recent_runs or search_activities to find the run's `id`. Then pass that id here.

        Returns `summary` (stats) plus `splits` (1km segments if source supplied them, otherwise empty).
        DESC;
    }

    public function schema(JsonSchema $schema): array
    {
        return [
            'activity_id' => $schema->integer()
                ->required()
                ->description('The local activity id (`id` field from get_recent_runs or search_activities).'),
        ];
    }

    public function handle(Request $request): string
    {
        $activityId = (int) $request['activity_id'];

        $activity = WearableActivity::query()
            ->where('user_id', $this->user->id)
            ->find($activityId);

        if (! $activity) {
            return json_encode(['error' => "No activity found with id {$activityId} for this runner."]);
        }

        return json_encode([
            'summary' => $this->formatSummary($activity),
            'splits' => $this->extractSplits($activity),
        ]);
    }

    private function formatSummary(WearableActivity $activity): array
    {
        return [
            'id' => $activity->id,
            'name' => $activity->name ?? 'Run',
            'type' => $activity->type,
            'source' => $activity->source,
            'date' => $activity->start_date->format('Y-m-d'),
            'distance_km' => round($activity->distance_meters / 1000, 2),
            'duration_minutes' => round($activity->duration_seconds / 60, 1),
            'avg_pace' => $this->formatPace($activity->average_pace_seconds_per_km),
            'avg_heart_rate' => $activity->average_heartrate !== null ? round((float) $activity->average_heartrate) : null,
            'max_heart_rate' => $activity->max_heartrate !== null ? round((float) $activity->max_heartrate) : null,
            'total_elevation_gain_m' => $activity->elevation_gain_meters,
            'calories_kcal' => $activity->calories_kcal,
        ];
    }

    /**
     * Pull pre-computed splits/segments out of `raw_data` if the ingestion
     * pipeline stored them. Conventions across sources:
     *  - Apple HealthKit (via the Flutter app's Swift bridge): `raw_data.splits[]`
     *    each `{distance_m, duration_seconds, pace_seconds_per_km, average_heart_rate?}`.
     *  - Open Wearables (later): same shape, populated from their workout
     *    detail endpoint.
     * Returns an empty array when no splits are available.
     *
     * @return array<int, array<string, mixed>>
     */
    private function extractSplits(WearableActivity $activity): array
    {
        $splits = $activity->raw_data['splits'] ?? null;

        if (! is_array($splits)) {
            return [];
        }

        return array_values(array_map(fn (array $s) => [
            'duration_seconds' => (int) ($s['duration_seconds'] ?? 0),
            'distance_m' => (int) ($s['distance_m'] ?? 0),
            'pace_seconds_per_km' => (int) ($s['pace_seconds_per_km'] ?? 0),
            'average_heart_rate' => isset($s['average_heart_rate']) ? (int) $s['average_heart_rate'] : null,
        ], $splits));
    }

    private function formatPace(int $seconds): string
    {
        if ($seconds <= 0) {
            return '-';
        }

        return floor($seconds / 60).':'.str_pad((string) ($seconds % 60), 2, '0', STR_PAD_LEFT).'/km';
    }
}
