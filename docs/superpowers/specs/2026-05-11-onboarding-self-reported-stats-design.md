# Onboarding — self-reported baseline stats for users without wearables

**Status:** draft
**Author:** Erwin + Claude
**Date:** 2026-05-11

## Problem

Today's onboarding assumes the runner connects Apple Health (or, later, Garmin/Polar via Open Wearables) and lets the cascade in `FitnessSnapshotService` derive their fitness baseline from `wearable_activities`. Users who deny HealthKit permission or have no run history land on `/onboarding/overview` with zeroed metrics (`weekly_avg_km: 0`, etc.), continue through the form, and get a plan generated from `FitnessSnapshotService`'s tier-4 fallback: `weeklyKmRecent4Weeks = 0`, `easyPaceSecondsPerKm = 360 (6:00/km)`, `thresholdPaceSecondsPerKm = 300 (5:00/km)`. The volume curve floors at `MIN_LONG_RUN_KM × 2 = 16 km/wk` and every pace target is the same cookie-cutter default.

Result: a runner who already runs 30 km/week at 5:30/km easy pace, but doesn't connect a wearable, gets the exact same plan as a complete beginner. The app silently produces a plan that is wrong for them and they have no obvious way to correct it during onboarding.

The fix is straightforward: instead of showing the user *zeros* on the overview screen, show *inputs* that work for everyone. Users with a wearable see them prefilled and locked (with explicit unlock to override); users without see them empty and editable.

## Goal

1. Replace the read-only `/onboarding/overview` screen with an editable baseline-stats screen that works for both wearable-connected and non-connected users.
2. Ask for two numeric fields that the plan builder actually consumes:
   - **Average weekly km over the last 4 weeks** — maps directly to `FitnessSnapshot::weeklyKmRecent4Weeks`, drives the volume curve.
   - **Easy run pace (mm:ss/km)** — maps to `FitnessSnapshot::easyPaceSecondsPerKm`, drives easy + long-run pace targets.
3. When wearable cascade data is available, prefill both fields and lock them by default. Surfacing the source ("From Apple Health"). Allow override after an explicit confirmation dialog so the runner cannot accidentally degrade plan quality.
4. Persist self-reported values on `users` so coach-chat plan rebuilds (months later) still benefit, not just the initial onboarding.

## Non-goals

- **Asking for 12-month total km** — the builder doesn't consume it. The earlier design draft floated it as an "experience" signal but `TrainingPlanBuilder` only reads recent-4-week km. YAGNI.
- **Deriving threshold / VO2max pace anchors from self-reported easy pace** (e.g. `threshold = easy − 75s`). For self-reported users, those anchors stay `null` and the builder's existing fallback (`goal_pace`-driven for race/PR, optimizer's per-type pace offsets for fitness/weight-loss) handles tempo + interval paces. HR zones (already derived in the preceding `/onboarding/zones` step) cover intensity calibration at run-time. Offset-derived anchors risked unrealistic interval paces for slow runners (8:00/km easy → 5:55/km VO2max).
- **Stale-detection / "your numbers are 6 months old" reminders** — v2 polish. Source-tracking is in place but no scheduled job nudges the runner to refresh.
- **Three-or-more questions** — the request was for "a few questions" but the builder only needs these two. More fields would add friction without lifting plan quality.
- **A separate edit-mode toggle on a read-only screen** — the lock pattern handles both states in one screen.

## Design

### High-level flow

```
[unchanged]
/onboarding/connect-health  →  /onboarding/zones  →  /onboarding/overview  →  /onboarding/form  →  /onboarding/generating

[changed]
/onboarding/overview now:
    1. GET /onboarding/profile (extended response includes `baseline` block)
    2. Render editable card with 2 fields:
         - weekly km          (CupertinoTextField, numeric, suffix "km")
         - easy run pace      (tap row → bottom-sheet dual-wheel picker)
    3. Lock state per field:
         - wearable source available     → 🔒 locked, "From Apple Health" badge
         - wearable source NOT available → unlocked, placeholder visible
    4. Tap 🔒 → CupertinoAlertDialog warning, "Edit anyway" unlocks
    5. Continue gates on validation (both fields required when not prefilled)
    6. POST /onboarding/self-reported-stats  (NEW)
    7. context.go('/onboarding/form')
```

### UI — editable overview screen

#### Wearable-prefilled (locked) state

```
┌────────────────────────────────────────┐
│   Your running baseline                │
│                                        │
│   We use these to calibrate            │
│   your training plan.                  │
│   ─────────────────────────────        │
│                                        │
│   Average weekly km (last 4 weeks)     │
│   ┌────────────────────────────┐       │
│   │  24 km                🔒   │       │
│   └────────────────────────────┘       │
│   ✓ From Apple Health                  │
│                                        │
│   Easy run pace                        │
│   ┌────────────────────────────┐       │
│   │  5:30 /km             🔒   │       │
│   └────────────────────────────┘       │
│   ✓ From Apple Health                  │
│                                        │
│              [ Continue ]              │
└────────────────────────────────────────┘
```

#### Tap 🔒 → confirmation alert (Cupertino)

```
┌─────────────────────────────────────────┐
│   Override Apple Health data?           │
│                                         │
│   These values are calculated from      │
│   your synced run history and are       │
│   likely the most accurate signal       │
│   we have.                              │
│                                         │
│   Editing them may result in a less     │
│   accurate training plan.               │
│                                         │
│   [ Cancel ]         [ Edit anyway ]    │
└─────────────────────────────────────────┘
```

After "Edit anyway": field becomes editable, lock turns to 🔓, badge changes to "Edited by you". Tap 🔓 again re-locks and restores wearable value.

#### No-wearable (unlocked) state

```
┌────────────────────────────────────────┐
│   Your running baseline                │
│                                        │
│   Tell us about your running so we     │
│   can build an accurate plan.          │
│   ─────────────────────────────        │
│                                        │
│   Average weekly km (last 4 weeks)     │
│   ┌────────────────────────────┐       │
│   │  ___ km                    │       │
│   └────────────────────────────┘       │
│    Required                            │
│                                        │
│   Easy run pace                        │
│   ┌────────────────────────────┐       │
│   │  Tap to choose             │       │
│   └────────────────────────────┘       │
│    Conversational, can hold a chat     │
│                                        │
│              [ Continue ]              │
└────────────────────────────────────────┘
```

- Continue is disabled until both fields have a value.
- Easy-pace placeholder reads "Tap to choose" (not a pre-filled number), so a no-wearable user can't accidentally submit the default 6:00 they never looked at.

#### Pace picker (bottom-sheet, dual-wheel Cupertino)

```
┌──────────────────────────────────┐
│   ✕            Easy pace      Done│
│                                  │
│       3         00               │
│       4         05               │
│      [5]    :  [30]              │
│       6         55               │
│       7                          │
│                                  │
│       minutes   seconds          │
│                                  │
│       per kilometer              │
└──────────────────────────────────┘
```

- Minute wheel: 3–12 (sensible running range, no 2:00/km speedster errors, no 13:00/km outliers).
- Second wheel: 00, 05, 10 … 55 (steps of 5 — 5-second precision is plenty for easy pace).
- Initial position when no prefill: **6:00**.
- "Done" returns the chosen value and marks the field as touched; closing via ✕ or backdrop keeps the field untouched (Continue stays disabled).

### Backend — schema, endpoint, snapshot integration

#### Migration (forward-only)

```php
// database/migrations/2026_05_11_NNNNNN_add_self_reported_stats_to_users.php
public function up(): void
{
    Schema::table('users', function (Blueprint $table): void {
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
```

Idempotent guards per `api/CLAUDE.md` migrations rule (forward-only, never edit committed migrations).

#### User model

```php
// app/Models/User.php — add to fillable + casts
#[Fillable]
protected $fillable = [
    // ... existing ...
    'self_reported_weekly_km',
    'self_reported_easy_pace_seconds_per_km',
    'self_reported_stats_at',
];

protected $casts = [
    // ... existing ...
    'self_reported_weekly_km' => 'decimal:1',
    'self_reported_easy_pace_seconds_per_km' => 'integer',
    'self_reported_stats_at' => 'datetime',
];
```

#### Endpoint

```
POST /api/v1/onboarding/self-reported-stats
Auth: auth:sanctum
```

Request body (both fields nullable — wearable user with no edits sends both null):

```json
{
  "weekly_km": 24.0,
  "easy_pace_seconds_per_km": 330
}
```

`app/Http/Requests/SelfReportedStatsRequest.php`:

```php
public function rules(): array
{
    return [
        'weekly_km' => ['nullable', 'numeric', 'min:1', 'max:300'],
        'easy_pace_seconds_per_km' => ['nullable', 'integer', 'min:180', 'max:720'],
    ];
}
```

- `weekly_km` range: 1–300 km/week (300 covers ultra-runners; <1 is meaningless).
- `easy_pace_seconds_per_km` range: 180–720 = 3:00–12:00/km. Matches `FitnessSnapshotService::PACE_SANITY_BOUNDS`.

`OnboardingController::saveSelfReportedStats($request)`:

```php
$user = $request->user();
$user->update([
    'self_reported_weekly_km' => $request->validated('weekly_km'),
    'self_reported_easy_pace_seconds_per_km' => $request->validated('easy_pace_seconds_per_km'),
    'self_reported_stats_at' => ($request->validated('weekly_km') !== null
        || $request->validated('easy_pace_seconds_per_km') !== null)
        ? now()
        : null,
]);

return response()->json(['status' => 'saved']);
```

PUT-style — replaces what's there. The `_stats_at` timestamp only ticks when at least one field was actually set; clearing both (revert to wearable cascade) clears the timestamp too.

#### Extending `GET /onboarding/profile`

```json
{
  "status": "ready",
  "metrics": { /* existing 12mo aggregate */ },
  "narrative_summary": "...",
  "baseline": {
    "weekly_km": 24.0,
    "weekly_km_source": "apple_health",
    "easy_pace_seconds_per_km": 330,
    "easy_pace_source": "apple_health"
  }
}
```

`baseline.weekly_km_source` values:
- `"apple_health"` — derived from cascade Tier 1–3, no self-report set
- `"self_reported"` — `users.self_reported_weekly_km` is non-null
- `null` — no signal (cascade hit Tier 4, no self-report)

Same for `easy_pace_source`. The Flutter app uses these to decide initial lock state per field independently — mixed prefill (km from wearable, pace from self-report) is supported by design.

Resolution logic in `OnboardingController::profile()`:

```php
// New: build baseline block alongside existing metrics + narrative
$snapshot = $fitnessSnapshotService->snapshot($user); // existing call moved up or shared

$baseline = [
    'weekly_km' => $user->self_reported_weekly_km
        ?? ($snapshot->weeklyKmRecent4Weeks > 0
            ? round($snapshot->weeklyKmRecent4Weeks, 1)
            : null),
    'weekly_km_source' => $user->self_reported_weekly_km !== null
        ? 'self_reported'
        : ($snapshot->weeklyKmRecent4Weeks > 0 ? 'apple_health' : null),
    'easy_pace_seconds_per_km' => $user->self_reported_easy_pace_seconds_per_km
        ?? $snapshot->easyPaceSecondsPerKm,
    'easy_pace_source' => $user->self_reported_easy_pace_seconds_per_km !== null
        ? 'self_reported'
        : ($snapshot->derivation !== PaceDerivation::Fallback ? 'apple_health' : null),
];
```

(Source label is `apple_health` regardless of actual wearable source — for v1 there's only Apple Health. When Garmin/Polar arrive, look at `wearable_activities.source` for the user and label accordingly.)

#### FitnessSnapshotService — self-reported priority

The self-report path is **Tier 0** (highest priority). When `self_reported_*` columns are set, they win over everything — including a freshly-derived cascade Tier 1 hit. This matches user intent: an explicit edit (after the warning dialog) means "I know better than the data."

```php
// app/Services/Onboarding/FitnessSnapshotService.php

public function snapshot(User $user): FitnessSnapshot
{
    $cascade = $this->deriveFromCascade($user); // existing cascade Tier 1-4

    // Tier 0: self-reported overrides
    $weeklyKm = $user->self_reported_weekly_km !== null
        ? (float) $user->self_reported_weekly_km
        : $cascade->weeklyKmRecent4Weeks;

    $easyPace = $user->self_reported_easy_pace_seconds_per_km
        ?? $cascade->easyPaceSecondsPerKm;

    // If either override fired, drop confidence to Low and tag derivation as SelfReported
    $usedOverride = $user->self_reported_weekly_km !== null
        || $user->self_reported_easy_pace_seconds_per_km !== null;

    if (! $usedOverride) {
        return $cascade;
    }

    return new FitnessSnapshot(
        thresholdPaceSecondsPerKm: $cascade->thresholdPaceSecondsPerKm,
        easyPaceSecondsPerKm: $easyPace,
        vo2maxPaceSecondsPerKm: $cascade->vo2maxPaceSecondsPerKm,
        confidence: PaceConfidence::Low,
        derivation: PaceDerivation::SelfReported,
        weeklyKmRecent4Weeks: $weeklyKm,
        weeklyRunsRecent4Weeks: $cascade->weeklyRunsRecent4Weeks,
        longestRunRecent8Weeks: $cascade->longestRunRecent8Weeks,
        maxHeartRate: $cascade->maxHeartRate,
        hasIntensityHistory: $cascade->hasIntensityHistory,
    );
}
```

**Key call-outs:**
- `thresholdPaceSecondsPerKm` and `vo2maxPaceSecondsPerKm` are inherited from the cascade unchanged. For a no-wearable user with cascade-Tier-4 fallback, those stay at their tier-4 defaults (300 / 270). The builder's `tempoPace()` returns null when threshold is non-null? No — it works fine with the default 300. Tempo paces will progress around 5:00/km baseline, which is generic but not broken.
- For race/PR users with `goal_time_seconds` set, the builder's tempo/interval methods anchor on goal pace anyway (`tempoPace` line 929, `intervalBlueprint` line 1029), so the cascade threshold/vo2max defaults barely matter.
- `weeklyRunsRecent4Weeks`, `longestRunRecent8Weeks` stay at cascade values (0 / 0 for no-wearable). The builder doesn't read them.
- New enum case `App\Enums\PaceDerivation::SelfReported` — extends the existing enum (`RecentThresholdEffort`, `HrZonePace`, `RecentAverage`, `Fallback`).

### Data flow per user-archetype

| Archetype | At onboarding `/overview` | Submit body | Stored on users | At plan-gen FitnessSnapshot |
|---|---|---|---|---|
| **Wearable, no edit** | Both 🔒, prefilled from cascade | `{km: null, pace: null}` | All three columns null | Cascade Tier 1–3 wins (unchanged behavior) |
| **Wearable, edits pace** | km 🔒, pace 🔓 + new value | `{km: null, pace: 330}` | `pace=330, stats_at=now()` | km from cascade, pace = 330 |
| **Wearable, edits both** | Both 🔓, both edited | `{km: 28, pace: 320}` | Both set, stats_at=now() | km = 28, pace = 320 (override wins) |
| **No wearable, both filled** | Both unlocked, both filled | `{km: 30, pace: 360}` | Both set, stats_at=now() | km = 30, pace = 360 |

### Edge cases

| Case | Behaviour |
|---|---|
| User has wearable but cascade hit Tier 4 anyway (e.g. all activities have null pace) | Treated as no-wearable for the source label. Fields unlock, user fills in. |
| User submits with `weekly_km = 1` | Accepted (validator min:1). Plan will be ramp-from-near-zero — that's fine, it's what they reported. |
| User submits `easy_pace = 720` (12:00/km) | Accepted. Builder treats as a very slow runner; volume curve floors but pace targets stay realistic. |
| User comes back to `/overview` after Continue (e.g. via back nav) | Endpoint is PUT-style, idempotent. Latest submit wins. |
| Coach-chat plan rebuild months later | `FitnessSnapshotService::snapshot()` is the same code path — picks up `self_reported_*` columns if still set. No special-casing. |
| Wearable user unlocks, edits, then re-locks before submit | Re-lock restores the original wearable value in the UI. Field is "untouched" again. Submit sends null for that field. |
| User cancels the unlock alert | Field stays locked, value unchanged. |
| Validation fails (e.g. user enters 0 km) | 422 from backend, Flutter shows inline error below the field. |

### Files

#### Backend

| File | Change |
|---|---|
| `database/migrations/2026_05_11_NNNNNN_add_self_reported_stats_to_users.php` | **new** — three nullable columns |
| `app/Models/User.php` | fillable + casts for new columns |
| `app/Http/Requests/SelfReportedStatsRequest.php` | **new** — validation rules |
| `app/Http/Controllers/OnboardingController.php` | new `saveSelfReportedStats()` action; extend `profile()` response with `baseline` block |
| `routes/api.php` | `POST /onboarding/self-reported-stats` route |
| `app/Services/Onboarding/FitnessSnapshotService.php` | wrap existing cascade with Tier-0 self-reported override |
| `app/Enums/PaceDerivation.php` | new case `SelfReported` |

#### Flutter

| File | Change |
|---|---|
| `app/lib/features/onboarding/screens/onboarding_overview_screen.dart` | rewrite from read-only stats card to editable lock-pattern card |
| `app/lib/features/onboarding/widgets/locked_stat_field.dart` | **new** — generic locked-vs-unlocked field with confirmation dialog |
| `app/lib/features/onboarding/widgets/pace_wheel_picker.dart` | **new** — dual-wheel Cupertino picker in bottom-sheet |
| `app/lib/features/onboarding/api/onboarding_api.dart` | new `saveSelfReportedStats()` call; extend profile parsing with `baseline` |
| `app/lib/features/onboarding/models/onboarding_profile.dart` (or equivalent) | new `baseline` Freezed model: `{weeklyKm, weeklyKmSource, easyPaceSecondsPerKm, easyPaceSource}` |
| `app/lib/features/onboarding/providers/onboarding_profile_provider.dart` | expose baseline + per-field touched-state |
| `app/lib/core/api/api_client.dart` (Retrofit) | new endpoint declaration |

#### Tests

| File | Coverage |
|---|---|
| `tests/Feature/Http/SelfReportedStatsTest.php` (**new**) | endpoint auth, validation, persistence, idempotency, clear-on-null |
| `tests/Feature/Http/OnboardingProfileTest.php` (extend) | baseline block source labels for wearable vs self-reported vs none vs mixed |
| `tests/Feature/Services/Onboarding/FitnessSnapshotServiceTest.php` (extend) | Tier-0 override wins over cascade Tier 1, mixed-field overrides, derivation=SelfReported flag |
| `tests/Feature/Services/Onboarding/TrainingPlanBuilderTest.php` (extend) | plan generation with self-reported snapshot (low-volume runner, slow easy pace) |
| `app/test/features/onboarding/overview_screen_test.dart` (**new**) | lock toggle, confirmation alert flow, Continue gating on validation |

## Testing

- Unit: `FitnessSnapshotServiceTest` table-tests the override priority (cascade-tier × self-report-set matrix).
- Integration: `OnboardingGeneratePlanTest` extended to seed `self_reported_*` columns and assert the generated plan's `total_km` for week 1 lands within ±15% of `self_reported_weekly_km`.
- E2E (manual): on a fresh `DevOnboardingSeeder` user, run `bash app/scripts/run-dev.sh`:
  1. Skip HealthKit → land on overview → both fields unlocked → fill 30 km/wk + 5:30/km → Continue → form → generate → confirm plan week 1 ramps from ~25 km/wk (week1 = max(baseline, peak×0.55)).
  2. Connect HealthKit → cascade Tier 1 hits → land on overview → both fields locked + "From Apple Health" → tap pace lock → confirm → Edit → set 6:00/km → Continue → confirm plan uses 6:00/km easy pace not Tier 1's value.

## Open questions

- **Source label when other sources land** (Garmin via Open Wearables, later): query `wearable_activities.source` for the user, label accordingly. Out of scope for this spec — current `source` value is always `apple_health`.
- **Should we let the user clear their self-report from a future settings screen?** v1 answer: no UI for it. Re-running onboarding (not supported today) would be one path; a profile/settings screen is v2.
- **Pre-validate easy pace against weekly km?** A runner reporting 200 km/wk at 8:00/km easy is implausible. Skip for v1 — server validates each field independently, plan-gen handles the math.

## Migration / rollout

No backfill needed — existing users have `self_reported_*` = null, behave as before (cascade-only). New columns are nullable and additive. Forward migration deploys cleanly via `php artisan migrate --force` (Laravel Cloud deploy command).
