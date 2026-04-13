<?php

namespace App\Jobs;

use App\Models\StravaActivity;
use App\Models\User;
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

        if ($activityData['type'] !== 'Run') {
            return;
        }

        $activity = StravaActivity::updateOrCreate(
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

        $complianceService->matchAndScore($user, $activity);

        $result = $activity->fresh()->trainingResults()->first();
        if ($result) {
            GenerateActivityFeedback::dispatch($result->id);
            GenerateWeeklyInsight::dispatch($result->trainingDay->training_week_id);
        }
    }
}
