<?php

namespace App\Jobs;

use App\Ai\Agents\WeeklyInsightAgent;
use App\Models\TrainingWeek;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\App;
use Illuminate\Support\Facades\Log;

class GenerateWeeklyInsight implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(
        public int $trainingWeekId,
    ) {}

    public function handle(): void
    {
        $week = TrainingWeek::with('trainingDays.result', 'goal.user')->find($this->trainingWeekId);

        if (! $week) {
            return;
        }

        // Queue worker context — no SetLocale middleware ran. Honour the
        // runner's stored locale so LanguageDirective resolves correctly.
        $user = $week->goal?->user;
        if ($user) {
            App::setLocale($user->preferredLocale());
        }

        // Pro gate — same rule as GenerateActivityFeedback. Anthropic-spending
        // background jobs MUST skip silently for non-pro users (see
        // api/CLAUDE.md → AI job checklist).
        if ($user && ! $user->isPro()) {
            Log::info('Skipping AI work for non-pro user', [
                'user_id' => $user->id,
                'job' => static::class,
            ]);

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

        $response = WeeklyInsightAgent::make()->prompt($context);

        $week->update(['coach_notes' => $response->text]);
    }
}
