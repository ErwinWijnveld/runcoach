# Run Analysis Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade the post-run AI feedback to a richer analysis (splits, form vs last 5 runs, workout match), fire it on both webhook + manual match, and show a polling card on the day detail screen while it generates.

**Architecture:** No schema changes. Reuse `training_results.ai_feedback` — `null` means pending. Expand the prompt context inside the existing `GenerateActivityFeedback` job. Add one missing dispatch in the manual-match controller. Flutter reuses one card shell for both "Notes" and "Coach analysis" and polls `/training-days/{id}/result` every 5 s via a small stream provider.

**Tech Stack:** Laravel 13 + Laravel AI SDK, Flutter + Riverpod code-gen.

**Spec:** `docs/superpowers/specs/2026-04-17-run-analysis-design.md`

---

## File Structure

**Backend (api/):**
- **Modify** `app/Ai/Agents/ActivityFeedbackAgent.php` — rewrite the prompt.
- **Modify** `app/Jobs/GenerateActivityFeedback.php` — richer context built via `collect()->filter()->implode()`.
- **Modify** `app/Http/Controllers/TrainingScheduleController.php` — 1 new line + 1 import to dispatch on manual match.
- **Create** `tests/Feature/Jobs/GenerateActivityFeedbackTest.php` — 2 tests.
- **Modify** `tests/Feature/Http/TrainingDayMatchTest.php` — 1 new test.

**Flutter (app/):**
- **Modify** `lib/features/schedule/providers/schedule_provider.dart` — add one small `Stream<String?>` provider that polls the result endpoint directly (no model parsing).
- **Modify** `lib/features/schedule/screens/training_day_detail_screen.dart` — one shared `_DetailCard`, one `_AnalysisBody` consumer widget, conditional Notes/Analysis section.

---

## Task 1: Rewrite ActivityFeedbackAgent instructions

**Files:**
- Modify: `api/app/Ai/Agents/ActivityFeedbackAgent.php`

- [ ] **Step 1: Replace the file contents**

```php
<?php

namespace App\Ai\Agents;

use Laravel\Ai\Contracts\Agent;
use Laravel\Ai\Promptable;

class ActivityFeedbackAgent implements Agent
{
    use Promptable;

    public function instructions(): string
    {
        return <<<'PROMPT'
You are a running coach reviewing a completed run. In 4-6 sentences, comment on:
- pace progression across the per-km splits (steady, negative-split, fading?),
- form vs the last 5 runs (HR/pace drift at similar efforts — improving fitness or accumulating fatigue),
- how well the run matched the planned workout.
Reference actual numbers. Be specific and constructive, not generic.
PROMPT;
    }
}
```

- [ ] **Step 2: Pint**

Run: `cd api && vendor/bin/pint --dirty --format agent`
Expected: clean.

(No commit yet — Task 2 bundles these changes.)

---

## Task 2: Expand GenerateActivityFeedback with splits + recent runs

**Files:**
- Modify: `api/app/Jobs/GenerateActivityFeedback.php`
- Create: `api/tests/Feature/Jobs/GenerateActivityFeedbackTest.php`

- [ ] **Step 1: Write the failing tests**

Create `api/tests/Feature/Jobs/GenerateActivityFeedbackTest.php`:

```php
<?php

namespace Tests\Feature\Jobs;

use App\Ai\Agents\ActivityFeedbackAgent;
use App\Jobs\GenerateActivityFeedback;
use App\Models\Goal;
use App\Models\StravaActivity;
use App\Models\TrainingDay;
use App\Models\TrainingResult;
use App\Models\TrainingWeek;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class GenerateActivityFeedbackTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_builds_rich_prompt_and_stores_feedback(): void
    {
        ActivityFeedbackAgent::fake(['Generated feedback prose.']);

        $user = User::factory()->create();
        $goal = Goal::factory()->create(['user_id' => $user->id]);
        $week = TrainingWeek::factory()->create(['goal_id' => $goal->id]);
        $day = TrainingDay::factory()->create([
            'training_week_id' => $week->id,
            'title' => 'Easy 5k',
            'type' => 'easy',
            'target_km' => 5.0,
            'target_pace_seconds_per_km' => 360,
            'target_heart_rate_zone' => 2,
        ]);

        // 3 prior runs — should show up in "Recent runs".
        StravaActivity::factory()->count(3)->create([
            'user_id' => $user->id,
            'start_date' => now()->subDays(7),
        ]);

        $activity = StravaActivity::factory()->create([
            'user_id' => $user->id,
            'name' => 'Current run',
            'raw_data' => [
                'splits_metric' => [
                    ['split' => 1, 'distance' => 1000.0, 'moving_time' => 370],
                    ['split' => 2, 'distance' => 1000.0, 'moving_time' => 365],
                ],
            ],
        ]);

        $result = TrainingResult::factory()->create([
            'training_day_id' => $day->id,
            'strava_activity_id' => $activity->id,
            'actual_km' => 5.05,
            'actual_pace_seconds_per_km' => 362,
            'ai_feedback' => null,
        ]);

        (new GenerateActivityFeedback($result->id))->handle();

        $this->assertSame('Generated feedback prose.', $result->fresh()->ai_feedback);

        ActivityFeedbackAgent::assertPrompted(function ($prompt) {
            $text = (string) $prompt;

            return str_contains($text, 'Easy 5k')
                && str_contains($text, '5.05')
                && str_contains($text, 'Splits')
                && str_contains($text, '6:10')          // 370s
                && str_contains($text, 'Recent runs')
                && ! str_contains($text, 'Current run'); // current activity excluded
        });
    }

    public function test_skips_splits_when_missing_and_early_returns_when_done(): void
    {
        ActivityFeedbackAgent::fake(['x']);

        $user = User::factory()->create();
        $goal = Goal::factory()->create(['user_id' => $user->id]);
        $week = TrainingWeek::factory()->create(['goal_id' => $goal->id]);
        $day = TrainingDay::factory()->create(['training_week_id' => $week->id]);
        $activity = StravaActivity::factory()->create(['user_id' => $user->id, 'raw_data' => []]);
        $result = TrainingResult::factory()->create([
            'training_day_id' => $day->id,
            'strava_activity_id' => $activity->id,
            'ai_feedback' => null,
        ]);

        (new GenerateActivityFeedback($result->id))->handle();

        ActivityFeedbackAgent::assertPrompted(fn ($p) => ! str_contains((string) $p, 'Splits'));

        // Second run with feedback already present — no second prompt.
        ActivityFeedbackAgent::fake()->preventStrayPrompts();
        (new GenerateActivityFeedback($result->id))->handle();
        ActivityFeedbackAgent::assertNeverPrompted();
    }
}
```

- [ ] **Step 2: Run the tests — expect failure**

Run: `cd api && php artisan test --compact --filter=GenerateActivityFeedbackTest`
Expected: `test_builds_rich_prompt_and_stores_feedback` fails — current prompt has no `Splits` / `Recent runs` labels.

- [ ] **Step 3: Replace the job**

Write the whole file to:

```php
<?php

namespace App\Jobs;

use App\Ai\Agents\ActivityFeedbackAgent;
use App\Models\StravaActivity;
use App\Models\TrainingResult;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Collection;

class GenerateActivityFeedback implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(public int $trainingResultId) {}

    public function handle(): void
    {
        $result = TrainingResult::with('trainingDay', 'stravaActivity')->find($this->trainingResultId);

        if (! $result || $result->ai_feedback) {
            return;
        }

        $response = ActivityFeedbackAgent::make()->prompt($this->buildPrompt($result));

        $result->update(['ai_feedback' => $response->text]);
    }

    private function buildPrompt(TrainingResult $result): string
    {
        $day = $result->trainingDay;
        $activity = $result->stravaActivity;

        $target = collect([
            $day->target_km !== null ? "{$day->target_km}km" : null,
            $day->target_pace_seconds_per_km !== null ? $this->pace($day->target_pace_seconds_per_km).'/km' : null,
            $day->target_heart_rate_zone !== null ? "HR zone {$day->target_heart_rate_zone}" : null,
        ])->filter()->implode(', ');

        $actualHr = $result->actual_avg_heart_rate !== null ? ", avg HR {$result->actual_avg_heart_rate}" : '';
        $hrScore = $result->heart_rate_score !== null ? ", HR {$result->heart_rate_score}/10" : '';
        $splits = $this->splitPaces($activity?->raw_data['splits_metric'] ?? []);

        return collect([
            "Training: {$day->title} ({$day->type->value}).",
            $target !== '' ? "Target: {$target}." : null,
            "Actual: {$result->actual_km}km at {$this->pace($result->actual_pace_seconds_per_km)}/km{$actualHr}.",
            "Scores: compliance {$result->compliance_score}/10, pace {$result->pace_score}/10, distance {$result->distance_score}/10{$hrScore}.",
            $splits !== '' ? "Splits (pace/km): {$splits}." : null,
            $this->recentRuns($result),
        ])->filter()->implode("\n");
    }

    /** @param array<int, array<string, mixed>> $splits */
    private function splitPaces(array $splits): string
    {
        return collect($splits)
            ->map(fn (array $s) => ($d = (float) ($s['distance'] ?? 0)) > 0 && ($t = (int) ($s['moving_time'] ?? 0)) > 0
                ? $this->pace((int) round($t / ($d / 1000)))
                : null)
            ->filter()
            ->implode(', ');
    }

    private function recentRuns(TrainingResult $result): ?string
    {
        $activity = $result->stravaActivity;
        if (! $activity) {
            return null;
        }

        $runs = StravaActivity::query()
            ->where('user_id', $activity->user_id)
            ->where('id', '!=', $activity->id)
            ->orderByDesc('start_date')
            ->limit(5)
            ->get();

        if ($runs->isEmpty()) {
            return null;
        }

        $summary = $runs->map(function (StravaActivity $r) {
            $km = round($r->distance_meters / 1000, 1);
            $line = "{$km}km @ {$this->pace($r->paceSecondsPerKm())}/km";
            if ($r->average_heartrate !== null) {
                $line .= ", HR {$r->average_heartrate}";
            }

            return "{$line}, {$r->start_date->format('Y-m-d')}";
        })->implode('; ');

        return "Recent runs (most recent first): {$summary}.";
    }

    private function pace(int $seconds): string
    {
        return $seconds > 0 ? sprintf('%d:%02d', intdiv($seconds, 60), $seconds % 60) : '—';
    }
}
```

- [ ] **Step 4: Run the tests — expect pass**

Run: `cd api && php artisan test --compact --filter=GenerateActivityFeedbackTest`
Expected: both tests pass.

- [ ] **Step 5: Pint**

Run: `cd api && vendor/bin/pint --dirty --format agent`
Expected: clean.

- [ ] **Step 6: Commit**

```bash
git add api/app/Ai/Agents/ActivityFeedbackAgent.php \
        api/app/Jobs/GenerateActivityFeedback.php \
        api/tests/Feature/Jobs/GenerateActivityFeedbackTest.php \
        docs/superpowers/specs/2026-04-17-run-analysis-design.md \
        docs/superpowers/plans/2026-04-17-run-analysis.md
git commit -m "feat(api): richer post-run AI analysis with splits + recent runs"
```

---

## Task 3: Dispatch on manual match

**Files:**
- Modify: `api/app/Http/Controllers/TrainingScheduleController.php`
- Modify: `api/tests/Feature/Http/TrainingDayMatchTest.php`

- [ ] **Step 1: Add the failing test**

Append to the class in `api/tests/Feature/Http/TrainingDayMatchTest.php`:

```php
    public function test_match_dispatches_feedback_generation(): void
    {
        \Illuminate\Support\Facades\Queue::fake();

        [$user, $headers] = $this->authUser();
        StravaToken::factory()->create(['user_id' => $user->id]);
        $day = $this->scheduleDay($user);

        Http::fake([
            'strava.com/api/v3/activities/7777' => Http::response([
                'id' => 7777, 'type' => 'Run', 'name' => 'Run',
                'distance' => 5050, 'moving_time' => 1830, 'elapsed_time' => 1900,
                'average_speed' => 2.76, 'start_date' => now()->toIso8601String(),
                'map' => ['summary_polyline' => null],
            ], 200),
        ]);

        $this->postJson(
            "/api/v1/training-days/{$day->id}/match-activity",
            ['strava_activity_id' => 7777],
            $headers,
        )->assertOk();

        \Illuminate\Support\Facades\Queue::assertPushed(\App\Jobs\GenerateActivityFeedback::class);
    }
```

- [ ] **Step 2: Run — expect failure**

Run: `cd api && php artisan test --compact --filter=test_match_dispatches_feedback_generation`
Expected: FAIL.

- [ ] **Step 3: Dispatch the job**

In `api/app/Http/Controllers/TrainingScheduleController.php`:

a. Add `use App\Jobs\GenerateActivityFeedback;` near the other `use` imports.

b. In `matchActivityToDay()`, right after `$result = $compliance->scoreDay($day, $activity);` add:

```php
        GenerateActivityFeedback::dispatch($result->id);
```

- [ ] **Step 4: Run full suite**

Run: `cd api && php artisan test --compact`
Expected: all green.

- [ ] **Step 5: Pint + commit**

```bash
cd api && vendor/bin/pint --dirty --format agent
cd ..
git add api/app/Http/Controllers/TrainingScheduleController.php \
        api/tests/Feature/Http/TrainingDayMatchTest.php
git commit -m "feat(api): dispatch feedback generation on manual Strava match"
```

---

## Task 4: Flutter polling provider

**Files:**
- Modify: `app/lib/features/schedule/providers/schedule_provider.dart`
- Regenerated: `app/lib/features/schedule/providers/schedule_provider.g.dart`

- [ ] **Step 1: Append the stream provider**

At the bottom of `app/lib/features/schedule/providers/schedule_provider.dart` (after the `ManualMatchStravaActivity` class), append:

```dart
/// Polls `/training-days/{id}/result` every 5s until `ai_feedback` is non-null,
/// then yields the text and closes. Yields `null` while pending so the UI can
/// keep the spinner on screen. Auto-disposes when the screen leaves.
@riverpod
Stream<String?> trainingDayAiFeedback(Ref ref, int dayId) async* {
  final api = ref.read(scheduleApiProvider);
  while (true) {
    final data = await api.getTrainingResult(dayId);
    final feedback = (data['data'] as Map?)?['ai_feedback'] as String?;
    yield feedback;
    if (feedback != null) {
      ref.invalidate(trainingDayDetailProvider(dayId));
      ref.invalidate(trainingDayResultProvider(dayId));
      return;
    }
    await Future.delayed(const Duration(seconds: 5));
  }
}
```

- [ ] **Step 2: Regenerate**

Run: `cd app && dart run build_runner build --delete-conflicting-outputs`
Expected: succeeds; `trainingDayAiFeedbackProvider` appears in `schedule_provider.g.dart`.

- [ ] **Step 3: Analyze**

Run: `cd app && flutter analyze lib/features/schedule/providers/schedule_provider.dart`
Expected: `No issues found!`

(No commit yet — bundled with Task 5.)

---

## Task 5: Flutter UI — one shell, one body, two states

**Files:**
- Modify: `app/lib/features/schedule/screens/training_day_detail_screen.dart`

- [ ] **Step 1: Add the SwooshingStar import**

At the top of the file, alongside the other imports:

```dart
import 'package:app/features/coach/widgets/swooshing_star.dart';
```

- [ ] **Step 2: Replace the current Notes block**

Find the block at lines 108–134 (the `if (day.description != null && day.description!.trim().isNotEmpty) ...[...]` section) and replace it with:

```dart
                ..._buildDetailSection(day, status),
```

- [ ] **Step 3: Add the builder + widgets**

Inside the `_Loaded` class, after `_formatHrZone` and before `_showWatchPlaceholder`, add:

```dart
  List<Widget> _buildDetailSection(TrainingDay day, TrainingDayStatus status) {
    final completed = status == TrainingDayStatus.completed;
    final description = day.description?.trim();

    if (!completed && (description == null || description.isEmpty)) {
      return const [];
    }

    final Widget body = completed
        ? _AnalysisBody(dayId: day.id, initial: day.result?.aiFeedback)
        : Text(description!, style: _detailTextStyle);

    return [
      const SizedBox(height: 16),
      _SectionTitle(completed ? 'Coach analysis' : 'Notes'),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: _DetailCard(child: body),
      ),
    ];
  }

  static TextStyle get _detailTextStyle => GoogleFonts.publicSans(
        fontSize: 14,
        height: 1.5,
        color: AppColors.primaryInk,
      );
```

Note: `_SectionTitle` currently takes a positional `label`, but the existing `const _SectionTitle('Notes')` call already shows positional works. If `_SectionTitle`'s constructor requires `const` with a string literal only, remove the `const` modifier on the call above (it's called with a dynamic string). Check the widget in the same file — if it's `const _SectionTitle(this.label)` without `const` enforced on callsite, `_SectionTitle(completed ? 'Coach analysis' : 'Notes')` is fine.

- [ ] **Step 4: Append the two helper widgets at the bottom of the file**

After the `_BackButton` class at the end of the file, append:

```dart
class _DetailCard extends StatelessWidget {
  final Widget child;
  const _DetailCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 16),
        ],
      ),
      child: child,
    );
  }
}

class _AnalysisBody extends ConsumerWidget {
  final int dayId;
  final String? initial;
  const _AnalysisBody({required this.dayId, required this.initial});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = (initial != null && initial!.trim().isNotEmpty)
        ? initial
        : ref.watch(trainingDayAiFeedbackProvider(dayId)).value;

    if (text != null && text.trim().isNotEmpty) {
      return Text(text, style: _Loaded._detailTextStyle);
    }

    return Row(
      children: [
        const SwooshingStar(size: 18),
        const SizedBox(width: 12),
        Text('Analysing your run…', style: _Loaded._detailTextStyle),
      ],
    );
  }
}
```

- [ ] **Step 5: Analyze**

Run: `cd app && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 6: Tests**

Run: `cd app && flutter test`
Expected: all existing tests pass.

- [ ] **Step 7: Manual QA (3 states)**

1. **Upcoming day** — open a day in the future; "Notes" card still shows `day.description`.
2. **Completed, feedback already stored** — open an older completed day; "Coach analysis" card renders the prose, no spinner.
3. **Completed, feedback pending** — set one row's `ai_feedback` to `NULL` (or freshly match a run) and open the detail screen; confirm spinner + "Analysing your run…" appears, then swaps to prose without a manual refresh once the job completes.

- [ ] **Step 8: Commit**

```bash
git add app/lib/features/schedule/providers/schedule_provider.dart \
        app/lib/features/schedule/providers/schedule_provider.g.dart \
        app/lib/features/schedule/screens/training_day_detail_screen.dart
git commit -m "feat(app): polling coach-analysis card on training day detail"
```

---

## Self-review

**Spec coverage:**
- Richer context (splits + recent runs + workout match) → Task 2.
- Agent prompt rewrite → Task 1.
- Manual-match dispatch → Task 3.
- Flutter three-state card (Notes / spinner / prose) → Task 5.
- 5 s polling stream → Task 4.

**Placeholder scan:** none — all code blocks complete.

**Type consistency:**
- `GenerateActivityFeedback::__construct(public int $trainingResultId)` unchanged.
- `StravaActivity.raw_data` cast to `array` — `?? []` guard covers missing `splits_metric`.
- `StravaActivity::paceSecondsPerKm()` already exists on the model — reused in `recentRuns`.
- `trainingDayAiFeedbackProvider` generated name matches `@riverpod` function `trainingDayAiFeedback(Ref, int)`.
- `AsyncValue.value` (used across the codebase, e.g. `authState.value`, `state.value`) returns `T?` — matches how we read stream data here.

**Scope:** 5 small tasks, 3 commits, one afternoon.
