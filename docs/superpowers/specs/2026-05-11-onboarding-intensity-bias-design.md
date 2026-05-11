# Onboarding — intensity bias slider

**Status:** Draft, ready for implementation
**Date:** 2026-05-11
**Author:** Erwin + Claude

---

## 1. Problem

Today RunCoach's first plan is generated entirely from form inputs + auto-detected fitness. `PlanAmbitionAnalyzer` compares `goal_pace − current_pace` against `REALISTIC_IMPROVEMENT_PER_MONTH` and classifies the goal as `Realistic` / `Ambitious` / `VeryAmbitious` — driving a peak-volume multiplier (1.6× / 1.7× / 1.8×) and optional plan-length extension. This is invisible to the runner.

Two gaps:

1. **No user lever.** A runner whose goal looks "realistic" to the analyzer may still want to push themselves harder during the build — or, equally, may want to dial it back ("I'm coming back from a tough year, give me an easy ramp even though my goal time is modest"). Today they have no say.
2. **No tangible visualization.** The runner has no idea what the difference between "ambitious" and "realistic" actually looks like in their week-to-week plan. The plan arrives as a fait accompli on the chat screen.

The fix: a single new form step where the runner picks an intensity bias (`Take it easy` / `Standard` / `Push me harder`), with a decorative animated ramp curve so the choice feels tangible. The bias shifts the analyzer's output ±1 level against an extended 5-tier table.

---

## 2. Goals / non-goals

### Goals

1. Add **one new form step** at position 11 of 12 (after `coachStyle`, before `review`) where the runner picks an intensity bias.
2. **Bias the auto-detected ambition ±1 level** with extended `Conservative` floor and `AllIn` ceiling, so every slider position has a real effect even when auto is at an extreme.
3. **Surface the choice** via a decorative animated ramp curve that visually changes between the three positions.
4. **Persist the choice** on `users.intensity_bias` so coach-chat plan rebuilds reuse it without re-asking.
5. **Inform the AI's reply** so the OnboardingAgent's friendly post-build sentence reflects what the runner picked.

### Non-goals

- Letting the slider control **plan length**. Length stays governed by `target_date` or `default_weeks_for_goal`; `weeksExtension` (auto's existing lever) remains untouched.
- A settings surface for editing intensity bias outside onboarding. Future polish; today the runner just answers it once and gets a coach-chat tool later when we need it.
- Computing the **actual** plan curve as a backend preview. The visualization is purely decorative — three hardcoded curve shapes in Dart that tween between each other. Real impact appears in the post-acceptance plan.
- Continuous-slider UX (drag-a-knob 0-100%). Three discrete positions only.
- New `AmbitionLevel` enum cases at runtime — the five levels are an internal `EffectiveAmbitionLevel` computed inside `AmbitionAssessment::applyBias()`, not a new persisted enum.
- A way to set intensity per-goal (different bias for next race vs first race). v1 stores one value per user.

---

## 3. UI design

### 3a. The new step

Inserted into `_Step` enum in `app/lib/features/onboarding/screens/onboarding_form_screen.dart` between `coachStyle` and `review`:

```dart
enum _Step {
  goalType,
  distance,
  raceName,
  raceDate,
  goalTime,
  prCurrent,
  daysPerWeek,
  preferredWeekdays,
  runTypePreferences,
  coachStyle,
  intensity,   // ← new
  review,
}
```

`_flowFor()` adds `intensity` for every goal type (race, pr, fitness, weight_loss). All four flows reach this step. Per-flow step counts after this change:

| Flow | Steps before | After |
|---|---|---|
| race | 11 | 12 |
| pr | 10 | 11 |
| fitness | 6 | 7 |
| weight_loss | 6 | 7 |

### 3b. Layout

```
Step 11 of 12

How hard do you want this?
Based on your goal we lean ambitious.
Bump up or down if you feel different.

┌────────────────────────────────────┐
│  WEEKLY KM                         │   ← gold-glow eyebrow pill
│                                    │
│             ░░░                    │   bars: warmBrown
│          ░░░░░░░                   │
│       ░░░░░░░░░░░░                 │
│   ░░░░░░░░░░░░░░░░░  ▓             │   final bar = race day, gold
│   ─────────────────────            │
│   W1  …  peak  …  race             │
│                                    │
│  «caption animates with slider»    │
└────────────────────────────────────┘

  ┌─────────────┬───────────┬─────────────┐
  │ Take it     │ Standard  │  Push me    │
  │   easy      │           │   harder    │
  └─────────────┴───────────┴─────────────┘
                     ▲
              (auto-pick)              ← fades out when user picks another

   Tap to bias the build.

       [ Continue ]
```

Wrapped in the standard `StepScaffold` — same shell as every other form step.

### 3c. Curve component (decorative)

Three hardcoded `List<double>` arrays of equal length (13 entries), normalized to 0-1 — bar height = `value * chartHeight`.

```dart
const _curveTakeItEasy   = [0.30, 0.40, 0.50, 0.38, 0.55, 0.62, 0.68, 0.52, 0.72, 0.72, 0.58, 0.42, 0.22];
const _curveStandard     = [0.35, 0.48, 0.58, 0.42, 0.68, 0.78, 0.85, 0.60, 0.88, 0.82, 0.66, 0.46, 0.24];
const _curvePushMeHarder = [0.40, 0.55, 0.68, 0.50, 0.80, 0.92, 1.00, 0.72, 1.00, 0.90, 0.72, 0.50, 0.26];
```

Shape encodes: ramp → cutback @ week 4 → peak weeks 7-9 → cutback @ week 8 → taper → race-day bar (the last entry, rendered in `AppColors.gold` to distinguish from the warmBrown build bars).

**Tweening:** `TweenAnimationBuilder<List<double>>` interpolates element-wise over 350ms `Curves.easeInOutCubic` whenever the selected bias changes. `CustomPainter` draws bars from the current tween value × chart height. ~80 lines of Dart in total.

No real-data dependency. No backend call. No fitness-snapshot lookup. The curve is purely visual feedback for the slider position.

### 3d. Caption (animates with slider)

| Slider | Caption |
|---|---|
| `take_it_easy` | *"Gentler bumps, lower peak. Sustainable."* |
| `standard` | *"Steady weekly progression. Auto-picked."* |
| `push_me_harder` | *"Steeper ramp, higher peak. Stay sharp."* |

`AnimatedSwitcher` with a 200ms crossfade. Public Sans 14pt, `AppColors.inkMuted`.

### 3e. Segmented control

Custom three-segment widget (NOT a Material `SegmentedButton` — wrong visual language). Same `AppColors.primaryInk` / `lightTan` / `cream` palette as `_WeekdayTile` and `_RunTypeRankCard`.

Selected segment:
- Background: `AppColors.primaryInk`
- Text color: `AppColors.cream`
- `BorderRadius.circular(14)`

Unselected:
- Background: `Colors.white`
- Text color: `AppColors.primaryInk`
- 1px border `AppColors.inputBorder`

**Auto-pick affordance:** below the "Standard" segment, a tiny `(auto-pick)` label in `AppColors.inkMuted` Public Sans 11pt. `AnimatedOpacity` fades it out when the user picks another segment; fades back in if they re-select Standard.

### 3f. Continue gating

`canContinue: true` always. `Standard` is the default and a valid choice; the runner can skip past this step without interaction and get the same plan they would have gotten today.

### 3g. Review step

New row added in `_ReviewStep`'s review card, between "Coach style" and "Notes":

```
Coach style       Balanced
Intensity         Push me harder
Notes             …
```

Use the same `_reviewRow(label, value)` helper. Hide the row when bias = `standard` to keep the recap tight (Standard is the default; no point listing it).

---

## 4. Backend architecture

### 4a. Where the bias is applied

```
User submits POST /onboarding/generate-plan with `intensity_bias` in payload
        │
        ▼
GeneratePlan job
        │
        ▼
OnboardingPlanGeneratorService::generate($user, $payload)
        a. Persist users.intensity_bias = payload.intensity_bias    ← NEW
        b. snapshot = FitnessSnapshotService::snapshot($user)        (unchanged)
        c. ambition = PlanAmbitionAnalyzer::analyze(...)             (unchanged)
        d. ambition = ambition->applyBias($user->intensityBias)     ← NEW
        e. payload  = TrainingPlanBuilder::build($snapshot, $form, $ambition)
        f. payload  = PlanOptimizerService::optimize($payload, $user)
        g. proposal = ProposalService::persistPending(...)
```

The bias is applied to the analyzer's **output**, not its input. Reasons:

- The analyzer's feasibility assessment (`improvementPerMonth`, `volumeRatio`, etc.) still considers the runner's actual fitness vs goal pace — the safety signal stays intact.
- The bias just shifts the resulting `level + peakVolumeMultiplier + secondary knobs`.
- The `summary` and `suggestion` strings on `AmbitionAssessment` get recomputed for the post-bias level so the AI's reply reflects what the runner actually got.

### 4b. `AmbitionAssessment::applyBias()`

New pure method on `app/Support/Onboarding/AmbitionAssessment.php`:

```php
public function applyBias(IntensityBias $bias): self
{
    $shift = match ($bias) {
        IntensityBias::TakeItEasy => -1,
        IntensityBias::Standard => 0,
        IntensityBias::PushMeHarder => +1,
    };

    if ($shift === 0) {
        return $this;
    }

    $effective = EffectiveAmbitionLevel::shiftFrom($this->level, $shift);

    return new self(
        level: $this->level,                           // original auto-detected level retained
        effectiveLevel: $effective,                    // NEW field — post-bias
        paceGapSecondsPerKm: $this->paceGapSecondsPerKm,
        improvementPerMonthSeconds: $this->improvementPerMonthSeconds,
        volumeRatio: $this->volumeRatio,
        peakVolumeMultiplier: $effective->peakVolumeMultiplier(),
        weeklyGrowthRatio: $effective->weeklyGrowthRatio(),
        qualityPaceRampGain: $effective->qualityPaceRampGain(),
        weeksExtension: $this->weeksExtension,         // unchanged — slider doesn't move plan length
        summary: $this->buildSummaryFor($effective),
        suggestion: $this->buildSuggestionFor($effective, $bias),
    );
}
```

`buildSummaryFor()` and `buildSuggestionFor()` are refactors of the existing private builders — they take an `EffectiveAmbitionLevel` (not raw `AmbitionLevel`) and an optional `IntensityBias` to color the message ("you asked for a tougher build, so this plan sits at the upper edge of what your fitness supports").

### 4c. New value object: `EffectiveAmbitionLevel`

Lives at `app/Support/Onboarding/EffectiveAmbitionLevel.php`. Five-case backed enum, each case knows its three multiplier values:

```php
enum EffectiveAmbitionLevel: string
{
    case Conservative = 'conservative';   // floor — only reached via take_it_easy on Realistic auto
    case Realistic = 'realistic';
    case Ambitious = 'ambitious';
    case VeryAmbitious = 'very_ambitious';
    case AllIn = 'all_in';                // ceiling — only reached via push_me_harder on VeryAmbitious auto

    public function peakVolumeMultiplier(): float
    {
        return match ($this) {
            self::Conservative => 1.45,
            self::Realistic => 1.60,
            self::Ambitious => 1.70,
            self::VeryAmbitious => 1.80,
            self::AllIn => 1.95,
        };
    }

    public function weeklyGrowthRatio(): float
    {
        return match ($this) {
            self::Conservative => 1.22,
            self::Realistic => 1.27,
            self::Ambitious => 1.30,
            self::VeryAmbitious => 1.33,
            self::AllIn => 1.36,
        };
    }

    public function qualityPaceRampGain(): float
    {
        return match ($this) {
            self::Conservative => 0.85,
            self::Realistic => 0.92,
            self::Ambitious => 1.00,
            self::VeryAmbitious => 1.10,
            self::AllIn => 1.20,
        };
    }

    public static function shiftFrom(AmbitionLevel $base, int $shift): self
    {
        $ordered = [self::Conservative, self::Realistic, self::Ambitious, self::VeryAmbitious, self::AllIn];
        $baseIndex = match ($base) {
            AmbitionLevel::Realistic => 1,
            AmbitionLevel::Ambitious => 2,
            AmbitionLevel::VeryAmbitious => 3,
        };

        return $ordered[max(0, min(4, $baseIndex + $shift))];
    }

    public static function fromAmbitionLevel(AmbitionLevel $level): self
    {
        return self::shiftFrom($level, 0);
    }
}
```

The old `AmbitionLevel` enum stays untouched — it's the "auto-detect output" and the new `EffectiveAmbitionLevel` is "what the builder sees after bias is applied."

### 4d. New enum: `IntensityBias`

Lives at `app/Enums/IntensityBias.php`:

```php
enum IntensityBias: string
{
    case TakeItEasy = 'take_it_easy';
    case Standard = 'standard';
    case PushMeHarder = 'push_me_harder';
}
```

### 4e. `AmbitionAssessment` shape changes

Three new readonly fields on the existing value object:

| Field | Type | Default when no bias applied | Notes |
|---|---|---|---|
| `effectiveLevel` | `EffectiveAmbitionLevel` | derived from `level` via `fromAmbitionLevel()` | Post-bias level. |
| `weeklyGrowthRatio` | `float` | `1.30` (Ambitious value, matching today's `MAX_WEEKLY_GROWTH_RATIO`) | Was a builder constant, now per-level. |
| `qualityPaceRampGain` | `float` | `1.00` (Ambitious value, matching today's behavior) | New scalar multiplied into the `progress` ramp. |

The existing `peakVolumeMultiplier` field stays — its default is now derived from `effectiveLevel->peakVolumeMultiplier()` instead of a hardcoded `match` on `AmbitionLevel`.

### 4f. `TrainingPlanBuilder` consumes the new fields

| File location | Change |
|---|---|
| `api/app/Services/Onboarding/TrainingPlanBuilder.php` line ~310 (`resolvePeakKm`) | Already reads `$ambition?->peakVolumeMultiplier`. No change needed; just confirm assessment passes through. |
| `api/app/Services/Onboarding/TrainingPlanBuilder.php` line ~373 (`buildWeeklyVolumeCurve`) | Replace `self::MAX_WEEKLY_GROWTH_RATIO` with `$ambition?->weeklyGrowthRatio ?? self::MAX_WEEKLY_GROWTH_RATIO`. |
| `api/app/Services/Onboarding/TrainingPlanBuilder.php` `tempoPace()` (~line 946) | Multiply the computed `progress` value by `$ambition?->qualityPaceRampGain ?? 1.0`, then clamp `min($progress * $gain, 1.0)`. |
| `api/app/Services/Onboarding/TrainingPlanBuilder.php` `intervalBlueprint()` workPace ramp (~line 1029) | Same `qualityPaceRampGain` multiplier on the progress scalar. |

The `MAX_WEEKLY_GROWTH_RATIO` constant on the class is kept as a fallback for callers that don't pass an `AmbitionAssessment` (theoretically just unit tests).

### 4g. OnboardingAgent prompt update

Add to `app/Ai/Agents/OnboardingAgent.php` instructions:

> If the user picked a non-`standard` `intensity_bias`, briefly acknowledge it in your reply:
> - `take_it_easy` → "I dialed back the ramp a bit since you asked to ease in — week-to-week jumps are smaller and the peak is lower."
> - `push_me_harder` → "You asked for a tougher build, so this plan sits at the upper edge of what your fitness can support. Recovery becomes more important than usual."
>
> Don't repeat the level name ("ambitious", "all-in"). Don't use jargon. Speak to the *experience*. One sentence max.

The agent gets `intensity_bias` from the priming message (form payload).

---

## 5. Schema changes

### 5a. Migration (forward-only, idempotent)

`database/migrations/2026_05_11_NNNNNN_add_intensity_bias_to_users.php`:

```php
public function up(): void
{
    Schema::table('users', function (Blueprint $table): void {
        if (! Schema::hasColumn('users', 'intensity_bias')) {
            $table->string('intensity_bias', 16)
                ->default('standard')
                ->after('coach_style');
        }
    });
}
```

Per `api/CLAUDE.md` rule: forward-only, idempotent guard via `Schema::hasColumn`. No index — column is only read per-row.

### 5b. User model

```php
// app/Models/User.php
#[Fillable]
protected $fillable = [
    // ... existing ...
    'intensity_bias',
];

protected $casts = [
    // ... existing ...
    'intensity_bias' => IntensityBias::class,
];
```

### 5c. `OnboardingFormInput`

Add `intensityBias` to the constructor in `app/Support/Onboarding/OnboardingFormInput.php`:

```php
final readonly class OnboardingFormInput
{
    public function __construct(
        // ... existing ...
        public IntensityBias $intensityBias,
    ) {}
}
```

`OnboardingFormInput::fromArray()` parses `intensity_bias` (string) into the enum, falling back to `IntensityBias::Standard` when missing/invalid.

---

## 6. API changes

### 6a. `POST /onboarding/generate-plan`

Request body gains an optional field:

```json
{
  "goal_type": "race",
  "distance_meters": 21097,
  ...
  "coach_style": "balanced",
  "intensity_bias": "push_me_harder"
}
```

Validation in `GeneratePlanRequest` (FormRequest):

```php
'intensity_bias' => ['nullable', 'string', 'in:take_it_easy,standard,push_me_harder'],
```

When null/missing, the service persists `IntensityBias::Standard`. Fully back-compat with old clients.

### 6b. `GET /profile` + `/auth/apple` / `/auth/dev-login` responses

Add `intensity_bias` (string) to the `User` resource so the Flutter app can:
- Render it on a future settings screen
- Prefill the onboarding form if the user runs onboarding twice

No PUT endpoint in v1 — bias is only set via `/onboarding/generate-plan`.

---

## 7. Flutter changes

### 7a. New files

| File | Purpose |
|---|---|
| `app/lib/features/onboarding/widgets/intensity_bias_chart.dart` | `CustomPainter` bar curve with `TweenAnimationBuilder<List<double>>`. |
| `app/lib/features/onboarding/widgets/intensity_bias_segmented_control.dart` | Three-segment selector + auto-pick affordance. |

The `IntensityBias` enum lives inline in `app/lib/features/onboarding/models/onboarding_form_data.dart` — small enough not to warrant its own file.

### 7b. Modified files

| File | Change |
|---|---|
| `app/lib/features/onboarding/screens/onboarding_form_screen.dart` | Add `_Step.intensity`, `_IntensityStep` widget, route through it in every `_flowFor` branch. Add intensity row to `_ReviewStep` (hide when bias = standard). |
| `app/lib/features/onboarding/models/onboarding_form_data.dart` | Add `intensityBias` field (`IntensityBias` enum, default `IntensityBias.standard`) + Freezed regen. Add the enum at file bottom. |
| `app/lib/features/onboarding/providers/onboarding_form_provider.dart` | `setIntensityBias(IntensityBias bias)` method. |
| `app/lib/features/onboarding/data/onboarding_api.dart` | Include `intensity_bias` in the `generate-plan` request body. |
| `app/lib/features/auth/models/user.dart` | Add `intensityBias` field for round-trip from `/profile`. |

### 7c. New Flutter enum

```dart
enum IntensityBias {
  takeItEasy('take_it_easy'),
  standard('standard'),
  pushMeHarder('push_me_harder');

  const IntensityBias(this.wire);
  final String wire;

  static IntensityBias fromWire(String? s) =>
      IntensityBias.values.firstWhere(
        (b) => b.wire == s,
        orElse: () => IntensityBias.standard,
      );
}
```

### 7d. Code-gen rerun

After Freezed changes:

```bash
cd app
dart run build_runner build --delete-conflicting-outputs
```

---

## 8. Edge cases

| # | Scenario | Outcome |
|---|---|---|
| 1 | Existing user (pre-migration), reopens onboarding | Column defaults to `'standard'`. No special handling. |
| 2 | Auto = Realistic + slider = Take it easy | Effective = `Conservative` (1.45×). Plan is gentler than today's minimum. |
| 3 | Auto = VeryAmbitious + slider = Push me harder | Effective = `AllIn` (1.95×). AI reply MUST mention recovery emphasis. |
| 4 | Auto = VeryAmbitious + slider = Take it easy | Effective = `Ambitious` (1.7×). Safer build for an aggressive goal. |
| 5 | No `goal_time` (fitness / weight_loss) | `PlanAmbitionAnalyzer::analyze()` returns `realistic()` (no comparison possible). Slider still works, shifts to Conservative or Ambitious. |
| 6 | Runner runs onboarding twice (after manual wipe) | Second time: `users.intensity_bias` retains first answer. Form prefills with that value (read from `/profile`). Submitting overwrites it. |
| 7 | Coach-chat `BuildPlan` rebuild months later | `OnboardingFormInput::fromArray` reads `users.intensity_bias` as the default when the tool didn't pass it explicitly. The bias is "sticky" until the runner changes it via a future settings screen or coach tool. |
| 8 | Old API client (pre-feature) without `intensity_bias` | Validator treats it as nullable → service writes `Standard` → plan generates identically to today. Fully back-compat. |
| 9 | Tween in-flight when step is rebuilt | `TweenAnimationBuilder` animates from current value toward new target — no visual snap. |
| 10 | Push me harder + very low `weeklyKmRecent4Weeks` (e.g. 8 km/wk) | Peak = 8 × 1.95 = 15.6 km/wk. The `PEAK_KM_FOR_DISTANCE` floor still kicks in (e.g. 25km for 5k goal); whichever is higher applies. No collapse. |
| 11 | `qualityPaceRampGain > 1.0` could overshoot 100% progress | `min($progress * $gain, 1.0)` clamp in `tempoPace()` and `intervalBlueprint()` — can only reach goal pace faster, never beyond. |
| 12 | User changes bias mid-form (e.g. back to step 11, picks different) | Form state updates. Curve re-tweens to new shape. On submit, latest value wins. |
| 13 | Test fixture passes assessment without `applyBias` | `peakVolumeMultiplier` falls back to `effectiveLevel->peakVolumeMultiplier()` derived from `fromAmbitionLevel()`. `weeklyGrowthRatio` and `qualityPaceRampGain` default to Ambitious values. Existing test snapshots unchanged. |

---

## 9. Test plan

### Backend (PHPUnit)

**`tests/Unit/Support/Onboarding/EffectiveAmbitionLevelTest.php`** (new):
- `shiftFrom(Realistic, -1)` → `Conservative`
- `shiftFrom(Realistic, 0)` → `Realistic`
- `shiftFrom(Realistic, +1)` → `Ambitious`
- `shiftFrom(VeryAmbitious, +1)` → `AllIn` (ceiling clamp)
- `shiftFrom(Realistic, -2)` → `Conservative` (floor clamp; can't be reached via single bias but matters for future-proofing)
- Each level's `peakVolumeMultiplier()` / `weeklyGrowthRatio()` / `qualityPaceRampGain()` returns the table value.
- `fromAmbitionLevel(Realistic)` → `Realistic` (zero-shift parity).

**`tests/Unit/Support/Onboarding/AmbitionAssessmentApplyBiasTest.php`** (new):
- `applyBias(Standard)` → original assessment unchanged (identity).
- `applyBias(TakeItEasy)` on Realistic-auto → `effectiveLevel = Conservative`, `peakMult = 1.45`, `gain = 0.85`, summary mentions "gentler build".
- `applyBias(PushMeHarder)` on VeryAmbitious-auto → `effectiveLevel = AllIn`, `peakMult = 1.95`, suggestion mentions recovery emphasis.
- `weeksExtension` is unchanged by every `applyBias` call.

**`tests/Feature/Services/Onboarding/TrainingPlanBuilderTest.php`** (extend):
- Same form fixture × each of the 5 effective levels → assert `peak_km` scales monotonically with `peakVolumeMultiplier`.
- AllIn produces W-o-W jumps up to ~36% (vs ~30% for Ambitious).
- Conservative produces tempo paces that approach goal pace gentler (smaller pace delta from baseline by week T-3 than Ambitious).

**`tests/Feature/Jobs/GeneratePlanJobTest.php`** (extend):
- POST with `intensity_bias: 'push_me_harder'` → `users.intensity_bias` updated to `push_me_harder` → resulting proposal payload's peak `weeks[].total_km` matches AllIn (or VeryAmbitious-clamped) multiplier within tolerance.
- POST without `intensity_bias` → defaults to `standard`, behaves identically to current main.
- POST with invalid `intensity_bias` → 422.

**`tests/Feature/Http/OnboardingProfileTest.php`** (extend if exists, or new):
- `GET /profile` response includes `intensity_bias` for a user with the column set.

### Flutter

**`app/test/features/onboarding/intensity_step_test.dart`** (new):
- Widget renders three segments with labels "Take it easy", "Standard", "Push me harder".
- `Standard` segment is selected by default; `(auto-pick)` label is visible beneath it.
- Tap "Push me harder" → segment selection flips, caption text changes to the harder copy, `(auto-pick)` label fades out.
- Tap Continue → `onboardingFormProvider`'s state has `intensityBias == IntensityBias.pushMeHarder`.

**`app/test/features/onboarding/intensity_bias_chart_test.dart`** (new):
- Initial paint: chart paints 13 bars at the `_curveStandard` heights.
- After 350ms with `IntensityBias.pushMeHarder` selected, painter renders bars matching `_curvePushMeHarder`.
- Last bar is rendered in `AppColors.gold` regardless of bias.

### Manual E2E

On a fresh `DevOnboardingSeeder` user via `bash app/scripts/run-dev.sh`:
1. Step through onboarding → land on intensity step → leave Standard → Continue → review shows Coach style + Notes (Intensity row hidden because Standard is default) → submit → plan generates with auto-tier multiplier (e.g. Ambitious 1.7×).
2. Restart, replay → at intensity step, pick "Push me harder" → curve animates upward → review shows "Intensity: Push me harder" → submit → plan generates with AllIn-or-VeryAmbitious peak depending on auto, AI reply mentions the aggressive choice.
3. Restart, replay → pick "Take it easy" → curve animates lower → submit → plan with Conservative-or-Realistic peak; AI reply mentions easing in.

---

## 10. Migration / rollout

Single deploy. No feature flag (single-user pre-launch product, per existing convention).

- New `users.intensity_bias` column defaults to `'standard'` for existing rows → zero behavior change for their next plan generation (`applyBias(Standard)` is identity).
- Old Flutter clients keep working — they don't send `intensity_bias`, validator allows nullable, service defaults it to Standard.
- New TestFlight build bumps `version: 1.0.0+N` in `pubspec.yaml` per the usual release flow (see `app/CLAUDE.md` → Release builds + TestFlight).

---

## 11. Files

### Backend

| File | Change |
|---|---|
| `database/migrations/2026_05_11_NNNNNN_add_intensity_bias_to_users.php` | **new** — nullable string with `'standard'` default |
| `app/Enums/IntensityBias.php` | **new** — three-case backed enum |
| `app/Support/Onboarding/EffectiveAmbitionLevel.php` | **new** — five-case backed enum with multiplier getters + `shiftFrom()` |
| `app/Support/Onboarding/AmbitionAssessment.php` | add `effectiveLevel`, `weeklyGrowthRatio`, `qualityPaceRampGain` fields + `applyBias()` method; refactor summary/suggestion builders to take `EffectiveAmbitionLevel` + optional `IntensityBias` |
| `app/Support/Onboarding/OnboardingFormInput.php` | add `intensityBias` field; `fromArray()` parses with Standard fallback |
| `app/Services/Onboarding/PlanAmbitionAnalyzer.php` | `analyze()` returns assessment via `EffectiveAmbitionLevel::fromAmbitionLevel($level)` to populate the new fields with zero-shift defaults |
| `app/Services/Onboarding/TrainingPlanBuilder.php` | replace `MAX_WEEKLY_GROWTH_RATIO` use with `$ambition?->weeklyGrowthRatio ?? self::MAX_WEEKLY_GROWTH_RATIO`; multiply `qualityPaceRampGain` into `tempoPace()` + `intervalBlueprint()` progress |
| `app/Services/Onboarding/OnboardingPlanGeneratorService.php` | persist `users.intensity_bias` from form payload at top of `generate()`; call `$ambition = $ambition->applyBias($user->intensity_bias)` after analyzer runs |
| `app/Models/User.php` | fillable + cast for `intensity_bias` |
| `app/Http/Requests/GeneratePlanRequest.php` (or current FormRequest) | validation rule for `intensity_bias` |
| `app/Http/Resources/UserResource.php` (or wherever User is serialized) | expose `intensity_bias` |
| `app/Ai/Agents/OnboardingAgent.php` | add bias-aware reply guidance to `instructions()` |

### Flutter

| File | Change |
|---|---|
| `app/lib/features/onboarding/screens/onboarding_form_screen.dart` | add `_Step.intensity`, `_IntensityStep` widget, route through it, add intensity row to review (hide when standard) |
| `app/lib/features/onboarding/widgets/intensity_bias_chart.dart` | **new** — `CustomPainter` + `TweenAnimationBuilder<List<double>>` |
| `app/lib/features/onboarding/widgets/intensity_bias_segmented_control.dart` | **new** — three-segment selector with auto-pick affordance |
| `app/lib/features/onboarding/models/onboarding_form_data.dart` | add `intensityBias` field; add `IntensityBias` enum at file bottom |
| `app/lib/features/onboarding/providers/onboarding_form_provider.dart` | add `setIntensityBias(IntensityBias bias)` |
| `app/lib/features/onboarding/data/onboarding_api.dart` | include `intensity_bias` in generate-plan body |
| `app/lib/features/auth/models/user.dart` | add `intensityBias` field for `/profile` round-trip |

### Tests

| File | Coverage |
|---|---|
| `tests/Unit/Support/Onboarding/EffectiveAmbitionLevelTest.php` (**new**) | `shiftFrom` clamps + multiplier getters |
| `tests/Unit/Support/Onboarding/AmbitionAssessmentApplyBiasTest.php` (**new**) | `applyBias` shifts level, recomputes multipliers, refreshes summary/suggestion |
| `tests/Feature/Services/Onboarding/TrainingPlanBuilderTest.php` (extend) | builder consumes new fields, peak scales monotonically across the 5 effective levels |
| `tests/Feature/Jobs/GeneratePlanJobTest.php` (extend) | end-to-end: form-with-bias → persisted on user → plan reflects bias |
| `tests/Feature/Http/OnboardingProfileTest.php` (extend or new) | `/profile` exposes `intensity_bias` |
| `app/test/features/onboarding/intensity_step_test.dart` (**new**) | widget interactions, default selection, auto-pick fade |
| `app/test/features/onboarding/intensity_bias_chart_test.dart` (**new**) | tween, painter output |

---

## 12. Open questions

None. All knobs and values are explicit above; curve shapes are aesthetic and trivially tunable post-launch.
