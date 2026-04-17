# Run Analysis (post-run AI feedback, v2)

**Status:** design approved, ready for implementation plan
**Author:** Erwin + Claude
**Date:** 2026-04-17

## Problem

When a Strava run is matched to a training day — either by webhook auto-match or the manual "Select Strava run" flow — we already generate a short 2–3 sentence AI feedback and store it in `training_results.ai_feedback`. Two problems with the current setup:

1. **The analysis is thin.** It only sees target-vs-actual + compliance scores. It doesn't see the run's per-km splits, doesn't compare to recent runs (so it can't say anything about form trend), and doesn't really speak to whether the run executed the *intended* workout.
2. **Manual matches get no analysis at all.** `TrainingScheduleController::matchActivityToDay` calls `ComplianceScoringService::scoreDay(...)` but never dispatches `GenerateActivityFeedback`. Webhook path does, manual path doesn't.
3. **The UI doesn't account for the pending state.** `TrainingDayDetailScreen` shows the day's "Notes" (the pre-written workout description) unconditionally, even after the run is complete and analysis has been generated. When analysis *is* generated, nothing ever pulls the fresh text in until the user navigates away and back.

## Goal

When a run is synced (auto or manual):
- Generate a richer AI analysis covering pace progression across splits, form signal vs recent runs, and how the run matched the planned workout.
- Show it on the day detail screen in place of the workout description once complete.
- While the analysis is still generating, show a loading card with our `SwooshingStar` SVG spinner and poll every 5 s until it lands.

Minimum new code, no schema changes.

## Non-goals

- No structured sections / sub-cards. One prose card.
- No failure UI (retry button, error state). If the job fails, the queue retries; if it permanently fails the spinner stays and the next re-match re-dispatches.
- No push/SSE notification for feedback readiness — polling is fine.
- No "form badge" or numeric form score.
- No changes to `TrainingResultScreen` (the fuller result detail). That screen already renders `result.aiFeedback` correctly; it will automatically pick up the richer prose.

## Design

### Backend

Schema unchanged. Reuse `training_results.ai_feedback` TEXT column. `null` means *pending*.

**`app/Jobs/GenerateActivityFeedback.php`** — expand the context built before the agent prompt:

| Context block | Source |
|---|---|
| Training target | `trainingDay` (title, type, target_km, target_pace_seconds_per_km, target_heart_rate_zone) |
| Actual | `result` (actual_km, actual_pace_seconds_per_km, actual_avg_heart_rate) |
| Per-km splits | `stravaActivity.raw_data['splits_metric']` → compact pace-per-km string (`5:10, 5:00, 4:58, 5:05, 5:15`). Skip if absent. |
| Compliance scores | `result` (compliance_score, pace_score, distance_score, heart_rate_score) |
| Recent runs (context for form) | `StravaActivity::where('user_id', …)->where('id','!=',result.strava_activity_id)->orderByDesc('start_date')->limit(5)`. For each: distance km, avg pace, avg HR (if available), date. |

Keep each section to one or two lines so the prompt stays cheap (< 1k tokens of input on top of the small system prompt).

**`app/Ai/Agents/ActivityFeedbackAgent.php`** — rewrite `instructions()`:

```
You are a running coach reviewing a completed run. In 4–6 sentences, comment on:
- pace progression across the per-km splits (was the runner steady, negative-split, fading?),
- form vs the last 5 runs (HR/pace drift at similar efforts — signs of improving or accumulating fatigue),
- how well the run matched the planned workout.
Reference actual numbers. Be specific and constructive, not generic.
```

No structured output, no tools, no conversation memory. Still plain text via `->prompt(...)->text`.

**`app/Http/Controllers/TrainingScheduleController.php`** — in `matchActivityToDay`, after `$result = $compliance->scoreDay($day, $activity);` add:

```php
GenerateActivityFeedback::dispatch($result->id);
```

Same line ProcessStravaActivity uses. Idempotent because the job early-returns when `ai_feedback` is already set.

### Flutter

**`TrainingDayDetailScreen`** — the existing "Notes" section (lines 108–134 of `training_day_detail_screen.dart`) becomes a three-state card:

| Day status | `result.aiFeedback` | Card rendered |
|---|---|---|
| Not completed | n/a | **Notes** card with `day.description` (unchanged) |
| Completed | `null` | **Coach analysis** card: `SwooshingStar` + "Analysing your run…" |
| Completed | non-null | **Coach analysis** card: the prose |

The existing "Synced Strava run" summary card stays put.

**Polling provider** — add to `features/schedule/providers/schedule_provider.dart`:

```dart
@riverpod
Stream<String?> trainingDayAiFeedback(Ref ref, int dayId) async* {
  while (true) {
    final day = await ref.read(scheduleApiProvider).getTrainingDay(dayId);
    final feedback = day.result?.aiFeedback;
    yield feedback;
    if (feedback != null) {
      ref.invalidate(trainingDayDetailProvider(dayId));
      return;
    }
    await Future.delayed(const Duration(seconds: 5));
  }
}
```

The screen only `ref.watch`es this provider when the day is completed and the first detail fetch came back with `result.aiFeedback == null`. Once non-null lands, the stream closes (polling stops) and the detail provider is invalidated so any other screen using it picks up the text too. Provider auto-disposes on screen leave.

## Flow diagrams

**Webhook path** (unchanged shape):
```
Strava webhook → ProcessStravaActivity → ComplianceScoringService::matchAndScore
              → GenerateActivityFeedback::dispatch (richer prompt)
              → ai_feedback filled in DB
```

**Manual path** (new dispatch):
```
User taps Select Strava run → POST /training-days/{id}/match-activity
  → matchActivityToDay → ComplianceScoringService::scoreDay
  → GenerateActivityFeedback::dispatch  (← NEW LINE)
```

**Flutter detail screen** when completed:
```
Open day → detail fetch → result.ai_feedback == null?
  ├── yes: render analysis card with SwooshingStar; start polling stream (5s)
  │         stream yields null … null … non-null → render prose, invalidate detail
  └── no:  render analysis card with prose directly
```

## Testing

- **Backend**:
  - Update `tests/Feature/Jobs/GenerateActivityFeedbackTest.php` (or equivalent) so the agent input includes splits + recent runs.
  - Add a test in `tests/Feature/TrainingScheduleControllerTest.php` asserting `matchActivityToDay` dispatches `GenerateActivityFeedback` (use `Queue::fake()`).
  - `ActivityFeedbackAgent::fake(['prose…'])` for agent stubs.
- **Flutter**:
  - No automated test for the polling provider (matches existing project conventions — no provider tests yet).
  - Manual QA: complete a run, open day detail, confirm spinner then prose.

## Open questions

None at spec time. Any tweaks surface during plan review.
