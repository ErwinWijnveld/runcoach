<?php

namespace App\Jobs;

use App\Models\User;
use App\Models\WearableActivity;
use App\Services\ComplianceScoringService;
use App\Services\StravaSyncService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class ProcessStravaActivity implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(
        public int $userId,
        public int $stravaActivityId,
    ) {}

    public function handle(StravaSyncService $stravaSyncService, ComplianceScoringService $complianceService): void
    {
        $user = User::findOrFail($this->userId);
        $token = $user->stravaToken;

        if (! $token) {
            return;
        }

        $activityData = $stravaSyncService->fetchActivity($token, $this->stravaActivityId);

        if (! in_array($activityData['type'] ?? null, WearableActivity::RUN_TYPES, true)) {
            return;
        }

        $activity = WearableActivity::updateOrCreate(
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

        $complianceService->matchAndScore($user, $activity);

        $result = $activity->fresh()->trainingResults()->first();
        if ($result) {
            GenerateActivityFeedback::dispatch($result->id);
            GenerateWeeklyInsight::dispatch($result->trainingDay->training_week_id);
        }
    }
}
