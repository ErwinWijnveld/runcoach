<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Services\Auth\AppleIdentityTokenVerifier;
use App\Services\Auth\InvalidAppleIdentityTokenException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AuthController extends Controller
{
    public function __construct(
        private AppleIdentityTokenVerifier $appleVerifier,
    ) {}

    /**
     * Exchange an Apple "Sign in with Apple" identity token for a Sanctum
     * bearer. The Flutter app obtains the identity token via the native iOS
     * dialog (`sign_in_with_apple` package) and posts it here.
     *
     * Apple only includes `email` / `name` on the *first* sign-in for a user;
     * subsequent sign-ins return only the `sub`. We therefore accept optional
     * `email` and `name` fields from the client, falling back to the JWT's
     * `email` claim or a synthesized placeholder.
     */
    public function appleSignIn(Request $request): JsonResponse
    {
        $request->validate([
            'identity_token' => 'required|string',
            'email' => 'nullable|email',
            'name' => 'nullable|string|max:255',
        ]);

        try {
            $payload = $this->appleVerifier->verify($request->string('identity_token'));
        } catch (InvalidAppleIdentityTokenException $e) {
            abort(401, $e->getMessage());
        }

        $user = User::where('apple_sub', $payload['sub'])->first();

        if ($user === null) {
            $email = $request->string('email')->toString()
                ?: $payload['email']
                ?? sprintf('%s@privaterelay.appleid.com', $payload['sub']);

            $user = User::create([
                'apple_sub' => $payload['sub'],
                'email' => $email,
                'name' => $request->string('name')->toString() ?: 'Runner',
            ]);
        }

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

    /**
     * Local-only shortcut for signing in as the first seeded user without
     * the Apple OAuth round-trip. Use only when developing the iOS app
     * against a real backend on a physical device.
     */
    public function devLogin(): JsonResponse
    {
        abort_unless(app()->environment('local'), 404);

        $user = User::orderBy('id')->firstOrFail();
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
