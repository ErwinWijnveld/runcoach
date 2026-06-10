# Coach schedule — completed-run stats & compliance analysis

**Date:** 2026-06-10
**Status:** Approved
**Scope:** Filament coach panel (`/coach`), `GoalSchedule` page only

## Problem

The coach's per-runner schedule view (`app/Filament/Coach/Pages/GoalSchedule.php` +
`resources/views/filament/coach/pages/goal-schedule.blade.php`) marks a day
"Completed" but shows nothing about what actually happened. The compliance
analysis the runner sees in the app (`TrainingResult`: overall score, pace /
distance / HR sub-scores, actuals, AI feedback) is invisible to the coach,
even though the relation is already eager-loaded on the page.

## Goal

Surface the completed-run data on the coach's GoalSchedule overview at three
levels: inline on each completed day row, as rollups on week headers + the
hero summary, and in full inside the existing edit-day modal.

## Approach

**View-layer only.** No new endpoints, no migrations, no Flutter changes, no
extracted view-model class. The page class already owns the formatting
helpers (`paceToText`, `dayStatus`) and the data is already loaded; rollups
are computed in PHP from the loaded collection.

Rejected alternatives:
- *Extracted `CoachScheduleStats` view-model* — cleaner separation but
  display-only data with no second consumer; extra files for no payoff.
- *Livewire partials per row* — refactoring the feature doesn't need.

## Design

### 1. Data loading

`GoalSchedule::getGoalProperty()` eager load changes from
`trainingWeeks.trainingDays.result` to
`trainingWeeks.trainingDays.result.wearableActivity` so the modal's activity
extras don't N+1.

### 2. Inline day row (completed days only)

- Status pill becomes `✓ Completed · 87%`. The pill is color-banded by
  `compliance_score`: green ≥ 80, amber 50–79, red < 50, reusing the existing
  `--rc-success-bg` / `--rc-warn-bg` / `--rc-danger-bg` theme tokens. A
  completed day with a null `compliance_score` keeps the plain green
  "Completed" pill without a percentage.
- Below the planned description, one muted actuals line:
  `Ran 8.2 km @ 4:46/km · avg HR 162`. Each fragment (distance, pace, HR) is
  omitted when its value on the `TrainingResult` is null — avg HR in
  particular is frequently absent.
- The right-hand stats column keeps showing the **planned** km/pace, so the
  row reads planned (right) vs actual (inline line).
- Missed / today / upcoming rows are unchanged.

### 3. Week header rollup

For weeks with ≥ 1 result, the week-stats area gains
`3/4 done · avg 87%` before the existing `N sessions · X km`. The average is
the mean of non-null `compliance_score` values across that week's results.
Weeks with zero results render exactly as today.

### 4. Hero summary rollup

- The "Sessions" cell becomes `12 / 34 done` (results count / total days).
- A sixth cell **Compliance** shows the plan-wide mean of all non-null
  `compliance_score` values, or `—` when there are no results yet.
- The hero grid template gains one column (responsive collapse already
  handled by the existing `@media` rule).

### 5. Modal "Result" section

A read-only `Section::make('Result')` is prepended to the edit-day modal
schema, `visible` only when the day has a `TrainingResult`. Built from
Filament `Placeholder` components (display-only; the editable planned fields
below stay exactly as they are). Contents, in order:

1. **Compliance headline** — overall % (or `—` if null).
2. **Sub-scores** — pace / distance / HR scores on one line; null renders
   `—` (pace is always null on interval days by design;
   HR is null when the activity had no HR data).
3. **Actuals** — `actual_km` · `actual_pace_seconds_per_km` (via
   `paceToText`) · `actual_avg_heart_rate`.
4. **Activity extras** (from the linked `WearableActivity`, each omitted when
   null): duration (`duration_seconds` as `h:mm:ss` / `mm:ss`), max HR,
   elevation gain, calories. The whole block is skipped when
   `wearableActivity` is missing.
5. **AI feedback** — `ai_feedback` rendered as sanitized markdown via
   `Str::markdown($text, ['html_input' => 'strip'])` wrapped in
   `HtmlString`; omitted when null.

No per-km splits table in v1 (deliberately deferred — modal stays compact;
add later if coaches ask).

### 6. Edge handling

- Result whose `wearableActivity` row is missing → scores + actuals render,
  extras block skipped.
- MySQL decimal-string values are already handled by the `TrainingResult`
  casts (`decimal:1`).
- All rollups computed from the already-loaded Eloquent collections — zero
  additional queries beyond the one extended eager load.

## Testing

New `tests/Feature/Filament/GoalScheduleResultsTest.php` following the
existing `GoalScheduleIntervalsTest` pattern (acting as an org coach,
Livewire-testing the page):

- Completed day renders compliance pill text + actuals line; pill band class
  matches the score (green/amber/red cases).
- Completed day with null compliance score renders plain "Completed" pill.
- Week header shows `done/total · avg %` only for weeks with results.
- Hero shows sessions-done fraction and plan-wide compliance; `—` when no
  results exist.
- Edit-day modal form/schema includes the Result section for a completed day
  and hides it for a day without a result.
- Null sub-scores (interval day: `pace_score` null) render `—` without
  errors.
- Result with missing wearable activity renders without the extras block.

## Out of scope

- Per-km splits in the modal.
- Compliance columns on `ClientsTable` / `GoalsRelationManager`.
- Off-plan ("buiten schema") runs in the coach view.
- Any Flutter or API changes.
