<?php

use App\Http\Controllers\Api\MembershipController;
use App\Http\Controllers\Api\OrganizationController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\CoachController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\DeviceTokenController;
use App\Http\Controllers\GoalController;
use App\Http\Controllers\OnboardingController;
use App\Http\Controllers\ProfileController;
use App\Http\Controllers\TrainingScheduleController;
use App\Http\Controllers\WearableActivityController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    // Auth (public)
    Route::post('auth/apple', [AuthController::class, 'appleSignIn']);
    Route::post('auth/dev-login', [AuthController::class, 'devLogin']);

    // Authenticated routes
    Route::middleware('auth:sanctum')->group(function () {
        Route::post('auth/logout', [AuthController::class, 'logout']);

        // Profile
        Route::get('profile', [ProfileController::class, 'show']);
        Route::put('profile', [ProfileController::class, 'update']);
        Route::delete('profile', [ProfileController::class, 'destroy']);

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

        // Wearable activities (HealthKit ingestion from the app)
        Route::post('wearable/activities', [WearableActivityController::class, 'store']);
        Route::get('wearable/activities', [WearableActivityController::class, 'index']);
        Route::post('wearable/personal-records', [WearableActivityController::class, 'storePersonalRecords']);

        // Push notification device tokens
        Route::post('devices', [DeviceTokenController::class, 'store']);
        Route::delete('devices', [DeviceTokenController::class, 'destroy']);

        // Dashboard
        Route::get('dashboard', DashboardController::class);

        // Onboarding
        Route::prefix('onboarding')->group(function () {
            Route::get('/profile', [OnboardingController::class, 'profile']);
            Route::post('/generate-plan', [OnboardingController::class, 'generatePlan']);
            Route::get('/plan-generation/latest', [OnboardingController::class, 'latestPlanGeneration']);
            Route::post('/start', [OnboardingController::class, 'start']); // DEPRECATED
        });

        // Organizations / memberships (mobile)
        Route::get('organizations/search', [OrganizationController::class, 'search']);

        Route::prefix('me/memberships')->group(function () {
            Route::get('/', [MembershipController::class, 'index']);
            Route::post('invites/token/{token}/accept', [MembershipController::class, 'acceptByToken']);
            Route::post('invites/{membership}/accept', [MembershipController::class, 'accept']);
            Route::post('invites/{membership}/reject', [MembershipController::class, 'reject']);
            Route::post('requests', [MembershipController::class, 'requestJoin']);
            Route::delete('requests/{membership}', [MembershipController::class, 'cancelRequest']);
            Route::post('leave', [MembershipController::class, 'leave']);
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
