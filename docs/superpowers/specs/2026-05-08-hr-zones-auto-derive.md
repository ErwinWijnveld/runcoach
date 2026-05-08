# HR zones — auto-derive from HealthKit data

**Status:** shipped — rewritten 2026-05-08 after v0 review
**Author:** Erwin + Claude
**Date:** 2026-05-08

> **Update (2026-05-08, after v0 shipped):** The empirical-as-primary path
> ("median of top-N max_heartrate from recent runs") was removed. Real-world
> data showed it systematically underestimated max HR — recreational runners
> rarely hit true max in normal training (Erwin's last 12 runs maxed at 171 bpm
> while his Tanaka estimate is 184). Industry research confirms no major app
> uses observed-max as the primary source: Strava/Polar default to age-based,
> Apple Fitness uses Karvonen with HRR, Garmin uses age + upward-only
> correction. The new approach in this doc reflects that — Tanaka prior +
> Karvonen with RHR + upward-only correction (Garmin model). Sections below
> describe the current implementation; the original empirical-first proposal
> is preserved at the end under "Original v0 design (deprecated)" for context.

## Problem

Heart-rate zones drive the HR-component of compliance scoring (`ComplianceScoringService`) and the pace-adjustment notifications (`PaceAdjustmentEvaluator`). Today they're either:

- **The hardcoded "untrained athlete" defaults** in `App\Support\HeartRateZones::DEFAULTS` (Z1 0-115 … Z5 190+), assuming a max HR of ~190 — wrong for a 50-year-old recreational runner (real max ~170) AND for a fit 30-year-old (real max 195+).
- **Manually entered** by the user via the menu sheet (`heart_rate_zones_sheet.dart`) — but the runner has to know their max HR off the top of their head and tap a Max HR field that defaults to 190.

We have ~90 days of running activities with `max_heartrate` per workout sitting in `wearable_activities` after onboarding. We can derive accurate, personalised zones from that data automatically and never bother the user with a guess. Apple Health's *own* zones aren't readable via the public HealthKit API ([confirmed Apple developer forums](https://developer.apple.com/forums/thread/718549)) — so the only path is to compute our own from the underlying HR samples we already ingest.

## Goal

1. **Auto-derive HR zones** at the end of onboarding, using empirical max HR from the ingested running history when there's enough data, with a graceful fallback chain when there isn't.
2. **Add a confirmation step to onboarding**, between *connect-health* and *overview*, that shows the derived zones, lets the runner tap "Looks right" to continue, or open the existing edit sheet to tweak them.
3. **Track the source** of the zones (`default` / `derived_empirical` / `derived_age` / `manual`) so we never silently overwrite a manual edit, and so admin / future logic can reason about confidence.

## Non-goals

- **Reading Apple's own configured zones from HealthKit** — not exposed via public API.
- **Periodic auto-recalculation** as the runner gets fitter. v1 derives once at onboarding. A future "your zones might be outdated" notification (using the existing notifications inbox) is out of scope but the source field leaves the door open.
- **Karvonen-method zone math (HRR-based)** beyond the simple HRR-based fallback used when both age + resting HR are available. v1 keeps the existing 60/70/80/90% of max-HR scheme that the UI already shows, to avoid changing the user's mental model.
- **Reading Apple Health zones during a workout** (different concept — that's per-segment time-in-zone, which IS readable but it's an output of zones, not the zones themselves).
- **Per-activity-type zones** (running vs cycling separate zones) — single zone table per user.
- **Backfill for existing users** beyond next onboarding. v1 only runs at first connect-health.

## Design

### High-level flow

```
[Flutter] OnboardingConnectHealthScreen
    1. requests Apple Health read perm
    2. fetches last 90 days of HKWorkout (running)
    3. POST /wearable/activities (batched)
    4. when ingestion settles:
         POST /onboarding/derive-zones                     (NEW)
         → returns { zones, source, max_hr, sample_count, age, resting_hr }
    5. context.go('/onboarding/zones')                     (NEW screen)

[Flutter] OnboardingZonesScreen                            (NEW)
    - shows derived zones in the same visual style as heart_rate_zones_sheet
    - source-dependent subtitle (empirical N runs / age fallback / default)
    - [Looks right] → context.go('/onboarding/overview')
    - [Edit zones]  → opens HeartRateZonesSheet (existing)
                       on save: PATCH /profile flips source → 'manual'

[Flutter] OnboardingOverviewScreen   ← unchanged, just downstream of zones step
```

Backend flow inside `POST /onboarding/derive-zones` is described in **Algorithm** below.

### Schema changes

#### `users` table — new column

```php
$table->string('heart_rate_zones_source', 32)
      ->default('default')
      ->after('heart_rate_zones');
```

Enum-as-string (PHP 8.1 backed enum `App\Enums\HeartRateZonesSource`):

| Value | When set | Meaning |
|---|---|---|
| `default` | column default; never written by us | User's `heart_rate_zones` is null OR the row was created before this feature shipped — `HeartRateZones::forUser` falls through to `DEFAULTS`. |
| `derived_empirical` | derive job, ≥ `MIN_QUALIFYING_RUNS` qualifying workouts | Median-of-top-N max HR from the runner's actual runs. Highest confidence. |
| `derived_age` | derive job, insufficient runs but `dateOfBirth` available | Tanaka or Karvonen estimate. Marked clearly in the UI. |
| `manual` | user edits via `HeartRateZonesSheet` (PATCH `/profile heart_rate_zones`) | Never auto-overwritten. The "looks right" button on the new onboarding screen does NOT flip to `manual` — it leaves whatever the derive job set. |

Migration: pre-launch, edit the existing `0001_01_01_000000_create_users_table.php` in place per `feedback_migrations.md` (rewrite migrations directly + `migrate:fresh`, no new migration files).

#### Constants + algorithm parameters

`App\Support\HeartRateZones`:

```php
// Empirical-derivation thresholds. These are deliberately strict — we
// would rather fall back to the age formula than derive from 4 noisy
// junk runs.
public const MIN_QUALIFYING_RUNS = 5;          // need at least 5 valid runs
public const MAX_LOOKBACK_DAYS   = 365;        // recency window for fitness signal
public const MIN_DURATION_SEC    = 600;        // ≥ 10 min — kills warmup-only/aborted
public const MIN_AVG_HR          = 130;        // kills "watch on, walking the dog"
public const MIN_PHYSIO_HR       = 100;        // floor for max_heartrate sanity check
public const MAX_PHYSIO_HR       = 220;        // ceiling — anything above is sensor noise
public const TOP_N_SAMPLES       = 5;          // pick top N max_heartrates
                                               // and median them — robust to 1-2 outliers
                                               // even at the top end

// Fallback (age formula).
public const TANAKA_INTERCEPT = 208.0;
public const TANAKA_SLOPE     = 0.7;            // maxHR ≈ 208 − 0.7·age (more accurate than 220−age above 40)

// Zone percents. Match the UI's existing 60/70/80/90 scheme.
public const ZONE_PCT = [0.60, 0.70, 0.80, 0.90];
```

### Algorithm

`App\Support\HeartRateZoneDeriver` — new class, single public method `derive(User $user): DerivationResult` (a `readonly` PHP 8.5 class with `zones`, `source`, `max_hr`, `sample_count`, `age`, `resting_hr`).

#### Step 1 — gather candidate runs

```sql
SELECT max_heartrate, average_heartrate, duration_seconds, start_date
FROM wearable_activities
WHERE user_id = ?
  AND activity_type IN ('Run', 'TrailRun', 'VirtualRun')        -- WearableActivity::RUN_TYPES
  AND max_heartrate IS NOT NULL
  AND max_heartrate BETWEEN 100 AND 220                          -- MIN_PHYSIO_HR..MAX_PHYSIO_HR
  AND duration_seconds >= 600                                    -- MIN_DURATION_SEC
  AND average_heartrate IS NOT NULL
  AND average_heartrate >= 130                                   -- MIN_AVG_HR
  AND start_date >= NOW() - INTERVAL 365 DAY                     -- MAX_LOOKBACK_DAYS
ORDER BY max_heartrate DESC
LIMIT 50;
```

We pull up to 50 candidates so the median-of-top-N step has headroom to drop unsuspected anomalies. The four filters address specific failure modes:

| Filter | Failure mode it kills |
|---|---|
| `max_heartrate BETWEEN 100..220` | Sensor electrode glitch (chest strap reading 0 or 250+), wrist-strap interference (lighting up the IR sensor wrong), short bursts where the watch reported a spurious 999. |
| `duration_seconds >= 600` | Warmup-only walk before user remembered to stop the watch, aborted workouts, "I tapped Outdoor Run accidentally" — these never reach a real max. |
| `average_heartrate >= 130` | Recovery jog / cooldown shake-out / "walked the dog with the watch on running mode" — true running effort averages ≥ 130 for 99% of adult runners. |
| `start_date >= NOW() − 365d` | Old fitness state (the runner who used to be much fitter and is now starting over). |

#### Step 2 — empirical derivation

If `count(candidates) >= MIN_QUALIFYING_RUNS` (5):

1. Take the top `TOP_N_SAMPLES` (5) by `max_heartrate`.
2. Compute the **median** of those 5.
3. Round to nearest integer.
4. Source = `derived_empirical`.

**Why median-of-top-N, not just `MAX(max_heartrate)`?** This is the key edge case the user flagged. Concrete worst-case scenarios:

| Scenario | Top-5 max_heartrates | `MAX()` | Median-of-top-5 |
|---|---|---|---|
| Healthy data, clean | 192, 191, 191, 190, 190 | 192 | **191** ✓ |
| One sensor glitch | **218**, 192, 191, 191, 190 | 218 ✗ (bad) | **191** ✓ |
| Two sensor glitches in a row | **218**, **216**, 192, 191, 191 | 218 ✗ | **192** ✓ (still resilient) |
| Real race PB above normal training | **198**, 191, 191, 190, 190 | 198 (correct!) | **191** (slightly under) |
| Casual user — never went hard | 165, 164, 163, 162, 162 | 165 | **163** ✓ (matches reality) |

The "real race PB" row is the tradeoff — if you have ONE workout where you genuinely hit a higher max than your normal training, the median will undercount by ~5-7 bpm. That's an acceptable cost: zones derived 5 bpm too low cause Z5 to start a touch early, which means more workouts get classified as Z5 than necessary, which is conservative (the runner won't be told their easy run was actually moderate). The reverse error (zones derived 25 bpm too high from a sensor glitch) would cause every interval session to score "way under target HR" and trigger spurious pace-adjustment notifications — much worse UX.

If the runner WANTS to push the ceiling up because they know their true max is higher, they hit "Edit zones" and bump it. The source flips to `manual`, which the derive job will never overwrite.

#### Step 3 — age-based fallback

If empirical derivation is rejected (insufficient runs OR no HR data at all):

1. Try to read `dateOfBirth` from HealthKit (Flutter `health` package: `HealthDataType.BIRTH_DATE`). Pass it in the request body — backend has no other way to get it (we don't store DOB).
2. Try to read `restingHeartRate` from HealthKit (`HealthDataType.RESTING_HEART_RATE`, latest sample) — same way.
3. **If both available — Karvonen:**
   - `max_hr = 208 − 0.7 × age` (Tanaka, more accurate than 220−age over 40)
   - `hrr = max_hr − resting_hr`
   - Zone i upper bound: `resting_hr + ZONE_PCT[i] × hrr` (where `ZONE_PCT = [0.60, 0.70, 0.80, 0.90]`)
4. **If only age available — Tanaka percent-of-max:**
   - `max_hr = 208 − 0.7 × age`
   - Zone i upper bound: `ZONE_PCT[i] × max_hr` (matches existing UI math)
5. **If neither available** — leave `heart_rate_zones` null, source stays `default`. The new onboarding screen explains "We couldn't auto-detect your zones — please verify these defaults or set your max HR."
6. Source = `derived_age` for cases 3 + 4.

The Flutter onboarding screen reads `dateOfBirth` and `restingHeartRate` from HealthKit BEFORE calling `POST /onboarding/derive-zones`, so the payload looks like:

```json
{
  "age": 47,                  // optional, integer years
  "resting_heart_rate": 52    // optional, integer bpm
}
```

Both are optional. Backend uses them only as inputs to `HeartRateZoneDeriver` and does NOT persist them on the user (no schema change for DOB / resting HR — they live in HealthKit as the source of truth, and we re-read them next onboarding if ever).

#### Step 4 — persist

`HeartRateZoneDeriver::derive` returns a `DerivationResult`. The endpoint:
1. Refuses to overwrite if `user.heart_rate_zones_source === 'manual'` (returns the existing zones with `source: 'manual'` and a flag — the onboarding screen handles this case by skipping the confirmation and going straight to overview, since the user already manually configured them in some other flow).
2. Otherwise persists `zones` + `source` to the user.
3. Returns the full `DerivationResult` for the screen.

### Edge cases (full enumeration)

This is the matrix the implementation MUST cover. Every row should map to a deterministic outcome:

| # | Scenario | Outcome |
|---|---|---|
| 1 | Healthy runner, 30+ qualifying runs | `derived_empirical`, median-of-top-5 |
| 2 | New user, 0 runs synced | Empirical fails → age fallback → `derived_age` if DOB present, else `default` |
| 3 | User runs without watch (no HR field) | Same as #2 — `max_heartrate IS NOT NULL` filter eliminates them |
| 4 | One sensor glitch (`max_heartrate = 218`) in otherwise clean data | Median-of-top-5 absorbs it; result correct |
| 5 | Two adjacent sensor glitches (218 + 216) | Median absorbs (5th from top is real); result correct |
| 6 | All easy/Z2 runs — runner never went hard | Empirical max ≈ 165 (truthful representation of demonstrated effort). Acceptable: if/when they do a hard session, the future "zones look outdated" notification (out of scope v1) catches it. Manual edit available now. |
| 7 | One real race PB above all training | Median undercounts by ~5 bpm. Discussed above — acceptable conservative bias. |
| 8 | All runs are short (≤ 10 min) | `MIN_DURATION_SEC` filter rejects → empirical fails → age fallback |
| 9 | All runs are recovery jogs (avg HR < 130) | `MIN_AVG_HR` filter rejects → empirical fails → age fallback |
| 10 | All runs are old (> 1 year ago) | `MAX_LOOKBACK_DAYS` filter rejects → empirical fails → age fallback |
| 11 | DOB in HealthKit but user denied permission | Flutter side: pass `null` for age; backend falls through to `default` |
| 12 | Indoor / treadmill runs only | `WearableActivity::RUN_TYPES` already includes `VirtualRun` (HKWorkout `runningTreadmill` ingests as `VirtualRun`). Treadmill HR is via wrist sensor — already filtered by physiological bounds. Kept. |
| 13 | Cycling / other-sport HR samples | `RUN_TYPES` filter excludes them. |
| 14 | User has `heart_rate_zones_source = 'manual'` already | Endpoint short-circuits, returns existing zones with `source: 'manual'`, screen skips to overview (no confirmation prompt). |
| 15 | User edits zones in the menu sheet → source flips to `manual`. Next time they go through onboarding (rare — only after account deletion + re-create) | Same as #14 — manual is sticky. |
| 16 | Activity ingestion is still in flight when the screen calls `POST /onboarding/derive-zones` | The Flutter screen MUST await ingestion completion before dispatching. The current `onboarding_connect_health_screen` already awaits the batched POST resolves. If somehow zero activities were ingested at call time, endpoint returns `derived_age` or `default` — no error. |
| 17 | Age = 12 (dummy DOB in HealthKit) → `max_hr = 208 − 8.4 = 199.6`. Plausible. | Pass through. We don't try to validate plausibility of `dateOfBirth` — Apple already restricts under-13 accounts; in the unlikely event the DOB is wrong, the user can edit. |
| 18 | Age = 90 → `max_hr = 208 − 63 = 145`. Implausibly low for an active person but mathematically valid. | Pass through. Tanaka is documented as accurate ±10 bpm for ages 18-75; for outliers manual edit is the escape hatch. |
| 19 | `resting_heart_rate = 38` (elite athlete) | Karvonen with low resting HR pushes lower zone bounds down — correct behaviour. |
| 20 | `resting_heart_rate = 80` (deconditioned) | Karvonen pushes lower zone bounds up — correct behaviour. |
| 21 | Computed Z1 lower > 0 via Karvonen (e.g. `Z1 = [resting_hr + 0%, resting_hr + 60% × hrr]`) | We force Z1 lower to 0 to keep the "everything below tempo" semantic of Z1 — the UI's lower-zone shape doesn't change. Karvonen only adjusts the four interior boundaries. |
| 22 | Two derived runs back-to-back (race + sensor glitch) collapse top-5 down to 3 valid + 2 glitchy | Top-5 still spans real values once filters bite (218 + 216 are filtered out by `MAX_PHYSIO_HR` if they exceed 220). Medianing 191/191/190 is fine. |
| 23 | All `max_heartrate` values identical (e.g. all 191) | Median = 191. Result fine. |
| 24 | Mid-onboarding network failure on `POST /onboarding/derive-zones` | Onboarding screen retries up to 2× (consistent with existing connect-health network handling), then surfaces an inline error with "Skip — set zones later". Skipping leaves source as `default` and routes to /overview. |
| 25 | Runner hits "Looks right" on the new screen | No additional persistence (zones already saved by the derive endpoint). Just navigates to /overview. Source stays `derived_*`. |
| 26 | Runner hits "Edit zones" → makes a change → saves | Existing `PATCH /profile` flow. We extend it to set `heart_rate_zones_source = 'manual'` whenever `heart_rate_zones` is in the request body. |
| 27 | Runner edits, then later does a re-onboarding (e.g. dev rebuild + dev-login) | `derive-zones` endpoint sees `source = 'manual'`, returns existing zones, screen skips. (See #14.) |
| 28 | Onboarding completes, but runner manually edits zones a week later from the menu | `PATCH /profile` flips source to `manual`. Future re-derives (out of scope v1, but if/when added) will skip them. |
| 29 | Two devices syncing same user simultaneously | The single derive call is idempotent; either request returns the same persisted result. The "Looks right" button isn't a write, it's a navigate. |
| 30 | User's HealthKit data was just bulk-imported from a different platform with truncated max_heartrate values | Same as #6 — we derive from what we can see. The `MIN_AVG_HR` filter eliminates importer-padding rows that have unrealistic averages. |

### Backend — concrete files

#### `App\Enums\HeartRateZonesSource` (new)

```php
enum HeartRateZonesSource: string
{
    case Default = 'default';
    case DerivedEmpirical = 'derived_empirical';
    case DerivedAge = 'derived_age';
    case Manual = 'manual';
}
```

#### `App\Support\HeartRateZoneDeriver` (new)

Single public method:

```php
public function derive(User $user, ?int $age, ?int $restingHeartRate): DerivationResult
```

Returns:

```php
final readonly class DerivationResult
{
    public function __construct(
        /** @var list<array{min:int, max:int}> */
        public array $zones,
        public HeartRateZonesSource $source,
        public ?int $maxHeartRate,        // null when source = default
        public int $sampleCount,          // qualifying runs found (0 when source != derived_empirical)
        public ?int $age,                 // echoed back when used
        public ?int $restingHeartRate,    // echoed back when used
    ) {}
}
```

The class extends `App\Support\HeartRateZones` for the constants/zone math but doesn't replace it — `HeartRateZones::forUser` stays the runtime read-path used by `ComplianceScoringService` + `PaceAdjustmentEvaluator`.

#### `POST /api/v1/onboarding/derive-zones` (new)

Auth: `auth:sanctum`. Controller: `App\Http\Controllers\OnboardingController::deriveZones`.

Request:
```json
{
  "age": 47,                    // optional, integer 5-120 (defensive)
  "resting_heart_rate": 52      // optional, integer 30-120
}
```

Response (200):
```json
{
  "zones": [
    {"min": 0,   "max": 115},
    {"min": 115, "max": 134},
    {"min": 134, "max": 153},
    {"min": 153, "max": 172},
    {"min": 172, "max": -1}
  ],
  "source": "derived_empirical",
  "max_hr": 191,
  "sample_count": 23,
  "age": 47,
  "resting_heart_rate": 52
}
```

When `source === 'manual'` (sticky, won't overwrite):
```json
{
  "zones": [...],
  "source": "manual",
  "max_hr": null,
  "sample_count": 0,
  "age": null,
  "resting_heart_rate": null
}
```

#### `App\Http\Requests\UpdateProfileRequest` — extension

When `heart_rate_zones` is present in the request body, set `heart_rate_zones_source = 'manual'`. Add a `prepareForValidation` hook that only sets it when zones are explicitly being changed (so `PATCH /profile {name: "..."}` doesn't accidentally flip the source).

### Flutter — concrete files

#### `lib/features/onboarding/screens/onboarding_zones_screen.dart` (new)

Layout (matches the existing `heart_rate_zones_sheet.dart` visual language so the runner sees the same shape twice — once in onboarding, once in the menu):

```
GradientScaffold
├── SafeArea
    ├── progress dots / step header (matches existing form steps)
    ├── Title (italic Garamond 28pt)
    │   "Your heart rate zones"
    ├── Subtitle (publicSans 14pt, inkMuted)
    │   ├─ derived_empirical:
    │   │     "Based on your last N runs, your max heart rate is around X bpm.
    │   │      We've split that into 5 training zones."
    │   ├─ derived_age:
    │   │     "Estimated from your age (Y years). Sync more runs with heart rate
    │   │      data and we'll refine these later."
    │   └─ default:
    │     "We couldn't pull HR data from Apple Health — please verify these
    │      defaults or set your max HR before continuing."
    ├── Zones list (read-only — same _ZonesList widget as the sheet, just non-editable)
    │   Z1 Endurance     0 – 115 bpm
    │   Z2 Moderate    115 – 134 bpm
    │   ...
    │   Z5 Anaerobic   172 – ∞ bpm
    ├── Spacer
    └── Two-button row
        ├── "Edit zones" (lightTan secondary) → showHeartRateZonesSheet(context)
        └── "Looks right" (gold primary)      → context.go('/onboarding/overview')
```

After `showHeartRateZonesSheet` resolves (sheet pops itself on save), we re-read `authProvider.user.heartRateZones` and re-render the read-only list. The "Looks right" button works regardless of whether zones came from derive or manual edit.

The read-only `_ZonesList` widget should be extracted from `heart_rate_zones_sheet.dart` into a shared widget `lib/core/widgets/hr_zones_readonly_list.dart`, reusable here. Existing sheet keeps its editable variant inline.

#### `lib/features/onboarding/screens/onboarding_connect_health_screen.dart` — change

After ingestion completes (line where it currently calls `context.go('/onboarding/overview')`):

1. Read `dateOfBirth` + `restingHeartRate` from HealthKit (graceful — null if denied / unavailable).
2. `await api.deriveZones(age: age, restingHeartRate: rhr)` (Retrofit call, returns the typed `DerivationResult`).
3. Refresh `authProvider` so `user.heartRateZones` is current.
4. `context.go('/onboarding/zones')`.

If the derive call fails twice (network), set local error state with a "Skip — set zones later" button that goes straight to /overview without persisting (source stays `default`). Don't block onboarding on this.

#### `lib/router/app_router.dart` — change

Add the new route between connect-health and overview:

```dart
GoRoute(
  path: '/onboarding/zones',
  builder: (_, _) => const OnboardingZonesScreen(),
),
```

Order in the file: keep onboarding routes grouped, place this between `/onboarding/connect-health` and `/onboarding/overview` for readability.

#### `lib/features/auth/models/user.dart` — change

Add `String? heartRateZonesSource` field (Freezed). The auth/profile API responses already serialize it (Eloquent will pick it up automatically via `$fillable`).

#### `lib/features/onboarding/data/onboarding_api.dart` — extension

```dart
@POST('/onboarding/derive-zones')
Future<dynamic> deriveZones(@Body() DeriveZonesRequest body);
```

Plus a Freezed `DeriveZonesRequest` (age + resting_heart_rate, both optional) and `DeriveZonesResponse` (zones + source + maxHr + sampleCount + age + restingHeartRate).

#### `lib/features/wearable/services/health_kit_service.dart` — extension

Add `Future<int?> getAge()` and `Future<int?> getLatestRestingHeartRate()` thin wrappers over the `health` package. Both return null on permission denial / no data; never throw.

### Tests

Backend:
- `tests/Feature/Support/HeartRateZoneDeriverTest.php`:
  - happy path empirical
  - top-5 median ignores 1 outlier
  - top-5 median ignores 2 outliers
  - falls back to age when < 5 qualifying runs
  - falls back to age when no `max_heartrate` data at all
  - filters: too short, too easy, too old, out-of-range max
  - Karvonen path when both age + RHR present
  - Tanaka percent-of-max when only age
  - manual source short-circuits — no overwrite
  - default source persists when nothing available
- `tests/Feature/Http/OnboardingDeriveZonesTest.php`:
  - 200 with `derived_empirical` when activities exist
  - 200 with `derived_age` when age in body, no activities
  - 200 with `default` when no inputs
  - 200 short-circuit when `source = manual`
  - 401 unauthenticated
  - validation: age out of range, RHR out of range
- `tests/Feature/ProfileTest.php` — extend:
  - `PATCH /profile` with `heart_rate_zones` flips source to `manual`
  - `PATCH /profile` with only `name` does NOT touch source

Flutter:
- `test/features/onboarding/onboarding_zones_screen_test.dart`:
  - renders empirical subtitle when source = derived_empirical
  - renders age subtitle when source = derived_age
  - renders default warning when source = default
  - "Edit zones" opens the sheet
  - "Looks right" navigates to /overview

### Migration / rollout

- Pre-launch: edit existing migration in place, `php artisan migrate:fresh` per `feedback_migrations.md`.
- No data backfill needed — existing users (only Erwin) will see source = `default` until they re-onboard or manually edit. After a single manual edit, source = `manual` and they're unaffected by future derive logic.
- iOS build doesn't change. No new native bridge work.
- App Store: no new privacy permissions required (HealthKit + dateOfBirth + heart rate are all under existing `NSHealthShareUsageDescription` umbrella).

## Open questions

1. **Persist the derivation metadata** (sample_count, max_hr) on the user, or compute on-the-fly each time the screen loads? *Proposal: compute on-the-fly via the endpoint return value. Avoids a stale "based on 23 runs" message after the user has synced 50.* The screen uses the response directly, doesn't re-read from `users`.
2. **Should "Looks right" flip source to `confirmed`** to differentiate user-confirmed-derived from never-touched-derived? *Proposal: no — adds enum complexity for no behavioural difference. The derive job already won't overwrite a `derived_empirical` source it just set, and a future "your zones look outdated" feature would key on `max_heartrate` deltas, not the source string.*
3. **Age formula choice — Tanaka vs `220 − age`?** *Proposal: Tanaka. More accurate for ages 18-75 (the realistic user base), and the implementation cost is identical.*
4. **Hard floor on Z5 lower bound?** If the user's empirical max is 145 (very deconditioned), Z5 lower = `0.90 × 145 = 130 bpm` — which a fitter person would hit on a moderate jog. This is correct behaviour for the deconditioned runner but feels low. *Proposal: no floor. The numbers are personalised; the runner's "moderate jog" might literally be Z5 work for them. If feedback comes in, revisit.*
