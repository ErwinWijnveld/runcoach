<?php

namespace App\Jobs;

use App\Models\StravaActivity;
use App\Models\User;
use App\Services\StravaSyncService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class SyncStravaHistory implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

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

        $after = now()->subMonths($this->months)->timestamp;
        $page = 1;

        do {
            $activities = $stravaSyncService->fetchActivities($token, $page, 30, $after);

            foreach ($activities as $activityData) {
                if ($activityData['type'] !== 'Run') {
                    continue;
                }

                StravaActivity::updateOrCreate(
                    ['strava_id' => $activityData['id']],
                    [
                        'user_id' => $user->id,
                        'type' => $activityData['type'],
                        'name' => $activityData['name'],
                        'distance_meters' => (int) $activityData['distance'],
                        'moving_time_seconds' => $activityData['moving_time'],
                        'elapsed_time_seconds' => $activityData['elapsed_time'],
                        'average_heartrate' => $activityData['average_heartrate'] ?? null,
                        'average_speed' => $activityData['average_speed'],
                        'start_date' => $activityData['start_date'],
                        'summary_polyline' => $activityData['map']['summary_polyline'] ?? null,
                        'raw_data' => $activityData,
                        'synced_at' => now(),
                    ]
                );
            }

            $page++;
        } while (count($activities) === 30);
    }
}
