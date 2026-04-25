<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Services\StravaSyncService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AuthController extends Controller
{
    public function __construct(
        private StravaSyncService $stravaSyncService,
    ) {}

    public function redirect(): JsonResponse
    {
        return response()->json([
            'url' => $this->stravaSyncService->getAuthorizeUrl(),
        ]);
    }

    public function callback(Request $request): JsonResponse
    {
        $request->validate(['code' => 'required|string']);

        $stravaData = $this->stravaSyncService->exchangeCode($request->code);
        $user = $this->stravaSyncService->createOrUpdateUser($stravaData);

        // Strava history sync is now run inline by `OnboardingController::profile()`
        // on first hit (~30-90s), and incrementally by `DashboardController` /
        // `StravaController::sync()` thereafter. Dispatching here would race with
        // the inline sync during onboarding without saving any wall-clock time.

        $token = $user->createToken('api')->plainTextToken;

        return response()->json([
            'token' => $token,
            'user' => $this->serializeUser($user),
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Logged out']);
    }

    public function devLogin(): JsonResponse
    {
        abort_unless(app()->environment('local'), 404);

        $user = User::whereNotNull('strava_athlete_id')->orderBy('id')->firstOrFail();
        $token = $user->createToken('dev')->plainTextToken;

        return response()->json([
            'token' => $token,
            'user' => $this->serializeUser($user),
        ]);
    }

    /**
     * @return array<string, mixed>
     */
    private function serializeUser(User $user): array
    {
        $pending = $user->pendingPlanGeneration();

        return [
            ...$user->only(['id', 'name', 'email', 'coach_style', 'has_completed_onboarding']),
            'pending_plan_generation' => $pending !== null
                ? OnboardingController::serialize($pending)
                : null,
        ];
    }
}
