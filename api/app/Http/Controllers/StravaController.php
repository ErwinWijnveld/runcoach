<?php

namespace App\Http\Controllers;

use App\Jobs\SyncStravaHistory;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class StravaController extends Controller
{
    public function sync(Request $request): JsonResponse
    {
        SyncStravaHistory::dispatch($request->user()->id);

        return response()->json(['message' => 'Sync started']);
    }

    public function activities(Request $request): JsonResponse
    {
        $activities = $request->user()->wearableActivities()
            ->orderByDesc('start_date')
            ->paginate(30);

        return response()->json($activities);
    }

    public function status(Request $request): JsonResponse
    {
        $user = $request->user();
        $token = $user->stravaToken;
        $lastActivity = $user->wearableActivities()->orderByDesc('synced_at')->first();

        return response()->json([
            'connected' => $token !== null,
            'token_valid' => $token && ! $token->isExpired(),
            'last_sync' => $lastActivity?->synced_at,
        ]);
    }
}
