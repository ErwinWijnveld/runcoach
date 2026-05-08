<?php

namespace App\Console\Commands;

use App\Models\User;
use App\Notifications\BirthdayZoneCheckReminder;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;
use Illuminate\Support\Carbon;

#[Signature('plan:remind-birthday {--date= : Override the target date (YYYY-MM-DD), defaults to today in the reminder timezone}')]
#[Description("Send a push to every user whose birthday is today, prompting them to refresh their HR zones (Tanaka's prior shifts by ~0.7 bpm/year so it's a sensible yearly nudge).")]
class SendBirthdayZoneReminders extends Command
{
    public function handle(): int
    {
        $tz = config('app.reminder_timezone', 'Europe/Amsterdam');
        $today = $this->option('date')
            ? Carbon::parse($this->option('date'))
            : now($tz);

        // whereMonth + whereDay handles leap-year birthdays (Feb 29)
        // gracefully on non-leap years by simply not matching — fine for
        // v1. ~0.07% of users; a future polish could shift them to Feb 28.
        $users = User::query()
            ->whereNotNull('date_of_birth')
            // Skip the runner's own birth date (newborn edge case).
            ->whereDate('date_of_birth', '<', $today->toDateString())
            ->whereMonth('date_of_birth', $today->month)
            ->whereDay('date_of_birth', $today->day)
            ->get();

        foreach ($users as $user) {
            $user->notify(new BirthdayZoneCheckReminder);
        }

        $this->info("Birthday reminders queued for {$today->toDateString()}: sent={$users->count()}");

        return self::SUCCESS;
    }
}
