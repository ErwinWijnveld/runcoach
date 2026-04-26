<?php

namespace App\Http\Controllers;

use App\Models\DeviceToken;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

class DeviceTokenController extends Controller
{
    /**
     * Register an APNs/FCM device token for the authenticated user. Called on
     * every cold-start so `last_seen_at` stays fresh — duplicate (user, token)
     * pairs are upserted, never inserted twice.
     */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'token' => 'required|string|min:32|max:255',
            'platform' => 'required|in:ios,android',
            'app_version' => 'nullable|string|max:32',
        ]);

        DeviceToken::updateOrCreate(
            [
                'user_id' => $request->user()->id,
                'token' => $data['token'],
            ],
            [
                'platform' => $data['platform'],
                'app_version' => $data['app_version'] ?? null,
                'last_seen_at' => now(),
            ],
        );

        return response()->json(null, Response::HTTP_ACCEPTED);
    }

    /**
     * Unregister a device token, called from the Flutter logout flow so a
     * signed-out device stops receiving pushes for the previous user.
     */
    public function destroy(Request $request): Response
    {
        $data = $request->validate([
            'token' => 'required|string|min:32|max:255',
        ]);

        DeviceToken::where('user_id', $request->user()->id)
            ->where('token', $data['token'])
            ->delete();

        return response()->noContent();
    }
}
