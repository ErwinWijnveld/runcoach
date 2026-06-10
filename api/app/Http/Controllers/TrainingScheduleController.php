<?php

namespace App\Http\Controllers;

use App\Enums\TrainingType;
use App\Jobs\GenerateActivityFeedback;
use App\Models\Goal;
use App\Models\TrainingDay;
use App\Models\TrainingResult;
use App\Models\TrainingWeek;
use App\Models\User;
use App\Models\WearableActivity;
use App\Services\ComplianceScoringService;
use App\Support\Intervals\IntervalBlueprint;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class TrainingScheduleController extends Controller
{
    public function schedule(Request $request, Goal $goal): JsonResponse
    {
        abort_unless($goal->user_id === $request->user()->id, 403);

        $weeks = $goal->trainingWeeks()
            ->with(['trainingDays' => fn ($q) => $q->orderBy('date'), 'trainingDays.result'])
            ->orderBy('week_number')
            ->get();

        $this->attachUnplannedRuns($request->user(), $weeks);

        return response()->json(['data' => $weeks]);
    }

    /**
     * Attach off-plan ("buiten schema") runs to each week: run-type activities
     * that fall within the week's [starts_at, starts_at + 7d) range but never
     * matched a planned session (no TrainingResult). One query for the whole
     * plan span, grouped in PHP. Each entry is shaped to match the Flutter
     * `WearableActivitySummary` model so the app reuses it as-is.
     *
     * @param  Collection<int, TrainingWeek>  $weeks
     */
    private function attachUnplannedRuns(User $user, Collection $weeks): void
    {
        if ($weeks->isEmpty()) {
            return;
        }

        $rangeStart = Carbon::parse($weeks->first()->starts_at)->startOfDay();
        $rangeEnd = Carbon::parse($weeks->last()->starts_at)->addDays(7)->startOfDay();

        $runs = WearableActivity::query()
            ->where('user_id', $user->id)
            ->whereIn('type', WearableActivity::RUN_TYPES)
            ->whereBetween('start_date', [$rangeStart, $rangeEnd])
            ->whereDoesntHave('trainingResults')
            ->orderBy('start_date')
            ->get();

        foreach ($weeks as $week) {
            $weekStart = Carbon::parse($week->starts_at)->startOfDay();
            $weekEnd = $weekStart->copy()->addDays(7);

            $week->setAttribute('unplanned_runs', $runs
                ->filter(fn (WearableActivity $r) => $r->start_date >= $weekStart && $r->start_date < $weekEnd)
                ->map(fn (WearableActivity $r) => $r->toSummaryPayload())
                ->values()
                ->all());
        }
    }

    public function currentWeek(Request $request, Goal $goal): JsonResponse
    {
        abort_unless($goal->user_id === $request->user()->id, 403);

        $week = $goal->trainingWeeks()
            ->with(['trainingDays' => fn ($q) => $q->orderBy('date'), 'trainingDays.result'])
            ->where('starts_at', '<=', now())
            ->orderByDesc('starts_at')
            ->first();

        return response()->json(['data' => $week]);
    }

    /**
     * Look up the RunCoachAgent conversation already attached to this week,
     * if any. Returns `{data: {id}}` or `{data: null}`. The conversation
     * itself is created lazily by `POST /coach/conversations` with
     * `subject_type=training_week` on the first send — same pattern as the
     * workout chat. Owning check goes through the goal.
     */
    public function weekChat(Request $request, TrainingWeek $week): JsonResponse
    {
        $user = $request->user();
        abort_unless($week->goal()->where('user_id', $user->id)->exists(), 403);

        $conversationId = DB::table('agent_conversations')
            ->where('user_id', $user->id)
            ->where('subject_type', 'training_week')
            ->where('subject_id', $week->id)
            ->value('id');

        if ($conversationId === null) {
            return response()->json(['data' => null]);
        }

        return response()->json(['data' => ['id' => (string) $conversationId]]);
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
        $dateRules = ['sometimes', 'date', "after_or_equal:{$minDate}"];
        if ($goal->target_date !== null) {
            $dateRules[] = 'before_or_equal:'.$goal->target_date->toDateString();
        }
        // `date` moves the day; the three content fields let the runner tweak
        // a session in place (the minimal edit-day UI). All optional — a
        // date-only body keeps the original reschedule behaviour. Pace/km
        // honor the same wide sanity windows as the AdjustPlan tool.
        $validated = $request->validate([
            'date' => $dateRules,
            'target_km' => ['sometimes', 'nullable', 'numeric', 'min:1', 'max:80'],
            'target_pace_seconds_per_km' => ['sometimes', 'nullable', 'integer', 'min:150', 'max:720'],
            'target_heart_rate_zone' => ['sometimes', 'nullable', 'integer', 'min:1', 'max:5'],
            'intervals' => ['sometimes', 'array'],
        ]);

        $updates = [];

        // Interval-structure edit (the app's block editor). Only meaningful
        // on interval days; normalize() clamps the structure and rejects
        // empty/garbage input — storing that would null the derived
        // target_km (the saving hook recomputes it from this blueprint).
        if (array_key_exists('intervals', $validated)) {
            abort_unless(
                $day->type === TrainingType::Interval,
                422,
                'Intervals can only be set on interval days.',
            );

            $normalized = IntervalBlueprint::normalize($validated['intervals']);
            abort_if(
                $normalized === null,
                422,
                'The interval structure must contain at least one step.',
            );

            $updates['intervals_json'] = $normalized;
        }

        if (array_key_exists('date', $validated)) {
            $newDate = Carbon::parse($validated['date'])->startOfDay();

            // Re-assign to the week whose [starts_at, starts_at+7) range
            // contains the new date. Falls back to the existing week if no
            // match (defensive — shouldn't happen when validation passes).
            $matchingWeek = $goal->trainingWeeks()
                ->where('starts_at', '<=', $newDate->toDateString())
                ->where('starts_at', '>', $newDate->copy()->subDays(7)->toDateString())
                ->orderByDesc('starts_at')
                ->first();

            // `order` is repurposed as day_of_week (1=Mon..7=Sun) across the
            // app (see PlanPayload, ProposalService::applyEditActivePlan). Keep
            // it in sync with the new date so AI-input and any order-based
            // sorts don't go stale.
            $updates['date'] = $newDate->toDateString();
            $updates['training_week_id'] = $matchingWeek?->id ?? $day->training_week_id;
            $updates['order'] = (int) $newDate->isoWeekday();
        }

        foreach (['target_km', 'target_pace_seconds_per_km', 'target_heart_rate_zone'] as $field) {
            if (array_key_exists($field, $validated)) {
                $updates[$field] = $validated[$field];
            }
        }

        // Interval invariant: day-level pace is never stored on interval days
        // (the per-rep paces live in `intervals_json`). Drop any attempt to set
        // one so the contract holds regardless of client.
        if ($day->type === TrainingType::Interval) {
            unset($updates['target_pace_seconds_per_km']);
        }

        if ($updates !== []) {
            $day->update($updates);
        }

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

    /**
     * Link an off-plan ("buiten schema") run to a planned session. Relocates the
     * chosen training day's calendar entry onto the run's ACTUAL date — the date
     * the run was really done, never the other way around — re-assigns it to the
     * matching week, then scores the run against it. The session becomes a
     * completed day on the run's date and the run stops surfacing as off-plan.
     */
    public function linkActivityToScheduleDay(
        Request $request,
        int $activityId,
        ComplianceScoringService $compliance,
    ): JsonResponse {
        $request->validate(['training_day_id' => 'required|integer']);

        $user = $request->user();

        $activity = WearableActivity::where('user_id', $user->id)->findOrFail($activityId);

        if (! in_array($activity->type, WearableActivity::RUN_TYPES, true)) {
            abort(422, 'Only running activities can be linked to a training day.');
        }

        if (TrainingResult::where('wearable_activity_id', $activity->id)->exists()) {
            abort(409, 'This run is already linked to a training day.');
        }

        $day = TrainingDay::whereHas('trainingWeek.goal', function ($query) use ($user) {
            $query->where('user_id', $user->id);
        })->with('trainingWeek.goal')->findOrFail((int) $request->input('training_day_id'));

        abort_if(
            $day->result()->exists(),
            422,
            'That training already has a result. Unlink it first.'
        );

        $goal = $day->trainingWeek->goal;

        // The race-day entry has to stay on the goal date (optimizer invariant).
        if (
            $goal->target_date !== null
            && $day->date !== null
            && $goal->target_date->toDateString() === Carbon::parse($day->date)->toDateString()
        ) {
            abort(422, 'The goal day has to stay on the goal date — it can\'t be linked to a run.');
        }

        // Move the session onto the run's real date. Past dates are allowed here
        // (runs are in the past) — this is what `updateDay` deliberately forbids.
        $runDate = $activity->start_date->copy()->startOfDay();

        $matchingWeek = $goal->trainingWeeks()
            ->where('starts_at', '<=', $runDate->toDateString())
            ->where('starts_at', '>', $runDate->copy()->subDays(7)->toDateString())
            ->orderByDesc('starts_at')
            ->first();

        $day->update([
            'date' => $runDate->toDateString(),
            'training_week_id' => $matchingWeek?->id ?? $day->training_week_id,
            'order' => (int) $runDate->isoWeekday(),
        ]);

        $result = $compliance->scoreDay($day->fresh(['trainingWeek.goal']), $activity);

        GenerateActivityFeedback::dispatch($result->id);

        return response()->json([
            'data' => $day->fresh(['trainingWeek', 'result.wearableActivity']),
        ]);
    }
}
