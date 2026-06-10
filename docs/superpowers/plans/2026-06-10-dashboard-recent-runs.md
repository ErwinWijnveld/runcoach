# Dashboard Recent Runs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A "Recent runs" section on the dashboard showing the 5 newest synced runs — unlinked runs get a blue plus that opens the link-to-training sheet, linked runs show the compliance score in the icon slot and navigate to the day detail.

**Architecture:** `GET /dashboard` grows a `recent_runs` array (run summary + `training_day_id` + `compliance_score` per entry). The wire shape for the run reuses the existing `WearableActivitySummary` contract, extracted to `WearableActivity::toSummaryPayload()` so the schedule's off-plan payload and the dashboard can't drift. Flutter adds a `RecentRun` Freezed model, a `recentRuns` list on `DashboardData`, and a `_RecentRunsSection` in `dashboard_screen.dart`. Refresh-after-link is free: `dashboardProvider` already watches `planVersionProvider`, which `linkUnplannedRunProvider` bumps.

**Tech Stack:** Laravel 13 + PHPUnit (`LazilyRefreshDatabase`), Flutter + Freezed/Riverpod codegen, `flutter gen-l10n` ARB workflow.

**Spec:** `docs/superpowers/specs/2026-06-10-dashboard-recent-runs-design.md`

**Working-tree caveat:** the repo has many unrelated uncommitted changes. Stage ONLY the files listed in each commit step — never `git add -A`.

---

### Task 1: Backend — `recent_runs` on the dashboard endpoint

**Files:**
- Modify: `api/app/Models/WearableActivity.php` (add `toSummaryPayload()`)
- Modify: `api/app/Http/Controllers/TrainingScheduleController.php` (delegate `unplannedRunPayload` → model)
- Modify: `api/app/Http/Controllers/DashboardController.php` (add `recent_runs`)
- Test: `api/tests/Feature/DashboardTest.php`

- [ ] **Step 1: Write the failing tests**

Append to `api/tests/Feature/DashboardTest.php` (inside the class). Add `use App\Models\WearableActivity;` to the imports at the top.

```php
public function test_dashboard_includes_recent_runs_with_linkage(): void
{
    [$user, $headers] = $this->authUser();
    $goal = Goal::factory()->create(['user_id' => $user->id, 'status' => GoalStatus::Active]);
    $week = TrainingWeek::factory()->create([
        'goal_id' => $goal->id,
        'starts_at' => now()->startOfWeek(),
    ]);
    $day = TrainingDay::factory()->create([
        'training_week_id' => $week->id,
        'date' => now()->subDays(2),
    ]);

    $linked = WearableActivity::factory()->create([
        'user_id' => $user->id,
        'type' => 'Run',
        'start_date' => now()->subDays(2),
    ]);
    TrainingResult::factory()->create([
        'training_day_id' => $day->id,
        'wearable_activity_id' => $linked->id,
        'compliance_score' => 8.2,
    ]);

    $unlinked = WearableActivity::factory()->create([
        'user_id' => $user->id,
        'type' => 'Run',
        'start_date' => now()->subDay(),
    ]);

    WearableActivity::factory()->create([
        'user_id' => $user->id,
        'type' => 'Ride',
        'start_date' => now(),
    ]);

    $response = $this->getJson('/api/v1/dashboard', $headers);

    $response->assertOk();
    $runs = $response->json('recent_runs');
    $this->assertCount(2, $runs);
    $this->assertSame($unlinked->id, $runs[0]['run']['id']);
    $this->assertNull($runs[0]['training_day_id']);
    $this->assertNull($runs[0]['compliance_score']);
    $this->assertSame($linked->id, $runs[1]['run']['id']);
    $this->assertSame($day->id, $runs[1]['training_day_id']);
    $this->assertSame(8.2, $runs[1]['compliance_score']);
}

public function test_recent_runs_are_capped_at_five_newest(): void
{
    [$user, $headers] = $this->authUser();
    Goal::factory()->create(['user_id' => $user->id, 'status' => GoalStatus::Active]);

    foreach (range(1, 7) as $i) {
        WearableActivity::factory()->create([
            'user_id' => $user->id,
            'type' => 'Run',
            'start_date' => now()->subDays($i),
        ]);
    }

    $runs = $this->getJson('/api/v1/dashboard', $headers)->json('recent_runs');

    $this->assertCount(5, $runs);
    $dates = array_map(fn (array $r) => $r['run']['start_date'], $runs);
    $sorted = $dates;
    rsort($sorted);
    $this->assertSame($sorted, $dates);
}

public function test_dashboard_without_active_goal_still_returns_recent_runs(): void
{
    [$user, $headers] = $this->authUser();
    WearableActivity::factory()->create(['user_id' => $user->id, 'type' => 'Run']);

    $response = $this->getJson('/api/v1/dashboard', $headers);

    $response->assertOk();
    $this->assertNull($response->json('active_goal'));
    $this->assertCount(1, $response->json('recent_runs'));
}
```

- [ ] **Step 2: Run the tests — expect FAIL**

```bash
cd api && php artisan test --compact tests/Feature/DashboardTest.php
```

Expected: the 3 new tests fail (`recent_runs` is null → assertCount fails); the 2 existing tests pass.

- [ ] **Step 3: Add `WearableActivity::toSummaryPayload()`**

In `api/app/Models/WearableActivity.php`, after the `casts()` method:

```php
/**
 * Compact wire shape matching the Flutter `WearableActivitySummary` model.
 * Single source for the schedule's off-plan runs and the dashboard's
 * recent runs so the two payloads can't drift.
 *
 * @return array<string, mixed>
 */
public function toSummaryPayload(): array
{
    return [
        'id' => $this->id,
        'source' => $this->source,
        'source_activity_id' => $this->source_activity_id,
        'type' => $this->type,
        'name' => $this->name,
        'distance_meters' => $this->distance_meters,
        'duration_seconds' => $this->duration_seconds,
        'elapsed_seconds' => $this->elapsed_seconds,
        'average_pace_seconds_per_km' => $this->average_pace_seconds_per_km,
        'average_heartrate' => $this->average_heartrate !== null ? (float) $this->average_heartrate : null,
        'max_heartrate' => $this->max_heartrate !== null ? (float) $this->max_heartrate : null,
        'elevation_gain_meters' => $this->elevation_gain_meters,
        'calories_kcal' => $this->calories_kcal,
        'start_date' => $this->start_date->toIso8601String(),
        'end_date' => $this->end_date?->toIso8601String(),
    ];
}
```

- [ ] **Step 4: Delegate the schedule controller to the model**

In `api/app/Http/Controllers/TrainingScheduleController.php`:
- In `attachUnplannedRuns()`, replace `->map(fn (WearableActivity $r) => $this->unplannedRunPayload($r))` with `->map(fn (WearableActivity $r) => $r->toSummaryPayload())`.
- Delete the entire private `unplannedRunPayload()` method (and its docblock).

- [ ] **Step 5: Add `recent_runs` to `DashboardController`**

Replace `api/app/Http/Controllers/DashboardController.php`'s imports and both return branches:

Add imports:

```php
use App\Models\User;
use App\Models\WearableActivity;
```

No-goal branch becomes:

```php
if (! $goal) {
    return response()->json([
        'weekly_summary' => null,
        'next_training' => null,
        'active_goal' => null,
        'coach_insight' => null,
        'recent_runs' => $this->recentRuns($user),
    ]);
}
```

Main return gains the same key after `'coach_insight' => $coachInsight,`:

```php
'recent_runs' => $this->recentRuns($user),
```

New private method at the bottom of the class:

```php
/**
 * The five newest synced runs with their training-day linkage, so the
 * dashboard renders linked runs (compliance in the icon slot) and
 * off-plan runs (link CTA) in one list.
 *
 * @return list<array{run: array<string, mixed>, training_day_id: int|null, compliance_score: float|null}>
 */
private function recentRuns(User $user): array
{
    return WearableActivity::query()
        ->where('user_id', $user->id)
        ->whereIn('type', WearableActivity::RUN_TYPES)
        ->with('trainingResults:id,wearable_activity_id,training_day_id,compliance_score')
        ->orderByDesc('start_date')
        ->limit(5)
        ->get()
        ->map(function (WearableActivity $activity): array {
            $result = $activity->trainingResults->first();

            return [
                'run' => $activity->toSummaryPayload(),
                'training_day_id' => $result?->training_day_id,
                'compliance_score' => $result?->compliance_score !== null
                    ? (float) $result->compliance_score
                    : null,
            ];
        })
        ->all();
}
```

- [ ] **Step 6: Run the dashboard + schedule tests — expect PASS**

```bash
cd api && php artisan test --compact tests/Feature/DashboardTest.php tests/Feature/TrainingScheduleTest.php
```

Expected: all pass (TrainingScheduleTest proves the payload extraction didn't change the off-plan shape — `test_schedule_includes_off_plan_runs_in_their_week` covers it).

- [ ] **Step 7: Pint + commit**

```bash
cd api && vendor/bin/pint --dirty --format agent
cd /Users/erwin/personal/runcoach && git add \
  api/app/Models/WearableActivity.php \
  api/app/Http/Controllers/TrainingScheduleController.php \
  api/app/Http/Controllers/DashboardController.php \
  api/tests/Feature/DashboardTest.php
git commit -m "feat(api): recent runs with linkage on dashboard endpoint

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 2: Flutter — `RecentRun` model + `DashboardData.recentRuns`

**Files:**
- Create: `app/lib/features/dashboard/models/recent_run.dart`
- Modify: `app/lib/features/dashboard/models/dashboard_data.dart`
- Test: `app/test/features/dashboard/recent_run_test.dart`
- Generated: `recent_run.freezed.dart` / `recent_run.g.dart` / `dashboard_data.*` via build_runner

- [ ] **Step 1: Write the model**

`app/lib/features/dashboard/models/recent_run.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/core/utils/json_converters.dart';
import 'package:app/features/schedule/models/wearable_activity_summary.dart';

part 'recent_run.freezed.dart';
part 'recent_run.g.dart';

/// One entry in the dashboard's "Recent runs" list: the wearable run plus
/// its training-day linkage. `trainingDayId` null means off-plan (render the
/// blue plus → link sheet); `complianceScore` (0–10) is null until the run
/// has been matched and scored.
@freezed
sealed class RecentRun with _$RecentRun {
  const factory RecentRun({
    required WearableActivitySummary run,
    @JsonKey(name: 'training_day_id', fromJson: toIntOrNull) int? trainingDayId,
    @JsonKey(name: 'compliance_score', fromJson: toDoubleOrNull)
    double? complianceScore,
  }) = _RecentRun;

  factory RecentRun.fromJson(Map<String, dynamic> json) =>
      _$RecentRunFromJson(json);
}
```

- [ ] **Step 2: Add the field to `DashboardData`**

In `app/lib/features/dashboard/models/dashboard_data.dart`, add the import and field:

```dart
import 'package:app/features/dashboard/models/recent_run.dart';
```

Inside the `DashboardData` factory, after `coachInsight`:

```dart
    @JsonKey(name: 'recent_runs') @Default(<RecentRun>[]) List<RecentRun> recentRuns,
```

- [ ] **Step 3: Run build_runner**

```bash
cd app && dart run build_runner build --delete-conflicting-outputs
```

Expected: generates `recent_run.freezed.dart`, `recent_run.g.dart`, regenerates `dashboard_data.freezed.dart` + `dashboard_data.g.dart`. No errors.

- [ ] **Step 4: Write the model test**

`app/test/features/dashboard/recent_run_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/dashboard/models/dashboard_data.dart';
import 'package:app/features/dashboard/models/recent_run.dart';

Map<String, dynamic> _runJson() => {
      'id': 7,
      'source': 'apple_health',
      'source_activity_id': 'abc-123',
      'type': 'Run',
      'name': 'Riverside loop',
      'distance_meters': 8200,
      'duration_seconds': 1710,
      'average_pace_seconds_per_km': 310,
      'start_date': '2026-06-08T07:30:00+02:00',
    };

void main() {
  test('parses a linked run with a string decimal score', () {
    final entry = RecentRun.fromJson({
      'run': _runJson(),
      'training_day_id': 42,
      'compliance_score': '8.2',
    });

    expect(entry.trainingDayId, 42);
    expect(entry.complianceScore, 8.2);
    expect(entry.run.name, 'Riverside loop');
  });

  test('parses an unlinked run with null linkage', () {
    final entry = RecentRun.fromJson({
      'run': _runJson(),
      'training_day_id': null,
      'compliance_score': null,
    });

    expect(entry.trainingDayId, isNull);
    expect(entry.complianceScore, isNull);
  });

  test('DashboardData defaults to an empty recent runs list', () {
    final dashboard = DashboardData.fromJson(const {});

    expect(dashboard.recentRuns, isEmpty);
  });
}
```

- [ ] **Step 5: Run the test — expect PASS**

```bash
cd app && flutter test test/features/dashboard/recent_run_test.dart
```

Expected: 3 tests pass.

- [ ] **Step 6: Commit**

```bash
cd /Users/erwin/personal/runcoach && git add \
  app/lib/features/dashboard/models/recent_run.dart \
  app/lib/features/dashboard/models/recent_run.freezed.dart \
  app/lib/features/dashboard/models/recent_run.g.dart \
  app/lib/features/dashboard/models/dashboard_data.dart \
  app/lib/features/dashboard/models/dashboard_data.freezed.dart \
  app/lib/features/dashboard/models/dashboard_data.g.dart \
  app/test/features/dashboard/recent_run_test.dart
git commit -m "feat(app): RecentRun model + recent_runs on DashboardData

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 3: Flutter — l10n keys

**Files:**
- Modify: `app/lib/l10n/app_en.arb`, `app/lib/l10n/app_nl.arb`
- Generated: `app/lib/l10n/app_localizations*.dart` via `flutter gen-l10n`

- [ ] **Step 1: Add the keys**

In `app/lib/l10n/app_en.arb`, after `"dashEmptyCta": "Go to Goals",`:

```json
  "dashRecentRunsEyebrow": "RECENT RUNS",
  "dashRecentRunsSeeAll": "See all",
  "dashRecentRunFallbackTitle": "Run",
```

In `app/lib/l10n/app_nl.arb`, in the matching `dash*` block:

```json
  "dashRecentRunsEyebrow": "RECENTE RUNS",
  "dashRecentRunsSeeAll": "Bekijk alles",
  "dashRecentRunFallbackTitle": "Run",
```

- [ ] **Step 2: Regenerate localizations**

```bash
cd app && flutter gen-l10n
```

Expected: regenerates `app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_nl.dart` without untranslated-key warnings for the new keys.

(Commit happens together with Task 4 — the keys are unused until the section exists, and `flutter analyze` would flag nothing either way.)

---

### Task 4: Flutter — `_RecentRunsSection` on the dashboard

**Files:**
- Modify: `app/lib/features/dashboard/screens/dashboard_screen.dart`

- [ ] **Step 1: Add imports**

In `dashboard_screen.dart`:
- Extend the material import (line 2) to:
  ```dart
  import 'package:flutter/material.dart'
      show Icons, Material, InkWell, MaterialType;
  ```
- Add:
  ```dart
  import 'package:app/core/theme/compliance_colors.dart';
  import 'package:app/features/dashboard/models/recent_run.dart';
  import 'package:app/features/schedule/widgets/unplanned_run_sheet.dart';
  ```

- [ ] **Step 2: Render the section in `_DashboardContent`**

In `_DashboardContent.build`, inside the `IntroColumn` children, after `_WeeksMatrixCard(...)`:

```dart
          if (dashboard.recentRuns.isNotEmpty)
            _RecentRunsSection(runs: dashboard.recentRuns, goalId: goal.id),
```

- [ ] **Step 3: Add the section + row widgets**

Add after the `_WeeksMatrixCard` class (before `_RoundedCard`):

```dart
// ---------------------------------------------------------------------------
// Recent runs — every synced run, linked (compliance in the icon slot,
// taps through to the day detail) or off-plan (blue plus → link sheet).
// ---------------------------------------------------------------------------

class _RecentRunsSection extends StatelessWidget {
  final List<RecentRun> runs;
  final int goalId;

  const _RecentRunsSection({required this.runs, required this.goalId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 4, 6, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  context.l10n.dashRecentRunsEyebrow,
                  style: RunCoreText.sectionEyebrow(color: _inkBlack),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => context.go('/schedule'),
                child: Text(
                  context.l10n.dashRecentRunsSeeAll,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _eyebrowGold,
                  ),
                ),
              ),
            ],
          ),
        ),
        _RoundedCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < runs.length; i++) ...[
                if (i > 0) Container(height: 1, color: _lineSoft),
                _RecentRunRow(entry: runs[i], goalId: goalId),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RecentRunRow extends StatelessWidget {
  final RecentRun entry;
  final int goalId;

  const _RecentRunRow({required this.entry, required this.goalId});

  bool get _linked => entry.trainingDayId != null;

  String _subtitle(BuildContext context) {
    final run = entry.run;
    final parts = <String>[];
    final date = DateTime.tryParse(run.startDate);
    if (date != null) {
      parts.add(
        DateFormat.E(Localizations.localeOf(context).toString()).format(date),
      );
    }
    if (run.averagePaceSecondsPerKm > 0) {
      parts.add('${_formatPace(run.averagePaceSecondsPerKm)} /km');
    }
    if (run.durationSeconds > 0) {
      parts.add(_formatClock(run.durationSeconds));
    }
    return parts.join(' · ');
  }

  Widget _leadingIcon(BuildContext context) {
    if (!_linked) {
      return Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.offPlan,
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.add_rounded,
          color: CupertinoColors.white,
          size: 22,
        ),
      );
    }
    final score = entry.complianceScore;
    final color = ComplianceColors.forScore10(score);
    if (score == null || color == null) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.goldGlow,
        ),
        alignment: Alignment.center,
        child: const RunBoostSpark(size: 20),
      );
    }
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.15),
      ),
      alignment: Alignment.center,
      child: Text(
        score.toStringAsFixed(1),
        style: GoogleFonts.spaceGrotesk(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final run = entry.run;
    final km = run.distanceMeters / 1000;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: _linked
            ? () => context.go('/schedule/day/${entry.trainingDayId}')
            : () => showUnplannedRunSheet(context, run: run, goalId: goalId),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              _leadingIcon(context),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      run.name ?? context.l10n.dashRecentRunFallbackTitle,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryInk,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(context),
                      style: RunCoreText.statSuffix(color: _muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Transform(
                alignment: Alignment.bottomRight,
                transform: kRunBoostLean,
                child: Text(
                  km.toStringAsFixed(1),
                  style: RunBoostText.display(
                    size: 22,
                    color: AppColors.primaryInk,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Add the `_formatClock` helper**

Next to the existing helpers at the bottom of `dashboard_screen.dart` (near `_formatPace`):

```dart
/// 1710 → "28:30", 5400 → "1:30:00".
String _formatClock(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  final mm = m.toString().padLeft(2, '0');
  final ss = s.toString().padLeft(2, '0');
  return h > 0 ? '$h:$mm:$ss' : '$m:$ss';
}
```

- [ ] **Step 5: Analyze + run Flutter tests**

```bash
cd app && flutter analyze && flutter test
```

Expected: no analyzer issues, all tests pass.

- [ ] **Step 6: Verify in the running app**

The user runs Flutter web at `http://localhost:62259/#/dashboard` (hot reload picks the change up, or they restart). The `DevPlanSeeder` state has linked runs with compliance AND off-plan unmatched runs, so both row states are visible. Verify: section renders under the weeks matrix, blue plus opens the link sheet, linking refreshes the list (blue plus → score icon), linked row navigates to day detail, "See all" jumps to the Schedule tab.

- [ ] **Step 7: Commit (l10n + UI together)**

```bash
cd /Users/erwin/personal/runcoach && git add \
  app/lib/l10n/app_en.arb \
  app/lib/l10n/app_nl.arb \
  app/lib/l10n/app_localizations.dart \
  app/lib/l10n/app_localizations_en.dart \
  app/lib/l10n/app_localizations_nl.dart \
  app/lib/features/dashboard/screens/dashboard_screen.dart
git commit -m "feat(app): recent runs section on dashboard

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 5: Full suites + CLAUDE.md bullet

- [ ] **Step 1: Full backend suite**

```bash
cd api && php artisan test --compact
```

Expected: all ~300 tests pass.

- [ ] **Step 2: CLAUDE.md bullet**

Append to the "Current state" bullet list in `/Users/erwin/personal/runcoach/CLAUDE.md`:

```markdown
- **Dashboard recent runs** — `GET /dashboard` returns `recent_runs` (5 newest run-type `wearable_activities` + `training_day_id`/`compliance_score` from their `TrainingResult`; summary shape shared via `WearableActivity::toSummaryPayload()`). Flutter `_RecentRunsSection` on the dashboard: linked runs show the 0–10 compliance score in the icon slot (`ComplianceColors.forScore10`) and open `/schedule/day/{id}`; off-plan runs get the blue plus → `showUnplannedRunSheet`. Spec: `docs/superpowers/specs/2026-06-10-dashboard-recent-runs-design.md`.
```

- [ ] **Step 3: Commit docs**

```bash
cd /Users/erwin/personal/runcoach && git add CLAUDE.md docs/superpowers/plans/2026-06-10-dashboard-recent-runs.md
git commit -m "docs: dashboard recent-runs plan + CLAUDE.md bullet

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

## Self-review notes

- **Spec coverage:** backend shape + shared payload helper (Task 1), Freezed model + default-empty list (Task 2), l10n (Task 3), icon-slot states / tap behaviour / See all / hidden-when-empty (Task 4), tests + docs (Tasks 1, 2, 5). Refresh-after-link needs no code (existing `planVersionProvider` watch) — verified manually in Task 4 Step 6.
- **Types:** `compliance_score` decimal→string from MySQL is floated server-side AND guarded client-side with `toDoubleOrNull`; `trainingDayId` is `int?` everywhere; conversation IDs untouched.
- **No-goal branch** returns `recent_runs` for shape stability, but the UI only renders the section inside `_DashboardContent` (active goal present) — guaranteeing `goal.id` for the link sheet, matching the spec.
