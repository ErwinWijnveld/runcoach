# Plan feasibility analysis in the proposal modal

**Date:** 2026-05-12
**Status:** design

## Problem

For goal types where the runner sets a measurable target — `train_for_race` with a goal time, `pr_attempt`, and `get_faster_at_distance` — they can pick a target that is numerically unreachable given their current fitness, available weeks, and supportable volume. `PlanAmbitionAnalyzer` already computes this judgement (`realistic` / `ambitious` / `very_ambitious`, plus the underlying pace gap and volume ratio), and the onboarding agent uses it to paraphrase a soft warning in chat. But:

- The assessment never surfaces visually inside the plan-details modal — the runner sees the plan and the Accept button without any signal about whether the goal itself is realistic.
- The agent's paraphrased warning lives in the chat above the proposal card; once the runner taps "View Details" the warning is out of view.
- There is no escalation: a 12-week 5K goal that demands 38 sec/km/month of improvement (3× the realistic baseline) looks identical in the UI to a perfectly-paced plan.

## Goal

Render a single feasibility score (0-100%) with a horizontal zone-bar inside `PlanDetailsSheet`, and escalate the Accept CTA to a red "Adjust goal" CTA when the score falls below 40%.

Scope is limited to proposals where a measurable goal exists. Plans for `complete_a_race` (no goal time), `general_fitness`, and `weight_loss` do not render the section.

## Non-goals

- Localising verdict copy (Dutch strings are fine; matches the rest of the app).
- Showing feasibility on plan-revision proposals (the diff view is the affordance for tweaks).
- A live re-render of feasibility while the user moves the intensity-bias slider during onboarding (decorative chart there is enough).
- Re-scoring an active goal after acceptance — feasibility is a pre-accept signal, not an ongoing dashboard widget.

## User flow

1. Runner finishes onboarding or asks the coach for a new plan → agent calls `BuildPlan`.
2. `BuildPlan` persists a pending `CoachProposal` whose payload now carries an `ambition` block.
3. Proposal card appears in chat → runner taps "View Details".
4. `PlanDetailsSheet` opens. Below the header, before the top-stats row, a **Feasibility** section renders:
   - Italic Garamond verdict label on the left ("Pittig maar haalbaar"), big Space-Grotesk percentage on the right (colour follows zone).
   - Horizontal zone-bar (red 0-35% / amber 35-70% / green 70-100% linear gradient) with a 4×22px black pointer marking where this plan lands.
   - Axis labels under the bar: `Onhaalbaar · Stretch · Goed`.
   - One-sentence detail line ("10 sec/km/maand verbetering nodig — binnen normaal voor jouw volume.").
5. Below: existing top-stats + weekly volume chart + per-week cards (unchanged).
6. Sticky footer:
   - **ok** (≥70%) or **stretch** (40-69%) → unchanged gold Accept + light-tan Adjust.
   - **unrealistic** (<40%) → primary CTA flips to red `ADJUST GOAL FOR REALISTIC PLAN`; Accept demotes to a secondary "Accept anyway" tan button below it.
7. Tap red CTA → sheet pops → chat input gets prefilled with `ambition.adjust_prefill` and focuses. Runner can edit/send; the agent then calls `BuildPlan` (or `AdjustPlan`) with the new target.

## Architecture

### 1. Backend — `AmbitionAssessment::toFeasibilityPayload()`

New nullable accessor on `app/Support/Onboarding/AmbitionAssessment.php`. Returns `null` when `paceGapSecondsPerKm === null` (no measurable goal — no feasibility to compute). Otherwise:

```php
[
  'feasibility_pct' => int,                            // 0..100
  'pace_score_pct' => int,                             // 0..100
  'volume_score_pct' => int,                           // 0..100
  'verdict_zone' => 'ok' | 'stretch' | 'unrealistic',
  'verdict_label' => string,                           // 'Pittig maar haalbaar' etc.
  'detail' => string,                                  // one-line explanation
  'pace_gap_seconds_per_km' => int,
  'required_improvement_per_month_seconds' => int,
  'adjust_prefill' => string,                          // chat prefill copy when unrealistic
]
```

**Computation:**

- `paceFeasibility01 = min(1.0, PlanAmbitionAnalyzer::REALISTIC_IMPROVEMENT_PER_MONTH / improvementPerMonthSeconds)` — clamped to `[0, 1]`. A goal that demands exactly the realistic rate scores 1.0; double that rate scores 0.5.
- `volumeFeasibility01 = volumeRatio === null ? 1.0 : min(1.0, volumeRatio)` — defaults to 1.0 when no volume signal (rare; means general-fitness-style plans, which this method already filtered out via the null pace gap, but keep the clamp defensive).
- `feasibility01 = paceFeasibility01 * 0.6 + volumeFeasibility01 * 0.4` — pace is the dominant blocker, volume is the secondary one. Public constants on the class so they're easy to tune.
- `feasibility_pct = round(feasibility01 * 100)`.
- Zone thresholds (also class constants): `ZONE_OK_MIN = 70`, `ZONE_STRETCH_MIN = 40`. Below 40 → `unrealistic`.

**Verdict labels and details** are picked from a small in-class map keyed by `verdict_zone`. The detail string interpolates the actual numbers (`required_improvement_per_month_seconds`, `volume_score_pct`) so it stays specific to this runner.

**`adjust_prefill`** is a fixed Dutch sentence keyed to whether `target_date` is locked: when locked, prefill suggests adjusting the goal time; when open-ended, suggests either extending the timeline or softening the time.

### 2. Backend — wire payload through `BuildPlan`

`api/app/Ai/Tools/BuildPlan.php` already returns `ambition` in the tool JSON output, but `CoachProposal.payload` does not carry it. Single insertion before `proposals->persistPending(...)`:

```php
$ambitionPayload = $assessment->toFeasibilityPayload();
if ($ambitionPayload !== null) {
    $payload['ambition'] = $ambitionPayload;
}
```

`payload` is already a JSON column — no migration. Old proposals without `ambition` keep working: the Flutter widget renders nothing when the key is missing.

The existing `'ambition' => $assessment->toFitnessSummary()` field in the tool's JSON return (for the agent's reply paraphrasing) stays — it serves a different consumer.

### 3. Flutter — `_FeasibilityZoneBar` widget

Lives inline in `app/lib/features/coach/widgets/plan_details_sheet.dart` (matches existing pattern of `_WeeklyVolumeChart`, `_TopStats`, etc. — single-file modal). Reads from `proposal.payload['ambition']` as a `Map<String, dynamic>`.

**Render guards:**
- `proposal.payload['ambition'] == null` → return `SizedBox.shrink()`.
- `ops != null` (revision) → return `SizedBox.shrink()`.

**Layout** (mirrors Variant B from the brainstorming mockup):
- `Container` with `BorderRadius.circular(18)`, padding `20px 18px 18px`.
- Background colour: `AppColors.lightTan` when zone is `ok` or `stretch`, `AppColors.dangerBg` (new colour token, soft red) when `unrealistic`.
- Header row: verdict label (italic Garamond 20pt) + percentage (Space Grotesk 28pt 700, colour from zone).
- Zone track: 14px tall, `BorderRadius.circular(8)`, linear gradient red→amber→green at the breakpoints above.
- Pointer: `Positioned` 4×22px black stick, white halo via `BoxShadow`, `left: percent% - 2px`.
- Axis: 3 small Space-Grotesk labels evenly distributed.
- Detail line: `Public Sans` 12.5pt muted, line-height 1.45.

Inserted between `_Header` and `_TopStats` in the column.

### 4. Flutter — `_StickyFooter` escalation

Extend `_StickyFooter` with a new boolean `warnUnrealistic` (computed by the caller from `ambition['verdict_zone'] == 'unrealistic'`). When true:

- Primary button: full-width `ElevatedButton`, `backgroundColor: AppColors.danger`, white label "ADJUST GOAL FOR REALISTIC PLAN".
- Secondary button below: full-width `ElevatedButton`, `backgroundColor: AppColors.lightTan`, label "Accept anyway".
- Adjust button (existing tan button next to Accept in the ok/stretch state) is hidden — the red CTA replaces it.

Otherwise: existing layout unchanged.

### 5. Flutter — Adjust-goal callback wiring

`PlanDetailsSheet` already has an `onAdjust` callback (currently: close sheet + focus chat input). To carry the prefill, extend the signature:

- Existing: `Future<void> Function()? onAdjust`.
- New: `Future<void> Function({String? prefill})? onAdjust`.

The "Adjust" button on ok/stretch states calls `onAdjust()` (no prefill — runner types their own). The red "Adjust goal" button on unrealistic state calls `onAdjust(prefill: ambition['adjust_prefill'])`.

The caller (`features/coach/widgets/proposal_card.dart` is the main one; also any other surface that opens the sheet) handles the prefill by setting the chat input's text controller before focusing it. Reuse `coach_provider.dart`'s existing prompt-input controller; if the controller isn't already exposed, add an `ensurePromptText(String text)` action to the coach provider so the sheet doesn't reach into private widget state.

## Data flow

```
PlanAmbitionAnalyzer::analyze
    ↓ returns AmbitionAssessment
BuildPlan::handle
    ├─ $assessment->toFeasibilityPayload()  →  $payload['ambition']  →  CoachProposal.payload (JSON)
    └─ $assessment->toFitnessSummary()      →  tool JSON return        →  agent's reply paraphrasing
                                                                       (unchanged path)

Flutter:
CoachProposal.payload['ambition']
    ↓ Map<String, dynamic>
_FeasibilityZoneBar (renders zone bar + verdict)
_StickyFooter (escalates CTAs when verdict_zone == 'unrealistic')
    ↓ tap red CTA
onAdjust(prefill: ...)  →  coach prompt controller  →  chat input focused with prefilled text
```

## Edge cases

- **Old proposals (pre-deploy)**: `payload['ambition']` is missing → section + CTA escalation both skip silently.
- **Revisions** (`ops != null`): section skipped (no scope for plan-level feasibility on a tweak).
- **Goal with no measurable target** (`pace_gap_seconds_per_km` was null at compute time): `toFeasibilityPayload()` returns `null` → no `payload['ambition']` → section skipped.
- **Volume ratio is null but pace gap exists** (rare; means non-standard distance): clamp volume feasibility to 1.0, score from pace only — defensive, doesn't crash.
- **Score exactly at boundary** (40 or 70): `>=` semantics — 70 is `ok`, 40 is `stretch`. Boundaries are class constants.
- **AdjustPlan re-build**: if the agent later calls `AdjustPlan` and supersedes the pending proposal, the new proposal gets its own `ambition` payload via the same `persistPending` path inside `AdjustPlan`. Add the same `$payload['ambition'] = $assessment->toFeasibilityPayload()` line in `AdjustPlan::handle()` for parity.
- **Coach chat (post-onboarding) rebuild**: `BuildPlan` is the same tool used by `RunCoachAgent`, so the fix benefits coach-driven rebuilds for free.

## Files touched

| File | Change |
|---|---|
| `api/app/Support/Onboarding/AmbitionAssessment.php` | + `toFeasibilityPayload(): ?array`, + class constants for weights and thresholds |
| `api/app/Ai/Tools/BuildPlan.php` | Inject `$ambitionPayload` into `$payload` before `persistPending()` |
| `api/app/Ai/Tools/AdjustPlan.php` | No change — `AdjustPlan` produces revision proposals (carrying a `diff`) and the modal's render guard already skips feasibility on revisions. Goal-time changes inside `AdjustPlan::set_goal` are out of scope for v1; the next full `BuildPlan` recomputes feasibility |
| `api/tests/Feature/Support/AmbitionAssessmentTest.php` | New: cover the 3 zones + the null-when-no-pace-gap case + the weight/threshold maths |
| `api/tests/Feature/Ai/Tools/BuildPlanTest.php` | Update existing tests to assert `payload['ambition']` is present when goal has time; absent when no measurable goal |
| `app/lib/features/coach/widgets/plan_details_sheet.dart` | + `_FeasibilityZoneBar`, + `warnUnrealistic` branch in `_StickyFooter`, + extended `onAdjust` signature |
| `app/lib/features/coach/widgets/proposal_card.dart` (or whichever caller mounts the sheet) | Pass `prefill` through to coach prompt controller |
| `app/lib/features/coach/providers/coach_provider.dart` | + `ensurePromptText(String text)` action if controller isn't already exposed |
| `app/lib/core/theme/app_theme.dart` | + `AppColors.danger`, `AppColors.dangerBg` if not already present (verify before adding) |
| `app/test/features/coach/widgets/plan_details_sheet_feasibility_test.dart` | New widget test: 3 zones render correctly, missing payload skips, revision skips, red CTA fires `onAdjust(prefill: …)` |

## Tunable constants (and where to find them)

In `AmbitionAssessment.php`:
- `PACE_WEIGHT = 0.6`, `VOLUME_WEIGHT = 0.4` — composite mix.
- `ZONE_OK_MIN = 70`, `ZONE_STRETCH_MIN = 40` — verdict thresholds.

In `PlanAmbitionAnalyzer.php` (already exist, unchanged):
- `REALISTIC_IMPROVEMENT_PER_MONTH = 12.0` — denominator for pace feasibility.
- `MIN_VOLUME_FOR_RACE_PREP` — feeds `volumeRatio` which becomes volume feasibility.

These live server-side so we can tune without a Flutter release.

## Open questions resolved during brainstorming

- **Visualisation**: Variant B (horizontal zone bar with pointer) — picked because it shows the "where am I on the spectrum" affordance at a glance, and the gradient communicates the gradient nature of feasibility better than a single dial.
- **Adjust target**: Coach chat with prefilled message — consistent with the existing Adjust button and lets the agent decide between `BuildPlan` and `AdjustPlan` based on the runner's edit.
- **Scope**: Only goal types where a measurable target exists. `complete_a_race` and goalless plans skip the section entirely.
