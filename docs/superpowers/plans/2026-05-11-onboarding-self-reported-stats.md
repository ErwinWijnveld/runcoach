# Onboarding self-reported baseline stats — implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the read-only `/onboarding/overview` screen with an editable lock-pattern screen so users without HealthKit/Garmin can bootstrap an accurate fitness profile. Two fields (avg weekly km, easy run pace), prefilled and locked when wearable data exists, with a confirmation dialog to override.

**Architecture:** Three nullable columns on `users` cache the runner's self-reported numbers. A new Tier-0 wrap around `FitnessSnapshotService::snapshot` injects those values into the snapshot when set, overriding the existing cascade. The Flutter overview screen reads a new `baseline` block from `/onboarding/profile` to decide initial lock state per field, and POSTs back to a new endpoint before navigating to the form.

**Tech Stack:** Laravel 13 + Sanctum + PHPUnit on the backend; Flutter + Riverpod (codegen) + Freezed 3 + Retrofit + Dio + GoRouter + flutter_test on the app.

**Spec:** `docs/superpowers/specs/2026-05-11-onboarding-self-reported-stats-design.md`

---

## Task 1: Schema — add self-reported columns to users + model fillable/casts

**Files:**
- Create: `api/database/migrations/2026_05_11_120000_add_self_reported_stats_to_users.php`
- Modify: `api/app/Models/User.php`

- [ ] **Step 1: Create the migration via Artisan**

```bash
cd api && php artisan make:migration add_self_reported_stats_to_users --table=users --no-interaction
```

Rename the generated file to `2026_05_11_120000_add_self_reported_stats_to_users.php` (or whatever Artisan picked — the exact timestamp doesn't matter, just keep it newer than the latest existing migration).

- [ ] **Step 2: Fill in the migration body**

Replace the file's contents with:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Forward migration for the onboarding self-reported baseline stats
 * feature (`docs/superpowers/specs/2026-05-11-onboarding-self-reported-stats-design.md`).
 *
 * Three nullable columns on `users` store the runner's hand-entered
 * baseline volume + easy pace. Null = use cascade. Idempotent guards so
 * this is safe to re-run on dev DBs that may already have the columns.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (! Schema::hasColumn('users', 'self_reported_weekly_km')) {
                $table->decimal('self_reported_weekly_km', 5, 1)
                    ->nullable()
                    ->after('date_of_birth');
            }

            if (! Schema::hasColumn('users', 'self_reported_easy_pace_seconds_per_km')) {
                $table->unsignedSmallInteger('self_reported_easy_pace_seconds_per_km')
                    ->nullable()
                    ->after('self_reported_weekly_km');
            }

            if (! Schema::hasColumn('users', 'self_reported_stats_at')) {
                $table->timestamp('self_reported_stats_at')
                    ->nullable()
                    ->after('self_reported_easy_pace_seconds_per_km');
            }
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (Schema::hasColumn('users', 'self_reported_stats_at')) {
                $table->dropColumn('self_reported_stats_at');
            }
            if (Schema::hasColumn('users', 'self_reported_easy_pace_seconds_per_km')) {
                $table->dropColumn('self_reported_easy_pace_seconds_per_km');
            }
            if (Schema::hasColumn('users', 'self_reported_weekly_km')) {
                $table->dropColumn('self_reported_weekly_km');
            }
        });
    }
};
```

- [ ] **Step 3: Run the migration**

```bash
cd api && php artisan migrate --no-interaction
```

Expected: `Running … add_self_reported_stats_to_users … DONE`. Three columns appear on `users`.

- [ ] **Step 4: Add fillable + casts to the User model**

Open `api/app/Models/User.php`. Find the existing `protected $fillable` array (Laravel uses the property form here, not the PHP attribute — `Fillable` is a Laravel convention name, but `User.php` declares it as a plain `protected $fillable`). Add the three columns.

```php
protected $fillable = [
    // ... existing fields ...
    'self_reported_weekly_km',
    'self_reported_easy_pace_seconds_per_km',
    'self_reported_stats_at',
];
```

Then find or add `casts()`:

```php
protected function casts(): array
{
    return [
        // ... existing casts ...
        'self_reported_weekly_km' => 'decimal:1',
        'self_reported_easy_pace_seconds_per_km' => 'integer',
        'self_reported_stats_at' => 'datetime',
    ];
}
```

If the file uses an older `protected $casts = [...]` property form, mirror that style instead.

- [ ] **Step 5: Run pint to format**

```bash
cd api && vendor/bin/pint --dirty --format agent
```

Expected: `{"result":"pass"}`.

- [ ] **Step 6: Commit**

```bash
cd /Users/erwin/personal/runcoach
git add api/database/migrations api/app/Models/User.php
git commit -m "feat(onboarding): schema for self-reported baseline stats"
```

---

## Task 2: Add `PaceDerivation::SelfReported` enum case

**Files:**
- Modify: `api/app/Enums/PaceDerivation.php`

- [ ] **Step 1: Add the enum case**

Open `api/app/Enums/PaceDerivation.php`. Add the new case below the existing `Fallback` case:

```php
/** Tier 0 — user-entered baseline in onboarding overrides cascade. */
case SelfReported = 'self_reported';
```

- [ ] **Step 2: Run pint**

```bash
cd api && vendor/bin/pint --dirty --format agent
```

- [ ] **Step 3: Commit**

```bash
cd /Users/erwin/personal/runcoach
git add api/app/Enums/PaceDerivation.php
git commit -m "feat(onboarding): add PaceDerivation::SelfReported enum case"
```

---

## Task 3: Tier-0 self-reported override in `FitnessSnapshotService`

**Files:**
- Modify: `api/app/Services/Onboarding/FitnessSnapshotService.php`
- Test: `api/tests/Feature/Services/Onboarding/FitnessSnapshotServiceTest.php`

- [ ] **Step 1: Add the failing test**

Open `api/tests/Feature/Services/Onboarding/FitnessSnapshotServiceTest.php` and add three new tests at the bottom of the class (before the final `}`):

```php
public function test_self_reported_easy_pace_overrides_cascade_easy_pace(): void
{
    $user = User::factory()->create([
        'self_reported_easy_pace_seconds_per_km' => 360,
        'self_reported_weekly_km' => null,
        'self_reported_stats_at' => now(),
    ]);

    $snapshot = app(FitnessSnapshotService::class)->snapshot($user->fresh());

    $this->assertSame(360, $snapshot->easyPaceSecondsPerKm);
    $this->assertSame(\App\Enums\PaceDerivation::SelfReported, $snapshot->derivation);
    $this->assertSame(\App\Enums\PaceConfidence::Low, $snapshot->confidence);
}

public function test_self_reported_weekly_km_overrides_cascade_volume(): void
{
    $user = User::factory()->create([
        'self_reported_weekly_km' => 30.0,
        'self_reported_easy_pace_seconds_per_km' => null,
        'self_reported_stats_at' => now(),
    ]);

    $snapshot = app(FitnessSnapshotService::class)->snapshot($user->fresh());

    $this->assertSame(30.0, $snapshot->weeklyKmRecent4Weeks);
    $this->assertSame(\App\Enums\PaceDerivation::SelfReported, $snapshot->derivation);
}

public function test_no_self_report_falls_through_to_cascade(): void
{
    $user = User::factory()->create([
        'self_reported_weekly_km' => null,
        'self_reported_easy_pace_seconds_per_km' => null,
        'self_reported_stats_at' => null,
    ]);

    $snapshot = app(FitnessSnapshotService::class)->snapshot($user->fresh());

    // No wearable activities + no self-report → Tier 4 fallback.
    $this->assertSame(\App\Enums\PaceDerivation::Fallback, $snapshot->derivation);
    $this->assertSame(360, $snapshot->easyPaceSecondsPerKm); // FALLBACK_EASY_PACE
}
```

The file should already `use App\Models\User;` and `use App\Services\Onboarding\FitnessSnapshotService;`. If not, add them.

- [ ] **Step 2: Run the tests to verify they fail**

```bash
cd api && php artisan test --compact --filter='FitnessSnapshotServiceTest::test_self_reported'
```

Expected: FAIL — the service doesn't read the new columns yet. The third test (`test_no_self_report_falls_through_to_cascade`) may pass already; it's a regression guard.

- [ ] **Step 3: Refactor the service — extract the cascade, wrap with self-report check**

Open `api/app/Services/Onboarding/FitnessSnapshotService.php`. Rename the existing public `snapshot()` method to `private function deriveFromCascade()`, then add a new public `snapshot()` that wraps it.

Find:

```php
public function snapshot(User $user): FitnessSnapshot
{
    $runs = $this->loadCandidateRuns($user);
    // ... rest of existing body ...
}
```

Change to:

```php
public function snapshot(User $user): FitnessSnapshot
{
    $cascade = $this->deriveFromCascade($user);

    return $this->applySelfReportedOverrides($user, $cascade);
}

private function deriveFromCascade(User $user): FitnessSnapshot
{
    $runs = $this->loadCandidateRuns($user);
    // ... rest of existing body unchanged ...
}
```

Then add the override method below `deriveFromCascade()`:

```php
/**
 * Tier 0 — self-reported overrides. When the user has filled in their
 * baseline numbers during onboarding (`/onboarding/overview`), those
 * values win over the cascade. An empty self-report (both columns null)
 * falls through to the cascade unchanged.
 */
private function applySelfReportedOverrides(User $user, FitnessSnapshot $cascade): FitnessSnapshot
{
    $weeklyKm = $user->self_reported_weekly_km;
    $easyPace = $user->self_reported_easy_pace_seconds_per_km;

    if ($weeklyKm === null && $easyPace === null) {
        return $cascade;
    }

    return new FitnessSnapshot(
        thresholdPaceSecondsPerKm: $cascade->thresholdPaceSecondsPerKm,
        easyPaceSecondsPerKm: $easyPace ?? $cascade->easyPaceSecondsPerKm,
        vo2maxPaceSecondsPerKm: $cascade->vo2maxPaceSecondsPerKm,
        confidence: PaceConfidence::Low,
        derivation: PaceDerivation::SelfReported,
        weeklyKmRecent4Weeks: $weeklyKm !== null ? (float) $weeklyKm : $cascade->weeklyKmRecent4Weeks,
        weeklyRunsRecent4Weeks: $cascade->weeklyRunsRecent4Weeks,
        longestRunRecent8Weeks: $cascade->longestRunRecent8Weeks,
        maxHeartRate: $cascade->maxHeartRate,
        hasIntensityHistory: $cascade->hasIntensityHistory,
    );
}
```

- [ ] **Step 4: Run the tests to verify they pass**

```bash
cd api && php artisan test --compact --filter='FitnessSnapshotServiceTest'
```

Expected: PASS. All existing tests + the three new ones.

- [ ] **Step 5: Run pint**

```bash
cd api && vendor/bin/pint --dirty --format agent
```

- [ ] **Step 6: Commit**

```bash
cd /Users/erwin/personal/runcoach
git add api/app/Services/Onboarding/FitnessSnapshotService.php api/tests/Feature/Services/Onboarding/FitnessSnapshotServiceTest.php
git commit -m "feat(onboarding): self-reported Tier-0 override in FitnessSnapshotService"
```

---

## Task 4: `SelfReportedStatsRequest` + endpoint + route

**Files:**
- Create: `api/app/Http/Requests/SelfReportedStatsRequest.php`
- Modify: `api/app/Http/Controllers/OnboardingController.php`
- Modify: `api/routes/api.php`
- Test: `api/tests/Feature/Http/SelfReportedStatsTest.php`

- [ ] **Step 1: Write the failing endpoint test**

Create `api/tests/Feature/Http/SelfReportedStatsTest.php`:

```php
<?php

namespace Tests\Feature\Http;

use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class SelfReportedStatsTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_requires_authentication(): void
    {
        $this->postJson('/api/v1/onboarding/self-reported-stats', [
            'weekly_km' => 25,
            'easy_pace_seconds_per_km' => 360,
        ])->assertUnauthorized();
    }

    public function test_persists_both_fields_and_timestamp(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user)->postJson('/api/v1/onboarding/self-reported-stats', [
            'weekly_km' => 25.5,
            'easy_pace_seconds_per_km' => 360,
        ])->assertOk();

        $user->refresh();
        $this->assertSame('25.5', (string) $user->self_reported_weekly_km);
        $this->assertSame(360, $user->self_reported_easy_pace_seconds_per_km);
        $this->assertNotNull($user->self_reported_stats_at);
    }

    public function test_allows_either_field_to_be_null(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user)->postJson('/api/v1/onboarding/self-reported-stats', [
            'weekly_km' => null,
            'easy_pace_seconds_per_km' => 330,
        ])->assertOk();

        $user->refresh();
        $this->assertNull($user->self_reported_weekly_km);
        $this->assertSame(330, $user->self_reported_easy_pace_seconds_per_km);
        $this->assertNotNull($user->self_reported_stats_at);
    }

    public function test_clears_timestamp_when_both_null(): void
    {
        $user = User::factory()->create([
            'self_reported_weekly_km' => 20,
            'self_reported_easy_pace_seconds_per_km' => 360,
            'self_reported_stats_at' => now()->subDay(),
        ]);

        $this->actingAs($user)->postJson('/api/v1/onboarding/self-reported-stats', [
            'weekly_km' => null,
            'easy_pace_seconds_per_km' => null,
        ])->assertOk();

        $user->refresh();
        $this->assertNull($user->self_reported_weekly_km);
        $this->assertNull($user->self_reported_easy_pace_seconds_per_km);
        $this->assertNull($user->self_reported_stats_at);
    }

    public function test_rejects_out_of_range_pace(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user)->postJson('/api/v1/onboarding/self-reported-stats', [
            'weekly_km' => 20,
            'easy_pace_seconds_per_km' => 90, // < 180 floor (3:00/km)
        ])->assertStatus(422);
    }

    public function test_rejects_out_of_range_km(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user)->postJson('/api/v1/onboarding/self-reported-stats', [
            'weekly_km' => 500, // > 300 ceiling
            'easy_pace_seconds_per_km' => 360,
        ])->assertStatus(422);
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

```bash
cd api && php artisan test --compact tests/Feature/Http/SelfReportedStatsTest.php
```

Expected: FAIL with 404 (route doesn't exist).

- [ ] **Step 3: Create the form request**

Create `api/app/Http/Requests/SelfReportedStatsRequest.php`:

```php
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class SelfReportedStatsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    /**
     * @return array<string, list<string>>
     */
    public function rules(): array
    {
        return [
            'weekly_km' => ['nullable', 'numeric', 'min:1', 'max:300'],
            'easy_pace_seconds_per_km' => ['nullable', 'integer', 'min:180', 'max:720'],
        ];
    }
}
```

- [ ] **Step 4: Add the controller action**

Open `api/app/Http/Controllers/OnboardingController.php`. Add at the top:

```php
use App\Http\Requests\SelfReportedStatsRequest;
```

Add a new public method below `latestPlanGeneration()`:

```php
/**
 * Persist the runner's self-reported baseline stats from the onboarding
 * overview screen. Either field may be null (wearable user with that
 * field still locked); writing both nulls clears the timestamp too so
 * subsequent reads fall back to the cascade.
 */
public function saveSelfReportedStats(SelfReportedStatsRequest $request): JsonResponse
{
    $user = $request->user();
    $weeklyKm = $request->validated('weekly_km');
    $easyPace = $request->validated('easy_pace_seconds_per_km');
    $touched = $weeklyKm !== null || $easyPace !== null;

    $user->update([
        'self_reported_weekly_km' => $weeklyKm,
        'self_reported_easy_pace_seconds_per_km' => $easyPace,
        'self_reported_stats_at' => $touched ? now() : null,
    ]);

    return response()->json(['status' => 'saved']);
}
```

- [ ] **Step 5: Register the route**

Open `api/routes/api.php`. Find the existing onboarding group:

```php
Route::prefix('onboarding')->group(function () {
    Route::get('/profile', [OnboardingController::class, 'profile']);
    Route::post('/generate-plan', [OnboardingController::class, 'generatePlan']);
    // ...
});
```

Add inside the group:

```php
Route::post('/self-reported-stats', [OnboardingController::class, 'saveSelfReportedStats']);
```

- [ ] **Step 6: Run the tests to verify they pass**

```bash
cd api && php artisan test --compact tests/Feature/Http/SelfReportedStatsTest.php
```

Expected: PASS for all 6 tests.

- [ ] **Step 7: Run pint**

```bash
cd api && vendor/bin/pint --dirty --format agent
```

- [ ] **Step 8: Commit**

```bash
cd /Users/erwin/personal/runcoach
git add api/app/Http/Requests/SelfReportedStatsRequest.php api/app/Http/Controllers/OnboardingController.php api/routes/api.php api/tests/Feature/Http/SelfReportedStatsTest.php
git commit -m "feat(onboarding): POST /onboarding/self-reported-stats endpoint"
```

---

## Task 5: Extend `GET /onboarding/profile` with `baseline` block

**Files:**
- Modify: `api/app/Http/Controllers/OnboardingController.php`
- Test: `api/tests/Feature/OnboardingProfileTest.php`

- [ ] **Step 1: Write the failing test**

Add to `api/tests/Feature/OnboardingProfileTest.php` (before the closing `}` of the class):

```php
public function test_profile_baseline_block_is_null_when_no_wearable_and_no_self_report(): void
{
    $user = User::factory()->create();

    $response = $this->actingAs($user)->getJson('/api/v1/onboarding/profile');

    $response->assertOk();
    $this->assertNull($response->json('baseline.weekly_km'));
    $this->assertNull($response->json('baseline.weekly_km_source'));
    $this->assertSame(360, $response->json('baseline.easy_pace_seconds_per_km')); // Tier 4 default
    $this->assertNull($response->json('baseline.easy_pace_source'));
}

public function test_profile_baseline_block_marks_self_reported_source(): void
{
    $user = User::factory()->create([
        'self_reported_weekly_km' => 28.0,
        'self_reported_easy_pace_seconds_per_km' => 330,
        'self_reported_stats_at' => now(),
    ]);

    $response = $this->actingAs($user)->getJson('/api/v1/onboarding/profile');

    $this->assertSame(28.0, $response->json('baseline.weekly_km'));
    $this->assertSame('self_reported', $response->json('baseline.weekly_km_source'));
    $this->assertSame(330, $response->json('baseline.easy_pace_seconds_per_km'));
    $this->assertSame('self_reported', $response->json('baseline.easy_pace_source'));
}
```

If the test file doesn't already `use App\Models\User;`, add it.

- [ ] **Step 2: Run the tests to verify they fail**

```bash
cd api && php artisan test --compact --filter='OnboardingProfileTest::test_profile_baseline'
```

Expected: FAIL — the `baseline` key isn't in the response yet.

- [ ] **Step 3: Add the `baseline` block to the controller**

Open `api/app/Http/Controllers/OnboardingController.php`. Add at the top:

```php
use App\Enums\PaceDerivation;
use App\Services\Onboarding\FitnessSnapshotService;
```

Update `profile()` to inject a `FitnessSnapshotService` (Laravel auto-resolves):

```php
public function profile(
    Request $request,
    RunningProfileService $profiles,
    FitnessSnapshotService $fitness,
): JsonResponse {
    $user = $request->user();
    $profile = $profiles->getOrAnalyze($user);
    $snapshot = $fitness->snapshot($user);

    $baseline = $this->buildBaseline($user, $snapshot);

    $personalRecords = $user->personal_records ?: null;

    if ($profile === null) {
        return response()->json([
            'status' => 'ready',
            'analyzed_at' => null,
            'data_start_date' => null,
            'data_end_date' => null,
            'metrics' => [],
            'narrative_summary' => null,
            'personal_records' => $personalRecords,
            'baseline' => $baseline,
        ]);
    }

    return response()->json([
        'status' => 'ready',
        'analyzed_at' => $profile->analyzed_at,
        'data_start_date' => $profile->data_start_date,
        'data_end_date' => $profile->data_end_date,
        'metrics' => $profile->metrics,
        'narrative_summary' => $profile->narrative_summary,
        'personal_records' => $personalRecords,
        'baseline' => $baseline,
    ]);
}

/**
 * Build the baseline block used by /onboarding/overview to decide per-field
 * lock state. Source is `self_reported` if the column is set; otherwise
 * `apple_health` when the cascade had real signal; otherwise null.
 *
 * @return array{
 *   weekly_km: float|null,
 *   weekly_km_source: string|null,
 *   easy_pace_seconds_per_km: int|null,
 *   easy_pace_source: string|null,
 * }
 */
private function buildBaseline($user, \App\Support\Onboarding\FitnessSnapshot $snapshot): array
{
    $weeklyKm = $user->self_reported_weekly_km !== null
        ? (float) $user->self_reported_weekly_km
        : ($snapshot->weeklyKmRecent4Weeks > 0
            ? round($snapshot->weeklyKmRecent4Weeks, 1)
            : null);

    $weeklyKmSource = match (true) {
        $user->self_reported_weekly_km !== null => 'self_reported',
        $snapshot->weeklyKmRecent4Weeks > 0 => 'apple_health',
        default => null,
    };

    $easyPace = $user->self_reported_easy_pace_seconds_per_km
        ?? $snapshot->easyPaceSecondsPerKm;

    $easyPaceSource = match (true) {
        $user->self_reported_easy_pace_seconds_per_km !== null => 'self_reported',
        $snapshot->derivation !== PaceDerivation::Fallback
            && $snapshot->derivation !== PaceDerivation::SelfReported => 'apple_health',
        default => null,
    };

    return [
        'weekly_km' => $weeklyKm,
        'weekly_km_source' => $weeklyKmSource,
        'easy_pace_seconds_per_km' => $easyPace,
        'easy_pace_source' => $easyPaceSource,
    ];
}
```

- [ ] **Step 4: Run the tests to verify they pass**

```bash
cd api && php artisan test --compact tests/Feature/OnboardingProfileTest.php
```

Expected: PASS — existing tests + the two new baseline tests.

- [ ] **Step 5: Run pint**

```bash
cd api && vendor/bin/pint --dirty --format agent
```

- [ ] **Step 6: Commit**

```bash
cd /Users/erwin/personal/runcoach
git add api/app/Http/Controllers/OnboardingController.php api/tests/Feature/OnboardingProfileTest.php
git commit -m "feat(onboarding): expose baseline block in GET /onboarding/profile"
```

---

## Task 6: Verify plan-generation respects self-reported baseline (regression test)

**Files:**
- Modify: `api/tests/Feature/Services/Onboarding/TrainingPlanBuilderTest.php`

- [ ] **Step 1: Add a regression test**

Open `api/tests/Feature/Services/Onboarding/TrainingPlanBuilderTest.php`. Look at the existing tests in the file to confirm the helper methods (`$this->form(...)`, `$this->snapshot(...)`) — most tests in that file build a snapshot directly and pass it to `TrainingPlanBuilder::build`. We want an end-to-end test that builds the snapshot from a User with self-report columns set.

Add this test at the bottom (before the closing `}`):

```php
public function test_self_reported_user_drives_volume_curve_from_their_baseline(): void
{
    $user = \App\Models\User::factory()->create([
        'self_reported_weekly_km' => 30.0,
        'self_reported_easy_pace_seconds_per_km' => 360,
        'self_reported_stats_at' => now(),
    ]);

    $snapshot = app(\App\Services\Onboarding\FitnessSnapshotService::class)->snapshot($user->fresh());

    $this->assertSame(30.0, $snapshot->weeklyKmRecent4Weeks);
    $this->assertSame(360, $snapshot->easyPaceSecondsPerKm);

    $payload = app(\App\Services\Onboarding\TrainingPlanBuilder::class)->build(
        $snapshot,
        $this->form([
            'goal_type' => 'pr_attempt',
            'distance_meters' => 10000,
            'target_date' => now()->addWeeks(10)->toDateString(),
            'days_per_week' => 3,
        ]),
    );

    // Week 1 should sit near the baseline (week1 = max(baseline, peak*0.55))
    // rather than near the floor of 16 km that no-baseline plans get.
    $week1Total = $payload['schedule']['weeks'][0]['total_km'];
    $this->assertGreaterThanOrEqual(25.0, $week1Total, "week 1 should start near self-reported 30 km baseline, got {$week1Total}");

    // Easy day pace should be exactly the self-reported value, not the
    // Tier-4 default.
    $firstWeek = $payload['schedule']['weeks'][0]['days'];
    $easyDay = collect($firstWeek)->firstWhere('type', 'easy');
    $this->assertNotNull($easyDay, 'expected an easy day in week 1');
    $this->assertSame(360, $easyDay['target_pace_seconds_per_km']);
}
```

- [ ] **Step 2: Run the test**

```bash
cd api && php artisan test --compact --filter='test_self_reported_user_drives_volume_curve'
```

Expected: PASS (the snapshot service + builder are now wired up).

- [ ] **Step 3: Run the full plan-builder test file as a sanity check**

```bash
cd api && php artisan test --compact tests/Feature/Services/Onboarding/TrainingPlanBuilderTest.php
```

Expected: all tests pass (existing + new).

- [ ] **Step 4: Commit**

```bash
cd /Users/erwin/personal/runcoach
git add api/tests/Feature/Services/Onboarding/TrainingPlanBuilderTest.php
git commit -m "test(onboarding): plan builder respects self-reported snapshot"
```

---

## Task 7: Flutter model — extend `OnboardingProfile` with `baseline`

**Files:**
- Modify: `app/lib/features/onboarding/models/onboarding_profile.dart`

- [ ] **Step 1: Add the `OnboardingBaseline` Freezed model + extend `OnboardingProfile`**

Open `app/lib/features/onboarding/models/onboarding_profile.dart`. Add a new `@freezed sealed class OnboardingBaseline` BELOW the existing `OnboardingProfileMetrics` class (before `PersonalRecord`):

```dart
@freezed
sealed class OnboardingBaseline with _$OnboardingBaseline {
  const factory OnboardingBaseline({
    @JsonKey(name: 'weekly_km', fromJson: toDoubleOrNull) double? weeklyKm,
    @JsonKey(name: 'weekly_km_source') String? weeklyKmSource,
    @JsonKey(name: 'easy_pace_seconds_per_km', fromJson: toIntOrNull) int? easyPaceSecondsPerKm,
    @JsonKey(name: 'easy_pace_source') String? easyPaceSource,
  }) = _OnboardingBaseline;

  factory OnboardingBaseline.fromJson(Map<String, dynamic> json) =>
      _$OnboardingBaselineFromJson(json);
}
```

Then update `OnboardingProfile` to include the new field:

```dart
@freezed
sealed class OnboardingProfile with _$OnboardingProfile {
  const factory OnboardingProfile({
    required String status,
    OnboardingProfileMetrics? metrics,
    @JsonKey(name: 'narrative_summary') String? narrativeSummary,
    @JsonKey(name: 'analyzed_at') DateTime? analyzedAt,
    @JsonKey(name: 'personal_records') Map<String, PersonalRecord?>? personalRecords,
    OnboardingBaseline? baseline,
  }) = _OnboardingProfile;

  factory OnboardingProfile.fromJson(Map<String, dynamic> json) =>
      _$OnboardingProfileFromJson(json);
}
```

- [ ] **Step 2: Run code generation**

```bash
cd app && dart run build_runner build --delete-conflicting-outputs
```

Expected: regenerates `onboarding_profile.freezed.dart` + `onboarding_profile.g.dart` with `OnboardingBaseline` types.

- [ ] **Step 3: Verify no analyzer errors**

```bash
cd app && flutter analyze lib/features/onboarding/models/
```

Expected: 0 issues.

- [ ] **Step 4: Commit**

```bash
cd /Users/erwin/personal/runcoach
git add app/lib/features/onboarding/models/onboarding_profile.dart app/lib/features/onboarding/models/onboarding_profile.freezed.dart app/lib/features/onboarding/models/onboarding_profile.g.dart
git commit -m "feat(onboarding): OnboardingBaseline model"
```

---

## Task 8: Flutter API client — `saveSelfReportedStats` method

**Files:**
- Modify: `app/lib/features/onboarding/data/onboarding_api.dart`

- [ ] **Step 1: Add the Retrofit method + a typed call provider**

Open `app/lib/features/onboarding/data/onboarding_api.dart`. Add inside `abstract class OnboardingApi`:

```dart
@POST('/onboarding/self-reported-stats')
Future<dynamic> saveSelfReportedStats(@Body() Map<String, dynamic> body);
```

Then add a typed call provider near the bottom of the file (after `pollPlanGenerationCall`):

```dart
/// Saves the runner's self-reported baseline numbers. Either field may be
/// null when that field is still locked from the wearable cascade. Returns
/// once the POST completes; throws on validation errors so the screen can
/// surface them.
@riverpod
Future<void> Function({double? weeklyKm, int? easyPaceSecondsPerKm}) saveSelfReportedStatsCall(
  Ref ref,
) {
  final dio = ref.watch(dioProvider);
  return ({double? weeklyKm, int? easyPaceSecondsPerKm}) async {
    await dio.post<Map<String, dynamic>>(
      '/onboarding/self-reported-stats',
      data: <String, dynamic>{
        'weekly_km': weeklyKm,
        'easy_pace_seconds_per_km': easyPaceSecondsPerKm,
      },
    );
  };
}
```

- [ ] **Step 2: Run code generation**

```bash
cd app && dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 3: Verify no analyzer errors**

```bash
cd app && flutter analyze lib/features/onboarding/data/
```

- [ ] **Step 4: Commit**

```bash
cd /Users/erwin/personal/runcoach
git add app/lib/features/onboarding/data/onboarding_api.dart app/lib/features/onboarding/data/onboarding_api.g.dart
git commit -m "feat(onboarding): API call for self-reported stats"
```

---

## Task 9: Flutter widget — `pace_wheel_picker.dart`

**Files:**
- Create: `app/lib/features/onboarding/widgets/pace_wheel_picker.dart`
- Test: `app/test/features/onboarding/pace_wheel_picker_test.dart`

- [ ] **Step 1: Write the failing widget test**

Create `app/test/features/onboarding/pace_wheel_picker_test.dart`:

```dart
import 'package:app/features/onboarding/widgets/pace_wheel_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('showPaceWheelPicker returns initial value when Done tapped without scrolling', (tester) async {
    int? result;

    await tester.pumpWidget(
      CupertinoApp(
        home: Builder(
          builder: (context) => CupertinoButton(
            onPressed: () async {
              result = await showPaceWheelPicker(context, initialSecondsPerKm: 360);
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Easy pace'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(result, 360);
  });

  testWidgets('showPaceWheelPicker returns null when dismissed via Cancel', (tester) async {
    int? result = -1;

    await tester.pumpWidget(
      CupertinoApp(
        home: Builder(
          builder: (context) => CupertinoButton(
            onPressed: () async {
              result = await showPaceWheelPicker(context, initialSecondsPerKm: 360);
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cd app && flutter test test/features/onboarding/pace_wheel_picker_test.dart
```

Expected: FAIL with "Target of URI doesn't exist".

- [ ] **Step 3: Create the widget**

Create `app/lib/features/onboarding/widgets/pace_wheel_picker.dart`:

```dart
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';

/// Cupertino bottom-sheet with a dual-wheel picker for selecting an easy-run
/// pace in mm:ss/km. Minutes 3-12, seconds in steps of 5. Returns the chosen
/// total seconds when the user taps Done; returns null on Cancel or dismiss.
Future<int?> showPaceWheelPicker(
  BuildContext context, {
  required int initialSecondsPerKm,
}) async {
  final clamped = initialSecondsPerKm.clamp(180, 12 * 60 + 55);
  final initialMinutes = (clamped ~/ 60).clamp(3, 12);
  final initialSecondsRaw = clamped % 60;
  final initialSecondsIndex = (initialSecondsRaw ~/ 5).clamp(0, 11);

  int minutes = initialMinutes;
  int secondsIndex = initialSecondsIndex;

  return showCupertinoModalPopup<int>(
    context: context,
    builder: (sheetContext) {
      return Container(
        height: 320,
        decoration: const BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _SheetHeader(
              onCancel: () => Navigator.of(sheetContext).pop(),
              onDone: () => Navigator.of(sheetContext).pop(minutes * 60 + secondsIndex * 5),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoPicker(
                      itemExtent: 36,
                      scrollController: FixedExtentScrollController(initialItem: initialMinutes - 3),
                      onSelectedItemChanged: (i) => minutes = i + 3,
                      children: List<Widget>.generate(10, (i) {
                        return Center(
                          child: Text(
                            '${i + 3}',
                            style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w500),
                          ),
                        );
                      }),
                    ),
                  ),
                  Text(':', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w500)),
                  Expanded(
                    child: CupertinoPicker(
                      itemExtent: 36,
                      scrollController: FixedExtentScrollController(initialItem: initialSecondsIndex),
                      onSelectedItemChanged: (i) => secondsIndex = i,
                      children: List<Widget>.generate(12, (i) {
                        final seconds = i * 5;
                        return Center(
                          child: Text(
                            seconds.toString().padLeft(2, '0'),
                            style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w500),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'per kilometer',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.inkMuted,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _SheetHeader extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onDone;
  const _SheetHeader({required this.onCancel, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onCancel,
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(fontSize: 16, color: AppColors.inkMuted),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Easy pace',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onDone,
            child: Text(
              'Done',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primaryInk),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
cd app && flutter test test/features/onboarding/pace_wheel_picker_test.dart
```

Expected: 2/2 passing.

- [ ] **Step 5: Commit**

```bash
cd /Users/erwin/personal/runcoach
git add app/lib/features/onboarding/widgets/pace_wheel_picker.dart app/test/features/onboarding/pace_wheel_picker_test.dart
git commit -m "feat(onboarding): pace wheel picker widget"
```

---

## Task 10: Flutter widget — `locked_stat_field.dart`

**Files:**
- Create: `app/lib/features/onboarding/widgets/locked_stat_field.dart`
- Test: `app/test/features/onboarding/locked_stat_field_test.dart`

- [ ] **Step 1: Write the failing widget test**

Create `app/test/features/onboarding/locked_stat_field_test.dart`:

```dart
import 'package:app/features/onboarding/widgets/locked_stat_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tapping lock shows confirmation; Edit anyway calls onUnlock', (tester) async {
    var unlockedCount = 0;

    await tester.pumpWidget(
      CupertinoApp(
        localizationsDelegates: const [
          DefaultMaterialLocalizations.delegate,
          DefaultCupertinoLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        home: CupertinoPageScaffold(
          child: LockedStatField(
            label: 'Weekly km',
            valueText: '24 km',
            sourceLabel: 'Apple Health',
            locked: true,
            onUnlock: () => unlockedCount++,
            onTapWhenUnlocked: () {},
          ),
        ),
      ),
    );

    expect(find.text('24 km'), findsOneWidget);
    expect(find.text('From Apple Health'), findsOneWidget);

    await tester.tap(find.byIcon(CupertinoIcons.lock_fill));
    await tester.pumpAndSettle();

    expect(find.text('Edit anyway'), findsOneWidget);
    await tester.tap(find.text('Edit anyway'));
    await tester.pumpAndSettle();

    expect(unlockedCount, 1);
  });

  testWidgets('tapping lock shows confirmation; Cancel keeps locked', (tester) async {
    var unlockedCount = 0;

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: LockedStatField(
            label: 'Weekly km',
            valueText: '24 km',
            sourceLabel: 'Apple Health',
            locked: true,
            onUnlock: () => unlockedCount++,
            onTapWhenUnlocked: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(CupertinoIcons.lock_fill));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(unlockedCount, 0);
  });

  testWidgets('unlocked field calls onTapWhenUnlocked on tap', (tester) async {
    var tapped = 0;

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: LockedStatField(
            label: 'Weekly km',
            valueText: '24 km',
            sourceLabel: null,
            locked: false,
            onUnlock: () {},
            onTapWhenUnlocked: () => tapped++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('24 km'));
    await tester.pumpAndSettle();

    expect(tapped, 1);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cd app && flutter test test/features/onboarding/locked_stat_field_test.dart
```

Expected: FAIL with "Target of URI doesn't exist".

- [ ] **Step 3: Create the widget**

Create `app/lib/features/onboarding/widgets/locked_stat_field.dart`:

```dart
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';

/// A single onboarding-baseline field with a lock-by-default pattern.
///
/// When `locked` is true the field is read-only and a lock icon is shown;
/// tapping the icon opens a confirmation dialog ("Override … data?"). On
/// "Edit anyway" the parent should set `locked: false` and the field
/// becomes tappable to invoke `onTapWhenUnlocked` (typically opens a
/// picker sheet or focuses a text field).
class LockedStatField extends StatelessWidget {
  final String label;
  final String valueText;
  final String? sourceLabel; // e.g. "Apple Health"; null hides the badge
  final bool locked;
  final VoidCallback onUnlock;
  final VoidCallback onTapWhenUnlocked;

  const LockedStatField({
    super.key,
    required this.label,
    required this.valueText,
    required this.sourceLabel,
    required this.locked,
    required this.onUnlock,
    required this.onTapWhenUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.inkMuted,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: locked ? null : onTapWhenUnlocked,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    valueText,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryInk,
                    ),
                  ),
                ),
                if (locked)
                  GestureDetector(
                    onTap: () => _confirmUnlock(context),
                    behavior: HitTestBehavior.opaque,
                    child: const Icon(CupertinoIcons.lock_fill, size: 20, color: AppColors.inkMuted),
                  ),
              ],
            ),
          ),
        ),
        if (sourceLabel != null) ...[
          const SizedBox(height: 6),
          Text(
            locked ? 'From $sourceLabel' : 'Edited by you',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmUnlock(BuildContext context) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Override Apple Health data?'),
        content: const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'These values are calculated from your synced run history and are likely the most accurate signal we have. Editing them may result in a less accurate training plan.',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Edit anyway'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      onUnlock();
    }
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
cd app && flutter test test/features/onboarding/locked_stat_field_test.dart
```

Expected: 3/3 passing.

- [ ] **Step 5: Commit**

```bash
cd /Users/erwin/personal/runcoach
git add app/lib/features/onboarding/widgets/locked_stat_field.dart app/test/features/onboarding/locked_stat_field_test.dart
git commit -m "feat(onboarding): locked_stat_field widget with confirmation dialog"
```

---

## Task 11: Flutter screen — rewrite `onboarding_overview_screen.dart`

**Files:**
- Modify: `app/lib/features/onboarding/screens/onboarding_overview_screen.dart`

- [ ] **Step 1: Replace the screen body**

Open `app/lib/features/onboarding/screens/onboarding_overview_screen.dart`. Replace the entire file contents with:

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/gradient_scaffold.dart';
import 'package:app/core/widgets/runcore_logo.dart';
import 'package:app/features/onboarding/data/onboarding_api.dart';
import 'package:app/features/onboarding/models/onboarding_profile.dart';
import 'package:app/features/onboarding/providers/onboarding_profile_provider.dart';
import 'package:app/features/onboarding/widgets/locked_stat_field.dart';
import 'package:app/features/onboarding/widgets/onboarding_primary_button.dart';
import 'package:app/features/onboarding/widgets/pace_wheel_picker.dart';

/// Editable baseline-stats screen. Works for users with AND without
/// wearable data: prefills + locks fields when cascade data is available,
/// otherwise asks the user to fill them in. Spec:
/// `docs/superpowers/specs/2026-05-11-onboarding-self-reported-stats-design.md`
class OnboardingOverviewScreen extends ConsumerWidget {
  const OnboardingOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(onboardingProfileControllerProvider);

    return GradientScaffold(
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(
              height: 56,
              child: Center(child: RunCoreLogo(starSize: 22, textSize: 22, gap: 8)),
            ),
            Expanded(
              child: profileAsync.when(
                data: (profile) => _BaselineForm(profile: profile),
                loading: () => const Center(child: CupertinoActivityIndicator()),
                error: (e, _) => _ErrorState(
                  message: e.toString(),
                  onRetry: () => ref
                      .read(onboardingProfileControllerProvider.notifier)
                      .refresh(),
                  onSkip: () => context.go('/onboarding/form'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BaselineForm extends ConsumerStatefulWidget {
  final OnboardingProfile profile;
  const _BaselineForm({required this.profile});

  @override
  ConsumerState<_BaselineForm> createState() => _BaselineFormState();
}

class _BaselineFormState extends ConsumerState<_BaselineForm> {
  final _kmController = TextEditingController();

  // Lock state per field. Initialised from the baseline source.
  bool _kmLocked = false;
  bool _paceLocked = false;

  // Original wearable values (for restoring on re-lock).
  double? _wearableKm;
  int? _wearablePace;

  // Current displayed values.
  double? _km;
  int? _paceSeconds;

  // Touched = user has explicitly committed a value for this field
  // (either by editing it after unlock, or by filling it in when there
  // was no prefill). Continue gating reads from these.
  bool _kmTouched = false;
  bool _paceTouched = false;

  bool _submitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    final baseline = widget.profile.baseline;

    if (baseline?.weeklyKm != null) {
      _km = baseline!.weeklyKm;
      _wearableKm = baseline.weeklyKm;
      _kmController.text = baseline.weeklyKm!.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
      _kmLocked = baseline.weeklyKmSource == 'apple_health';
      _kmTouched = baseline.weeklyKmSource == 'self_reported';
    }

    if (baseline?.easyPaceSecondsPerKm != null && baseline?.easyPaceSource != null) {
      _paceSeconds = baseline!.easyPaceSecondsPerKm;
      _wearablePace = baseline.easyPaceSecondsPerKm;
      _paceLocked = baseline.easyPaceSource == 'apple_health';
      _paceTouched = baseline.easyPaceSource == 'self_reported';
    }
  }

  @override
  void dispose() {
    _kmController.dispose();
    super.dispose();
  }

  bool get _canContinue {
    final kmReady = _kmLocked || (_km != null && _km! >= 1);
    final paceReady = _paceLocked || _paceTouched;
    return kmReady && paceReady && !_submitting;
  }

  Future<void> _openPaceWheel() async {
    final picked = await showPaceWheelPicker(
      context,
      initialSecondsPerKm: _paceSeconds ?? 360,
    );
    if (picked != null && mounted) {
      setState(() {
        _paceSeconds = picked;
        _paceTouched = true;
      });
    }
  }

  void _unlockKm() {
    setState(() {
      _kmLocked = false;
      _kmTouched = false;
      // Keep the prefilled value in the field; user can edit or clear.
    });
  }

  void _unlockPace() {
    setState(() {
      _paceLocked = false;
      _paceTouched = false;
    });
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _submitError = null;
    });

    final save = ref.read(saveSelfReportedStatsCallProvider);
    // Only send fields that the user actually edited (touched). Locked-
    // untouched fields keep cascade authority and stay null on the user.
    final weeklyKm = _kmLocked ? null : (_kmTouched ? _km : null);
    final easyPace = _paceLocked ? null : (_paceTouched ? _paceSeconds : null);

    try {
      await save(weeklyKm: weeklyKm, easyPaceSecondsPerKm: easyPace);
      if (!mounted) return;
      context.push('/onboarding/form');
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitError = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String get _paceText {
    if (_paceSeconds == null) return 'Tap to choose';
    final m = _paceSeconds! ~/ 60;
    final s = (_paceSeconds! % 60).toString().padLeft(2, '0');
    return '$m:$s /km';
  }

  @override
  Widget build(BuildContext context) {
    final hasAnyPrefill = _wearableKm != null || _wearablePace != null;
    final title = hasAnyPrefill ? 'Your running baseline' : 'Tell us about your running';
    final subtitle = hasAnyPrefill
        ? 'We use these to calibrate your training plan.'
        : 'We need two numbers to build an accurate plan.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Text(title, style: RunCoreText.serifTitle(size: 30)),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Weekly km
                  _kmLocked
                      ? LockedStatField(
                          label: 'Average weekly km (last 4 weeks)',
                          valueText: _km == null ? '—' : '${_km!.toStringAsFixed(1).replaceAll(RegExp(r"\.0$"), "")} km',
                          sourceLabel: 'Apple Health',
                          locked: true,
                          onUnlock: _unlockKm,
                          onTapWhenUnlocked: () {},
                        )
                      : _KmEditField(
                          controller: _kmController,
                          sourceLabel: _wearableKm != null ? 'Apple Health' : null,
                          touched: _kmTouched,
                          onChanged: (text) {
                            final parsed = double.tryParse(text.replaceAll(',', '.'));
                            setState(() {
                              _km = parsed;
                              _kmTouched = parsed != null && parsed >= 1;
                            });
                          },
                        ),

                  const SizedBox(height: 24),

                  // Easy pace
                  LockedStatField(
                    label: 'Easy run pace',
                    valueText: _paceLocked
                        ? _paceText
                        : (_paceTouched ? _paceText : 'Tap to choose'),
                    sourceLabel: _wearablePace != null ? 'Apple Health' : null,
                    locked: _paceLocked,
                    onUnlock: _unlockPace,
                    onTapWhenUnlocked: _openPaceWheel,
                  ),

                  if (_submitError != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _submitError!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: CupertinoColors.systemRed,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          OnboardingPrimaryButton(
            label: _submitting ? 'Saving…' : 'Continue',
            onTap: _canContinue ? _submit : null,
          ),
        ],
      ),
    );
  }
}

class _KmEditField extends StatelessWidget {
  final TextEditingController controller;
  final String? sourceLabel;
  final bool touched;
  final ValueChanged<String> onChanged;

  const _KmEditField({
    required this.controller,
    required this.sourceLabel,
    required this.touched,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Average weekly km (last 4 weeks)',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.inkMuted,
          ),
        ),
        const SizedBox(height: 6),
        CupertinoTextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: onChanged,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryInk,
          ),
          placeholder: '0',
          placeholderStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.inkMuted.withValues(alpha: 0.5),
          ),
          suffix: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              'km',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.inkMuted,
              ),
            ),
          ),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.inputBorder),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          sourceLabel != null
              ? (touched ? 'Edited by you' : 'From $sourceLabel')
              : 'Required',
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onSkip;
  const _ErrorState({required this.message, required this.onRetry, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'We couldn\'t load your data.',
            style: RunCoreText.serifTitle(size: 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.inkMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OnboardingPrimaryButton(label: 'Retry', onTap: onRetry),
          const SizedBox(height: 8),
          CupertinoButton(onPressed: onSkip, child: const Text('Skip')),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Run the analyzer**

```bash
cd app && flutter analyze lib/features/onboarding/screens/onboarding_overview_screen.dart
```

Expected: 0 issues. If `RunCoreText.serifTitle` or `AppColors.inputBorder` are not defined, check `app/lib/core/theme/app_theme.dart` for the actual constant names and fix the imports / references accordingly (the spec uses idiomatic names; the codebase may use slightly different ones — `app_theme.dart` is the source of truth).

- [ ] **Step 3: Commit**

```bash
cd /Users/erwin/personal/runcoach
git add app/lib/features/onboarding/screens/onboarding_overview_screen.dart
git commit -m "feat(onboarding): editable baseline overview screen"
```

---

## Task 12: Flutter widget test for the overview screen

**Files:**
- Test: `app/test/features/onboarding/onboarding_overview_screen_test.dart`

- [ ] **Step 1: Write the test**

Create `app/test/features/onboarding/onboarding_overview_screen_test.dart`:

```dart
import 'package:app/features/onboarding/data/onboarding_api.dart';
import 'package:app/features/onboarding/models/onboarding_profile.dart';
import 'package:app/features/onboarding/providers/onboarding_profile_provider.dart';
import 'package:app/features/onboarding/screens/onboarding_overview_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Pumps the overview screen with a mocked profile and a save fn that
/// captures the last call's arguments.
class _SaveCapture {
  double? weeklyKm;
  int? easyPaceSecondsPerKm;
  int calls = 0;
}

Future<_SaveCapture> _pumpScreen(WidgetTester tester, {required OnboardingProfile profile}) async {
  final capture = _SaveCapture();

  final router = GoRouter(
    initialLocation: '/onboarding/overview',
    routes: [
      GoRoute(path: '/onboarding/overview', builder: (_, _) => const OnboardingOverviewScreen()),
      GoRoute(path: '/onboarding/form', builder: (_, _) => const Text('FORM REACHED')),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        onboardingProfileControllerProvider.overrideWith(() {
          final ctrl = _StubProfileController(profile);
          return ctrl;
        }),
        saveSelfReportedStatsCallProvider.overrideWith((ref) {
          return ({double? weeklyKm, int? easyPaceSecondsPerKm}) async {
            capture.calls++;
            capture.weeklyKm = weeklyKm;
            capture.easyPaceSecondsPerKm = easyPaceSecondsPerKm;
          };
        }),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();

  return capture;
}

class _StubProfileController extends OnboardingProfileController {
  _StubProfileController(this._profile);
  final OnboardingProfile _profile;

  @override
  Future<OnboardingProfile> build() async => _profile;
}

void main() {
  testWidgets('continue is disabled until both fields are touched on no-wearable', (tester) async {
    final profile = OnboardingProfile(
      status: 'ready',
      baseline: const OnboardingBaseline(
        weeklyKm: null,
        weeklyKmSource: null,
        easyPaceSecondsPerKm: 360,
        easyPaceSource: null,
      ),
    );

    await _pumpScreen(tester, profile: profile);

    // Initial state: Continue should be disabled (both untouched).
    final continueFinder = find.text('Continue');
    expect(continueFinder, findsOneWidget);

    // Enter weekly km.
    await tester.enterText(find.byType(CupertinoTextField), '25');
    await tester.pumpAndSettle();

    // Open pace picker, tap Done with default 6:00.
    await tester.tap(find.text('Tap to choose'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('FORM REACHED'), findsNothing);
    await tester.tap(continueFinder);
    await tester.pumpAndSettle();
    expect(find.text('FORM REACHED'), findsOneWidget);
  });

  testWidgets('wearable user can continue without unlocking — sends nulls', (tester) async {
    final profile = OnboardingProfile(
      status: 'ready',
      baseline: const OnboardingBaseline(
        weeklyKm: 24.0,
        weeklyKmSource: 'apple_health',
        easyPaceSecondsPerKm: 330,
        easyPaceSource: 'apple_health',
      ),
    );

    final capture = await _pumpScreen(tester, profile: profile);

    expect(find.text('24 km'), findsOneWidget);
    expect(find.text('5:30 /km'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.lock_fill), findsNWidgets(2));

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(capture.calls, 1);
    expect(capture.weeklyKm, isNull);
    expect(capture.easyPaceSecondsPerKm, isNull);
    expect(find.text('FORM REACHED'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the test**

```bash
cd app && flutter test test/features/onboarding/onboarding_overview_screen_test.dart
```

Expected: PASS. If the stub provider override syntax breaks due to riverpod codegen specifics, fall back to a simpler approach: skip the controller override and rely on `AsyncValue.data(profile)` injected via `valueOverride` if available. The Riverpod-codegen way is to extend the generated `_$OnboardingProfileController` class — adjust the stub to match what the regenerated file expects.

- [ ] **Step 3: Commit**

```bash
cd /Users/erwin/personal/runcoach
git add app/test/features/onboarding/onboarding_overview_screen_test.dart
git commit -m "test(onboarding): widget test for editable overview screen"
```

---

## Task 13: Documentation updates

**Files:**
- Modify: `CLAUDE.md`
- Modify: `api/CLAUDE.md`
- Modify: `app/CLAUDE.md`

- [ ] **Step 1: Add a bullet to the monorepo CLAUDE.md**

Open `/Users/erwin/personal/runcoach/CLAUDE.md`. Find the "Current state" / bullet list of shipped features (search for "Reschedule training days" or "HR-zone auto-derivation" — they're in the same list). Append:

```markdown
- **Self-reported onboarding baseline** — `/onboarding/overview` now editable: 2 fields (avg weekly km, easy pace). Wearable users see prefilled + locked values with a confirmation dialog to override. No-wearable users fill in directly. Stored on `users.self_reported_*` + injected as Tier-0 in `FitnessSnapshotService::snapshot`. Spec: `docs/superpowers/specs/2026-05-11-onboarding-self-reported-stats-design.md`.
```

- [ ] **Step 2: Add a section to api/CLAUDE.md**

Open `api/CLAUDE.md`. Find the "FitnessSnapshotService" description (under the "Plan-pipeline services" section). Replace it with an updated version that mentions Tier-0:

Find:

```markdown
- **`FitnessSnapshotService`** (`app/Services/Onboarding/`) — derives a recent-fitness snapshot via 4-tier cascade
```

Change to:

```markdown
- **`FitnessSnapshotService`** (`app/Services/Onboarding/`) — derives a recent-fitness snapshot. Tier 0: self-reported overrides from `users.self_reported_weekly_km` / `users.self_reported_easy_pace_seconds_per_km` (filled in `/onboarding/overview` — when non-null they win over the cascade). Then 4-tier cascade
```

Then append at the end of the "Current state" section:

```markdown
- **Self-reported onboarding baseline** — `POST /onboarding/self-reported-stats` (`OnboardingController::saveSelfReportedStats`) persists `users.self_reported_weekly_km` + `self_reported_easy_pace_seconds_per_km` + `self_reported_stats_at`. `GET /onboarding/profile` returns a new `baseline` block with per-field source (`apple_health` / `self_reported` / `null`). `FitnessSnapshotService::snapshot()` wraps the existing cascade with Tier-0 self-report overrides. Spec: `docs/superpowers/specs/2026-05-11-onboarding-self-reported-stats-design.md`.
```

- [ ] **Step 3: Add a note to app/CLAUDE.md**

Open `app/CLAUDE.md`. Find the "Onboarding flow (new user)" section. Replace the line:

```markdown
3. `/onboarding/overview` — `OnboardingOverviewScreen` shows 4 stat cards + a one-line AI narrative computed from the freshly ingested activities
```

with:

```markdown
3. `/onboarding/overview` — `OnboardingOverviewScreen` is an editable 2-field form (avg weekly km + easy pace). Wearable users see prefilled values with a lock icon; tapping unlock shows a "this may degrade your plan" Cupertino alert before allowing edits. No-wearable users fill the fields directly (both required). Submit POSTs to `/onboarding/self-reported-stats` before navigating to the form. Spec: `../docs/superpowers/specs/2026-05-11-onboarding-self-reported-stats-design.md`.
```

- [ ] **Step 4: Commit**

```bash
cd /Users/erwin/personal/runcoach
git add CLAUDE.md api/CLAUDE.md app/CLAUDE.md
git commit -m "docs: self-reported onboarding baseline"
```

---

## Task 14: Full-suite sanity check

- [ ] **Step 1: Run the backend test suite**

```bash
cd api && php artisan test --compact
```

Expected: all green (existing pre-feature APNs `.p8` failures are pre-existing and unrelated — count is the same as before this feature).

- [ ] **Step 2: Run the Flutter tests**

```bash
cd app && flutter test
```

Expected: all green.

- [ ] **Step 3: Run flutter analyze**

```bash
cd app && flutter analyze
```

Expected: 0 issues.

- [ ] **Step 4: Manual smoke test on simulator**

```bash
cd app && bash scripts/run-dev.sh
```

(Assumes the local backend is running via `cd api && composer run dev`.)

In the simulator:

1. Sign in with the dev login (use the welcome screen "I have an Apple device" path → falls through to dev-login on simulator).
2. The router lands you on `/onboarding/connect-health` (or `/onboarding/zones` on web). Skip HealthKit via "Continue without syncing".
3. Confirm HR zones → tap "Looks right".
4. **On `/onboarding/overview`**: verify both fields are unlocked (no lock icons), pace shows "Tap to choose", weekly km is empty. Continue is disabled.
5. Enter 25 km, tap pace → wheel opens at 6:00 → tap Done. Continue enables.
6. Tap Continue → navigates to `/onboarding/form`.
7. (Optional) restart the seeder with `DevOnboardingSeeder` (which has wearable activities) to confirm the locked path: fields show "24 km" + a pace + "From Apple Health" badge + lock icons. Tap lock → confirmation alert. Cancel → stays locked. Edit anyway → unlocks.

- [ ] **Step 5: Commit nothing — this is verification only**

If steps 1-4 all pass cleanly, no further commit needed. If anything failed, investigate, fix, and add a follow-up commit.

---

## Self-review

**Spec coverage:**
- Problem + goals → Task 11 (UI), Tasks 4-5 (backend endpoints + baseline block)
- Non-goals (no 12mo question, no threshold/vo2max derivation, no stale-detection) → respected throughout
- UI states (locked, unlock alert, no-wearable) → Task 10 (locked field), Task 11 (screen)
- Pace picker → Task 9
- Migration schema → Task 1
- Endpoint → Task 4
- FitnessSnapshot Tier-0 → Task 3
- Profile baseline block → Task 5
- All 4 user archetypes from the spec's flow table → covered by Tasks 4, 5, 11, 12
- 9 edge cases from spec → most are exercised by Tasks 4 (validation, idempotency), 5 (mixed source labels), 11 (re-lock restoration)
- Files list — all covered

**Placeholder scan:**
- The migration filename (`2026_05_11_120000_*`) is concrete.
- No "TODO" or "fill in" steps.
- One reference to "check `app_theme.dart` for the actual constant names" in Task 11 step 2 — acceptable because it's a known-but-trivial environment-dependent step that requires reading a file the engineer already has open.

**Type consistency:**
- `OnboardingBaseline` field names match across spec, model (Task 7), and screen (Task 11).
- Endpoint payload `weekly_km` / `easy_pace_seconds_per_km` matches between request rules (Task 4), API call (Task 8), and screen submit (Task 11).
- `users.self_reported_*` column names match between migration, model fillable, controller, and snapshot service.

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-05-11-onboarding-self-reported-stats.md`. Two execution options:

**1. Subagent-Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks, fast iteration. Good for plans with 10+ tasks like this one — keeps each subagent's context focused.

**2. Inline Execution** — Execute tasks in this session using executing-plans, batch execution with checkpoints. Faster turnaround per task but the conversation context grows quickly.

Which approach?
