<?php

namespace App\Jobs;

use App\Models\User;
use App\Models\WearableActivity;
use App\Services\StravaSyncService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Encryption\DecryptException;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class SyncStravaHistory implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 1;

    public function __construct(
        public int $userId,
        public int $months = 3,
    ) {}

    public function handle(StravaSyncService $stravaSyncService): void
    {
        $user = User::findOrFail($this->userId);
        $token = $user->stravaToken;

        if (! $token) {
            return;
        }

        try {
            $token->access_token;
        } catch (DecryptException $e) {
            logger()->warning("Strava token for user {$user->id} is unreadable (APP_KEY mismatch). Deleting so user can re-auth.", [
                'user_id' => $user->id,
            ]);
            $token->delete();

            return;
        }

        $after = now()->subMonths($this->months)->timestamp;
        $page = 1;

        do {
            $activities = $stravaSyncService->fetchActivities($token, $page, 30, $after);

            foreach ($activities as $activityData) {
                if ($activityData['type'] !== 'Run') {
                    continue;
                }

                WearableActivity::updateOrCreate(
                    [
                        'source' => 'strava',
                        'source_activity_id' => (string) $activityData['id'],
                    ],
                    [
                        'user_id' => $user->id,
                        'source_user_id' => isset($activityData['athlete']['id']) ? (string) $activityData['athlete']['id'] : null,
                        'type' => $activityData['type'],
                        'name' => $activityData['name'] ?? null,
                        'distance_meters' => (int) $activityData['distance'],
                        'duration_seconds' => (int) $activityData['moving_time'],
                        'elapsed_seconds' => (int) $activityData['elapsed_time'],
                        'average_pace_seconds_per_km' => $activityData['distance'] > 0
                            ? (int) round($activityData['moving_time'] / ($activityData['distance'] / 1000))
                            : 0,
                        'average_heartrate' => $activityData['average_heartrate'] ?? null,
                        'max_heartrate' => $activityData['max_heartrate'] ?? null,
                        'elevation_gain_meters' => isset($activityData['total_elevation_gain']) ? (int) round($activityData['total_elevation_gain']) : null,
                        'calories_kcal' => isset($activityData['calories']) ? (int) round($activityData['calories']) : null,
                        'start_date' => $activityData['start_date'],
                        'raw_data' => $activityData,
                        'synced_at' => now(),
                    ]
                );
            }

            $page++;
        } while (count($activities) === 30);
    }
}
