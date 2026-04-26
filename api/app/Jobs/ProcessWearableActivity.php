<?php

namespace App\Jobs;

use App\Models\WearableActivity;
use App\Services\ComplianceScoringService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

/**
 * Run after a wearable activity is ingested via POST /wearable/activities.
 * Filters to runs only, matches the activity against the user's active
 * training schedule, scores compliance, and queues per-run AI feedback +
 * weekly insight regeneration when a match lands.
 *
 * Idempotent: the underlying ComplianceScoringService::matchAndScore returns
 * null if a TrainingResult already exists for this activity, so re-pushing
 * the same workout is a no-op.
 */
class ProcessWearableActivity implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(public int $wearableActivityId) {}

    public function handle(ComplianceScoringService $compliance): void
    {
        $activity = WearableActivity::find($this->wearableActivityId);

        if (! $activity || ! in_array($activity->type, WearableActivity::RUN_TYPES, true)) {
            return;
        }

        $user = $activity->user;
        if (! $user) {
            return;
        }

        $compliance->matchAndScore($user, $activity);

        $result = $activity->fresh()->trainingResults()->first();
        if ($result) {
            GenerateActivityFeedback::dispatch($result->id);
            GenerateWeeklyInsight::dispatch($result->trainingDay->training_week_id);
        }
    }
}
