<?php

namespace App\Console\Commands;

use App\Enums\GoalStatus;
use App\Models\TrainingDay;
use App\Notifications\TrainingDayReminder;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Notification;
use Throwable;

#[Signature('plan:remind-today {--date= : Override the target date (YYYY-MM-DD), defaults to today in the reminder timezone} {--user= : Only dispatch for a single user id} {--sync : Send synchronously (bypass the queue) so APNs errors surface in this command output} {--debug : Print per-user details (token count, title, body, exceptions)}')]
#[Description('Send a push notification to every user with a training day scheduled for today, summarizing distance + pace. Skips days that already have a TrainingResult linked (the user already ran).')]
class SendTrainingDayReminders extends Command
{
    public function handle(): int
    {
        $tz = config('app.reminder_timezone', 'Europe/Amsterdam');
        $date = $this->option('date') ?: now($tz)->toDateString();
        $userFilter = $this->option('user') !== null ? (int) $this->option('user') : null;
        $sync = (bool) $this->option('sync');
        $debug = (bool) $this->option('debug') || $sync;

        $days = TrainingDay::query()
            ->whereDate('date', $date)
            ->whereDoesntHave('result')
            ->whereHas('trainingWeek.goal', function ($q) use ($userFilter) {
                $q->where('status', GoalStatus::Active);

                if ($userFilter !== null) {
                    $q->where('user_id', $userFilter);
                }
            })
            ->with(['trainingWeek.goal.user'])
            ->get();

        $sent = 0;
        $skipped = 0;
        $failed = 0;

        foreach ($days as $day) {
            $user = $day->trainingWeek?->goal?->user;

            if ($user === null) {
                $skipped++;

                if ($debug) {
                    $this->warn("  day_id={$day->id}: no user (orphaned trainingWeek/goal)");
                }

                continue;
            }

            if ($debug) {
                $tokens = $user->routeNotificationForApn();
                $tokenCount = is_array($tokens) || $tokens instanceof \Countable ? count($tokens) : 0;
                $this->line("  user_id={$user->id} day_id={$day->id} tokens={$tokenCount}");
                $this->line('    title='.TrainingDayReminder::title($day));
                $this->line('    body='.TrainingDayReminder::body($day));
            }

            try {
                $notification = new TrainingDayReminder($day->id);

                if ($sync) {
                    Notification::sendNow($user, $notification);
                } else {
                    $user->notify($notification);
                }

                $sent++;
            } catch (Throwable $e) {
                $failed++;
                $this->error("  user_id={$user->id} day_id={$day->id} FAILED: ".$e::class.': '.$e->getMessage());
                if ($debug) {
                    $this->line('    '.$e->getTraceAsString());
                }
            }
        }

        $verb = $sync ? 'sent' : 'queued';
        $this->info("Reminders {$verb} for {$date}: sent={$sent} skipped={$skipped} failed={$failed}");

        return self::SUCCESS;
    }
}
