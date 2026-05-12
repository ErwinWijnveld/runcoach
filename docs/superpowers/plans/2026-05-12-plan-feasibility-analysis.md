# Plan Feasibility Analysis Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Surface `PlanAmbitionAnalyzer` output as a percentage + horizontal zone-bar inside `PlanDetailsSheet`, with a red "Adjust goal" CTA that prefills the coach chat when feasibility falls below 40%.

**Architecture:** Three changes in sequence. (1) New nullable accessor `AmbitionAssessment::toFeasibilityPayload()` produces a wire-shape with `feasibility_pct` + `verdict_zone` + Dutch verdict copy. (2) `BuildPlan` injects this into `CoachProposal.payload` so the modal can read it. (3) `PlanDetailsSheet` renders a `_FeasibilityZoneBar` widget between header and top-stats, and `_StickyFooter` flips to a red primary CTA when zone is `unrealistic` — tap routes through the existing `onAdjust` callback with a new `prefill` parameter that lands in the chat input.

**Tech Stack:** PHP 8.5 / Laravel 13 / PHPUnit 12 (backend); Flutter / Riverpod / Freezed 3 (app). Spec: `docs/superpowers/specs/2026-05-12-plan-feasibility-analysis-design.md`.

Reference design constants:
- `PlanAmbitionAnalyzer::REALISTIC_IMPROVEMENT_PER_MONTH = 12.0` (already exists)
- `PACE_WEIGHT = 0.6`, `VOLUME_WEIGHT = 0.4` (new — pace dominates)
- `ZONE_OK_MIN = 70`, `ZONE_STRETCH_MIN = 40` (new — verdict thresholds)
- App theme: `AppColors.danger = #8F3A3A` (exists), `AppColors.secondary = #E9B638` (gold, exists), `AppColors.lightTan` (exists). The mockup used a brighter `#C24A2C` red — keep the existing `AppColors.danger` to stay on-palette unless contrast on white reads too dark in widget review.

---

### Task 1: `AmbitionAssessment::toFeasibilityPayload()` — happy paths

**Files:**
- Modify: `api/app/Support/Onboarding/AmbitionAssessment.php`
- Create: `api/tests/Unit/Support/Onboarding/AmbitionAssessmentFeasibilityPayloadTest.php`

- [ ] **Step 1: Write the failing test file**

Create `api/tests/Unit/Support/Onboarding/AmbitionAssessmentFeasibilityPayloadTest.php`:

```php
<?php

namespace Tests\Unit\Support\Onboarding;

use App\Enums\AmbitionLevel;
use App\Support\Onboarding\AmbitionAssessment;
use App\Support\Onboarding\EffectiveAmbitionLevel;
use PHPUnit\Framework\TestCase;

class AmbitionAssessmentFeasibilityPayloadTest extends TestCase
{
    public function test_returns_null_when_no_pace_gap(): void
    {
        $assessment = AmbitionAssessment::realistic();

        $this->assertNull($assessment->toFeasibilityPayload());
    }

    public function test_ok_zone_for_modest_pace_gap_and_full_volume(): void
    {
        // Needs 10 sec/km/month — under the 12 sec/km realistic baseline.
        // Volume ratio 0.88 → volume feasibility 88%.
        // pace_pct = round(min(1, 12/10) * 100) = 100 (clamped)
        // volume_pct = round(0.88 * 100) = 88
        // feasibility = round((1.0 * 0.6 + 0.88 * 0.4) * 100) = 95
        $assessment = $this->assessment(
            improvementPerMonthSeconds: 10.0,
            volumeRatio: 0.88,
            paceGap: 31,
        );

        $payload = $assessment->toFeasibilityPayload();

        $this->assertNotNull($payload);
        $this->assertSame(95, $payload['feasibility_pct']);
        $this->assertSame(100, $payload['pace_score_pct']);
        $this->assertSame(88, $payload['volume_score_pct']);
        $this->assertSame('ok', $payload['verdict_zone']);
        $this->assertSame(31, $payload['pace_gap_seconds_per_km']);
        $this->assertSame(10, $payload['required_improvement_per_month_seconds']);
    }

    public function test_stretch_zone_for_double_required_rate(): void
    {
        // 24 sec/km/month required (2× baseline). Volume 80%.
        // pace_pct = round(12/24 * 100) = 50
        // volume_pct = 80
        // feasibility = round((0.5 * 0.6 + 0.8 * 0.4) * 100) = 62
        $assessment = $this->assessment(
            improvementPerMonthSeconds: 24.0,
            volumeRatio: 0.80,
            paceGap: 60,
            level: AmbitionLevel::Ambitious,
        );

        $payload = $assessment->toFeasibilityPayload();

        $this->assertSame(62, $payload['feasibility_pct']);
        $this->assertSame('stretch', $payload['verdict_zone']);
    }

    public function test_unrealistic_zone_for_triple_required_rate(): void
    {
        // 38 sec/km/month required (3× baseline). Volume 60%.
        // pace_pct = round(12/38 * 100) = 32
        // volume_pct = 60
        // feasibility = round((0.32 * 0.6 + 0.6 * 0.4) * 100) = 43
        // Wait — 0.32*0.6 + 0.6*0.4 = 0.192 + 0.24 = 0.432 → 43
        // 43 is in stretch zone. Push lower: vol 0.5.
        // pace 0.32, vol 0.5: 0.192 + 0.20 = 0.392 → 39 → unrealistic.
        $assessment = $this->assessment(
            improvementPerMonthSeconds: 38.0,
            volumeRatio: 0.50,
            paceGap: 114,
            level: AmbitionLevel::VeryAmbitious,
        );

        $payload = $assessment->toFeasibilityPayload();

        $this->assertSame(39, $payload['feasibility_pct']);
        $this->assertSame('unrealistic', $payload['verdict_zone']);
    }

    public function test_null_volume_ratio_clamps_to_full_volume_feasibility(): void
    {
        $assessment = $this->assessment(
            improvementPerMonthSeconds: 12.0,
            volumeRatio: null,
            paceGap: 20,
        );

        $payload = $assessment->toFeasibilityPayload();

        $this->assertSame(100, $payload['volume_score_pct']);
        $this->assertSame(100, $payload['pace_score_pct']);
        $this->assertSame(100, $payload['feasibility_pct']);
    }

    public function test_zone_boundary_70_is_ok(): void
    {
        // pace 1.0, vol 0.25: (0.6 + 0.1) = 0.70 → 70 → ok (>= 70)
        $assessment = $this->assessment(
            improvementPerMonthSeconds: 12.0,
            volumeRatio: 0.25,
            paceGap: 12,
        );

        $payload = $assessment->toFeasibilityPayload();

        $this->assertSame(70, $payload['feasibility_pct']);
        $this->assertSame('ok', $payload['verdict_zone']);
    }

    public function test_zone_boundary_40_is_stretch(): void
    {
        // Construct exactly 40%: pace 0.4, vol 0.4 → (0.24 + 0.16) = 0.40
        // 12/30 = 0.4 → improvement = 30 sec/km/month
        $assessment = $this->assessment(
            improvementPerMonthSeconds: 30.0,
            volumeRatio: 0.40,
            paceGap: 90,
        );

        $payload = $assessment->toFeasibilityPayload();

        $this->assertSame(40, $payload['feasibility_pct']);
        $this->assertSame('stretch', $payload['verdict_zone']);
    }

    private function assessment(
        float $improvementPerMonthSeconds,
        ?float $volumeRatio,
        int $paceGap,
        AmbitionLevel $level = AmbitionLevel::Realistic,
    ): AmbitionAssessment {
        return new AmbitionAssessment(
            level: $level,
            paceGapSecondsPerKm: $paceGap,
            improvementPerMonthSeconds: $improvementPerMonthSeconds,
            volumeRatio: $volumeRatio,
            peakVolumeMultiplier: 1.6,
            weeksExtension: 0,
            summary: null,
            suggestion: null,
            effectiveLevel: EffectiveAmbitionLevel::Realistic,
            weeklyGrowthRatio: 1.30,
            qualityPaceRampGain: 1.0,
        );
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cd /Users/erwin/personal/runcoach/api
php artisan test --compact --filter=AmbitionAssessmentFeasibilityPayloadTest
```

Expected: every test errors with `Error: Call to undefined method ... toFeasibilityPayload()`.

- [ ] **Step 3: Add the method to `AmbitionAssessment`**

Open `api/app/Support/Onboarding/AmbitionAssessment.php`. Add class constants directly under the class declaration (above the constructor):

```php
final readonly class AmbitionAssessment
{
    public const PACE_WEIGHT = 0.6;
    public const VOLUME_WEIGHT = 0.4;
    public const ZONE_OK_MIN_PCT = 70;
    public const ZONE_STRETCH_MIN_PCT = 40;

    public const REALISTIC_IMPROVEMENT_PER_MONTH = 12.0;

    public function __construct(
```

(Keep the existing constructor unchanged.)

Then append a new method below `toFitnessSummary()`:

```php
    /**
     * Wire-shape consumed by the Flutter plan-details modal. Null when
     * there's no measurable goal (no pace gap) — the section is skipped
     * in that case. Numbers are pre-aggregated to integers so the app
     * never has to do arithmetic.
     */
    public function toFeasibilityPayload(): ?array
    {
        if ($this->paceGapSecondsPerKm === null || $this->improvementPerMonthSeconds === null) {
            return null;
        }

        $paceFeasibility = min(
            1.0,
            self::REALISTIC_IMPROVEMENT_PER_MONTH / max($this->improvementPerMonthSeconds, 0.01),
        );
        $volumeFeasibility = $this->volumeRatio === null
            ? 1.0
            : max(0.0, min(1.0, $this->volumeRatio));

        $feasibility01 = $paceFeasibility * self::PACE_WEIGHT
            + $volumeFeasibility * self::VOLUME_WEIGHT;

        $feasibilityPct = (int) round($feasibility01 * 100);
        $zone = match (true) {
            $feasibilityPct >= self::ZONE_OK_MIN_PCT => 'ok',
            $feasibilityPct >= self::ZONE_STRETCH_MIN_PCT => 'stretch',
            default => 'unrealistic',
        };

        return [
            'feasibility_pct' => $feasibilityPct,
            'pace_score_pct' => (int) round($paceFeasibility * 100),
            'volume_score_pct' => (int) round($volumeFeasibility * 100),
            'verdict_zone' => $zone,
            'verdict_label' => $this->verdictLabel($zone),
            'detail' => $this->verdictDetail($zone, $this->improvementPerMonthSeconds, $volumeFeasibility),
            'pace_gap_seconds_per_km' => $this->paceGapSecondsPerKm,
            'required_improvement_per_month_seconds' => (int) round($this->improvementPerMonthSeconds),
            'adjust_prefill' => $this->adjustPrefill($zone),
        ];
    }

    private function verdictLabel(string $zone): string
    {
        return match ($zone) {
            'ok' => 'Goed haalbaar',
            'stretch' => 'Pittig maar haalbaar',
            'unrealistic' => 'Te ambitieus voor dit plan',
            default => '',
        };
    }

    private function verdictDetail(string $zone, float $improvementPerMonth, float $volumeFeasibility): string
    {
        $rate = (int) round($improvementPerMonth);
        $volPct = (int) round($volumeFeasibility * 100);

        return match ($zone) {
            'ok' => sprintf(
                '%d sec/km per maand verbetering nodig — binnen normaal voor jouw volume.',
                $rate,
            ),
            'stretch' => sprintf(
                'Vraagt %d sec/km per maand — bijna 2× wat realistisch is. Volume %d%% van aanbevolen.',
                $rate,
                $volPct,
            ),
            'unrealistic' => sprintf(
                'Vraagt %d sec/km per maand — ruim boven realistische verbeteringsrate. Volume %d%% van aanbevolen.',
                $rate,
                $volPct,
            ),
            default => '',
        };
    }

    private function adjustPrefill(string $zone): string
    {
        return 'Mijn doel voelt te ambitieus voor dit plan — kun je een realistischer tijd voorstellen?';
    }
```

- [ ] **Step 4: Run the test to verify all cases pass**

```bash
php artisan test --compact --filter=AmbitionAssessmentFeasibilityPayloadTest
```

Expected: PASS (7 tests).

- [ ] **Step 5: Run pint on the modified file**

```bash
vendor/bin/pint --dirty --format agent
```

- [ ] **Step 6: Commit**

```bash
git add api/app/Support/Onboarding/AmbitionAssessment.php api/tests/Unit/Support/Onboarding/AmbitionAssessmentFeasibilityPayloadTest.php
git commit -m "feat(feasibility): AmbitionAssessment::toFeasibilityPayload()"
```

---

### Task 2: Inject `ambition` into `BuildPlan` proposal payload

**Files:**
- Modify: `api/app/Ai/Tools/BuildPlan.php` (around line 220 — `persistPending` call)
- Create: `api/tests/Feature/Ai/Tools/BuildPlanFeasibilityPayloadTest.php`

- [ ] **Step 1: Write the failing test**

Create `api/tests/Feature/Ai/Tools/BuildPlanFeasibilityPayloadTest.php`:

```php
<?php

namespace Tests\Feature\Ai\Tools;

use App\Ai\Tools\BuildPlan;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Laravel\Ai\Agent\Tool\Request as ToolRequest;
use Tests\TestCase;

class BuildPlanFeasibilityPayloadTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_payload_includes_ambition_when_goal_has_time(): void
    {
        $user = User::factory()->create();
        $tool = $this->buildTool($user);

        $result = json_decode($tool->handle(ToolRequest::fromArray([
            'goal_type' => 'train_for_race',
            'distance_meters' => 5000,
            'target_date' => now()->addWeeks(12)->toDateString(),
            'goal_time_seconds' => 1320, // 22:00
            'goal_name' => 'Spring 5K',
            'days_per_week' => 4,
            'preferred_weekdays' => [1, 3, 5, 6],
            'run_type_preferences' => ['easy', 'tempo', 'interval', 'long_run'],
            'additional_notes' => null,
            'intensity_bias' => null,
        ])), true);

        $this->assertTrue($result['requires_approval']);

        $proposal = \App\Models\CoachProposal::findOrFail($result['proposal_id']);
        $this->assertArrayHasKey('ambition', $proposal->payload);

        $ambition = $proposal->payload['ambition'];
        $this->assertArrayHasKey('feasibility_pct', $ambition);
        $this->assertArrayHasKey('verdict_zone', $ambition);
        $this->assertArrayHasKey('adjust_prefill', $ambition);
        $this->assertContains($ambition['verdict_zone'], ['ok', 'stretch', 'unrealistic']);
    }

    public function test_payload_omits_ambition_for_general_fitness_goal(): void
    {
        $user = User::factory()->create();
        $tool = $this->buildTool($user);

        $result = json_decode($tool->handle(ToolRequest::fromArray([
            'goal_type' => 'general_fitness',
            'distance_meters' => null,
            'target_date' => null,
            'goal_time_seconds' => null,
            'goal_name' => 'Stay fit',
            'days_per_week' => 3,
            'preferred_weekdays' => [1, 3, 5],
            'run_type_preferences' => ['easy', 'tempo', 'interval', 'long_run'],
            'additional_notes' => null,
            'intensity_bias' => null,
        ])), true);

        $proposal = \App\Models\CoachProposal::findOrFail($result['proposal_id']);
        $this->assertArrayNotHasKey('ambition', $proposal->payload);
    }

    private function buildTool(User $user): BuildPlan
    {
        return new BuildPlan(
            user: $user,
            snapshots: app(\App\Services\Onboarding\FitnessSnapshotService::class),
            ambition: app(\App\Services\Onboarding\PlanAmbitionAnalyzer::class),
            builder: app(\App\Services\Onboarding\TrainingPlanBuilder::class),
            optimizer: app(\App\Services\PlanOptimizerService::class),
            proposals: app(\App\Services\ProposalService::class),
        );
    }
}
```

(If the `BuildPlan` constructor signature in `BuildPlan.php` differs from the parameters above, adjust the `buildTool` helper to match — read `api/app/Ai/Tools/BuildPlan.php` line 50-60 to confirm before running.)

- [ ] **Step 2: Run the test to verify it fails**

```bash
php artisan test --compact --filter=BuildPlanFeasibilityPayloadTest
```

Expected: `test_payload_includes_ambition_when_goal_has_time` fails with `Failed asserting that an array has the key 'ambition'`.

- [ ] **Step 3: Inject the payload in `BuildPlan::handle()`**

In `api/app/Ai/Tools/BuildPlan.php`, locate the block ending with `$proposal = $this->proposals->persistPending(...)`. Immediately before it, add:

```php
        $ambitionPayload = $assessment->toFeasibilityPayload();
        if ($ambitionPayload !== null) {
            $payload['ambition'] = $ambitionPayload;
        }

        $proposal = $this->proposals->persistPending(
            $this->user,
            ProposalType::CreateSchedule,
            $payload,
        );
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
php artisan test --compact --filter=BuildPlanFeasibilityPayloadTest
```

Expected: PASS (2 tests).

- [ ] **Step 5: Run the rest of BuildPlan tests to confirm no regressions**

```bash
php artisan test --compact --filter=BuildPlan
```

Expected: all pre-existing BuildPlan tests still pass.

- [ ] **Step 6: Pint + commit**

```bash
vendor/bin/pint --dirty --format agent
git add api/app/Ai/Tools/BuildPlan.php api/tests/Feature/Ai/Tools/BuildPlanFeasibilityPayloadTest.php
git commit -m "feat(feasibility): persist ambition in CoachProposal.payload"
```

---

### Task 3: Add `dangerBg` colour token + ensure `danger` is reachable

**Files:**
- Modify: `app/lib/core/theme/app_theme.dart`

Background: `AppColors.danger = #8F3A3A` already exists but there is no soft-bg variant for the red feasibility card. We need one.

- [ ] **Step 1: Inspect the current AppColors block**

```bash
sed -n '1,32p' app/lib/core/theme/app_theme.dart
```

Confirm `danger` exists at line 14 and there is no `dangerBg`.

- [ ] **Step 2: Add `dangerBg` colour**

Edit `app/lib/core/theme/app_theme.dart`. Find this line:

```dart
  static const danger = Color(0xFF8F3A3A);
```

Add directly below it:

```dart
  static const dangerBg = Color(0xFFFBE9E3);
```

- [ ] **Step 3: Run flutter analyze**

```bash
cd /Users/erwin/personal/runcoach/app
flutter analyze
```

Expected: no new issues.

- [ ] **Step 4: Commit**

```bash
git add app/lib/core/theme/app_theme.dart
git commit -m "chore(theme): add AppColors.dangerBg for feasibility red state"
```

---

### Task 4: Extend `onAdjust` to carry a prefill string

**Files:**
- Modify: `app/lib/features/coach/widgets/plan_details_sheet.dart` (lines 13-37, 127-132, 673-746)
- Modify: `app/lib/features/coach/widgets/coach_chat_view.dart` (lines 145-162, look for `_controller` and `_inputFocus`)

This task only changes the signature and wiring. Visual changes follow in Task 5.

- [ ] **Step 1: Read the relevant slice of coach_chat_view.dart**

```bash
sed -n '140,200p' app/lib/features/coach/widgets/coach_chat_view.dart
```

Confirm `_controller` (TextEditingController) and `_inputFocus` (FocusNode) are the chat input handles used by `CoachPromptBar.input`.

- [ ] **Step 2: Update `PlanDetailsSheet` to accept prefill in onAdjust**

In `app/lib/features/coach/widgets/plan_details_sheet.dart`, change the `onAdjust` field signature:

```dart
class PlanDetailsSheet extends StatelessWidget {
  final CoachProposal proposal;
  final Future<void> Function()? onAccept;
  final Future<void> Function({String? prefill})? onAdjust;

  const PlanDetailsSheet({
    super.key,
    required this.proposal,
    this.onAccept,
    this.onAdjust,
  });

  static Future<void> show(
    BuildContext context, {
    required CoachProposal proposal,
    Future<void> Function()? onAccept,
    Future<void> Function({String? prefill})? onAdjust,
  }) {
```

(Keep all other code in `show()` identical — just the param type changes.)

Then in `_StickyFooter`, change the field type and call site:

```dart
class _StickyFooter extends StatelessWidget {
  final bool isPending;
  final bool isRevision;
  final Future<void> Function()? onAccept;
  final Future<void> Function({String? prefill})? onAdjust;
```

And the existing tap handler stays:

```dart
                        onPressed: onAdjust == null
                            ? null
                            : () {
                                Navigator.of(context).pop();
                                onAdjust!();
                              },
```

(No prefill from the ADJUST button — that's the soft path. The red CTA in Task 5 will pass `prefill:`.)

- [ ] **Step 3: Update the caller in coach_chat_view.dart**

In `app/lib/features/coach/widgets/coach_chat_view.dart`, change the `onAdjust` lambda passed to `PlanDetailsSheet.show()`:

```dart
                            onAdjust: ({String? prefill}) async {
                              if (prefill != null && prefill.isNotEmpty) {
                                _controller.text = prefill;
                                _controller.selection = TextSelection.collapsed(
                                  offset: _controller.text.length,
                                );
                              }
                              _inputFocus.requestFocus();
                            },
```

- [ ] **Step 4: Run flutter analyze**

```bash
cd app
flutter analyze
```

Expected: no new issues. The signature change is a pure rename — every existing call site (only the one in `coach_chat_view.dart`) is updated in Step 3.

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/coach/widgets/plan_details_sheet.dart app/lib/features/coach/widgets/coach_chat_view.dart
git commit -m "refactor(coach): onAdjust accepts optional prefill for chat input"
```

---

### Task 5: Render `_FeasibilityZoneBar` in the modal

**Files:**
- Modify: `app/lib/features/coach/widgets/plan_details_sheet.dart`

- [ ] **Step 1: Add `_FeasibilityZoneBar` widget definition at end of file**

Append to `app/lib/features/coach/widgets/plan_details_sheet.dart`, after the existing widgets (after `_WeekCard` / before the last closing brace if the file has a private painter — read line 920+ to find the right insertion point):

```dart
/// Feasibility verdict + horizontal zone-bar. Reads `proposal.payload['ambition']`
/// — a map produced by `AmbitionAssessment::toFeasibilityPayload()` on the
/// backend. Renders nothing when the key is absent (no measurable goal).
class _FeasibilityZoneBar extends StatelessWidget {
  final Map<String, dynamic> ambition;
  const _FeasibilityZoneBar({required this.ambition});

  @override
  Widget build(BuildContext context) {
    final pct = (ambition['feasibility_pct'] as num?)?.toInt() ?? 0;
    final zone = ambition['verdict_zone'] as String? ?? 'ok';
    final label = ambition['verdict_label'] as String? ?? '';
    final detail = ambition['detail'] as String? ?? '';

    final isUnrealistic = zone == 'unrealistic';
    final bgColor = isUnrealistic ? AppColors.dangerBg : AppColors.lightTan;
    final pctColor = switch (zone) {
      'ok' => AppColors.success,
      'stretch' => AppColors.secondary,
      'unrealistic' => AppColors.danger,
      _ => AppColors.primaryInk,
    };

    final clampedPct = pct.clamp(0, 100);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.ebGaramond(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                    color: isUnrealistic ? AppColors.danger : AppColors.primaryInk,
                    height: 1.15,
                  ),
                ),
              ),
              Text(
                '$clampedPct%',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: pctColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final markerLeft = (width * clampedPct / 100).clamp(0.0, width - 4);
              return SizedBox(
                height: 22,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: 4,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 14,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFC24A2C),
                              Color(0xFFC24A2C),
                              Color(0xFFE0B044),
                              Color(0xFFE0B044),
                              Color(0xFF6FAA59),
                              Color(0xFF6FAA59),
                            ],
                            stops: [0.0, 0.35, 0.35, 0.70, 0.70, 1.0],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: markerLeft,
                      child: Container(
                        width: 4,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppColors.primaryInk,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.white,
                              blurRadius: 0,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _axisLabel('Onhaalbaar'),
              _axisLabel('Stretch'),
              _axisLabel('Goed'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            detail,
            style: GoogleFonts.publicSans(
              fontSize: 12.5,
              height: 1.45,
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _axisLabel(String text) => Text(
        text,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: AppColors.inkMuted,
        ),
      );
}
```

- [ ] **Step 2: Read `ambition` from payload in build()**

In `PlanDetailsSheet.build()`, near the top of the existing builder body (where `weeks` and `avgKm` are computed), add:

```dart
        final ambition = _ambition(proposal.payload);
```

And add a helper method on the class (next to `_weeks`, `_averageWeeklyKm`):

```dart
  Map<String, dynamic>? _ambition(Map<String, dynamic> payload) {
    final raw = payload['ambition'];
    if (raw is! Map) return null;
    return Map<String, dynamic>.from(raw);
  }
```

- [ ] **Step 3: Insert the widget between header and top-stats**

In the existing `Column` that contains `_Header`, `SizedBox(height: 16)`, then `_TopStats` / chart / cards, insert the feasibility section IMMEDIATELY after the header SizedBox AND inside the `else ...[ ]` branch (so it appears on creation proposals only, not revisions). The existing code is:

```dart
                      _Header(
                        goalName: _goalName(),
                        isRevision: ops != null,
                      ),
                      const SizedBox(height: 16),
                      if (ops != null) ...[
                        PlanRevisionContent(ops: ops),
                      ] else ...[
                        _TopStats(
                          totalWeeks: weeks.length,
                          avgWeeklyKm: avgKm,
                          weeklyRuns: runsRange,
                        ),
```

Change the `else ...[` block to:

```dart
                      ] else ...[
                        if (ambition != null) ...[
                          _FeasibilityZoneBar(ambition: ambition),
                          const SizedBox(height: 20),
                        ],
                        _TopStats(
                          totalWeeks: weeks.length,
                          avgWeeklyKm: avgKm,
                          weeklyRuns: runsRange,
                        ),
```

- [ ] **Step 4: Run flutter analyze**

```bash
cd app
flutter analyze
```

Expected: no new issues.

- [ ] **Step 5: Manual sanity check via dev seeder**

```bash
cd /Users/erwin/personal/runcoach/api
php artisan db:seed --class=DevPlanSeeder
```

Then `bash app/scripts/run-dev.sh -d <sim-id>`, open the existing proposal in coach chat, tap View Details. Confirm the section renders, or doesn't (depending on whether the seeded proposal has `ambition` — it may not since it was created before this change. If absent, generate a new plan via onboarding flow).

- [ ] **Step 6: Commit**

```bash
git add app/lib/features/coach/widgets/plan_details_sheet.dart
git commit -m "feat(feasibility): render zone-bar verdict in PlanDetailsSheet"
```

---

### Task 6: Escalate `_StickyFooter` to red CTA when zone is unrealistic

**Files:**
- Modify: `app/lib/features/coach/widgets/plan_details_sheet.dart`

- [ ] **Step 1: Pass zone state from build() into _StickyFooter**

In `PlanDetailsSheet.build()`, derive a flag after reading `ambition`:

```dart
        final ambition = _ambition(proposal.payload);
        final warnUnrealistic = ambition != null && ambition['verdict_zone'] == 'unrealistic';
```

Update the `_StickyFooter` instantiation to pass the new param + the prefill:

```dart
              _StickyFooter(
                isPending: _isPending,
                isRevision: ops != null,
                warnUnrealistic: warnUnrealistic,
                adjustPrefill: warnUnrealistic
                    ? ambition!['adjust_prefill'] as String?
                    : null,
                onAccept: onAccept,
                onAdjust: onAdjust,
              ),
```

- [ ] **Step 2: Extend `_StickyFooter` with the new fields and red-state branch**

Replace the existing `_StickyFooter` class with:

```dart
class _StickyFooter extends StatelessWidget {
  final bool isPending;
  final bool isRevision;
  final bool warnUnrealistic;
  final String? adjustPrefill;
  final Future<void> Function()? onAccept;
  final Future<void> Function({String? prefill})? onAdjust;

  const _StickyFooter({
    required this.isPending,
    required this.isRevision,
    required this.warnUnrealistic,
    required this.adjustPrefill,
    required this.onAccept,
    required this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: !isPending
              ? _PrimaryButton(
                  label: 'CLOSE',
                  background: AppColors.lightTan,
                  foreground: AppColors.primary,
                  onPressed: () => Navigator.of(context).pop(),
                )
              : warnUnrealistic
                  ? _UnrealisticFooter(
                      adjustPrefill: adjustPrefill,
                      onAccept: onAccept,
                      onAdjust: onAdjust,
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _PrimaryButton(
                            label: 'ADJUST',
                            background: AppColors.lightTan,
                            foreground: AppColors.primary,
                            onPressed: onAdjust == null
                                ? null
                                : () {
                                    Navigator.of(context).pop();
                                    onAdjust!();
                                  },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: _PrimaryButton(
                            label: isRevision ? 'APPLY CHANGES' : 'ACCEPT PLAN',
                            background: AppColors.secondary,
                            foreground: AppColors.primary,
                            onPressed: onAccept == null
                                ? null
                                : () async {
                                    await onAccept!();
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}

class _UnrealisticFooter extends StatelessWidget {
  final String? adjustPrefill;
  final Future<void> Function()? onAccept;
  final Future<void> Function({String? prefill})? onAdjust;

  const _UnrealisticFooter({
    required this.adjustPrefill,
    required this.onAccept,
    required this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PrimaryButton(
          label: 'ADJUST GOAL FOR REALISTIC PLAN',
          background: AppColors.danger,
          foreground: Colors.white,
          onPressed: onAdjust == null
              ? null
              : () {
                  Navigator.of(context).pop();
                  onAdjust!(prefill: adjustPrefill);
                },
        ),
        const SizedBox(height: 8),
        _PrimaryButton(
          label: 'Accept anyway',
          background: AppColors.lightTan,
          foreground: AppColors.primary,
          onPressed: onAccept == null
              ? null
              : () async {
                  await onAccept!();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: Verify `_PrimaryButton` already exists and accepts these params**

```bash
grep -n "class _PrimaryButton" app/lib/features/coach/widgets/plan_details_sheet.dart
```

If `_PrimaryButton` doesn't already accept `background`, `foreground`, `label`, and `onPressed` — read its definition and reconcile. (It does, based on the existing callsites in Task 4's read of lines 700-730.)

- [ ] **Step 4: Run flutter analyze**

```bash
cd app
flutter analyze
```

Expected: no new issues.

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/coach/widgets/plan_details_sheet.dart
git commit -m "feat(feasibility): red Adjust-goal CTA when zone unrealistic"
```

---

### Task 7: Widget test for feasibility section

**Files:**
- Create: `app/test/features/coach/widgets/plan_details_sheet_feasibility_test.dart`

- [ ] **Step 1: Inspect existing widget tests in app/test/ for patterns**

```bash
find app/test -name "*.dart" | head -10
ls app/test/features/coach/ 2>/dev/null
```

If no existing pattern — write the test using vanilla `flutter_test`'s `testWidgets`.

- [ ] **Step 2: Write the widget test**

Create `app/test/features/coach/widgets/plan_details_sheet_feasibility_test.dart`:

```dart
import 'package:app/features/coach/models/coach_proposal.dart';
import 'package:app/features/coach/widgets/plan_details_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlanDetailsSheet feasibility', () {
    testWidgets('renders zone-bar when ambition payload present', (tester) async {
      final proposal = _makeProposal(ambition: {
        'feasibility_pct': 78,
        'pace_score_pct': 83,
        'volume_score_pct': 88,
        'verdict_zone': 'ok',
        'verdict_label': 'Pittig maar haalbaar',
        'detail': '10 sec/km per maand verbetering nodig.',
        'adjust_prefill': null,
      });

      await tester.pumpWidget(_host(proposal: proposal));
      await tester.pumpAndSettle();

      expect(find.text('Pittig maar haalbaar'), findsOneWidget);
      expect(find.text('78%'), findsOneWidget);
      expect(find.text('Onhaalbaar'), findsOneWidget);
      expect(find.text('Stretch'), findsOneWidget);
      expect(find.text('Goed'), findsOneWidget);
    });

    testWidgets('skips section when ambition is null', (tester) async {
      final proposal = _makeProposal(ambition: null);

      await tester.pumpWidget(_host(proposal: proposal));
      await tester.pumpAndSettle();

      expect(find.text('Onhaalbaar'), findsNothing);
    });

    testWidgets('red CTA fires onAdjust with prefill when zone unrealistic',
        (tester) async {
      final proposal = _makeProposal(ambition: {
        'feasibility_pct': 28,
        'pace_score_pct': 32,
        'volume_score_pct': 60,
        'verdict_zone': 'unrealistic',
        'verdict_label': 'Te ambitieus',
        'detail': '38 sec/km per maand vraagt 3× realistische rate.',
        'adjust_prefill': 'Mijn doel voelt te ambitieus.',
      });

      String? capturedPrefill;
      var adjustCalls = 0;

      await tester.pumpWidget(_host(
        proposal: proposal,
        onAdjust: ({String? prefill}) async {
          adjustCalls++;
          capturedPrefill = prefill;
        },
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ADJUST GOAL FOR REALISTIC PLAN'));
      await tester.pumpAndSettle();

      expect(adjustCalls, 1);
      expect(capturedPrefill, 'Mijn doel voelt te ambitieus.');
    });

    testWidgets('soft ADJUST passes null prefill when zone ok', (tester) async {
      final proposal = _makeProposal(ambition: {
        'feasibility_pct': 78,
        'verdict_zone': 'ok',
        'verdict_label': 'Goed',
        'detail': 'ok',
        'adjust_prefill': 'should-not-leak',
      });

      String? capturedPrefill = 'sentinel';

      await tester.pumpWidget(_host(
        proposal: proposal,
        onAdjust: ({String? prefill}) async {
          capturedPrefill = prefill;
        },
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ADJUST'));
      await tester.pumpAndSettle();

      expect(capturedPrefill, isNull);
    });
  });
}

CoachProposal _makeProposal({Map<String, dynamic>? ambition}) {
  return CoachProposal(
    id: 1,
    type: 'create_schedule',
    status: 'pending',
    payload: {
      'goal_name': 'Test 5K',
      'schedule': {
        'weeks': [
          {
            'week_number': 1,
            'total_km': 20.0,
            'days': [
              {'day_of_week': 1, 'type': 'easy', 'target_km': 5.0},
            ],
          },
          {
            'week_number': 2,
            'total_km': 22.0,
            'days': [
              {'day_of_week': 1, 'type': 'easy', 'target_km': 5.5},
            ],
          },
        ],
      },
      if (ambition != null) 'ambition': ambition,
    },
  );
}

Widget _host({
  required CoachProposal proposal,
  Future<void> Function({String? prefill})? onAdjust,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () => PlanDetailsSheet.show(
              context,
              proposal: proposal,
              onAccept: () async {},
              onAdjust: onAdjust ?? ({String? prefill}) async {},
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}
```

Then the test body opens the sheet before assertions:

In each `testWidgets` block, add right after `await tester.pumpAndSettle();` the first time:

```dart
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
```

(Re-read the test once written and add this line in the right place — it must run between pumping the host and looking for the sheet content.)

- [ ] **Step 3: Run the widget test**

```bash
cd app
flutter test test/features/coach/widgets/plan_details_sheet_feasibility_test.dart
```

Expected: PASS (4 tests). If `CoachProposal`'s constructor signature differs from the assumed shape, adjust `_makeProposal` to match — read `app/lib/features/coach/models/coach_proposal.dart` to verify field names + types.

- [ ] **Step 4: Commit**

```bash
git add app/test/features/coach/widgets/plan_details_sheet_feasibility_test.dart
git commit -m "test(feasibility): widget test for zone-bar + red CTA"
```

---

### Task 8: Update CLAUDE.md notes + manual end-to-end check

**Files:**
- Modify: `api/CLAUDE.md`
- Modify: `app/CLAUDE.md`

- [ ] **Step 1: Add a one-line bullet to api/CLAUDE.md**

In `api/CLAUDE.md`, find the "Plan-pipeline services" section (near `AmbitionAssessment` references). Append a bullet to the `AmbitionAssessment` entry:

```markdown
- **`AmbitionAssessment::toFeasibilityPayload()`** — produces the `{feasibility_pct, verdict_zone, verdict_label, detail, adjust_prefill, ...}` wire-shape consumed by `PlanDetailsSheet`'s feasibility section. Returns null when no measurable goal. Constants `PACE_WEIGHT`, `VOLUME_WEIGHT`, `ZONE_OK_MIN_PCT`, `ZONE_STRETCH_MIN_PCT` are tunable. Spec: `../docs/superpowers/specs/2026-05-12-plan-feasibility-analysis-design.md`.
```

Also add a bullet to the `BuildPlan tool` entry:

```markdown
- Injects `ambition` (via `toFeasibilityPayload()`) into the persisted proposal payload so the modal can render feasibility without re-running the analyzer. Skipped when the goal has no measurable target.
```

- [ ] **Step 2: Add a bullet to app/CLAUDE.md**

In `app/CLAUDE.md` → "Current state" section (bottom) or section 5c (the proposal/data-flow part), append:

```markdown
- **Plan feasibility section** — `PlanDetailsSheet` reads `proposal.payload['ambition']` (set server-side by `AmbitionAssessment::toFeasibilityPayload()`) and renders `_FeasibilityZoneBar` between header and top-stats: italic verdict label + big % (zone-coloured), red-amber-green linear-gradient track with black pointer, axis labels (Onhaalbaar / Stretch / Goed), and a one-line detail. When `verdict_zone == 'unrealistic'`, `_StickyFooter` replaces the gold Accept with a red full-width "ADJUST GOAL FOR REALISTIC PLAN" button and demotes Accept to a tan "Accept anyway" below. Red CTA tap → modal pops → `onAdjust(prefill: ambition['adjust_prefill'])` → chat input receives prefilled text + focus. Skipped on revision proposals (those carry a `diff` and use the existing revision view). Spec: `../docs/superpowers/specs/2026-05-12-plan-feasibility-analysis-design.md`.
```

- [ ] **Step 3: Manual end-to-end check via dev seed**

Local backend:
```bash
cd api
php artisan migrate:fresh --seed
php artisan serve --host=0.0.0.0 --port=8001
```

In another terminal: queue worker.
```bash
cd api
php artisan queue:work
```

Then open the simulator app and walk through onboarding with three different goal-time inputs to verify each zone:
- Realistic: pick a goal time near current ability — expect zone `ok` (green ring, gold Accept stays).
- Stretch: pick a goal time ~10% faster than realistic — expect zone `stretch` (amber).
- Unrealistic: pick a 16:00 5K time if current pace suggests 25:00 — expect zone `unrealistic` + red CTA.

Tap the red CTA, confirm chat input gets the prefilled text and is focused.

- [ ] **Step 4: Run the full test suite (backend + app)**

```bash
cd api && php artisan test --compact
cd ../app && flutter test && flutter analyze
```

Expected: all green.

- [ ] **Step 5: Commit**

```bash
git add api/CLAUDE.md app/CLAUDE.md
git commit -m "docs(claude-md): note feasibility section + payload contract"
```

---

## Self-review notes

- **Spec coverage:** every section of the design spec maps to a task — `toFeasibilityPayload()` is Task 1, `BuildPlan` injection is Task 2, theme color is Task 3, callback signature is Task 4, rendered widget is Task 5, footer escalation is Task 6, tests are Task 7, docs are Task 8.
- **Tunable constants are class constants on `AmbitionAssessment`**, matching the spec's "live server-side so we can tune without a Flutter release" requirement.
- **Render guards** in Task 5 (`if (ops != null) ...[ ] else ...[ if (ambition != null) ... ]`) cover both "no ambition payload" (skip) and "revision proposal" (skip), per spec.
- **`AdjustPlan` deliberately untouched** — design spec says no change there for v1; revisions are skipped by the render guard so a stale `ambition` on an edited proposal doesn't matter visually.
- **Boundary tests at 70% and 40%** lock the zone semantics so a future tweak to weights doesn't silently flip a runner from `ok` to `stretch`.
