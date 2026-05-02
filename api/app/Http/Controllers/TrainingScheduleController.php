<?php

namespace App\Http\Controllers;

use App\Jobs\GenerateActivityFeedback;
use App\Models\Goal;
use App\Models\TrainingDay;
use App\Models\TrainingResult;
use App\Models\WearableActivity;
use App\Services\ComplianceScoringService;
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

    /**
     * Move a training day to a different date. Re-assigns the day to the
     * matching TrainingWeek if the new date crosses a week boundary, so the
     * weekly view stays coherent. Refuses when the day already has a result —
     * unlink the activity first if you really want to move a completed day.
     */
    public function updateDay(Request $request, int $dayId): JsonResponse
    {
        $user = $request->user();

        $day = TrainingDay::whereHas('trainingWeek.goal', function ($query) use ($user) {
            $query->where('user_id', $user->id);
        })->with('trainingWeek.goal')->findOrFail($dayId);

        abort_if(
            $day->result()->exists(),
            422,
            'Cannot reschedule a day that already has a result. Unlink the activity first.'
        );

        $goal = $day->trainingWeek->goal;

        // The race-day invariant: the day on `goal.target_date` IS the race
        // (renamed by the optimizer's enforceRaceDay pass). Letting the user
        // move it would put the race on the wrong calendar slot and the
        // optimizer can't fix it because updateDay doesn't run optimize.
        if (
            $goal->target_date !== null
            && $day->date !== null
            && $goal->target_date->toDateString() === Carbon::parse($day->date)->toDateString()
        ) {
            abort(422, 'This is your goal day — it has to stay on the goal date. Edit the goal date instead.');
        }

        $minDate = now()->startOfDay()->toDateString();
        $rules = ['date' => ['required', 'date', "after_or_equal:{$minDate}"]];
        if ($goal->target_date !== null) {
            $rules['date'][] = 'before_or_equal:'.$goal->target_date->toDateString();
        }
        $request->validate($rules);

        $newDate = Carbon::parse($request->input('date'))->startOfDay();

        // Re-assign to the week whose [starts_at, starts_at+7) range contains
        // the new date. Falls back to the existing week if no match (defensive
        // — shouldn't happen when validation passes).
        $matchingWeek = $goal->trainingWeeks()
            ->where('starts_at', '<=', $newDate->toDateString())
            ->where('starts_at', '>', $newDate->copy()->subDays(7)->toDateString())
            ->orderByDesc('starts_at')
            ->first();

        $day->update([
            'date' => $newDate->toDateString(),
            'training_week_id' => $matchingWeek?->id ?? $day->training_week_id,
        ]);

        return response()->json([
            'data' => $day->fresh(['trainingWeek', 'result.wearableActivity']),
        ]);
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
     * List the runner's recently-synced wearable activities in a ±7-day window
     * around a training day, for the manual "Select activity" picker (used
     * when the auto-match picked the wrong day or didn't fire). Each entry
     * carries `matched_training_day_id` so the UI can mark already-matched
     * activities as non-selectable.
     */
    public function availableActivitiesForDay(Request $request, int $dayId): JsonResponse
    {
        $user = $request->user();

        $day = TrainingDay::whereHas('trainingWeek.goal', function ($query) use ($user) {
            $query->where('user_id', $user->id);
        })->findOrFail($dayId);

        $windowStart = Carbon::parse($day->date)->startOfDay()->subDays(7);
        $windowEnd = Carbon::parse($day->date)->startOfDay()->addDays(2);

        $activities = WearableActivity::query()
            ->where('user_id', $user->id)
            ->whereIn('type', WearableActivity::RUN_TYPES)
            ->whereBetween('start_date', [$windowStart, $windowEnd])
            ->with(['trainingResults:id,training_day_id,wearable_activity_id'])
            ->orderByDesc('start_date')
            ->limit(30)
            ->get();

        $payload = $activities->map(function (WearableActivity $a) {
            $matchedDayId = $a->trainingResults->first()?->training_day_id;

            return [
                'wearable_activity_id' => $a->id,
                'source' => $a->source,
                'name' => $a->name ?? 'Run',
                'start_date' => $a->start_date->toIso8601String(),
                'distance_km' => round($a->distance_meters / 1000, 2),
                'duration_seconds' => $a->duration_seconds,
                'average_pace_seconds_per_km' => $a->average_pace_seconds_per_km,
                'average_heart_rate' => $a->average_heartrate !== null ? (float) $a->average_heartrate : null,
                'matched_training_day_id' => $matchedDayId,
            ];
        });

        return response()->json(['data' => $payload]);
    }

    /**
     * Manually match a previously-synced wearable activity to a training day.
     * Used when the auto-match (`ProcessWearableActivity`) picked the wrong
     * day or didn't run. Refuses if the activity is already matched to a
     * different day.
     */
    public function matchActivityToDay(
        Request $request,
        int $dayId,
        ComplianceScoringService $compliance,
    ): JsonResponse {
        $request->validate(['wearable_activity_id' => 'required|integer']);

        $user = $request->user();

        $day = TrainingDay::whereHas('trainingWeek.goal', function ($query) use ($user) {
            $query->where('user_id', $user->id);
        })->findOrFail($dayId);

        $activity = WearableActivity::where('user_id', $user->id)
            ->findOrFail((int) $request->input('wearable_activity_id'));

        if (! in_array($activity->type, WearableActivity::RUN_TYPES, true)) {
            abort(422, 'Only running activities can be matched to a training day.');
        }

        $existing = TrainingResult::where('wearable_activity_id', $activity->id)->first();
        if ($existing && $existing->training_day_id !== $day->id) {
            abort(409, 'This activity is already matched to a different training day.');
        }

        $result = $compliance->scoreDay($day, $activity);

        GenerateActivityFeedback::dispatch($result->id);

        return response()->json([
            'data' => $result->load('wearableActivity'),
        ]);
    }

    /**
     * Remove the TrainingResult linking a wearable activity to this day so
     * the day goes back to "unmatched" state. The WearableActivity itself
     * is kept — the user can re-match it (or a different one).
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
