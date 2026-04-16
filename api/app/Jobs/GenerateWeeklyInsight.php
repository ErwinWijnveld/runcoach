<?php

namespace App\Jobs;

use App\Models\TrainingWeek;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use OpenAI\Laravel\Facades\OpenAI;

class GenerateWeeklyInsight implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(
        public int $trainingWeekId,
    ) {}

    public function handle(): void
    {
        $week = TrainingWeek::with('trainingDays.result', 'goal')->find($this->trainingWeekId);

        if (! $week) {
            return;
        }

        $completedDays = $week->trainingDays->filter(fn ($d) => $d->result !== null);

        if ($completedDays->isEmpty()) {
            return;
        }

        $avgScore = round($completedDays->avg(fn ($d) => $d->result->compliance_score), 1);
        $totalKm = $completedDays->sum(fn ($d) => $d->result->actual_km);
        $sessionsCompleted = $completedDays->count();
        $sessionsTotal = $week->trainingDays->count();

        $context = "Week {$week->week_number} ({$week->focus}) for {$week->goal->name}. "
            ."Completed {$sessionsCompleted}/{$sessionsTotal} sessions, {$totalKm}km total. "
            ."Average compliance: {$avgScore}/10. "
            ."Planned total: {$week->total_km}km.";

        $response = OpenAI::chat()->create([
            'model' => config('openai.model', 'gpt-4o'),
            'messages' => [
                ['role' => 'system', 'content' => 'You are a running coach giving a brief weekly insight. Be encouraging, specific, and concise (2-3 sentences max). Reference the runner\'s actual numbers and give one forward-looking tip.'],
                ['role' => 'user', 'content' => $context],
            ],
        ]);

        $week->update([
            'coach_notes' => $response->choices[0]->message->content,
        ]);
    }
}
