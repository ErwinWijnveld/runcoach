<?php

namespace App\Jobs;

use App\Ai\Agents\ActivityFeedbackAgent;
use App\Models\TrainingResult;
use App\Models\WearableActivity;
use App\Services\StravaStreamSplits;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class GenerateActivityFeedback implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(public int $trainingResultId) {}

    public function handle(StravaStreamSplits $splits): void
    {
        $result = TrainingResult::with('trainingDay', 'wearableActivity.user.stravaToken')->find($this->trainingResultId);

        if (! $result || $result->ai_feedback) {
            return;
        }

        $response = ActivityFeedbackAgent::make()->prompt($this->buildPrompt($result, $splits));

        $result->update(['ai_feedback' => $response->text]);
    }

    private function buildPrompt(TrainingResult $result, StravaStreamSplits $splitsService): string
    {
        $day = $result->trainingDay;
        $activity = $result->wearableActivity;

        $target = collect([
            $day->target_km !== null ? "{$day->target_km}km" : null,
            $day->target_pace_seconds_per_km !== null ? $this->pace($day->target_pace_seconds_per_km).'/km' : null,
            $day->target_heart_rate_zone !== null ? "HR zone {$day->target_heart_rate_zone}" : null,
        ])->filter()->implode(', ');

        $actualHr = $result->actual_avg_heart_rate !== null ? ", avg HR {$result->actual_avg_heart_rate}" : '';
        $hrScore = $result->heart_rate_score !== null ? ", HR {$result->heart_rate_score}/10" : '';
        $splitsLine = $this->finegrainedSplitsLine($activity, $splitsService);

        return collect([
            "Training: {$day->title} ({$day->type->value}).",
            $target !== '' ? "Target: {$target}." : null,
            "Actual: {$result->actual_km}km at {$this->pace($result->actual_pace_seconds_per_km)}/km{$actualHr}.",
            "Scores: compliance {$result->compliance_score}/10, pace {$result->pace_score}/10, distance {$result->distance_score}/10{$hrScore}.",
            $splitsLine,
            $this->recentRuns($result),
        ])->filter()->implode("\n");
    }

    private function finegrainedSplitsLine(?WearableActivity $activity, StravaStreamSplits $splitsService): ?string
    {
        // Splits via Strava's streams API only work for source='strava'
        // activities (we have the user's OAuth token). Other sources (Apple
        // HealthKit, Open Wearables) carry their own pre-computed splits in
        // raw_data and will be handled separately when those paths land.
        if (! $activity || $activity->source !== 'strava') {
            return null;
        }

        $token = $activity->user?->stravaToken;
        if (! $token) {
            return null;
        }

        $segments = $splitsService->compute(
            $token,
            (int) $activity->source_activity_id,
            $activity->distance_meters,
        );
        if (empty($segments)) {
            return null;
        }

        $rendered = collect($segments)->map(function (array $s) {
            $duration = $this->duration($s['duration_seconds']);
            $pace = $this->pace($s['pace_seconds_per_km']);
            $hr = $s['average_heart_rate'] !== null ? " HR {$s['average_heart_rate']}" : '';

            return "{$duration} @ {$pace}/km{$hr}";
        })->implode('; ');

        return "Splits: {$rendered}.";
    }

    private function duration(int $seconds): string
    {
        if ($seconds <= 0) {
            return '0s';
        }

        $mm = intdiv($seconds, 60);
        $ss = $seconds % 60;

        return $mm > 0 ? sprintf('%dm%02ds', $mm, $ss) : sprintf('%ds', $ss);
    }

    private function recentRuns(TrainingResult $result): ?string
    {
        $activity = $result->wearableActivity;
        if (! $activity) {
            return null;
        }

        $runs = WearableActivity::query()
            ->where('user_id', $activity->user_id)
            ->where('id', '!=', $activity->id)
            ->orderByDesc('start_date')
            ->limit(10)
            ->get();

        if ($runs->isEmpty()) {
            return null;
        }

        $summary = $runs->map(function (WearableActivity $r) {
            $km = round($r->distance_meters / 1000, 1);
            $line = "{$km}km @ {$this->pace($r->paceSecondsPerKm())}/km";
            if ($r->average_heartrate !== null) {
                $line .= ", HR {$r->average_heartrate}";
            }

            return "{$line}, {$r->start_date->format('Y-m-d')}";
        })->implode('; ');

        return "Recent runs (most recent first): {$summary}.";
    }

    private function pace(int $seconds): string
    {
        return $seconds > 0 ? sprintf('%d:%02d', intdiv($seconds, 60), $seconds % 60) : '-';
    }
}
