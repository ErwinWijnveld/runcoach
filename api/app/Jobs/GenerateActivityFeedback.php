<?php

namespace App\Jobs;

use App\Models\TrainingResult;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use OpenAI\Laravel\Facades\OpenAI;

class GenerateActivityFeedback implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(
        public int $trainingResultId,
    ) {}

    public function handle(): void
    {
        $result = TrainingResult::with('trainingDay', 'stravaActivity')->find($this->trainingResultId);

        if (! $result || $result->ai_feedback) {
            return;
        }

        $day = $result->trainingDay;
        $context = "Training: {$day->title} ({$day->type->value}). "
            ."Target: {$day->target_km}km at {$day->target_pace_seconds_per_km}s/km. "
            ."Actual: {$result->actual_km}km at {$result->actual_pace_seconds_per_km}s/km. "
            ."Compliance score: {$result->compliance_score}/10. "
            ."Pace score: {$result->pace_score}, Distance score: {$result->distance_score}.";

        if ($result->actual_avg_heart_rate) {
            $context .= " Avg HR: {$result->actual_avg_heart_rate}.";
        }

        $response = OpenAI::chat()->create([
            'model' => config('openai.model', 'gpt-4o'),
            'messages' => [
                ['role' => 'system', 'content' => 'You are a running coach giving brief post-run feedback. Be specific, constructive, and concise (2-3 sentences max). Reference the actual numbers.'],
                ['role' => 'user', 'content' => $context],
            ],
        ]);

        $result->update([
            'ai_feedback' => $response->choices[0]->message->content,
        ]);
    }
}
