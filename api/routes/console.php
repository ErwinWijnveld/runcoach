<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Daily morning reminder for runners with a training day on the calendar.
// Runs at 07:00 in the configured reminder timezone (DST-aware via Laravel's
// scheduler). For multi-timezone support later, hash users by tz and run
// one scheduled task per tz; for v1 a single market default is fine.
Schedule::command('plan:remind-today')
    ->dailyAt('07:00')
    ->timezone(config('app.reminder_timezone', 'Europe/Amsterdam'))
    ->withoutOverlapping()
    ->onOneServer();

// Yearly birthday push — runs daily, queries users whose DOB matches
// today's month+day. Slightly later than the training reminder so the
// runner doesn't open the app to two pushes back-to-back.
Schedule::command('plan:remind-birthday')
    ->dailyAt('09:00')
    ->timezone(config('app.reminder_timezone', 'Europe/Amsterdam'))
    ->withoutOverlapping()
    ->onOneServer();
