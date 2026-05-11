# Onboarding Intensity Bias — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a user-controlled difficulty slider to onboarding (Take it easy / Standard / Push me harder) that biases the auto-detected plan ambition ±1 level, with an animated decorative ramp-curve preview and persistence on `users.intensity_bias`.

**Architecture:** New `IntensityBias` PHP enum lands on a new `users.intensity_bias` column. After `PlanAmbitionAnalyzer::analyze()` returns an `AmbitionAssessment`, a new `applyBias()` method shifts the level ±1 within an extended 5-tier `EffectiveAmbitionLevel` (Conservative 1.45× / Realistic 1.6× / Ambitious 1.7× / VeryAmbitious 1.8× / AllIn 1.95×), recomputing peak volume multiplier, weekly growth ratio, and quality pace ramp gain. `TrainingPlanBuilder` consumes all three knobs from the assessment. Flutter gets a new form step with a `CustomPainter` animated bar curve and a 3-segment selector — the curve is purely decorative (three hardcoded shapes that tween element-wise), no backend preview call.

**Tech Stack:** Laravel 13 (backed enums, FormRequest, Eloquent migration), PHPUnit, Flutter (Riverpod codegen, Freezed 3.x, CustomPainter, TweenAnimationBuilder).

**Spec:** `docs/superpowers/specs/2026-05-11-onboarding-intensity-bias-design.md`

---

## Task 1: Create `IntensityBias` PHP enum

**Files:**
- Create: `api/app/Enums/IntensityBias.php`

- [ ] **Step 1: Create the enum file**

```php
<?php

namespace App\Enums;

use App\Enums\Concerns\HasValues;

/**
 * The runner's own bias on top of the auto-detected ambition. Captured
 * during onboarding as a 3-position slider; persisted on
 * `users.intensity_bias`. Consumed by `AmbitionAssessment::applyBias()`
 * to shift the effective level ±1 within the extended 5-tier table.
 */
enum IntensityBias: string
{
    use HasValues;

    case TakeItEasy = 'take_it_easy';
    case Standard = 'standard';
    case PushMeHarder = 'push_me_harder';
}
```

- [ ] **Step 2: Run Pint**

```bash
cd api && vendor/bin/pint --dirty --format agent
```

- [ ] **Step 3: Commit**

```bash
git add api/app/Enums/IntensityBias.php
git commit -m "feat(intensity-bias): add IntensityBias enum

Three cases matching the onboarding slider labels (take_it_easy /
standard / push_me_harder)."
```

---

## Task 2: Create `EffectiveAmbitionLevel` value object

**Files:**
- Create: `api/app/Support/Onboarding/EffectiveAmbitionLevel.php`
- Create: `api/tests/Unit/Support/Onboarding/EffectiveAmbitionLevelTest.php`

- [ ] **Step 1: Write the failing tests**

```php
<?php

namespace Tests\Unit\Support\Onboarding;

use App\Enums\AmbitionLevel;
use App\Support\Onboarding\EffectiveAmbitionLevel;
use PHPUnit\Framework\TestCase;

class EffectiveAmbitionLevelTest extends TestCase
{
    public function test_shift_from_realistic_minus_one_yields_conservative(): void
    {
        $this->assertSame(
            EffectiveAmbitionLevel::Conservative,
            EffectiveAmbitionLevel::shiftFrom(AmbitionLevel::Realistic, -1),
        );
    }

    public function test_shift_from_realistic_zero_yields_realistic(): void
    {
        $this->assertSame(
            EffectiveAmbitionLevel::Realistic,
            EffectiveAmbitionLevel::shiftFrom(AmbitionLevel::Realistic, 0),
        );
    }

    public function test_shift_from_realistic_plus_one_yields_ambitious(): void
    {
        $this->assertSame(
            EffectiveAmbitionLevel::Ambitious,
            EffectiveAmbitionLevel::shiftFrom(AmbitionLevel::Realistic, 1),
        );
    }

    public function test_shift_from_very_ambitious_plus_one_clamps_to_all_in(): void
    {
        $this->assertSame(
            EffectiveAmbitionLevel::AllIn,
            EffectiveAmbitionLevel::shiftFrom(AmbitionLevel::VeryAmbitious, 1),
        );
    }

    public function test_shift_from_realistic_minus_two_clamps_to_conservative(): void
    {
        $this->assertSame(
            EffectiveAmbitionLevel::Conservative,
            EffectiveAmbitionLevel::shiftFrom(AmbitionLevel::Realistic, -2),
        );
    }

    public function test_shift_from_very_ambitious_plus_three_clamps_to_all_in(): void
    {
        $this->assertSame(
            EffectiveAmbitionLevel::AllIn,
            EffectiveAmbitionLevel::shiftFrom(AmbitionLevel::VeryAmbitious, 3),
        );
    }

    public function test_from_ambition_level_is_zero_shift(): void
    {
        $this->assertSame(
            EffectiveAmbitionLevel::Realistic,
            EffectiveAmbitionLevel::fromAmbitionLevel(AmbitionLevel::Realistic),
        );
        $this->assertSame(
            EffectiveAmbitionLevel::Ambitious,
            EffectiveAmbitionLevel::fromAmbitionLevel(AmbitionLevel::Ambitious),
        );
        $this->assertSame(
            EffectiveAmbitionLevel::VeryAmbitious,
            EffectiveAmbitionLevel::fromAmbitionLevel(AmbitionLevel::VeryAmbitious),
        );
    }

    public function test_peak_volume_multipliers_match_tier_table(): void
    {
        $this->assertEqualsWithDelta(1.45, EffectiveAmbitionLevel::Conservative->peakVolumeMultiplier(), 0.001);
        $this->assertEqualsWithDelta(1.60, EffectiveAmbitionLevel::Realistic->peakVolumeMultiplier(), 0.001);
        $this->assertEqualsWithDelta(1.70, EffectiveAmbitionLevel::Ambitious->peakVolumeMultiplier(), 0.001);
        $this->assertEqualsWithDelta(1.80, EffectiveAmbitionLevel::VeryAmbitious->peakVolumeMultiplier(), 0.001);
        $this->assertEqualsWithDelta(1.95, EffectiveAmbitionLevel::AllIn->peakVolumeMultiplier(), 0.001);
    }

    public function test_weekly_growth_ratios_match_tier_table(): void
    {
        $this->assertEqualsWithDelta(1.22, EffectiveAmbitionLevel::Conservative->weeklyGrowthRatio(), 0.001);
        $this->assertEqualsWithDelta(1.27, EffectiveAmbitionLevel::Realistic->weeklyGrowthRatio(), 0.001);
        $this->assertEqualsWithDelta(1.30, EffectiveAmbitionLevel::Ambitious->weeklyGrowthRatio(), 0.001);
        $this->assertEqualsWithDelta(1.33, EffectiveAmbitionLevel::VeryAmbitious->weeklyGrowthRatio(), 0.001);
        $this->assertEqualsWithDelta(1.36, EffectiveAmbitionLevel::AllIn->weeklyGrowthRatio(), 0.001);
    }

    public function test_quality_pace_ramp_gain_matches_tier_table(): void
    {
        $this->assertEqualsWithDelta(0.85, EffectiveAmbitionLevel::Conservative->qualityPaceRampGain(), 0.001);
        $this->assertEqualsWithDelta(0.92, EffectiveAmbitionLevel::Realistic->qualityPaceRampGain(), 0.001);
        $this->assertEqualsWithDelta(1.00, EffectiveAmbitionLevel::Ambitious->qualityPaceRampGain(), 0.001);
        $this->assertEqualsWithDelta(1.10, EffectiveAmbitionLevel::VeryAmbitious->qualityPaceRampGain(), 0.001);
        $this->assertEqualsWithDelta(1.20, EffectiveAmbitionLevel::AllIn->qualityPaceRampGain(), 0.001);
    }
}
```

- [ ] **Step 2: Run test, expect fail**

```bash
cd api && php artisan test --compact --filter EffectiveAmbitionLevelTest
```

Expected: FAIL with "Class \"App\\Support\\Onboarding\\EffectiveAmbitionLevel\" not found".

- [ ] **Step 3: Write the enum**

```php
<?php

namespace App\Support\Onboarding;

use App\Enums\AmbitionLevel;

/**
 * Five-tier "post-bias" view of plan ambition. Computed from
 * `AmbitionLevel` + `IntensityBias` via `applyBias()`. Each case carries
 * the three knob values that `TrainingPlanBuilder` consumes:
 * peak-volume multiplier, week-over-week growth cap, and quality pace
 * ramp gain. The Conservative floor and AllIn ceiling are reachable
 * only via slider bias; without a bias, only Realistic / Ambitious /
 * VeryAmbitious appear.
 */
enum EffectiveAmbitionLevel: string
{
    case Conservative = 'conservative';
    case Realistic = 'realistic';
    case Ambitious = 'ambitious';
    case VeryAmbitious = 'very_ambitious';
    case AllIn = 'all_in';

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
        $ordered = [
            self::Conservative,
            self::Realistic,
            self::Ambitious,
            self::VeryAmbitious,
            self::AllIn,
        ];

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

- [ ] **Step 4: Run tests, expect pass**

```bash
cd api && php artisan test --compact --filter EffectiveAmbitionLevelTest
```

Expected: all 10 tests pass.

- [ ] **Step 5: Pint + commit**

```bash
cd api && vendor/bin/pint --dirty --format agent
git add api/app/Support/Onboarding/EffectiveAmbitionLevel.php api/tests/Unit/Support/Onboarding/EffectiveAmbitionLevelTest.php
git commit -m "feat(intensity-bias): EffectiveAmbitionLevel value object

Five-tier post-bias view (Conservative 1.45x / Realistic 1.6x /
Ambitious 1.7x / VeryAmbitious 1.8x / AllIn 1.95x) with shift+clamp
logic and per-tier knob accessors for peak volume, weekly growth,
and quality pace ramp gain."
```

---

## Task 3: Extend `AmbitionAssessment` with new fields + `applyBias()`

**Files:**
- Modify: `api/app/Support/Onboarding/AmbitionAssessment.php`
- Create: `api/tests/Unit/Support/Onboarding/AmbitionAssessmentApplyBiasTest.php`

- [ ] **Step 1: Write the failing test**

```php
<?php

namespace Tests\Unit\Support\Onboarding;

use App\Enums\AmbitionLevel;
use App\Enums\IntensityBias;
use App\Support\Onboarding\AmbitionAssessment;
use App\Support\Onboarding\EffectiveAmbitionLevel;
use PHPUnit\Framework\TestCase;

class AmbitionAssessmentApplyBiasTest extends TestCase
{
    public function test_standard_bias_is_identity(): void
    {
        $original = $this->ambitious();
        $biased = $original->applyBias(IntensityBias::Standard);

        $this->assertSame($original->level, $biased->level);
        $this->assertSame($original->effectiveLevel, $biased->effectiveLevel);
        $this->assertSame($original->peakVolumeMultiplier, $biased->peakVolumeMultiplier);
        $this->assertSame($original->weeklyGrowthRatio, $biased->weeklyGrowthRatio);
        $this->assertSame($original->qualityPaceRampGain, $biased->qualityPaceRampGain);
    }

    public function test_take_it_easy_on_realistic_yields_conservative(): void
    {
        $assessment = AmbitionAssessment::realistic()->applyBias(IntensityBias::TakeItEasy);

        $this->assertSame(AmbitionLevel::Realistic, $assessment->level);
        $this->assertSame(EffectiveAmbitionLevel::Conservative, $assessment->effectiveLevel);
        $this->assertEqualsWithDelta(1.45, $assessment->peakVolumeMultiplier, 0.001);
        $this->assertEqualsWithDelta(1.22, $assessment->weeklyGrowthRatio, 0.001);
        $this->assertEqualsWithDelta(0.85, $assessment->qualityPaceRampGain, 0.001);
    }

    public function test_push_me_harder_on_very_ambitious_yields_all_in(): void
    {
        $assessment = $this->veryAmbitious()->applyBias(IntensityBias::PushMeHarder);

        $this->assertSame(AmbitionLevel::VeryAmbitious, $assessment->level);
        $this->assertSame(EffectiveAmbitionLevel::AllIn, $assessment->effectiveLevel);
        $this->assertEqualsWithDelta(1.95, $assessment->peakVolumeMultiplier, 0.001);
        $this->assertEqualsWithDelta(1.36, $assessment->weeklyGrowthRatio, 0.001);
        $this->assertEqualsWithDelta(1.20, $assessment->qualityPaceRampGain, 0.001);
    }

    public function test_take_it_easy_on_very_ambitious_yields_ambitious(): void
    {
        $assessment = $this->veryAmbitious()->applyBias(IntensityBias::TakeItEasy);

        $this->assertSame(EffectiveAmbitionLevel::Ambitious, $assessment->effectiveLevel);
        $this->assertEqualsWithDelta(1.70, $assessment->peakVolumeMultiplier, 0.001);
    }

    public function test_apply_bias_preserves_weeks_extension(): void
    {
        $assessment = $this->ambitious()
            ->withWeeksExtension(4)
            ->applyBias(IntensityBias::PushMeHarder);

        $this->assertSame(4, $assessment->weeksExtension);
    }

    public function test_default_constructor_carries_effective_level_matching_level(): void
    {
        $assessment = AmbitionAssessment::realistic();

        $this->assertSame(EffectiveAmbitionLevel::Realistic, $assessment->effectiveLevel);
        $this->assertEqualsWithDelta(1.00, $assessment->qualityPaceRampGain, 0.001);
        $this->assertEqualsWithDelta(1.30, $assessment->weeklyGrowthRatio, 0.001);
    }

    private function ambitious(): AmbitionAssessment
    {
        return new AmbitionAssessment(
            level: AmbitionLevel::Ambitious,
            paceGapSecondsPerKm: 50,
            improvementPerMonthSeconds: 15.0,
            volumeRatio: 0.8,
            peakVolumeMultiplier: 1.70,
            weeksExtension: 0,
            summary: 'stretch goal',
            suggestion: null,
            effectiveLevel: EffectiveAmbitionLevel::Ambitious,
            weeklyGrowthRatio: 1.30,
            qualityPaceRampGain: 1.00,
        );
    }

    private function veryAmbitious(): AmbitionAssessment
    {
        return new AmbitionAssessment(
            level: AmbitionLevel::VeryAmbitious,
            paceGapSecondsPerKm: 90,
            improvementPerMonthSeconds: 25.0,
            volumeRatio: 0.6,
            peakVolumeMultiplier: 1.80,
            weeksExtension: 0,
            summary: 'big stretch',
            suggestion: 'consider a more conservative goal',
            effectiveLevel: EffectiveAmbitionLevel::VeryAmbitious,
            weeklyGrowthRatio: 1.33,
            qualityPaceRampGain: 1.10,
        );
    }
}
```

- [ ] **Step 2: Run test, expect fail**

```bash
cd api && php artisan test --compact --filter AmbitionAssessmentApplyBiasTest
```

Expected: FAIL on `effectiveLevel` / `weeklyGrowthRatio` / `qualityPaceRampGain` fields not existing on `AmbitionAssessment`, and `applyBias` method missing.

- [ ] **Step 3: Update `AmbitionAssessment.php`**

Replace the file with:

```php
<?php

namespace App\Support\Onboarding;

use App\Enums\AmbitionLevel;
use App\Enums\IntensityBias;

/**
 * Output of `PlanAmbitionAnalyzer`. Captures how realistic the runner's
 * goal looks given their fitness snapshot, plan length, and the volume
 * the builder can produce.
 *
 * After `applyBias()`, also carries the post-bias effective level plus
 * three builder knobs (peak volume, weekly growth, quality pace ramp).
 *
 * Two consumers:
 * 1. `TrainingPlanBuilder` reads `peakVolumeMultiplier`,
 *    `weeklyGrowthRatio`, and `qualityPaceRampGain` to shape the
 *    weekly volume curve + pace-progression speed.
 * 2. `BuildOnboardingPlan` exposes the assessment in `fitness_summary`
 *    so the `OnboardingAgent` can paraphrase a warning + suggestion in
 *    its reply.
 */
final readonly class AmbitionAssessment
{
    public function __construct(
        public AmbitionLevel $level,
        public ?int $paceGapSecondsPerKm,
        public ?float $improvementPerMonthSeconds,
        public ?float $volumeRatio,
        public float $peakVolumeMultiplier,
        /**
         * Weeks added to the base plan length to make the goal achievable.
         * 0 for realistic goals or when `target_date` is locked in
         * (the runner committed to a date — extension isn't an option).
         */
        public int $weeksExtension,
        public ?string $summary,
        public ?string $suggestion,
        public EffectiveAmbitionLevel $effectiveLevel = EffectiveAmbitionLevel::Ambitious,
        public float $weeklyGrowthRatio = 1.30,
        public float $qualityPaceRampGain = 1.00,
    ) {}

    public static function realistic(): self
    {
        return new self(
            level: AmbitionLevel::Realistic,
            paceGapSecondsPerKm: null,
            improvementPerMonthSeconds: null,
            volumeRatio: null,
            peakVolumeMultiplier: 1.6,
            weeksExtension: 0,
            summary: null,
            suggestion: null,
            effectiveLevel: EffectiveAmbitionLevel::Realistic,
            weeklyGrowthRatio: EffectiveAmbitionLevel::Realistic->weeklyGrowthRatio(),
            qualityPaceRampGain: EffectiveAmbitionLevel::Realistic->qualityPaceRampGain(),
        );
    }

    public function withWeeksExtension(int $extension): self
    {
        return new self(
            level: $this->level,
            paceGapSecondsPerKm: $this->paceGapSecondsPerKm,
            improvementPerMonthSeconds: $this->improvementPerMonthSeconds,
            volumeRatio: $this->volumeRatio,
            peakVolumeMultiplier: $this->peakVolumeMultiplier,
            weeksExtension: $extension,
            summary: $this->summary,
            suggestion: $this->suggestion,
            effectiveLevel: $this->effectiveLevel,
            weeklyGrowthRatio: $this->weeklyGrowthRatio,
            qualityPaceRampGain: $this->qualityPaceRampGain,
        );
    }

    /**
     * Apply the runner's intensity-bias slider to the assessment.
     * Shifts the effective level by ±1 within the five-tier table
     * (Conservative through AllIn) and recomputes the three builder
     * knobs from that level. The original auto-detected `level` is
     * retained for diagnostics; the builder reads `effectiveLevel`.
     */
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
            level: $this->level,
            paceGapSecondsPerKm: $this->paceGapSecondsPerKm,
            improvementPerMonthSeconds: $this->improvementPerMonthSeconds,
            volumeRatio: $this->volumeRatio,
            peakVolumeMultiplier: $effective->peakVolumeMultiplier(),
            weeksExtension: $this->weeksExtension,
            summary: $this->summary,
            suggestion: $this->suggestion,
            effectiveLevel: $effective,
            weeklyGrowthRatio: $effective->weeklyGrowthRatio(),
            qualityPaceRampGain: $effective->qualityPaceRampGain(),
        );
    }

    /**
     * @return array<string, mixed>
     */
    public function toFitnessSummary(): array
    {
        return [
            'level' => $this->level->value,
            'effective_level' => $this->effectiveLevel->value,
            'pace_gap_seconds_per_km' => $this->paceGapSecondsPerKm,
            'improvement_per_month_seconds' => $this->improvementPerMonthSeconds === null
                ? null
                : round($this->improvementPerMonthSeconds, 1),
            'volume_ratio' => $this->volumeRatio === null ? null : round($this->volumeRatio, 2),
            'weeks_extension' => $this->weeksExtension,
            'summary' => $this->summary,
            'suggestion' => $this->suggestion,
        ];
    }
}
```

- [ ] **Step 4: Run tests, expect pass**

```bash
cd api && php artisan test --compact --filter AmbitionAssessmentApplyBiasTest
```

Expected: all 6 tests pass.

- [ ] **Step 5: Pint + commit**

```bash
cd api && vendor/bin/pint --dirty --format agent
git add api/app/Support/Onboarding/AmbitionAssessment.php api/tests/Unit/Support/Onboarding/AmbitionAssessmentApplyBiasTest.php
git commit -m "feat(intensity-bias): applyBias on AmbitionAssessment

Adds effectiveLevel + weeklyGrowthRatio + qualityPaceRampGain fields
(defaulting to Ambitious-tier values to preserve existing behavior)
plus an applyBias() method that shifts the effective level ±1 and
recomputes all three knobs."
```

---

## Task 4: Update `PlanAmbitionAnalyzer` to populate new fields

**Files:**
- Modify: `api/app/Services/Onboarding/PlanAmbitionAnalyzer.php`

- [ ] **Step 1: Read the current `analyze()` method**

```bash
cd api && grep -n "new AmbitionAssessment" app/Services/Onboarding/PlanAmbitionAnalyzer.php
```

Note the single `new AmbitionAssessment(...)` call site (~line 121).

- [ ] **Step 2: Update the constructor call to populate new fields**

Find the `return new AmbitionAssessment(...)` block in `analyze()` and update the constructor args:

```php
$effectiveLevel = EffectiveAmbitionLevel::fromAmbitionLevel($level);

return new AmbitionAssessment(
    level: $level,
    paceGapSecondsPerKm: $paceGap,
    improvementPerMonthSeconds: $improvementPerMonth,
    volumeRatio: $volumeRatio,
    peakVolumeMultiplier: $effectiveLevel->peakVolumeMultiplier(),
    weeksExtension: $weeksExtension,
    summary: $this->buildSummary($level, $improvementPerMonth, $volumeRatio, $snapshot, $form),
    suggestion: $this->buildSuggestion($level, $form, $weeksCount, $paceGap, $currentRacePace, $weeksExtension),
    effectiveLevel: $effectiveLevel,
    weeklyGrowthRatio: $effectiveLevel->weeklyGrowthRatio(),
    qualityPaceRampGain: $effectiveLevel->qualityPaceRampGain(),
);
```

Add the import at the top of the file:

```php
use App\Support\Onboarding\EffectiveAmbitionLevel;
```

Delete the now-redundant `$multiplier = match (...)` block above the constructor call — `$effectiveLevel->peakVolumeMultiplier()` replaces it.

- [ ] **Step 3: Run existing analyzer tests to confirm no regression**

```bash
cd api && php artisan test --compact --filter PlanAmbitionAnalyzer
```

Expected: existing tests still pass. The 1.6/1.7/1.8 values come from `EffectiveAmbitionLevel` now but are numerically identical.

- [ ] **Step 4: Pint + commit**

```bash
cd api && vendor/bin/pint --dirty --format agent
git add api/app/Services/Onboarding/PlanAmbitionAnalyzer.php
git commit -m "feat(intensity-bias): analyzer populates effectiveLevel + new knobs

Analyzer now derives peakVolumeMultiplier / weeklyGrowthRatio /
qualityPaceRampGain from EffectiveAmbitionLevel instead of a local
match expression. Numerically identical when no bias is applied."
```

---

## Task 5: Parse `intensity_bias` in `OnboardingFormInput`

**Files:**
- Modify: `api/app/Support/Onboarding/OnboardingFormInput.php`
- Modify: existing tests for `OnboardingFormInput` (find via `grep -r OnboardingFormInput api/tests`) — extend the relevant `fromArray` test or add a new one.

- [ ] **Step 1: Write the failing test**

Find or create `api/tests/Unit/Support/Onboarding/OnboardingFormInputTest.php` and add:

```php
public function test_from_array_parses_intensity_bias_take_it_easy(): void
{
    $input = OnboardingFormInput::fromArray([
        'goal_type' => 'race',
        'days_per_week' => 4,
        'intensity_bias' => 'take_it_easy',
    ]);

    $this->assertSame(IntensityBias::TakeItEasy, $input->intensityBias);
}

public function test_from_array_defaults_intensity_bias_to_standard_when_missing(): void
{
    $input = OnboardingFormInput::fromArray([
        'goal_type' => 'race',
        'days_per_week' => 4,
    ]);

    $this->assertSame(IntensityBias::Standard, $input->intensityBias);
}

public function test_from_array_defaults_intensity_bias_to_standard_for_invalid(): void
{
    $input = OnboardingFormInput::fromArray([
        'goal_type' => 'race',
        'days_per_week' => 4,
        'intensity_bias' => 'nonsense',
    ]);

    $this->assertSame(IntensityBias::Standard, $input->intensityBias);
}
```

Add `use App\Enums\IntensityBias;` at the top.

- [ ] **Step 2: Run test, expect fail**

```bash
cd api && php artisan test --compact --filter OnboardingFormInputTest
```

Expected: FAIL — property `intensityBias` doesn't exist.

- [ ] **Step 3: Update `OnboardingFormInput`**

Add the field to the constructor:

```php
public function __construct(
    public GoalType $goalType,
    public ?string $goalName,
    public ?int $distanceMeters,
    public ?CarbonImmutable $targetDate,
    public ?int $goalTimeSeconds,
    public ?int $prCurrentSeconds,
    public int $daysPerWeek,
    public ?array $preferredWeekdays,
    public CoachStyle $coachStyle,
    public ?string $additionalNotes,
    public ?array $runTypePreferences = null,
    public IntensityBias $intensityBias = IntensityBias::Standard,
) {}
```

Add the import:

```php
use App\Enums\IntensityBias;
```

Update `fromArray()` to pass the new field:

```php
return new self(
    goalType: $goalType,
    goalName: self::resolveGoalName($data, $goalType),
    distanceMeters: $distanceMeters,
    targetDate: $targetDate,
    goalTimeSeconds: self::resolvePositiveInt($data['goal_time_seconds'] ?? null),
    prCurrentSeconds: self::resolvePositiveInt($data['pr_current_seconds'] ?? null),
    daysPerWeek: $days,
    preferredWeekdays: $weekdays,
    coachStyle: $coachStyle,
    additionalNotes: self::resolveNotes($data),
    runTypePreferences: self::resolveRunTypePreferences($data['run_type_preferences'] ?? null),
    intensityBias: self::resolveIntensityBias($data['intensity_bias'] ?? null),
);
```

Add the resolver:

```php
private static function resolveIntensityBias(mixed $raw): IntensityBias
{
    if ($raw instanceof IntensityBias) {
        return $raw;
    }
    if (! is_string($raw)) {
        return IntensityBias::Standard;
    }

    return IntensityBias::tryFrom($raw) ?? IntensityBias::Standard;
}
```

- [ ] **Step 4: Run tests, expect pass**

```bash
cd api && php artisan test --compact --filter OnboardingFormInputTest
```

Expected: all 3 new tests pass; pre-existing tests still pass.

- [ ] **Step 5: Pint + commit**

```bash
cd api && vendor/bin/pint --dirty --format agent
git add api/app/Support/Onboarding/OnboardingFormInput.php api/tests/Unit/Support/Onboarding/OnboardingFormInputTest.php
git commit -m "feat(intensity-bias): OnboardingFormInput parses intensity_bias

Defaults to Standard when missing or invalid so old payloads keep
generating identical plans."
```

---

## Task 6: `TrainingPlanBuilder` consumes `weeklyGrowthRatio` + `qualityPaceRampGain`

**Files:**
- Modify: `api/app/Services/Onboarding/TrainingPlanBuilder.php`
- Modify: `api/tests/Feature/Services/Onboarding/TrainingPlanBuilderTest.php` (or wherever builder tests live — check with `grep -r TrainingPlanBuilderTest api/tests`)

- [ ] **Step 1: Find the three call sites**

```bash
cd api && grep -n "MAX_WEEKLY_GROWTH_RATIO\|rampLen" app/Services/Onboarding/TrainingPlanBuilder.php
```

Confirm three knob locations:
- `buildWeeklyVolumeCurve()` — uses `self::MAX_WEEKLY_GROWTH_RATIO` (~line 373) to cap W-o-W growth.
- `tempoPace()` — computes `$progress = $weeksFromStart / $rampLen` (~line 946-948).
- `intervalBlueprint()` workPace ramp (~line 1029) — similar progress math.

- [ ] **Step 2: Write the failing test for weeklyGrowthRatio**

Add to the existing `TrainingPlanBuilderTest`:

```php
public function test_weekly_growth_ratio_from_ambition_caps_volume_curve(): void
{
    // Snapshot with low baseline → builder would otherwise jump aggressively
    $snapshot = $this->snapshotWith(weeklyKm: 10.0);
    $form = $this->formFor(goalType: 'race', distanceMeters: 10_000, weeks: 12, daysPerWeek: 4);

    $aggressiveAmbition = new AmbitionAssessment(
        level: AmbitionLevel::Ambitious,
        paceGapSecondsPerKm: 30,
        improvementPerMonthSeconds: 12.0,
        volumeRatio: 0.9,
        peakVolumeMultiplier: 1.95,
        weeksExtension: 0,
        summary: null,
        suggestion: null,
        effectiveLevel: EffectiveAmbitionLevel::AllIn,
        weeklyGrowthRatio: 1.36,
        qualityPaceRampGain: 1.20,
    );

    $payload = $this->builder()->build($snapshot, $form, $aggressiveAmbition);
    $weeks = $payload['schedule']['weeks'];

    // Successive build-week totals should not exceed 1.36x of the prior
    for ($i = 1; $i < count($weeks) - 3; $i++) {
        $prev = $weeks[$i - 1]['total_km'];
        $cur = $weeks[$i]['total_km'];
        if ($prev > 0 && $cur >= $prev) {  // skip cutbacks (drops)
            $this->assertLessThanOrEqual($prev * 1.36 + 0.5, $cur, "Week {$i} exceeds 1.36x cap");
        }
    }
}

public function test_quality_pace_ramp_gain_speeds_pace_approach(): void
{
    $snapshot = $this->snapshotWith(thresholdPace: 270, weeklyKm: 25.0);
    $form = $this->formFor(goalType: 'race', distanceMeters: 5000, weeks: 8, daysPerWeek: 4, goalTimeSeconds: 1200);  // 4:00/km goal

    $baseAmbition = new AmbitionAssessment(
        level: AmbitionLevel::Ambitious,
        paceGapSecondsPerKm: 30, improvementPerMonthSeconds: 15.0, volumeRatio: 0.9,
        peakVolumeMultiplier: 1.70, weeksExtension: 0, summary: null, suggestion: null,
        effectiveLevel: EffectiveAmbitionLevel::Ambitious,
        weeklyGrowthRatio: 1.30, qualityPaceRampGain: 1.00,
    );

    $fastAmbition = new AmbitionAssessment(
        level: AmbitionLevel::Ambitious,
        paceGapSecondsPerKm: 30, improvementPerMonthSeconds: 15.0, volumeRatio: 0.9,
        peakVolumeMultiplier: 1.95, weeksExtension: 0, summary: null, suggestion: null,
        effectiveLevel: EffectiveAmbitionLevel::AllIn,
        weeklyGrowthRatio: 1.36, qualityPaceRampGain: 1.20,
    );

    $base = $this->builder()->build($snapshot, $form, $baseAmbition);
    $fast = $this->builder()->build($snapshot, $form, $fastAmbition);

    // At mid-plan (week 4), fast-ramp tempo pace should already be at or
    // ahead of where base-ramp will be by week 6.
    $baseTempoWeek6 = $this->firstTempoPaceInWeek($base, 6);
    $fastTempoWeek4 = $this->firstTempoPaceInWeek($fast, 4);

    if ($baseTempoWeek6 !== null && $fastTempoWeek4 !== null) {
        $this->assertLessThanOrEqual($baseTempoWeek6, $fastTempoWeek4, 'Fast-ramp tempo at w4 should be ≤ base-ramp tempo at w6');
    }
}

// helper for the second test
private function firstTempoPaceInWeek(array $payload, int $weekNumber): ?int
{
    foreach ($payload['schedule']['weeks'] as $w) {
        if (($w['week_number'] ?? null) !== $weekNumber) {
            continue;
        }
        foreach ($w['days'] as $d) {
            if (($d['type'] ?? null) === 'tempo' && ($d['target_pace_seconds_per_km'] ?? null) !== null) {
                return (int) $d['target_pace_seconds_per_km'];
            }
        }
    }

    return null;
}
```

Add necessary imports: `use App\Support\Onboarding\EffectiveAmbitionLevel;` and `use App\Enums\AmbitionLevel;`.

- [ ] **Step 3: Run tests, expect fail**

```bash
cd api && php artisan test --compact --filter "test_weekly_growth_ratio_from_ambition_caps_volume_curve|test_quality_pace_ramp_gain_speeds_pace_approach"
```

Expected: FAIL — builder ignores the new fields (still uses constant 1.30 + flat progress).

- [ ] **Step 4: Update `TrainingPlanBuilder`**

In `buildWeeklyVolumeCurve()` (around line 373), replace the use of `self::MAX_WEEKLY_GROWTH_RATIO`:

```php
$growthRatio = $ambition?->weeklyGrowthRatio ?? self::MAX_WEEKLY_GROWTH_RATIO;
// ... in the cap comparison further down:
$thisWeek = min($thisWeek, $prev * $growthRatio);
```

In `tempoPace()` (around line 946), find the line that computes `progress` and apply the gain:

```php
$gain = $ambition?->qualityPaceRampGain ?? 1.0;
$progress = max(0.0, min(1.0, ($weeksFromStart / $rampLen) * $gain));
```

In `intervalBlueprint()` workPace ramp (around line 1029), same pattern:

```php
$gain = $ambition?->qualityPaceRampGain ?? 1.0;
$progress = max(0.0, min(1.0, ($weeksFromStart / $rampLen) * $gain));
```

(Method-level access to `$ambition` is via the existing parameter `?AmbitionAssessment $ambition`. If a method doesn't already accept it, thread it through from `build()` — the builder's existing pattern.)

- [ ] **Step 5: Run tests, expect pass**

```bash
cd api && php artisan test --compact --filter TrainingPlanBuilderTest
```

Expected: new tests pass; existing tests still pass (defaults preserve Ambitious-tier behavior).

- [ ] **Step 6: Pint + commit**

```bash
cd api && vendor/bin/pint --dirty --format agent
git add api/app/Services/Onboarding/TrainingPlanBuilder.php api/tests/Feature/Services/Onboarding/TrainingPlanBuilderTest.php
git commit -m "feat(intensity-bias): builder consumes weeklyGrowthRatio + qualityPaceRampGain

W-o-W cap and tempo/interval pace progression scale per
EffectiveAmbitionLevel. Falls back to the legacy 1.30 / 1.0 defaults
when no AmbitionAssessment is passed."
```

---

## Task 7: Migration — add `intensity_bias` to `users`

**Files:**
- Create: `api/database/migrations/2026_05_11_NNNNNN_add_intensity_bias_to_users.php`

- [ ] **Step 1: Generate the migration**

```bash
cd api && php artisan make:migration add_intensity_bias_to_users --table=users
```

The Artisan command produces a file like `database/migrations/2026_05_11_120000_add_intensity_bias_to_users.php` (timestamp varies).

- [ ] **Step 2: Edit the migration**

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
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

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table): void {
            if (Schema::hasColumn('users', 'intensity_bias')) {
                $table->dropColumn('intensity_bias');
            }
        });
    }
};
```

- [ ] **Step 3: Run the migration**

```bash
cd api && php artisan migrate
```

Expected: `INFO  Running migrations. … add_intensity_bias_to_users … DONE`.

- [ ] **Step 4: Commit**

```bash
git add api/database/migrations/*_add_intensity_bias_to_users.php
git commit -m "feat(intensity-bias): users.intensity_bias column

Nullable string defaulting to 'standard' so existing rows generate
unchanged plans. Forward-only with hasColumn guard per migrations
rule."
```

---

## Task 8: User model — fillable + cast

**Files:**
- Modify: `api/app/Models/User.php`

- [ ] **Step 1: Add to fillable + casts**

Find the `$fillable` array (or `#[Fillable]` attribute) and add `'intensity_bias'`. In `$casts`, add:

```php
'intensity_bias' => IntensityBias::class,
```

Add at the top of the file:

```php
use App\Enums\IntensityBias;
```

- [ ] **Step 2: Smoke-test the cast in tinker**

```bash
cd api && php artisan tinker --execute 'use App\Models\User; $u = User::first(); echo "before: ".$u->intensity_bias->value."\n"; $u->update(["intensity_bias" => "push_me_harder"]); $u->refresh(); echo "after: ".$u->intensity_bias->value."\n";'
```

Expected: `before: standard`, `after: push_me_harder`.

- [ ] **Step 3: Commit**

```bash
git add api/app/Models/User.php
git commit -m "feat(intensity-bias): User fillable + IntensityBias cast"
```

---

## Task 9: Validate `intensity_bias` on the generate-plan request

**Files:**
- Modify: the FormRequest used by `POST /onboarding/generate-plan` (find via `grep -rn "generatePlan\|generate_plan" api/app/Http/`)

- [ ] **Step 1: Locate the validator**

```bash
cd api && grep -n "intensity_bias\|coach_style\|preferred_weekdays" app/Http/Requests/*.php app/Http/Controllers/OnboardingController.php
```

Find the FormRequest or controller method that validates the request. Likely `OnboardingController::generatePlan` does inline `$request->validate([...])` or uses a dedicated FormRequest.

- [ ] **Step 2: Add the validation rule**

Add to the rules array:

```php
'intensity_bias' => ['nullable', 'string', 'in:take_it_easy,standard,push_me_harder'],
```

- [ ] **Step 3: Run existing onboarding controller tests**

```bash
cd api && php artisan test --compact --filter Onboarding
```

Expected: no regression. The new rule is permissive (`nullable`).

- [ ] **Step 4: Commit**

```bash
git add api/app/Http/
git commit -m "feat(intensity-bias): validate intensity_bias on generate-plan"
```

---

## Task 10: `OnboardingPlanGeneratorService` persists + applies the bias

**Files:**
- Modify: `api/app/Services/Onboarding/OnboardingPlanGeneratorService.php`

- [ ] **Step 1: Locate where the analyzer is called**

```bash
cd api && grep -n "PlanAmbitionAnalyzer\|->analyze\|FitnessSnapshotService" app/Services/Onboarding/OnboardingPlanGeneratorService.php
```

Note the line where `analyze()` is called and where the payload is read.

- [ ] **Step 2: Persist the bias from form payload + apply it post-analyze**

Near the top of `generate()`, before any other work that reads the user:

```php
$rawBias = $payload['intensity_bias'] ?? null;
$bias = is_string($rawBias) ? (IntensityBias::tryFrom($rawBias) ?? IntensityBias::Standard) : IntensityBias::Standard;

if ($user->intensity_bias !== $bias) {
    $user->update(['intensity_bias' => $bias]);
}
```

After the `analyze()` call, wrap the assessment:

```php
$ambition = $this->analyzer->analyze(...);
$ambition = $ambition->applyBias($user->intensity_bias);
```

Add the import:

```php
use App\Enums\IntensityBias;
```

- [ ] **Step 3: Run service tests**

```bash
cd api && php artisan test --compact --filter OnboardingPlanGenerator
```

Expected: no regression. Bias defaults to Standard (identity) when payload omits it.

- [ ] **Step 4: Pint + commit**

```bash
cd api && vendor/bin/pint --dirty --format agent
git add api/app/Services/Onboarding/OnboardingPlanGeneratorService.php
git commit -m "feat(intensity-bias): generator persists + applies bias

Stores the runner's pick on users.intensity_bias before plan gen,
then biases the analyzer's AmbitionAssessment so the builder sees
the post-bias multipliers."
```

---

## Task 11: `OnboardingAgent` prompt — acknowledge non-standard bias in reply

**Files:**
- Modify: `api/app/Ai/Agents/OnboardingAgent.php`

- [ ] **Step 1: Locate the agent's `instructions()` method**

```bash
cd api && grep -n "intensity_bias\|additional_notes\|build_onboarding_plan" app/Ai/Agents/OnboardingAgent.php
```

Find the section of the system prompt that lists the agent's steps (build → optionally adjust → reply).

- [ ] **Step 2: Add the bias-aware reply guidance**

In the reply-step section of `instructions()`, append:

```
If `intensity_bias` in the priming message is not `standard`, acknowledge it briefly in your reply:
- `take_it_easy` → say something like "I dialed back the ramp a bit since you asked to ease in — week-to-week jumps are smaller and the peak is lower."
- `push_me_harder` → say something like "You asked for a tougher build, so this plan sits at the upper edge of what your fitness supports. Recovery becomes more important than usual."

Do not repeat the level name ("ambitious", "all-in"). Do not use jargon. Speak to the experience. One sentence max.
```

Also make sure the priming-message builder (`OnboardingPlanGeneratorService` or wherever the priming string is composed) includes `intensity_bias: <value>` as a line — check by grepping `priming` or `Build the plan with these inputs` in the service.

- [ ] **Step 3: Commit**

```bash
git add api/app/Ai/Agents/OnboardingAgent.php api/app/Services/Onboarding/OnboardingPlanGeneratorService.php
git commit -m "feat(intensity-bias): agent acknowledges non-standard bias in reply

Adds one-sentence acknowledgement guidance for take_it_easy /
push_me_harder. Priming message now includes intensity_bias so the
agent has the value."
```

---

## Task 12: Expose `intensity_bias` on auth + profile responses

**Files:**
- Modify: wherever the User is serialized for `/auth/apple`, `/auth/dev-login`, `/profile`. Find with `grep -rn "coach_style" api/app/Http/`.

- [ ] **Step 1: Add `intensity_bias` to the serialized user array**

In every place where the User attributes are projected (UserResource, controller-side `->only([...])`, etc.), add `'intensity_bias'`. The Eloquent cast handles enum → string conversion for JSON output.

- [ ] **Step 2: Verify with curl/tinker**

```bash
cd api && php artisan tinker --execute 'echo json_encode(App\Models\User::first()->only(["id","email","coach_style","intensity_bias"]));'
```

Expected output includes `"intensity_bias":"standard"`.

- [ ] **Step 3: Commit**

```bash
git add api/app/Http/
git commit -m "feat(intensity-bias): expose intensity_bias on user responses"
```

---

## Task 13: End-to-end test through `GeneratePlanJobTest`

**Files:**
- Modify: `api/tests/Feature/Jobs/GeneratePlanJobTest.php`

- [ ] **Step 1: Write the failing test**

Add to the test class:

```php
public function test_intensity_bias_push_me_harder_persists_and_increases_peak_volume(): void
{
    Notification::fake();
    \App\Ai\Agents\OnboardingAgent::fake(['Plan ready — pushed the build to the upper edge as requested.']);

    $user = User::factory()->create([
        'has_completed_onboarding' => false,
        'intensity_bias' => 'standard',
    ]);

    $standardPlanGen = PlanGeneration::factory()->create([
        'user_id' => $user->id,
        'status' => PlanGenerationStatus::Queued,
        'payload' => $this->basePayload() + ['intensity_bias' => 'standard'],
    ]);

    (new GeneratePlan($standardPlanGen->id))->handle();

    $standardProposal = CoachProposal::where('user_id', $user->id)->latest('id')->first();
    $standardPeak = $this->peakWeeklyKm($standardProposal->payload);

    // Reset for second run
    CoachProposal::where('user_id', $user->id)->delete();
    $hardPlanGen = PlanGeneration::factory()->create([
        'user_id' => $user->id,
        'status' => PlanGenerationStatus::Queued,
        'payload' => $this->basePayload() + ['intensity_bias' => 'push_me_harder'],
    ]);

    (new GeneratePlan($hardPlanGen->id))->handle();

    $hardProposal = CoachProposal::where('user_id', $user->id)->latest('id')->first();
    $hardPeak = $this->peakWeeklyKm($hardProposal->payload);

    $this->assertGreaterThan($standardPeak, $hardPeak, 'Push-me-harder peak should exceed standard peak');
    $this->assertSame(IntensityBias::PushMeHarder, $user->fresh()->intensity_bias);
}

private function basePayload(): array
{
    return [
        'goal_type' => 'race',
        'distance_meters' => 21097,
        'target_date' => now()->addWeeks(12)->toDateString(),
        'goal_time_seconds' => 6300,
        'days_per_week' => 4,
        'preferred_weekdays' => [2, 4, 6, 7],
        'coach_style' => 'balanced',
    ];
}

private function peakWeeklyKm(array $proposalPayload): float
{
    $max = 0.0;
    foreach ($proposalPayload['schedule']['weeks'] ?? [] as $w) {
        $max = max($max, (float) ($w['total_km'] ?? 0));
    }

    return $max;
}
```

Add imports as needed (`IntensityBias`, `Notification`, etc).

- [ ] **Step 2: Run the test**

```bash
cd api && php artisan test --compact --filter test_intensity_bias_push_me_harder_persists_and_increases_peak_volume
```

Expected: PASS. If fails, the most likely culprit is wiring in Task 10 — verify `applyBias` is called after `analyze` in `OnboardingPlanGeneratorService`.

- [ ] **Step 3: Commit**

```bash
git add api/tests/Feature/Jobs/GeneratePlanJobTest.php
git commit -m "test(intensity-bias): end-to-end push_me_harder lifts peak vs standard"
```

---

## Task 14: Full backend test suite + Pint

- [ ] **Step 1: Pint everything**

```bash
cd api && vendor/bin/pint --dirty --format agent
```

- [ ] **Step 2: Run the full suite**

```bash
cd api && php artisan test --compact
```

Expected: all ~295+ tests pass.

- [ ] **Step 3: Commit any Pint fixes**

```bash
git status
# if Pint touched anything:
git add -A && git commit -m "style: pint"
```

---

## Task 15: Flutter — `IntensityBias` enum + form data field

**Files:**
- Modify: `app/lib/features/onboarding/models/onboarding_form_data.dart`

- [ ] **Step 1: Add the enum at the bottom of the file**

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

- [ ] **Step 2: Add the field to `OnboardingFormData`**

Locate the Freezed `OnboardingFormData` class (same file). Add the field to the constructor:

```dart
@Default(IntensityBias.standard) IntensityBias intensityBias,
```

Position it after `runTypePreferences` and before any internal-only fields.

- [ ] **Step 3: Run code-gen**

```bash
cd app && dart run build_runner build --delete-conflicting-outputs
```

Expected: regenerates `onboarding_form_data.freezed.dart` + `.g.dart` without errors.

- [ ] **Step 4: Verify analyze is clean**

```bash
cd app && flutter analyze
```

Expected: no analyzer errors related to the new field.

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/onboarding/models/onboarding_form_data.dart app/lib/features/onboarding/models/onboarding_form_data.freezed.dart app/lib/features/onboarding/models/onboarding_form_data.g.dart
git commit -m "feat(intensity-bias): Flutter IntensityBias enum + form field"
```

---

## Task 16: Form provider mutator

**Files:**
- Modify: `app/lib/features/onboarding/providers/onboarding_form_provider.dart`

- [ ] **Step 1: Add the setter method**

Inside the provider class:

```dart
void setIntensityBias(IntensityBias bias) {
  state = state.copyWith(intensityBias: bias);
}
```

If the import isn't picked up automatically, add:

```dart
import 'package:app/features/onboarding/models/onboarding_form_data.dart';
```

- [ ] **Step 2: Run code-gen if needed**

```bash
cd app && dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 3: Commit**

```bash
git add app/lib/features/onboarding/providers/onboarding_form_provider.dart app/lib/features/onboarding/providers/onboarding_form_provider.g.dart
git commit -m "feat(intensity-bias): setIntensityBias on form provider"
```

---

## Task 17: API client — send `intensity_bias`

**Files:**
- Modify: `app/lib/features/onboarding/data/onboarding_api.dart` (or whichever file builds the generate-plan POST body)

- [ ] **Step 1: Find the request-body builder**

```bash
cd app && grep -rn "generate-plan\|coach_style.*wire\|preferred_weekdays" lib/features/onboarding/
```

- [ ] **Step 2: Include `intensity_bias`**

In the body construction map, add:

```dart
'intensity_bias': formData.intensityBias.wire,
```

- [ ] **Step 3: Run code-gen if Retrofit changed**

```bash
cd app && dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 4: Commit**

```bash
git add app/lib/features/onboarding/data/
git commit -m "feat(intensity-bias): send intensity_bias in generate-plan body"
```

---

## Task 18: Flutter User model — round-trip `intensity_bias`

**Files:**
- Modify: `app/lib/features/auth/models/user.dart`

- [ ] **Step 1: Add the field to the Freezed class**

```dart
@JsonKey(name: 'intensity_bias') @Default('standard') String intensityBias,
```

Add it next to `coachStyle` for symmetry. Stored as a plain `String` (matching the backend wire format) — the rare consumer can convert with `IntensityBias.fromWire(...)` from `onboarding_form_data.dart`.

- [ ] **Step 2: Run code-gen**

```bash
cd app && dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 3: Commit**

```bash
git add app/lib/features/auth/models/user.dart app/lib/features/auth/models/user.freezed.dart app/lib/features/auth/models/user.g.dart
git commit -m "feat(intensity-bias): User model exposes intensity_bias"
```

---

## Task 19: Build `intensity_bias_chart.dart` widget

**Files:**
- Create: `app/lib/features/onboarding/widgets/intensity_bias_chart.dart`
- Create: `app/test/features/onboarding/intensity_bias_chart_test.dart`

- [ ] **Step 1: Write the failing widget test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/onboarding/models/onboarding_form_data.dart';
import 'package:app/features/onboarding/widgets/intensity_bias_chart.dart';

void main() {
  testWidgets('chart builds and survives a bias change', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: IntensityBiasChart(bias: IntensityBias.standard),
        ),
      ),
    );
    expect(find.byType(IntensityBiasChart), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: IntensityBiasChart(bias: IntensityBias.pushMeHarder),
        ),
      ),
    );
    // Let the tween progress
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(IntensityBiasChart), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test, expect fail**

```bash
cd app && flutter test test/features/onboarding/intensity_bias_chart_test.dart
```

Expected: FAIL with "Target of URI doesn't exist".

- [ ] **Step 3: Write the widget**

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/onboarding/models/onboarding_form_data.dart';

const _curveTakeItEasy = <double>[
  0.30, 0.40, 0.50, 0.38, 0.55, 0.62, 0.68, 0.52, 0.72, 0.72, 0.58, 0.42, 0.22,
];
const _curveStandard = <double>[
  0.35, 0.48, 0.58, 0.42, 0.68, 0.78, 0.85, 0.60, 0.88, 0.82, 0.66, 0.46, 0.24,
];
const _curvePushMeHarder = <double>[
  0.40, 0.55, 0.68, 0.50, 0.80, 0.92, 1.00, 0.72, 1.00, 0.90, 0.72, 0.50, 0.26,
];

List<double> _curveFor(IntensityBias bias) => switch (bias) {
      IntensityBias.takeItEasy => _curveTakeItEasy,
      IntensityBias.standard => _curveStandard,
      IntensityBias.pushMeHarder => _curvePushMeHarder,
    };

/// Decorative animated bar curve showing the runner's weekly volume
/// progression. Bars tween element-wise (350ms `easeInOutCubic`) when
/// [bias] changes. Values are illustrative — no real plan computation.
/// The last bar is rendered in `AppColors.gold` to represent race day;
/// the rest in `AppColors.warmBrown`.
class IntensityBiasChart extends StatefulWidget {
  final IntensityBias bias;
  final double height;

  const IntensityBiasChart({
    super.key,
    required this.bias,
    this.height = 140,
  });

  @override
  State<IntensityBiasChart> createState() => _IntensityBiasChartState();
}

class _IntensityBiasChartState extends State<IntensityBiasChart> {
  late List<double> _from = _curveFor(widget.bias);
  late List<double> _to = _curveFor(widget.bias);

  @override
  void didUpdateWidget(covariant IntensityBiasChart old) {
    super.didUpdateWidget(old);
    if (old.bias != widget.bias) {
      setState(() {
        _from = _to;
        _to = _curveFor(widget.bias);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(widget.bias),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
      builder: (context, t, _) {
        final values = List<double>.generate(
          _from.length,
          (i) => _from[i] + (_to[i] - _from[i]) * t,
        );
        return CustomPaint(
          size: Size.fromHeight(widget.height),
          painter: _BarsPainter(values: values),
        );
      },
    );
  }
}

class _BarsPainter extends CustomPainter {
  final List<double> values;

  _BarsPainter({required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const gap = 4.0;
    final barWidth = (size.width - gap * (values.length - 1)) / values.length;
    final lastIdx = values.length - 1;

    final buildPaint = Paint()..color = AppColors.warmBrown;
    final racePaint = Paint()..color = AppColors.gold;

    for (var i = 0; i < values.length; i++) {
      final h = (values[i].clamp(0.0, 1.0)) * size.height;
      final x = i * (barWidth + gap);
      final y = size.height - h;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, h),
        const Radius.circular(3),
      );
      canvas.drawRRect(rect, i == lastIdx ? racePaint : buildPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarsPainter oldDelegate) =>
      oldDelegate.values != values;
}
```

- [ ] **Step 4: Run test, expect pass**

```bash
cd app && flutter test test/features/onboarding/intensity_bias_chart_test.dart
```

Expected: test passes.

- [ ] **Step 5: Run analyze**

```bash
cd app && flutter analyze
```

- [ ] **Step 6: Commit**

```bash
git add app/lib/features/onboarding/widgets/intensity_bias_chart.dart app/test/features/onboarding/intensity_bias_chart_test.dart
git commit -m "feat(intensity-bias): animated bar-curve chart widget

Decorative — three hardcoded shapes that tween element-wise over
350ms when the selected bias changes. Last bar (race day) renders
in gold to distinguish from build bars."
```

---

## Task 20: Build `intensity_bias_segmented_control.dart` widget

**Files:**
- Create: `app/lib/features/onboarding/widgets/intensity_bias_segmented_control.dart`

- [ ] **Step 1: Write the widget**

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/onboarding/models/onboarding_form_data.dart';

class IntensityBiasSegmentedControl extends StatelessWidget {
  final IntensityBias selected;
  final ValueChanged<IntensityBias> onChanged;

  const IntensityBiasSegmentedControl({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final option in IntensityBias.values) ...[
              Expanded(
                child: _Segment(
                  label: _labelFor(option),
                  selected: option == selected,
                  onTap: () => onChanged(option),
                ),
              ),
              if (option != IntensityBias.values.last) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Expanded(child: SizedBox.shrink()),
            Expanded(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: selected == IntensityBias.standard ? 1.0 : 0.0,
                child: Text(
                  '(auto-pick)',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.publicSans(
                    fontSize: 11,
                    color: AppColors.inkMuted,
                  ),
                ),
              ),
            ),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ],
    );
  }

  static String _labelFor(IntensityBias bias) => switch (bias) {
        IntensityBias.takeItEasy => 'Take it easy',
        IntensityBias.standard => 'Standard',
        IntensityBias.pushMeHarder => 'Push me harder',
      };
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryInk : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primaryInk : AppColors.inputBorder,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.cream : AppColors.primaryInk,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run analyze**

```bash
cd app && flutter analyze
```

- [ ] **Step 3: Commit**

```bash
git add app/lib/features/onboarding/widgets/intensity_bias_segmented_control.dart
git commit -m "feat(intensity-bias): three-segment selector with auto-pick label"
```

---

## Task 21: Add `_IntensityStep` to the form + wire `_flowFor`

**Files:**
- Modify: `app/lib/features/onboarding/screens/onboarding_form_screen.dart`
- Create: `app/test/features/onboarding/intensity_step_test.dart`

- [ ] **Step 1: Add the enum case**

In the `_Step` enum at the top of the file, insert `intensity` between `coachStyle` and `review`:

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
  intensity,
  review,
}
```

- [ ] **Step 2: Add `_Step.intensity` to every branch of `_flowFor`**

In `_flowFor()`, add `_Step.intensity` between `_Step.coachStyle` and `_Step.review` in each of the three switch arms (race, pr, fitness/weight_loss/null).

- [ ] **Step 3: Add `_Step.intensity` to the `switch (step)` in `build()`**

In `_OnboardingFormScreenState.build()`, add the new case (mirroring the other arms):

```dart
_Step.intensity => _IntensityStep(
    stepIndex: safeIndex,
    stepCount: flow.length,
    form: form,
    onContinue: _advance,
    onBack: _goBack,
  ),
```

- [ ] **Step 4: Implement `_IntensityStep`**

At the bottom of the file (next to the other step widgets):

```dart
class _IntensityStep extends ConsumerStatefulWidget {
  final int stepIndex;
  final int stepCount;
  final OnboardingFormData form;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const _IntensityStep({
    required this.stepIndex,
    required this.stepCount,
    required this.form,
    required this.onContinue,
    required this.onBack,
  });

  @override
  ConsumerState<_IntensityStep> createState() => _IntensityStepState();
}

class _IntensityStepState extends ConsumerState<_IntensityStep> {
  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(onboardingFormProvider.notifier);
    final selected = widget.form.intensityBias;

    return StepScaffold(
      stepIndex: widget.stepIndex,
      stepCount: widget.stepCount,
      title: 'How hard do you want this?',
      subtitle: 'Bump up or down if you feel different — Standard matches what your goal calls for.',
      canContinue: true,
      onContinue: widget.onContinue,
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.goldGlow,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'WEEKLY KM',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.eyebrow,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                IntensityBiasChart(bias: selected),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _captionFor(selected),
                    key: ValueKey(selected),
                    style: GoogleFonts.ebGaramond(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: AppColors.inkMuted,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          IntensityBiasSegmentedControl(
            selected: selected,
            onChanged: notifier.setIntensityBias,
          ),
          const SizedBox(height: 12),
          Text(
            'Tap to bias the build.',
            textAlign: TextAlign.center,
            style: GoogleFonts.publicSans(
              fontSize: 13,
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }

  String _captionFor(IntensityBias bias) => switch (bias) {
        IntensityBias.takeItEasy => 'Gentler bumps, lower peak. Sustainable.',
        IntensityBias.standard => 'Steady weekly progression. Auto-picked.',
        IntensityBias.pushMeHarder => 'Steeper ramp, higher peak. Stay sharp.',
      };
}
```

Add imports at the top of the file:

```dart
import 'package:app/features/onboarding/widgets/intensity_bias_chart.dart';
import 'package:app/features/onboarding/widgets/intensity_bias_segmented_control.dart';
```

- [ ] **Step 5: Write the widget test**

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/onboarding/models/onboarding_form_data.dart';
import 'package:app/features/onboarding/providers/onboarding_form_provider.dart';
import 'package:app/features/onboarding/widgets/intensity_bias_segmented_control.dart';

void main() {
  testWidgets('segmented control renders three labels and reports taps', (tester) async {
    IntensityBias? captured;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Material(
            child: IntensityBiasSegmentedControl(
              selected: IntensityBias.standard,
              onChanged: (b) => captured = b,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Take it easy'), findsOneWidget);
    expect(find.text('Standard'), findsOneWidget);
    expect(find.text('Push me harder'), findsOneWidget);
    expect(find.text('(auto-pick)'), findsOneWidget);

    await tester.tap(find.text('Push me harder'));
    await tester.pump();
    expect(captured, IntensityBias.pushMeHarder);
  });

  testWidgets('auto-pick label fades out when non-standard selected', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Material(
            child: IntensityBiasSegmentedControl(
              selected: IntensityBias.pushMeHarder,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    // The label is still in the tree but with opacity 0.0
    final opacity = tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
    expect(opacity.opacity, 0.0);
  });
}
```

- [ ] **Step 6: Run the test**

```bash
cd app && flutter test test/features/onboarding/intensity_step_test.dart
```

Expected: all 2 tests pass.

- [ ] **Step 7: Run analyze**

```bash
cd app && flutter analyze
```

- [ ] **Step 8: Commit**

```bash
git add app/lib/features/onboarding/screens/onboarding_form_screen.dart app/test/features/onboarding/intensity_step_test.dart
git commit -m "feat(intensity-bias): add intensity form step + wire into all flows

New step between coach-style and review, presented as a card with
the animated curve chart, animated caption, and a three-segment
selector. Continue is always enabled (Standard is a valid default)."
```

---

## Task 22: Add `Intensity` row to `_ReviewStep`

**Files:**
- Modify: `app/lib/features/onboarding/screens/onboarding_form_screen.dart` (same file as Task 21)

- [ ] **Step 1: Add the review row**

Inside `_ReviewStep`'s `_reviewRow(...)` series, between coach style and notes:

```dart
if (form.intensityBias != IntensityBias.standard)
  _reviewRow('Intensity', _intensityLabel(form.intensityBias)),
```

Add the helper method to `_ReviewStepState`:

```dart
String _intensityLabel(IntensityBias bias) => switch (bias) {
      IntensityBias.takeItEasy => 'Take it easy',
      IntensityBias.standard => 'Standard',
      IntensityBias.pushMeHarder => 'Push me harder',
    };
```

The conditional means Standard (the default) doesn't show up in the recap — tightens the recap when the runner didn't take action.

- [ ] **Step 2: Run analyze**

```bash
cd app && flutter analyze
```

- [ ] **Step 3: Commit**

```bash
git add app/lib/features/onboarding/screens/onboarding_form_screen.dart
git commit -m "feat(intensity-bias): review recap shows non-default intensity"
```

---

## Task 23: Flutter analyze + test suite

- [ ] **Step 1: Run analyze**

```bash
cd app && flutter analyze
```

Expected: no errors. Warnings about unused imports are OK to fix inline.

- [ ] **Step 2: Run all tests**

```bash
cd app && flutter test
```

Expected: all tests pass (including the new intensity tests).

- [ ] **Step 3: Commit any fix-ups**

```bash
git status
# if any analyze/test fix-ups:
git add -A && git commit -m "fix(intensity-bias): analyzer/test fix-ups"
```

---

## Task 24: Manual E2E + version bump

This task is **not auto-executable** — it's a manual verification checklist. Do it once the previous tasks are merged.

- [ ] **Step 1: Backend running**

```bash
cd api && composer run dev
```

- [ ] **Step 2: Reset dev user to a pre-onboarding state**

```bash
cd api && php artisan tinker --execute 'use App\Models\User; $u = User::orderBy("id")->first(); $u->update(["has_completed_onboarding" => false, "intensity_bias" => "standard"]); echo "Reset user {$u->id}\n";'
```

- [ ] **Step 3: Open the simulator and walk through**

```bash
cd app && bash scripts/run-dev.sh
```

Onboard with goal_type = race, distance = 10K, target_date = 12 weeks out, goal_time = 50:00, days_per_week = 4. Reach the new step.

- [ ] **Step 4: Visually verify**

- Chart bars animate when you tap different segments.
- Race-day bar (last) is gold; build bars are warmBrown.
- Caption text crossfades.
- "(auto-pick)" label fades out when Standard is not selected.
- Review screen shows "Intensity: Push me harder" (or hides the row when Standard).

- [ ] **Step 5: Verify the plan reflects the choice**

After plan generation, the proposal opens in the chat:

```bash
cd api && php artisan tinker --execute 'use App\Models\CoachProposal; $p = CoachProposal::latest("id")->first(); echo "level={$p->payload["ambition"]["level"]} effective={$p->payload["ambition"]["effective_level"]}\n"; foreach ($p->payload["schedule"]["weeks"] as $w) echo "  w{$w["week_number"]}: {$w["total_km"]}km\n";'
```

For Push me harder + Ambitious auto, expect peak `total_km` around 38-45km (vs ~28-32 for Standard).

- [ ] **Step 6: Bump pubspec build number**

Open `app/pubspec.yaml` and bump `+N`:

```yaml
version: 1.0.0+N+1
```

- [ ] **Step 7: Commit**

```bash
git add app/pubspec.yaml
git commit -m "chore: bump build number for intensity-bias release"
```

---

## Done

The feature is shippable when:
- Backend test suite green (`php artisan test --compact`)
- Flutter analyze + test green (`flutter analyze && flutter test`)
- Manual E2E in Task 24 confirms the visual + the resulting plan reflects the bias

Do NOT auto-deploy. Per project convention (`./CLAUDE.md` → "Never auto-push, build, or upload"), wait for an explicit per-turn instruction before:
- `git push` to main
- `bash scripts/build-ios.sh`
- `bash scripts/upload-ios.sh`
