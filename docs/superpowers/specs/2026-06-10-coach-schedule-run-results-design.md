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

> **Scale note (changed during implementation):** compliance scores are a
> **1–10 grade** product-wide, not a percentage — the Flutter compliance ring
> renders "8.7" with band thresholds good ≥ 8.0 / ok ≥ 5.0
> (`app/lib/core/theme/compliance_colors.dart`), and
> `ComplianceScoringService` clamps every sub-score to [1.0, 10.0]. The coach
> panel matches that convention so coach and runner talk about the same
> number. Also: `compliance_score` is a NOT NULL column, so there is no
> null-compliance pill case.

- Status pill becomes `✓ Completed · 8.7`. The pill is color-banded by
  `compliance_score`: green ≥ 8.0, amber 5.0–7.9, red < 5.0, reusing the
  existing `--rc-success-bg` / `--rc-warn-bg` / `--rc-danger-bg` theme
  tokens (thresholds mirror Flutter's `ComplianceColors`).
- Below the planned description, one muted actuals line:
  `Ran 8.2 km @ 4:46/km · avg HR 162`. Each fragment (distance, pace, HR) is
  omitted when its value on the `TrainingResult` is null — avg HR in
  particular is frequently absent.
- The right-hand stats column keeps showing the **planned** km/pace, so the
  row reads planned (right) vs actual (inline line).
- Missed / today / upcoming rows are unchanged.

### 3. Week header rollup

For weeks with ≥ 1 result, the week-stats area gains
`3/4 done · avg 8.7` before the existing `N sessions · X km`. The average is
the mean of `compliance_score` values across that week's results, rounded to
one decimal. Weeks with zero results render exactly as today.

### 4. Hero summary rollup

- The "Sessions" cell becomes `12 / 34 done` (results count / total days).
- A sixth cell **Compliance** shows the plan-wide mean `compliance_score`
  grade (one decimal), or `—` when there are no results yet.
- The hero grid template gains one column (responsive collapse already
  handled by the existing `@media` rule).

### 5. Modal "Result" section

A read-only `Section::make('Result')` is prepended to the edit-day modal
schema, `visible` only when the day has a `TrainingResult`. Built from
Filament `Placeholder` components (display-only; the editable planned fields
below stay exactly as they are). Contents, in order:

1. **Compliance headline** — `8.7 / 10`.
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
- Week header shows `done/total · avg grade` only for weeks with results.
- Hero shows sessions-done fraction and plan-wide compliance; `—` when no
  results exist.
- Edit-day modal form/schema includes the Result section for a completed day
  and hides it for a day without a result.
- Null sub-scores (interval day: `pace_score` null) render `—` without
  errors.
- Result with missing wearable activity renders without the extras block.

## Iteration 2 — app-style visuals + off-plan runs (same day)

Follow-up request: "runs outside of schedule should also show; comparison
table actual vs plan like the app; big compliance ring in the overview with
the same color thresholds — make it look more like the app."

### Off-plan ("buiten schema") runs per week

`GoalSchedule::offPlanRunsByWeek(Goal)` mirrors
`TrainingScheduleController::attachUnplannedRuns` exactly (run-type
activities inside a week's `[starts_at, starts_at + 7d)` range with no
`TrainingResult`; one query for the plan span, grouped in PHP) so the coach
sees the same blue tiles the runner sees. Rendered after the day rows in
each week card, styled like Flutter's `_UnplannedRunTile`: blue accent
`#3E72C7` / `#D8E6FB`, gradient glow from the right, `Off-plan` pill,
"Run outside schedule" title, `8.2 km · 4:46/km` blue subtitle, blue plus
circle. Non-interactive in v1 (linking runs to sessions stays a
runner-side action).

### Compliance ring (shared partial)

`resources/views/filament/coach/components/compliance-ring.blade.php` —
HTML/SVG port of Flutter's `ComplianceRing` (15%-alpha track, round-cap arc
from 12 o'clock, grade centered in serif, band color). Band colors are the
app's `ComplianceColors` values verbatim: good `#34C759` (≥ 8.0), ok
`#E9B638` (≥ 5.0), bad `#8F3A3A`. Used at 84px in the hero Compliance cell
(replaces the plain number; `—` when no results) and at 96px in the modal.

### Modal Result panel (replaces the placeholder rows)

The Result section now renders one
`View::make('filament.coach.components.day-result-panel')` fed by
`GoalSchedule::resultPanelData(TrainingDay)` — a public, directly-testable
method returning `{score, grade, band, rows[], bars[], activity, feedback}`.
Layout mirrors the Flutter training-result screen:

- Ring + vertical sub-score bars (distance / pace / HR; null scores omitted).
- **Target vs Actual table** with per-row inclusion rules matching the
  app's `_TargetVsActualSection`: Distance when `target_km` set; Pace when
  `target_pace_seconds_per_km` set (so interval days get no pace row); Heart
  rate when either the target zone or an actual HR exists (`Zone N` / `—`
  target, `162 bpm` / `—` actual). Actual cells are colored by the matching
  sub-score band; null sub-score → ink color.
- Activity extras line and AI feedback markdown as before.

Testing note: the modal HTML ships via `wire:partial` effects and is not in
the Livewire test render, so tests assert `resultPanelData` output directly
plus one structural check that the mounted action schema contains the
result-panel View component only for completed days.

## Out of scope

- Per-km splits in the modal.
- Compliance columns on `ClientsTable` / `GoalsRelationManager`.
- Coach-side linking of off-plan runs to planned sessions.
- Any Flutter or API changes.
