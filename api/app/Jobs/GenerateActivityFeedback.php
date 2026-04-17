<?php

namespace App\Jobs;

use App\Ai\Agents\ActivityFeedbackAgent;
use App\Models\StravaActivity;
use App\Models\TrainingResult;
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
        $result = TrainingResult::with('trainingDay', 'stravaActivity.user.stravaToken')->find($this->trainingResultId);

        if (! $result || $result->ai_feedback) {
            return;
        }

        $response = ActivityFeedbackAgent::make()->prompt($this->buildPrompt($result, $splits));

        $result->update(['ai_feedback' => $response->text]);
    }

    private function buildPrompt(TrainingResult $result, StravaStreamSplits $splitsService): string
    {
        $day = $result->trainingDay;
        $activity = $result->stravaActivity;

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

    private function finegrainedSplitsLine(?StravaActivity $activity, StravaStreamSplits $splitsService): ?string
    {
        $token = $activity?->user?->stravaToken;
        if (! $activity || ! $token) {
            return null;
        }

        $splits = $splitsService->compute($token, $activity->strava_id, $activity->distance_meters);
        if (empty($splits)) {
            return null;
        }

        $bucketSize = $activity->distance_meters < 10000 ? 50 : 100;
        $samples = collect($splits)
            ->map(fn ($s) => $s['average_heart_rate'] !== null
                ? "{$this->pace($s['pace_seconds_per_km'])}@{$s['average_heart_rate']}"
                : $this->pace($s['pace_seconds_per_km']))
            ->implode(', ');

        return "Splits per {$bucketSize}m (pace/km @ avg HR): {$samples}.";
    }

    private function recentRuns(TrainingResult $result): ?string
    {
        $activity = $result->stravaActivity;
        if (! $activity) {
            return null;
        }

        $runs = StravaActivity::query()
            ->where('user_id', $activity->user_id)
            ->where('id', '!=', $activity->id)
            ->orderByDesc('start_date')
            ->limit(5)
            ->get();

        if ($runs->isEmpty()) {
            return null;
        }

        $summary = $runs->map(function (StravaActivity $r) {
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
        return $seconds > 0 ? sprintf('%d:%02d', intdiv($seconds, 60), $seconds % 60) : '—';
    }
}
