# In-app interval editor (EditDaySheet)

**Date:** 2026-06-10
**Status:** Approved verbally (block-editor scope + direct-save flow chosen by Erwin); review gate waived ("bouw het maar gewoon"). Guiding constraints: simple, minimal code, stable, user-friendly.

## What

Runners can edit an interval session's structure from the existing "Edit
workout" sheet on the day-detail screen — the same direct-save flow as
distance/pace edits on other day types. Distance stays server-derived
(recompute-on-write invariant, see `2026-06-10-interval-target-km-recompute.md`).

## Scope decision (chosen: block editor)

Warming-up row (on/off + duration), a list of work BLOCKS (reps × distance-or-
time @ pace, recovery seconds) with add/remove (min 1), cooling-down row
(duration), and a live "Distance (auto)" footer. No distance↔time toggle per
block (YAGNI — blocks keep whichever measure they already have; new blocks are
distance-based). Full Filament parity (standalone rep/rest steps, reordering)
was rejected as oversized; single-block-only was rejected as too limited for
AI-authored multi-block sessions.

**Lossless rare structures:** standalone `rep`/`rest` steps (coach-editor
authored) render as fixed, non-editable rows in their original position and
are sent back unchanged on save. Blocks around them stay editable.

## Flow

1. Day detail → "Edit workout" action (re-enabled for interval days).
2. `EditDaySheet` branches: interval day → block editor; otherwise the
   existing distance/pace rows.
3. Save → `PATCH /training-days/{day}` with `intervals` (grouped form) →
   server normalizes + stores → `TrainingDay::saving` hook derives
   `target_km` → response returns the fresh day → existing watch resync
   (`syncUpcoming`) ships the change to the watch.

## Backend contract

`PATCH /api/v1/training-days/{day}` gains an optional `intervals` field:

- Only allowed on interval-type days → 422 otherwise.
- `IntervalBlueprint::normalize($intervals)` must return non-null → 422 on
  empty/garbage structures (protects the derived-km invariant).
- Normalize's existing clamps apply (reps 1–60, warmup ≤120s, recovery ≥15s,
  cooldown 60–600s).
- Existing guards unchanged: day with a linked result → 422.
- Persisted via the model so the saving hook derives `target_km`.

## Flutter pieces

- `IntervalBlueprint.estimateTotalKm()` — Dart port of the PHP estimator,
  same constants (jog = avg work pace + 100 s/km clamped [180, 720], fallback
  360 s/km). Unit-tested against the exact expectation values of the PHP test
  (5.1 / 2.4 / 3.4 / 3.3 / 1.6 / null) so the implementations cannot diverge.
- `EditDaySheet` interval branch + block-editor rows (Cupertino wheels for
  reps / rep distance / pace / seconds, reusing the sheet's existing row +
  picker idiom). Live derived-km footer uses the Dart estimator.
- `editTrainingDayProvider.edit()` gains an `intervals` param (JSON grouped
  form in the PATCH body).
- New l10n keys (en + nl).

## Testing

- Backend: PATCH feature tests — happy path (normalized storage + derived
  `target_km` in response), 422 non-interval day, 422 empty steps, clamps,
  rep/rest passthrough, result-linked guard.
- Flutter: estimator unit test (mirrored PHP values); analyze + full suite.
