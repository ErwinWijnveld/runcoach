<?php

namespace App\Http\Controllers;

use App\Jobs\ProcessStravaActivity;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class StravaWebhookController extends Controller
{
    public function verify(Request $request): JsonResponse
    {
        if ($request->input('hub_verify_token') !== config('services.strava.webhook_verify_token')
            && $request->input('hub.verify_token') !== config('services.strava.webhook_verify_token')) {
            return response()->json(['error' => 'Invalid verify token'], 403);
        }

        $challenge = $request->input('hub_challenge') ?? $request->input('hub.challenge');

        return response()->json(['hub.challenge' => $challenge]);
    }

    public function handle(Request $request): JsonResponse
    {
        if ($request->input('object_type') !== 'activity') {
            return response()->json(['status' => 'ignored']);
        }

        if ($request->input('aspect_type') !== 'create') {
            return response()->json(['status' => 'ignored']);
        }

        $user = User::where('strava_athlete_id', $request->input('owner_id'))->first();

        if (! $user) {
            return response()->json(['status' => 'user not found']);
        }

        ProcessStravaActivity::dispatch(
            $user->id,
            (int) $request->input('object_id'),
        );

        return response()->json(['status' => 'ok']);
    }
}
