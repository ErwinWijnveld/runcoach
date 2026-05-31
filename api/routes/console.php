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

// Daily safety net for subscription state — expires any sub past grace whose
// EXPIRATION webhook was lost, and logs an overdue warning if an active sub
// hasn't had a renewal event in 7+ days. See:
// docs/superpowers/specs/2026-05-19-revenuecat-subscriptions.md
Schedule::command('subscriptions:reconcile')
    ->dailyAt('04:00')
    ->timezone(config('app.reminder_timezone', 'Europe/Amsterdam'))
    ->withoutOverlapping()
    ->onOneServer();

// Mid-plan check-ins: every 2 weeks the deterministic plan builder places an
// evaluation on a runner's schedule (TrainingPlanBuilder::scheduleEvaluations).
// This evening sweep dispatches GeneratePlanEvaluation for every row whose
// scheduled_for has arrived. 19:00 local time so the runner's Sunday run is
// already in the data when the AI looks back.
Schedule::command('plan:run-evaluations')
    ->dailyAt('19:00')
    ->timezone(config('app.reminder_timezone', 'Europe/Amsterdam'))
    ->withoutOverlapping()
    ->onOneServer();
