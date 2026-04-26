<?php

namespace App\Http\Controllers;

use App\Jobs\ProcessWearableActivity;
use App\Models\WearableActivity;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class WearableActivityController extends Controller
{
    /**
     * Ingest a batch of activities the Flutter app read from a device wearable
     * source (currently Apple HealthKit). Idempotent: rows are upserted on
     * `(source, source_activity_id)`. Each newly created/updated activity is
     * handed to `ProcessWearableActivity` to match against the active
     * training schedule and score compliance.
     *
     * Payload shape:
     *  {
     *    "activities": [
     *      {
     *        "source": "apple_health",                 // required
     *        "source_activity_id": "<HKWorkout uuid>", // required, stable
     *        "source_user_id": "<bundle id>",          // optional, dedup key
     *        "type": "Run",                             // required
     *        "name": "Morning run",                     // optional
     *        "distance_meters": 5050,                   // required
     *        "duration_seconds": 1820,                  // required
     *        "elapsed_seconds": 1900,                   // optional
     *        "average_heartrate": 152.4,                // optional
     *        "max_heartrate": 178.0,                    // optional
     *        "elevation_gain_meters": 32,               // optional
     *        "calories_kcal": 410,                      // optional
     *        "start_date": "2026-04-26T07:14:00Z",      // required, ISO-8601
     *        "end_date":   "2026-04-26T07:44:20Z",      // optional
     *        "raw_data":   { … }                        // optional, source-specific
     *      },
     *      …
     *    ]
     *  }
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'activities' => 'required|array|min:1|max:200',
            'activities.*.source' => 'required|string|max:32',
            'activities.*.source_activity_id' => 'required|string|max:255',
            'activities.*.source_user_id' => 'nullable|string|max:255',
            'activities.*.type' => 'required|string|max:32',
            'activities.*.name' => 'nullable|string|max:255',
            'activities.*.distance_meters' => 'required|integer|min:0',
            'activities.*.duration_seconds' => 'required|integer|min:1',
            'activities.*.elapsed_seconds' => 'nullable|integer|min:0',
            'activities.*.average_heartrate' => 'nullable|numeric|min:30|max:250',
            'activities.*.max_heartrate' => 'nullable|numeric|min:30|max:250',
            'activities.*.elevation_gain_meters' => 'nullable|integer',
            'activities.*.calories_kcal' => 'nullable|integer|min:0',
            'activities.*.start_date' => 'required|date',
            'activities.*.end_date' => 'nullable|date',
            'activities.*.raw_data' => 'nullable|array',
        ]);

        $user = $request->user();
        $created = 0;
        $updated = 0;

        foreach ($request->input('activities', []) as $payload) {
            $distance = (int) $payload['distance_meters'];
            $duration = (int) $payload['duration_seconds'];
            $pace = $distance > 0 ? (int) round($duration / ($distance / 1000)) : 0;

            $activity = WearableActivity::updateOrCreate(
                [
                    'user_id' => $user->id,
                    'source' => $payload['source'],
                    'source_activity_id' => $payload['source_activity_id'],
                ],
                [
                    'source_user_id' => $payload['source_user_id'] ?? null,
                    'type' => $payload['type'],
                    'name' => $payload['name'] ?? null,
                    'distance_meters' => $distance,
                    'duration_seconds' => $duration,
                    'elapsed_seconds' => isset($payload['elapsed_seconds']) ? (int) $payload['elapsed_seconds'] : null,
                    'average_pace_seconds_per_km' => $pace,
                    'average_heartrate' => $payload['average_heartrate'] ?? null,
                    'max_heartrate' => $payload['max_heartrate'] ?? null,
                    'elevation_gain_meters' => $payload['elevation_gain_meters'] ?? null,
                    'calories_kcal' => $payload['calories_kcal'] ?? null,
                    'start_date' => Carbon::parse($payload['start_date']),
                    'end_date' => isset($payload['end_date']) ? Carbon::parse($payload['end_date']) : null,
                    'raw_data' => $payload['raw_data'] ?? [],
                    'synced_at' => now(),
                ],
            );

            if ($activity->wasRecentlyCreated) {
                $created++;
                // Only dispatch on create — re-pushes (user reopens the
                // connect-health screen) shouldn't spawn N no-op jobs that
                // re-walk the matching+scoring pipeline for activities that
                // already have a TrainingResult.
                ProcessWearableActivity::dispatch($activity->id);
            } else {
                $updated++;
            }
        }

        // When new rows arrived, the cached running profile is now stale —
        // its metrics were computed against fewer activities. Drop the cache
        // so the next /onboarding/profile call recomputes from the fresh set.
        // (RunningProfileService::analyze costs ~1k tokens for the narrative,
        // so we only invalidate when there's actually something new.)
        if ($created > 0) {
            $user->runningProfile()->delete();
        }

        return response()->json([
            'created' => $created,
            'updated' => $updated,
        ], 201);
    }

    /**
     * List the user's wearable activities, newest-first. Used by the schedule
     * day picker and (later) settings/debug screens.
     */
    public function index(Request $request): JsonResponse
    {
        $activities = $request->user()->wearableActivities()
            ->orderByDesc('start_date')
            ->paginate(30);

        return response()->json($activities);
    }
}
