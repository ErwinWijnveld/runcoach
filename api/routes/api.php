<?php

use App\Http\Controllers\Api\MembershipController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\OrganizationController;
use App\Http\Controllers\Api\PlanEvaluationController;
use App\Http\Controllers\Api\SubscriptionsController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\CoachController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\DeviceTokenController;
use App\Http\Controllers\GoalController;
use App\Http\Controllers\HeartRateZonesController;
use App\Http\Controllers\OnboardingController;
use App\Http\Controllers\ProfileController;
use App\Http\Controllers\TrainingScheduleController;
use App\Http\Controllers\WearableActivityController;
use App\Http\Controllers\Webhooks\RevenueCatWebhookController;
use App\Http\Controllers\WorkoutChatController;
use Illuminate\Support\Facades\Route;

// Public webhook (auth is the shared-secret header check inside the controller).
// Not under /v1 because RC's webhook config is set once and shouldn't churn with
// our API versioning.
Route::post('webhooks/revenuecat', RevenueCatWebhookController::class)
    ->middleware('throttle:300,1');

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

        // Heart-rate zones — auto-derive from HealthKit data (called by
        // the onboarding zones step + the "Recompute" button in the menu sheet).
        Route::post('profile/heart-rate-zones/derive', [HeartRateZonesController::class, 'derive']);

        // Goals
        Route::apiResource('goals', GoalController::class);
        Route::post('goals/{goal}/activate', [GoalController::class, 'activate']);

        // Training Schedule
        Route::get('goals/{goal}/schedule', [TrainingScheduleController::class, 'schedule']);
        Route::get('goals/{goal}/schedule/current', [TrainingScheduleController::class, 'currentWeek']);
        Route::get('schedule/weeks/{week}/chat', [TrainingScheduleController::class, 'weekChat']);
        Route::get('training-days/{day}', [TrainingScheduleController::class, 'showDay']);
        Route::patch('training-days/{day}', [TrainingScheduleController::class, 'updateDay']);
        Route::get('training-days/{day}/result', [TrainingScheduleController::class, 'dayResult']);
        Route::get('training-days/{day}/available-activities', [TrainingScheduleController::class, 'availableActivitiesForDay']);
        Route::post('training-days/{day}/match-activity', [TrainingScheduleController::class, 'matchActivityToDay']);
        Route::delete('training-days/{day}/match-activity', [TrainingScheduleController::class, 'unlinkActivityFromDay']);

        // Wearable activities (HealthKit ingestion from the app)
        // Ingest + index stay free so non-pro users still build up history.
        // The per-activity AI analysis status is Pro-gated.
        Route::post('wearable/activities', [WearableActivityController::class, 'store']);
        Route::get('wearable/activities', [WearableActivityController::class, 'index']);
        Route::get('wearable/activities/{activity}/analysis', [WearableActivityController::class, 'analysisStatus'])
            ->middleware('require.pro');
        Route::get('wearable/activities/{activity}/route', [WearableActivityController::class, 'route']);
        Route::get('share/celebratable-run', [WearableActivityController::class, 'celebratableRun']);
        Route::post('wearable/personal-records', [WearableActivityController::class, 'storePersonalRecords']);

        // Push notification device tokens
        Route::post('devices', [DeviceTokenController::class, 'store']);
        Route::delete('devices', [DeviceTokenController::class, 'destroy']);

        // Subscriptions — client posts an empty body, server pulls truth from
        // RevenueCat REST API and writes pro_active_until accordingly. Belongs
        // OUTSIDE require.pro so an expired user can recover state.
        Route::post('subscriptions/sync', [SubscriptionsController::class, 'sync']);
        // Local-dev only (404 elsewhere): simulate a purchase / reset to free
        // so the paywall flow is testable without a real transaction.
        Route::post('subscriptions/dev-activate', [SubscriptionsController::class, 'devActivate']);
        Route::post('subscriptions/dev-deactivate', [SubscriptionsController::class, 'devDeactivate']);

        // In-app notifications inbox (action-required items)
        Route::get('notifications', [NotificationController::class, 'index']);
        Route::post('notifications/{notification}/accept', [NotificationController::class, 'accept']);
        Route::post('notifications/{notification}/dismiss', [NotificationController::class, 'dismiss']);

        // Mid-plan evaluation moments (see Jobs\GeneratePlanEvaluation).
        Route::get('plan-evaluations', [PlanEvaluationController::class, 'indexForActiveGoal']);
        Route::get('goals/{goal}/plan-evaluations', [PlanEvaluationController::class, 'indexForGoal']);
        Route::get('plan-evaluations/{evaluation}', [PlanEvaluationController::class, 'show']);

        // Dashboard
        Route::get('dashboard', DashboardController::class);

        // Onboarding
        Route::prefix('onboarding')->group(function () {
            Route::get('/profile', [OnboardingController::class, 'profile']);
            Route::post('/self-reported-stats', [OnboardingController::class, 'saveSelfReportedStats']);
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

        // AI Coach — all gated behind Pro entitlement.
        // (Reading history is also gated because the cards/messages reference
        // proposals; non-Pro users are sent back to the paywall anyway.)
        Route::middleware('require.pro')->group(function () {
            Route::get('coach/conversations', [CoachController::class, 'index']);
            Route::post('coach/conversations', [CoachController::class, 'store']);
            Route::get('coach/conversations/{conversation}', [CoachController::class, 'show']);
            Route::delete('coach/conversations/{conversation}', [CoachController::class, 'destroy']);
            Route::post('coach/conversations/{conversation}/messages', [CoachController::class, 'sendMessage']);
            Route::post('coach/proposals/{proposal}/accept', [CoachController::class, 'acceptProposal']);
            Route::post('coach/proposals/{proposal}/reject', [CoachController::class, 'rejectProposal']);

            // Per-training-day chat (WorkoutAgent)
            Route::get('workout-chat/{trainingDay}', [WorkoutChatController::class, 'show']);
            Route::post('workout-chat/{trainingDay}/messages', [WorkoutChatController::class, 'sendMessage']);
        });
    });
});
