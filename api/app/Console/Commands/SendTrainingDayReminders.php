<?php

namespace App\Console\Commands;

use App\Enums\GoalStatus;
use App\Models\TrainingDay;
use App\Notifications\TrainingDayReminder;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;

#[Signature('plan:remind-today {--date= : Override the target date (YYYY-MM-DD), defaults to today in the reminder timezone}')]
#[Description('Send a push notification to every user with a training day scheduled for today, summarizing distance + pace. Skips days that already have a TrainingResult linked (the user already ran).')]
class SendTrainingDayReminders extends Command
{
    public function handle(): int
    {
        $tz = config('app.reminder_timezone', 'Europe/Amsterdam');
        $date = $this->option('date') ?: now($tz)->toDateString();

        $days = TrainingDay::query()
            ->whereDate('date', $date)
            ->whereDoesntHave('result')
            ->whereHas('trainingWeek.goal', fn ($q) => $q->where('status', GoalStatus::Active))
            ->with(['trainingWeek.goal.user'])
            ->get();

        $sent = 0;
        $skipped = 0;

        foreach ($days as $day) {
            $user = $day->trainingWeek?->goal?->user;

            if ($user === null) {
                $skipped++;

                continue;
            }

            $user->notify(new TrainingDayReminder($day->id));
            $sent++;
        }

        $this->info("Reminders queued for {$date}: sent={$sent} skipped={$skipped}");

        return self::SUCCESS;
    }
}
