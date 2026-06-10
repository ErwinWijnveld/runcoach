# Interval compliance scoring — max-HR touch + pace band + asymmetric distance

**Date:** 2026-06-10
**Status:** approved (verbal, chat) — implemented same day

## Problem

Interval-day compliance is structurally broken. A correctly executed interval
session scores 2–4 instead of 8–10, for two independent reasons:

1. **HR**: `TrainingPlanBuilder` sets `target_heart_rate_zone = 5` on every
   interval day, and `ComplianceScoringService::calculateHeartRateScore`
   compares the **session-average** HR against the Z5 lower bound. An interval
   session's average mixes warmup + recoveries + cooldown, so it lands in
   Z3/Z4 physiologically — 25–45 bpm below the Z5 floor → score 1–5, always.
   The score punishes exactly the runner who executed the session correctly.
2. **Distance**: interval `target_km` is the blueprint estimate
   (`IntervalBlueprint::estimateTotalKm`) with warmup capped at 120s and
   cooldown at 300s. Real-world sessions carry a 10–15 min warmup and a long
   cooldown, so the actual run is easily 1.4–1.6× the target. The symmetric
   distance formula (`10 − deviation × 15`) turns that into a 2–4.

Because interval days have no pace score (day-level target pace is null by
design), the overall is 50% distance + 50% HR — both broken.

**Data constraint:** the app currently ingests no splits and no HR samples
(`raw_data` arrives empty apart from `route`). Per activity we have only:
distance, duration, avg pace, **avg HR, max HR**. Per-rep scoring requires
segment ingestion (HKWorkoutEvents + HR samples) — that is the structural
fix, deferred. This design is the deterministic plausibility model that works
with today's data, and stays as the fallback path for runs without segment
data once segment ingestion lands.

## Design

All changes apply ONLY when `day->type === TrainingType::Interval`. Other day
types are untouched.

### 1. HR score → max HR must touch zone (target − 1)

- Input becomes `activity->max_heartrate` instead of `average_heartrate`.
- Threshold = lower bound of zone `max(1, (target_heart_rate_zone ?? 5) − 1)`
  — a Z5 interval day requires the peaks to have at least touched Z4.
  Generalizes: a coach-set Z4 interval day requires touching Z3.
- Score: `maxHR ≥ threshold` → 10.0. Below → same slope as the existing HR
  penalty: 1 point per 5 bpm short, clamped [1, 10]. No upper penalty — Z5 is
  open-ended and high peaks are the point of intervals.
- `max_heartrate` null → score null (the avg-HR fallback must NOT kick in);
  `weightedOverall` renormalises as it already does.

### 2. Pace score → session average inside a blueprint-derived band (new)

Interval days previously always returned null. Now:

- `workAvg` = `TrainingDay::workSetAveragePaceSecondsPerKm()` (existing,
  unweighted mean of work-step paces). Null → pace score null (unchanged
  behaviour for paceless blueprints).
- `jogPace` = `IntervalBlueprint::estimateJogPace(workAvg)` (new public
  helper extracted from `estimateTotalKm`: workAvg + 100 s/km, clamped
  [180, 720]).
- Band = `[workAvg, jogPace + 90]`. The 90 s/km top margin
  (`INTERVAL_PACE_BAND_MARGIN_SECONDS`) exists because walking recoveries
  are legitimate interval execution — without a generous upper margin we'd
  recreate the avg-HR-vs-Z5 bug in pace form.
- Inside the band → 10.0. Outside → the existing deviation penalty
  (`10 − deviation% / 2.2`) measured against the nearest band edge.
  Faster than `workAvg` = recoveries skipped / wrong session; slower than
  the band = no meaningful work happened.

### 3. Distance score → asymmetric band

- `workKm` = `IntervalBlueprint::workDistanceKm(intervals_json)` (new
  helper: sum of work meters; duration-based work converts via its pace,
  falling back to the work-set average, then the jog fallback).
- Full-score band = `[workKm, target_km × 1.8]`
  (`INTERVAL_DISTANCE_OVERSHOOT_RATIO`). Anything between "just the reps"
  and "reps + a generous warmup/cooldown" is compliant.
- Below `workKm` → steep penalty, existing slope
  (`10 − deviation × 15`, deviation relative to `workKm`): the reps are
  demonstrably incomplete.
- Above the band → mild penalty (half slope, `10 − deviation × 7.5`,
  deviation relative to `target_km`): probably a mismatch or a different
  session.
- `workKm` null (no usable blueprint) → fall through to the existing
  symmetric formula.

### 4. Weights / downstream

- Interval days regain all three components → canonical 30/40/30; missing
  max HR or missing work paces renormalise via the existing
  `weightedOverall` machinery (no change there).
- `training_results.pace_score` is no longer always-null on interval days.
  Flutter + the coach panel render sub-scores generically, so they pick the
  pace bar up automatically. The "no pace row on interval days" rule in the
  Target-vs-Actual views stays — that rule keys off the day-level *target*
  pace, which remains null.
- `target_heart_rate_zone = 5` stays on interval days: it's a correct label
  for the work intensity; only the scoring interpretation changes.
- Tempo/threshold days keep avg-HR-vs-zone — a reasonable comparison for
  steady efforts.

### 5. Existing data

Already-scored interval runs carry the old broken scores. New artisan
command `compliance:rescore-intervals` re-runs `scoreDay` for every
`TrainingResult` on an interval day that has a linked activity. Idempotent,
manual trigger after deploy, `--dry-run` prints the old → new diff and rolls
back.

## Constants (tunable, on `ComplianceScoringService`)

| Constant | Value | Meaning |
|---|---|---|
| `INTERVAL_PACE_BAND_MARGIN_SECONDS` | 90 | Slack above jog pace before the avg-pace penalty starts |
| `INTERVAL_DISTANCE_OVERSHOOT_RATIO` | 1.8 | × target_km = upper edge of the full-score distance band |
| `INTERVAL_DISTANCE_UNDERSHOOT_SLOPE` | 15.0 | Penalty slope below work volume (matches the standard slope) |
| `INTERVAL_DISTANCE_OVERSHOOT_SLOPE` | 7.5 | Penalty slope above the band (half the standard slope) |
| `INTERVAL_HR_TOUCH_ZONE_FALLBACK` | 5 | Assumed target zone when an interval day has none |

## Not in scope

- Segment ingestion (HKWorkoutEvents + HR samples → per-rep pace/HR scoring,
  true time-in-zone). Structural follow-up; this scoring becomes its
  no-segment-data fallback.
- Any UI change. Both apps render whatever sub-scores exist.
- Changing the blueprint warmup cap (would ripple into watch workouts and
  plan totals for the same net effect).

## Tests

- `tests/Feature/ComplianceScoringTest.php` — interval cases rewritten:
  max-HR touch boundaries, pace band inside/faster/slower, distance band
  under/inside/over, null-HR and null-pace renormalisation paths. Existing
  non-interval tests unchanged.
- `tests/Feature/Support/IntervalBlueprintTest.php` — `workDistanceKm` +
  `estimateJogPace` cases.
- `tests/Feature/Console/RescoreIntervalComplianceTest.php` — command
  recomputes stale interval results, skips non-interval ones.
