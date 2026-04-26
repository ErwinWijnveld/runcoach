<?php

namespace App\Http\Controllers;

use App\Jobs\GenerateActivityFeedback;
use App\Models\Goal;
use App\Models\TrainingDay;
use App\Models\TrainingResult;
use App\Models\WearableActivity;
use App\Services\ComplianceScoringService;
use App\Services\StravaSyncService;
use Illuminate\Http\Client\RequestException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class TrainingScheduleController extends Controller
{
    public function schedule(Request $request, Goal $goal): JsonResponse
    {
        abort_unless($goal->user_id === $request->user()->id, 403);

        $weeks = $goal->trainingWeeks()
            ->with('trainingDays.result')
            ->orderBy('week_number')
            ->get();

        return response()->json(['data' => $weeks]);
    }

    public function currentWeek(Request $request, Goal $goal): JsonResponse
    {
        abort_unless($goal->user_id === $request->user()->id, 403);

        $week = $goal->trainingWeeks()
            ->with('trainingDays.result')
            ->where('starts_at', '<=', now())
            ->orderByDesc('starts_at')
            ->first();

        return response()->json(['data' => $week]);
    }

    public function showDay(Request $request, int $dayId): JsonResponse
    {
        $day = TrainingDay::whereHas('trainingWeek.goal', function ($query) use ($request) {
            $query->where('user_id', $request->user()->id);
        })
            ->with(['trainingWeek', 'result.wearableActivity'])
            ->findOrFail($dayId);

        return response()->json(['data' => $day]);
    }

    public function dayResult(Request $request, int $dayId): JsonResponse
    {
        $day = TrainingDay::whereHas('trainingWeek.goal', function ($query) use ($request) {
            $query->where('user_id', $request->user()->id);
        })->findOrFail($dayId);

        $result = $day->result?->load('wearableActivity');

        return response()->json(['data' => $result]);
    }

    /**
     * List the runner's recent Strava runs in a ±7-day window around a
     * training day, for the manual "Select Strava run" modal (fallback when
     * the webhook doesn't fire). Each entry carries `matched_training_day_id`
     * so the UI can mark already-synced runs as non-selectable.
     */
    public function availableActivitiesForDay(
        Request $request,
        int $dayId,
        StravaSyncService $strava,
    ): JsonResponse {
        $user = $request->user();

        $day = TrainingDay::whereHas('trainingWeek.goal', function ($query) use ($user) {
            $query->where('user_id', $user->id);
        })->findOrFail($dayId);

        $token = $user->stravaToken;
        if (! $token) {
            return response()->json(['data' => [], 'error' => 'strava_disconnected']);
        }

        // ±7 days before the day, + 2 days after (late-evening runs spilling
        // past midnight are still in-window). Strava's `before` is exclusive.
        $windowStart = Carbon::parse($day->date)->startOfDay()->subDays(7);
        $windowEnd = Carbon::parse($day->date)->startOfDay()->addDays(2);

        try {
            $raw = $strava->fetchActivities(
                $token,
                page: 1,
                perPage: 30,
                after: $windowStart->getTimestamp(),
                before: $windowEnd->getTimestamp(),
            );
        } catch (RequestException $e) {
            $status = $e->response?->status();

            if (in_array($status, [401, 403], true)) {
                return response()->json(['data' => [], 'error' => 'strava_disconnected']);
            }
            if ($status === 429) {
                return response()->json(['data' => [], 'error' => 'rate_limited']);
            }

            report($e);

            return response()->json(['data' => [], 'error' => 'strava_unreachable']);
        }

        $runs = array_values(array_filter(
            $raw,
            fn ($a) => in_array($a['type'] ?? null, WearableActivity::RUN_TYPES, true),
        ));

        $sourceIds = array_map(fn ($a) => (string) $a['id'], $runs);

        $matchedBySourceId = WearableActivity::query()
            ->where('user_id', $user->id)
            ->where('source', 'strava')
            ->whereIn('source_activity_id', $sourceIds)
            ->with(['trainingResults:id,training_day_id,wearable_activity_id'])
            ->get()
            ->keyBy('source_activity_id');

        $payload = array_map(function (array $a) use ($matchedBySourceId) {
            $activity = $matchedBySourceId->get((string) $a['id']);
            $matchedDayId = $activity?->trainingResults->first()?->training_day_id;

            return [
                'strava_activity_id' => (int) $a['id'],
                'name' => $a['name'] ?? 'Run',
                'start_date' => $a['start_date'] ?? null,
                'distance_km' => round(($a['distance'] ?? 0) / 1000, 2),
                'moving_time_seconds' => (int) ($a['moving_time'] ?? 0),
                'average_pace_seconds_per_km' => $a['moving_time'] && $a['distance']
                    ? (int) round($a['moving_time'] / ($a['distance'] / 1000))
                    : null,
                'average_heart_rate' => isset($a['average_heartrate']) ? (float) $a['average_heartrate'] : null,
                'matched_training_day_id' => $matchedDayId,
            ];
        }, $runs);

        return response()->json(['data' => $payload]);
    }

    /**
     * Manually match a Strava activity to a training day. Used when the
     * webhook didn't fire or the auto-match picked the wrong day.
     * Refuses if the activity is already matched to a different day.
     */
    public function matchActivityToDay(
        Request $request,
        int $dayId,
        StravaSyncService $strava,
        ComplianceScoringService $compliance,
    ): JsonResponse {
        $request->validate(['strava_activity_id' => 'required|integer']);

        $user = $request->user();

        $day = TrainingDay::whereHas('trainingWeek.goal', function ($query) use ($user) {
            $query->where('user_id', $user->id);
        })->findOrFail($dayId);

        $stravaActivityId = (int) $request->input('strava_activity_id');

        $token = $user->stravaToken;
        abort_unless($token, 422, 'Strava is not connected for this user.');

        try {
            $activityData = $strava->fetchActivity($token, $stravaActivityId);
        } catch (RequestException $e) {
            $status = $e->response?->status();
            if ($status === 404) {
                abort(404, 'That Strava activity was not found.');
            }
            if (in_array($status, [401, 403], true)) {
                abort(422, 'Your Strava connection is not authorised for this activity.');
            }
            report($e);
            abort(502, "Couldn't reach Strava. Please try again.");
        }

        if (! in_array($activityData['type'] ?? null, WearableActivity::RUN_TYPES, true)) {
            abort(422, 'Only running activities can be matched to a training day.');
        }

        // Verify the activity belongs to THIS user's Strava athlete. Strava's
        // API will happily return public activities from other athletes, so
        // without this check a user could "claim" anyone else's public run.
        $fetchedAthleteId = $activityData['athlete']['id'] ?? null;
        if ($fetchedAthleteId !== null
            && $user->strava_athlete_id !== null
            && (int) $fetchedAthleteId !== (int) $user->strava_athlete_id) {
            abort(403, 'That Strava activity belongs to another account.');
        }

        $sourceActivityId = (string) $activityData['id'];

        // Refuse to clobber a local mirror row owned by someone else.
        $existingActivity = WearableActivity::where('source', 'strava')
            ->where('source_activity_id', $sourceActivityId)
            ->first();
        if ($existingActivity && $existingActivity->user_id !== $user->id) {
            abort(403, 'That Strava activity belongs to another account.');
        }

        $activity = WearableActivity::updateOrCreate(
            [
                'source' => 'strava',
                'source_activity_id' => $sourceActivityId,
            ],
            [
                'user_id' => $user->id,
                'source_user_id' => isset($activityData['athlete']['id']) ? (string) $activityData['athlete']['id'] : null,
                'type' => $activityData['type'],
                'name' => $activityData['name'] ?? null,
                'distance_meters' => (int) $activityData['distance'],
                'duration_seconds' => (int) $activityData['moving_time'],
                'elapsed_seconds' => (int) $activityData['elapsed_time'],
                'average_pace_seconds_per_km' => $activityData['distance'] > 0
                    ? (int) round($activityData['moving_time'] / ($activityData['distance'] / 1000))
                    : 0,
                'average_heartrate' => $activityData['average_heartrate'] ?? null,
                'max_heartrate' => $activityData['max_heartrate'] ?? null,
                'elevation_gain_meters' => isset($activityData['total_elevation_gain']) ? (int) round($activityData['total_elevation_gain']) : null,
                'calories_kcal' => isset($activityData['calories']) ? (int) round($activityData['calories']) : null,
                'start_date' => $activityData['start_date'],
                'raw_data' => $activityData,
                'synced_at' => now(),
            ],
        );

        // Refuse if this activity is already bound to a DIFFERENT day.
        $existing = TrainingResult::where('wearable_activity_id', $activity->id)->first();
        if ($existing && $existing->training_day_id !== $day->id) {
            abort(409, 'This Strava run is already matched to a different training day.');
        }

        $result = $compliance->scoreDay($day, $activity);

        GenerateActivityFeedback::dispatch($result->id);

        return response()->json([
            'data' => $result->load('wearableActivity'),
        ]);
    }

    /**
     * Remove the TrainingResult linking a wearable activity to this day so
     * the day goes back to "unmatched" state. The WearableActivity itself is
     * kept — the user can re-match it (or a different run) from the modal.
     */
    public function unlinkActivityFromDay(Request $request, int $dayId): JsonResponse
    {
        $user = $request->user();

        $day = TrainingDay::whereHas('trainingWeek.goal', function ($query) use ($user) {
            $query->where('user_id', $user->id);
        })->findOrFail($dayId);

        $day->result?->delete();

        return response()->json(['data' => null]);
    }
}
