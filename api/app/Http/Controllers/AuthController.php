<?php

namespace App\Http\Controllers;

use App\Jobs\SyncStravaHistory;
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

        SyncStravaHistory::dispatch($user->id);

        $token = $user->createToken('api')->plainTextToken;

        return response()->json([
            'token' => $token,
            'user' => $user->only(['id', 'name', 'email', 'coach_style', 'has_completed_onboarding']),
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

        $user = User::orderBy('id')->firstOrFail();
        $token = $user->createToken('dev')->plainTextToken;

        return response()->json([
            'token' => $token,
            'user' => $user->only(['id', 'name', 'email', 'coach_style', 'has_completed_onboarding']),
        ]);
    }
}
