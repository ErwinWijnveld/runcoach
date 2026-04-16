<?php

namespace App\Ai\Tools;

use App\Models\User;
use App\Services\StravaSyncService;
use Illuminate\Contracts\JsonSchema\JsonSchema;
use Laravel\Ai\Contracts\Tool;
use Laravel\Ai\Tools\Request;

class GetActivityDetails implements Tool
{
    public function __construct(private User $user, private StravaSyncService $stravaSyncService) {}

    public function description(): string
    {
        return <<<'DESC'
        Fetch detailed data for a single run — per-kilometer splits, laps, average/max heart rate, and elevation profile summary.

        USE THIS for queries like:
        - "Show me the pace progression of my last run" (1st km, 2nd km, etc.)
        - "What was my HR curve?"
        - "How were my splits on Saturday?"
        - "Did I negative split?"
        - "Break down the laps on my interval session"

        WORKFLOW: First call get_recent_runs or search_strava_activities to find the run's `id`. Then pass that id here.

        Returns `splits_metric` (auto 1km splits from Strava with per-km pace, HR, elevation diff), `laps` (if the athlete recorded them), and summary stats.
        DESC;
    }

    public function schema(JsonSchema $schema): array
    {
        return [
            'activity_id' => $schema->integer()
                ->required()
                ->description('The Strava activity id. Get this from the `id` field in a get_recent_runs or search_strava_activities response.'),
        ];
    }

    public function handle(Request $request): string
    {
        $token = $this->user->stravaToken;

        if (! $token) {
            return json_encode(['message' => 'No Strava connection found. The runner needs to connect their Strava account.']);
        }

        $activityId = (int) $request['activity_id'];

        try {
            $activity = $this->stravaSyncService->fetchActivity($token, $activityId);
        } catch (\Exception $e) {
            return json_encode(['error' => 'Failed to fetch activity from Strava: '.$e->getMessage()]);
        }

        return json_encode([
            'summary' => $this->formatSummary($activity),
            'splits_metric' => $this->formatSplits($activity['splits_metric'] ?? []),
            'laps' => $this->formatLaps($activity['laps'] ?? []),
        ]);
    }

    private function formatSummary(array $activity): array
    {
        $distanceKm = round(($activity['distance'] ?? 0) / 1000, 2);
        $movingTime = $activity['moving_time'] ?? 0;
        $paceSeconds = $distanceKm > 0 ? (int) round($movingTime / $distanceKm) : 0;

        return [
            'id' => $activity['id'] ?? null,
            'name' => $activity['name'] ?? 'Unknown',
            'type' => $activity['type'] ?? null,
            'date' => isset($activity['start_date']) ? substr($activity['start_date'], 0, 10) : null,
            'distance_km' => $distanceKm,
            'duration_minutes' => round($movingTime / 60, 1),
            'avg_pace' => $this->formatPace($paceSeconds),
            'avg_heart_rate' => isset($activity['average_heartrate']) ? round($activity['average_heartrate'], 0) : null,
            'max_heart_rate' => isset($activity['max_heartrate']) ? round($activity['max_heartrate'], 0) : null,
            'total_elevation_gain_m' => $activity['total_elevation_gain'] ?? null,
            'has_heartrate' => $activity['has_heartrate'] ?? false,
            'average_cadence' => $activity['average_cadence'] ?? null,
        ];
    }

    /**
     * @param  array<int, array<string, mixed>>  $splits
     * @return array<int, array<string, mixed>>
     */
    private function formatSplits(array $splits): array
    {
        return collect($splits)->map(function (array $split) {
            $distanceM = $split['distance'] ?? 0;
            $movingTime = $split['moving_time'] ?? 0;
            $distanceKm = $distanceM / 1000;
            $paceSeconds = $distanceKm > 0 ? (int) round($movingTime / $distanceKm) : 0;

            return [
                'split' => $split['split'] ?? null,
                'distance_km' => round($distanceKm, 2),
                'moving_time_seconds' => $movingTime,
                'pace' => $this->formatPace($paceSeconds),
                'pace_seconds_per_km' => $paceSeconds,
                'elevation_difference_m' => $split['elevation_difference'] ?? null,
                'average_heart_rate' => isset($split['average_heartrate']) ? round($split['average_heartrate'], 0) : null,
                'pace_zone' => $split['pace_zone'] ?? null,
            ];
        })->values()->toArray();
    }

    /**
     * @param  array<int, array<string, mixed>>  $laps
     * @return array<int, array<string, mixed>>
     */
    private function formatLaps(array $laps): array
    {
        return collect($laps)->map(function (array $lap) {
            $distanceM = $lap['distance'] ?? 0;
            $movingTime = $lap['moving_time'] ?? 0;
            $distanceKm = $distanceM / 1000;
            $paceSeconds = $distanceKm > 0 ? (int) round($movingTime / $distanceKm) : 0;

            return [
                'lap' => $lap['lap_index'] ?? null,
                'name' => $lap['name'] ?? null,
                'distance_km' => round($distanceKm, 2),
                'moving_time_seconds' => $movingTime,
                'pace' => $this->formatPace($paceSeconds),
                'average_heart_rate' => isset($lap['average_heartrate']) ? round($lap['average_heartrate'], 0) : null,
                'max_heart_rate' => isset($lap['max_heartrate']) ? round($lap['max_heartrate'], 0) : null,
                'total_elevation_gain_m' => $lap['total_elevation_gain'] ?? null,
            ];
        })->values()->toArray();
    }

    private function formatPace(int $seconds): string
    {
        if ($seconds <= 0) {
            return '—';
        }

        return floor($seconds / 60).':'.str_pad($seconds % 60, 2, '0', STR_PAD_LEFT).'/km';
    }
}
