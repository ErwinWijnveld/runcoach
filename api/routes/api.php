<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\CoachController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\GoalController;
use App\Http\Controllers\OnboardingController;
use App\Http\Controllers\ProfileController;
use App\Http\Controllers\StravaController;
use App\Http\Controllers\StravaWebhookController;
use App\Http\Controllers\TrainingScheduleController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    // Auth (public)
    Route::get('auth/strava/redirect', [AuthController::class, 'redirect']);
    Route::get('auth/strava/callback', [AuthController::class, 'callback']);
    Route::post('auth/dev-login', [AuthController::class, 'devLogin']);

    // Strava webhook (public, Strava-signed)
    Route::get('webhook/strava', [StravaWebhookController::class, 'verify']);
    Route::post('webhook/strava', [StravaWebhookController::class, 'handle']);

    // Authenticated routes
    Route::middleware('auth:sanctum')->group(function () {
        Route::post('auth/logout', [AuthController::class, 'logout']);

        // Profile
        Route::get('profile', [ProfileController::class, 'show']);
        Route::put('profile', [ProfileController::class, 'update']);

        // Goals
        Route::apiResource('goals', GoalController::class);
        Route::post('goals/{goal}/activate', [GoalController::class, 'activate']);

        // Training Schedule
        Route::get('goals/{goal}/schedule', [TrainingScheduleController::class, 'schedule']);
        Route::get('goals/{goal}/schedule/current', [TrainingScheduleController::class, 'currentWeek']);
        Route::get('training-days/{day}', [TrainingScheduleController::class, 'showDay']);
        Route::get('training-days/{day}/result', [TrainingScheduleController::class, 'dayResult']);
        Route::get('training-days/{day}/available-activities', [TrainingScheduleController::class, 'availableActivitiesForDay']);
        Route::post('training-days/{day}/match-activity', [TrainingScheduleController::class, 'matchActivityToDay']);
        Route::delete('training-days/{day}/match-activity', [TrainingScheduleController::class, 'unlinkActivityFromDay']);

        // Strava
        Route::post('strava/sync', [StravaController::class, 'sync']);
        Route::get('strava/activities', [StravaController::class, 'activities']);
        Route::get('strava/status', [StravaController::class, 'status']);

        // Dashboard
        Route::get('dashboard', DashboardController::class);

        // Onboarding
        Route::prefix('onboarding')->group(function () {
            Route::post('/start', [OnboardingController::class, 'start']);
        });

        // AI Coach
        Route::get('coach/conversations', [CoachController::class, 'index']);
        Route::post('coach/conversations', [CoachController::class, 'store']);
        Route::get('coach/conversations/{conversation}', [CoachController::class, 'show']);
        Route::post('coach/conversations/{conversation}/messages', [CoachController::class, 'sendMessage']);
        Route::post('coach/proposals/{proposal}/accept', [CoachController::class, 'acceptProposal']);
        Route::post('coach/proposals/{proposal}/reject', [CoachController::class, 'rejectProposal']);
    });
});
