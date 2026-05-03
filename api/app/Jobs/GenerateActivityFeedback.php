<?php

namespace App\Jobs;

use App\Ai\Agents\ActivityFeedbackAgent;
use App\Enums\TrainingType;
use App\Models\TrainingResult;
use App\Models\WearableActivity;
use App\Notifications\WorkoutAnalyzed;
use App\Services\PaceAdjustmentEvaluator;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class GenerateActivityFeedback implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(public int $trainingResultId) {}

    public function handle(): void
    {
        $result = TrainingResult::with('trainingDay', 'wearableActivity')->find($this->trainingResultId);

        if (! $result || $result->ai_feedback) {
            return;
        }

        $response = ActivityFeedbackAgent::make()->prompt($this->buildPrompt($result));

        $result->update(['ai_feedback' => $response->text]);

        // Push BEFORE evaluator so a downstream throw can't drop it. Once
        // ai_feedback is set, the early-return at the top of handle() makes
        // a job retry a no-op — meaning whatever runs last in the success
        // path is "all-or-nothing" on retry. The push is user-visible and
        // critical; the evaluator is opportunistic. Order them accordingly.
        $user = $result->wearableActivity?->user;
        if ($user) {
            $user->notify(new WorkoutAnalyzed($result->id));
        }

        // Evaluator failures are non-fatal: log and move on so a brittle
        // edge case in pace-adjustment heuristics can't take down the AI
        // feedback pipeline.
        try {
            app(PaceAdjustmentEvaluator::class)->evaluate($result);
        } catch (\Throwable $e) {
            report($e);
        }
    }

    private function buildPrompt(TrainingResult $result): string
    {
        $day = $result->trainingDay;

        $isInterval = $day->type === TrainingType::Interval;
        // Day-level target_pace is null on interval days (the work pace lives
        // per segment); surface the work-set average instead so the agent
        // has something to talk about. The label "work-set avg" is in the
        // text so the model doesn't conflate it with a full-run target.
        $paceLabel = $isInterval
            ? (($workAvg = $day->workSetAveragePaceSecondsPerKm()) !== null
                ? $this->pace($workAvg).'/km work-set avg'
                : null)
            : ($day->target_pace_seconds_per_km !== null
                ? $this->pace($day->target_pace_seconds_per_km).'/km'
                : null);

        $target = collect([
            $day->target_km !== null ? "{$day->target_km}km" : null,
            $paceLabel,
            $day->target_heart_rate_zone !== null ? "HR zone {$day->target_heart_rate_zone}" : null,
        ])->filter()->implode(', ');

        $actualHr = $result->actual_avg_heart_rate !== null ? ", avg HR {$result->actual_avg_heart_rate}" : '';

        // Pace score is null on interval days — the full-run avg pace mixes
        // work + recovery so we don't score it. Compose the scores line
        // dynamically so we never print "pace null/10".
        $scoreParts = ["compliance {$result->compliance_score}/10"];
        if ($result->pace_score !== null) {
            $scoreParts[] = "pace {$result->pace_score}/10";
        }
        $scoreParts[] = "distance {$result->distance_score}/10";
        if ($result->heart_rate_score !== null) {
            $scoreParts[] = "HR {$result->heart_rate_score}/10";
        }
        $scoresLine = 'Scores: '.implode(', ', $scoreParts).'.';

        $intervalNote = $isInterval
            ? 'This was an interval session — the actual avg pace below mixes work + recovery + warmup + cooldown, so do NOT compare it directly to the work-set avg. Comment on distance + HR + perceived effort instead.'
            : null;

        return collect([
            "Training: {$day->title} ({$day->type->value}).",
            $target !== '' ? "Target: {$target}." : null,
            "Actual: {$result->actual_km}km at {$this->pace($result->actual_pace_seconds_per_km)}/km{$actualHr}.",
            $scoresLine,
            $intervalNote,
            $this->recentRuns($result),
        ])->filter()->implode("\n");
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
