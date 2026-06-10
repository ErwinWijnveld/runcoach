# Interval-day `target_km` — recompute on write

**Date:** 2026-06-10
**Status:** Implemented alongside this spec (user pre-approved skipping the review round-trip).

## Problem

`training_days.target_km` on interval days is written once at plan-build time
(`TrainingPlanBuilder::renderQuality` → `round(max($estimatedKm, $allocatedKm), 1)`)
and never touched again. Two failure modes:

1. **Staleness.** Any later edit to the interval structure (AdjustPlan op, coach
   editing in Filament, agent type-swap) changes the blueprint but not the stored
   km — the day detail screen then shows a distance that contradicts the intervals
   table rendered directly below it.
2. **Build-time inflation.** The `max(estimated, allocated)` floor means even a
   fresh plan can show a km value larger than the blueprint sums to, whenever the
   week's volume share exceeded the estimate.

Pace already has a contract for this (day-level pace is forced null on interval
days, work-set average derived at read time). Distance had no equivalent contract.

## Decision

**Recompute-on-write, not read-time derivation.** A fully-dynamic (null column)
approach would ripple into compliance scoring (distance is the dominant scored
component on intervals since pace is already null), stored weekly totals, the
daily-reminder push copy, and every Flutter consumer — and a read-time estimate
needs an external pace input that isn't available client-side. Instead:

> **Invariant: after any write, an interval day's `target_km` always equals
> `IntervalBlueprint::estimateTotalKm(intervals_json)`.**

## The estimator — `IntervalBlueprint::estimateTotalKm()`

A **pure function of the grouped blueprint** (no user/snapshot input — same
blueprint always yields the same km, regardless of which write path ran):

- Work steps: literal `work_distance_m` × reps; duration-based work converts via
  the step's `work_pace_seconds_per_km`, falling back to the blueprint-wide
  work-set average pace.
- Time-based segments (warmup, block recoveries, standalone rests, cooldown)
  convert at a **jog pace** = work-set average pace + `ESTIMATE_JOG_OFFSET_FROM_WORK`
  (100 s/km), clamped to [180, 720]. When no work pace exists anywhere in the
  blueprint, `ESTIMATE_FALLBACK_JOG_PACE_SECONDS` (360 = 6:00/km) applies.
- Input goes through `normalize()` first (accepts grouped or legacy flat); null
  blueprint → null estimate.
- Result rounded to 0.1 km.

The 100 s/km offset is consistent with existing precedent: the optimizer's
`PACE_DELTA_INTERVAL_RECOVERY` (recovery = baseline + 60) vs interval work
(baseline − 50) implies recovery ≈ work + 110; the old builder estimate (easy =
threshold + 75 vs work ≈ threshold − 20) implied ≈ work + 95.

## Write paths covered

| Path | Mechanism |
|---|---|
| BuildPlan / AdjustPlan / any payload through the optimizer | New `recomputeIntervalDistances` pass in `PlanOptimizerService::optimize`, **after `computePaces`** (work paces filled by then) and **before `recalculateWeeklyTotals`** (week totals pick up the recomputed value). |
| Plan build (`TrainingPlanBuilder::renderQuality`) | Uses the shared estimator; the `max(estimated, allocated)` floor is **dropped** (failure mode 2). The long-run-is-longest post-render bump still runs after and keeps the long run on top. |
| Filament coach editor, ProposalService row writes, any future direct write | `TrainingDay::saving` model hook: when `type === interval` and a blueprint is present, `target_km` is recomputed unconditionally. Pure + idempotent, so re-saves are no-ops. |
| Existing stale rows | Forward-only data migration recomputes `target_km` for every interval-type `training_days` row from its `intervals_json`, then refreshes `total_km` on affected `training_weeks`. Idempotent. |

Explicitly NOT covered: pending `coach_proposals.payload` blobs (transient; the
rows they produce on acceptance pass through the model hook anyway).

## Agent + coach UX

- `AdjustPlan` tool description: `target_km` is **derived on interval days** — to
  change an interval session's distance, change the `intervals` structure.
  `adjustmentNotes` gains an interval-specific wording so a runner who asked for
  "8 km of intervals" is told the distance follows from the session structure.
- Filament `GoalSchedule` edit modal: the Distance input is hidden for
  `type=interval`, replaced by a live read-only placeholder ("Distance (auto)")
  computed from the in-form interval structure — mirroring the existing
  "Pace (work-set avg)" placeholder.

## Out of scope

- Segment-level ingestion of actual workouts (compliance still scores full-run
  distance vs `target_km`; unchanged semantics, now against a never-stale target).
- Flutter changes (the app keeps rendering `target_km`; it's just always fresh).
  Only a stale doc comment on `_displayTitle` in `weekly_plan_screen.dart` is fixed.

## Tests

- `tests/Feature/Support/IntervalBlueprintTest.php` — estimator: distance blocks,
  duration work with/without pace, jog fallback, rest steps, flat input, null.
- `tests/Feature/Services/PlanOptimizerServiceTest.php` — agent-supplied km on an
  interval day is overridden; week totals include the recomputed value; null work
  paces get filled before estimation (ordering).
- `tests/Feature/Models/TrainingDayTargetKmRecomputeTest.php` — saving hook:
  recompute on blueprint edit, on type swap to interval, no-op for non-interval
  days and interval days without a blueprint.
- `tests/Feature/Migrations/RecomputeIntervalTargetKmTest.php` — backfill fixes a
  stale row + its week total, leaves non-interval rows alone.
- `tests/Feature/Filament/GoalScheduleIntervalsTest.php` — saving the modal stores
  the derived km (coach-typed value ignored on interval days).
