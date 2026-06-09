# HealthKit Background Sync (Strava-style auto-sync)

**Date:** 2026-06-02
**Status:** Design — not yet implemented
**Scope:** iOS only (Apple HealthKit). Android is out of scope (HealthConnect has its own background path, deferred).

---

## Summary

Today a finished run is only ingested when the user **opens the app** (the foreground sync in `WorkoutSyncLifecycle`). The AI analysis then runs while they wait. We want the Strava behaviour: the run syncs **in the background** right after it finishes, the backend analyses it, and the existing `WorkoutAnalyzed` push lands **before** the user opens the app.

**The backend is already complete.** `POST /wearable/activities` → match → compliance score → `GenerateActivityFeedback` (Pro-gated) → writes `training_results.ai_feedback` → sends the `WorkoutAnalyzed` APNs push. The push type is already routed on tap (`PushService.routeFromPayload` → `workout_analyzed`, `push_service.dart:48`). **No backend changes, no new push types, no new endpoints.**

The **only** missing piece is the trigger that pushes the new workout to `/wearable/activities` while the app is backgrounded/terminated. That is a small native-iOS addition.

**Design in one line:** a native Swift `HKObserverQuery` with background delivery that, when woken, fetches new runs via an anchored query and POSTs them to the existing endpoint **in Swift** — because the Flutter/Dart engine is not running on a background launch. The current foreground sync stays unchanged as the guaranteed fallback.

### Non-goals (kept deliberately minimal)
- No new Notification classes / no new push payloads — reuse `WorkoutAnalyzed`.
- No backend changes.
- No GPS routes in the background (heavy) — the existing foreground route-backfill keeps owning polylines.
- No `user_notifications` inbox row for analyzed runs (push only, as today).
- No locale bridge to native (the AI feedback + push already localize via `$user->locale` in the queue worker — the POST request header is irrelevant for that).

---

## Current state (for reference)

| Piece | Where | Note |
|---|---|---|
| Foreground sync triggers | `wearable/widgets/workout_sync_lifecycle.dart` | app-resume + cold-start, 90s debounce — **stays as fallback** |
| Workout → payload shape | `health_kit_service.dart:228` `_shape()` | Swift must mirror this exactly |
| Run-type mapping | `health_kit_service.dart:259` `_normalizeType()` | `.running` / `.runningTreadmill` → `"Run"`, else skip |
| Ingest endpoint | `POST /wearable/activities`, body `{ "activities": [...] }`, Sanctum auth, free (not Pro-gated) | upsert on `(user, source, source_activity_id)` |
| Sanctum token | `flutter_secure_storage` key `sanctum_token` (`token_storage.dart:6`) | not read directly by Swift — see config bridge |
| Base URL | compile-time `String.fromEnvironment('API_BASE_URL')` (`dio_client.dart:12`) | not visible to native — see config bridge |
| Native HK pattern | `WorkoutRoute.swift`, `HealthKitPersonalRecords.swift` | `HKHealthStore()` + `requestAuthorization` + query; mirror this style |
| Native bridge registration | `AppDelegate.didInitializeImplicitFlutterEngine` | register the new channel here |
| Entitlements | `Runner.entitlements` | HealthKit present; **background-delivery key absent** |
| Push already exists | `WorkoutAnalyzed` + tap routing `push_service.dart:48` | nothing to add |

---

## Architecture

```
Run finishes → Apple Watch syncs to iPhone Health
  → iOS wakes the app (HKObserverQuery, .immediate)            [native, no Dart engine]
    → HealthKitBackgroundSync fetches NEW runs (anchored query)
      → builds payload (mirror _shape) + HR via HKStatisticsQuery
        → URLSession POST {activities:[...]} to /wearable/activities
          → [backend, unchanged] match → score → AI → WorkoutAnalyzed push ✅
    → persist new anchor, call observer completion handler

Fallback (unchanged): app opened → WorkoutSyncLifecycle foreground sync
```

Two new native files + one thin Dart wrapper + one entitlement. No more.

### Component 1 — `ios/Runner/HealthKitBackgroundSync.swift` (new)

A singleton (`HealthKitBackgroundSync.shared`) owning the observer + the sync logic.

Responsibilities:
- `start()` — idempotent. Guard on `HKHealthStore.isHealthDataAvailable()` and on a configured token (no token = user signed out = no-op). Request read auth for `workoutType()` + `quantityType(.heartRate)` (best-effort; normally already granted). Register one long-lived `HKObserverQuery` for `HKObjectType.workoutType()`, then `enableBackgroundDelivery(for: workoutType, frequency: .immediate, withCompletion:)`. Store the running query so a second `start()` doesn't stack observers.
- `stop()` — `disableBackgroundDelivery` + `store.stop(observerQuery)`. Called on logout.
- Observer `updateHandler` → `handleUpdate(completionHandler:)`:
  1. Read persisted `HKQueryAnchor` from `UserDefaults` (archived via `NSKeyedArchiver`).
  2. **Priming case (anchor == nil):** run the anchored query once to obtain a baseline anchor, persist it, **do not POST** (the foreground sync owns historical backfill). Call the completion handler and return. This avoids a huge first batch.
  3. **Normal case:** run `HKAnchoredObjectQuery(type: .workoutType(), predicate: runningPredicate, anchor: saved, limit: 50)`. For each returned `HKWorkout` that is `.running`/`.runningTreadmill` with `totalDistance > 0`, build the payload + fetch HR (avg/max) via `HKStatisticsQuery(predicateForObjects(from: workout))`.
  4. POST once with all new activities batched.
  5. **On HTTP 2xx:** persist the new anchor (so they're not re-sent). **On failure:** keep the old anchor (retry on next wake).
  6. **Always** call the observer completion handler (after the network call resolves) — failing to do so causes a watchdog crash and back-off that disables delivery.

Key correctness points:
- `runningPredicate` = `HKQuery.predicateForWorkouts(with: .running)` OR-ed with `.runningTreadmill`. (Backend filters to runs anyway + upsert is idempotent, so this is just to keep payloads small.)
- Time budget is ~15-30s; one batch + a few HR stat queries is well within it. `limit: 50` caps a pathological catch-up.
- All HealthKit completion work hops onto the bridge's flow exactly like `WorkoutRoute.swift`.

### Component 2 — config bridge `nl.runcoach/bg-sync` (in the same Swift file)

The native sync needs the **base URL** and **bearer token**, which live in the Dart layer. Rather than reverse-engineer `flutter_secure_storage`'s Keychain service from Swift (fragile), Dart pushes them down explicitly.

MethodChannel `nl.runcoach/bg-sync`:
- `configure(baseUrl: String, token: String)` — store `baseUrl` in `UserDefaults` (non-secret), store `token` in the **Keychain** (`kSecClassGenericPassword`, service `nl.runcoach.bgsync`, account `sanctum_token`), then call `start()`.
- `clear()` — delete the Keychain token, call `stop()`. (Logout.)

Token in Keychain (not UserDefaults) because it's a credential. Base URL in UserDefaults is fine.

### Component 3 — `AppDelegate.swift` changes

- In `didInitializeImplicitFlutterEngine(...)`: register the `nl.runcoach/bg-sync` channel (same `registrar(forPlugin:)` pattern as the other four bridges).
- In `application(_:didFinishLaunchingWithOptions:)`: call `HealthKitBackgroundSync.shared.start()` **early and synchronously** so the observer is armed before iOS delivers a pending update on a background launch. (No-op when no token is configured.)

No `launchOptions` key inspection is needed — re-arming the observer on every launch is what the HealthKit background-delivery contract requires.

### Component 4 — Dart wrapper `BackgroundSyncService` (new, thin)

`app/lib/features/wearable/services/background_sync_service.dart` — a ~30-line `MethodChannel('nl.runcoach/bg-sync')` wrapper with `configure({required String baseUrl, required String token})` and `clear()`. iOS-only (guard with `Platform.isIOS` / `!kIsWeb`).

Wire-in points (mirror how push registration is already wired):
- **After login** — `Auth.loginWithApple` and the dev-login path, right after `tokenStorage.setToken(...)` (`auth_provider.dart:45` / `:71`) → `configure(baseUrl, token)`.
- **Cold start** — `Auth.loadProfile` (`auth_provider.dart:79`), alongside the existing `registerIfPermitted()` call (`:87`), when a token is present → `configure(baseUrl, token)` (refreshes the stored creds).
- **Logout** — `Auth.logout` after `tokenStorage.clearToken()` (`auth_provider.dart:104`) → `clear()`.

`baseUrl` is the existing `baseUrl` const from `dio_client.dart`. `token` is read from `tokenStorage`.

### Component 5 — Entitlement + capability

- `Runner.entitlements`: add
  ```xml
  <key>com.apple.developer.healthkit.background-delivery</key>
  <true/>
  ```
- Enable **HealthKit → Background Delivery** on App ID `com.erwinwijnveld.runcoach` at developer.apple.com (self-serve checkbox; Automatic Signing regenerates the profile).
- **No `UIBackgroundModes`** entry — pure `HKObserverQuery` delivery does not use Background Modes.
- **No new usage-description string** required; the existing `NSHealthShareUsageDescription` covers it (optionally reword to mention automatic/background sync).

### Component 6 — pbxproj registration

`HealthKitBackgroundSync.swift` must be added to `Runner.xcodeproj/project.pbxproj` in the 4 standard places (PBXBuildFile, PBXFileReference, PBXGroup, PBXSourcesBuildPhase) — mirror `WorkoutRoute.swift` / `PushNotifications.swift`, or Xcode build fails with "Cannot find 'HealthKitBackgroundSync' in scope".

---

## Payload contract (Swift mirrors `_shape`)

Per workout, the POST body item must match the Dart shape so the existing backend validation passes unchanged:

```json
{
  "source": "apple_health",
  "source_activity_id": "<HKWorkout.uuid as String>",
  "source_user_id": "<workout.sourceRevision.source.bundleIdentifier>",
  "type": "Run",
  "name": null,
  "distance_meters": 10234,
  "duration_seconds": 3138,
  "elapsed_seconds": 3138,
  "start_date": "2026-06-02T07:01:00.000Z",
  "end_date":   "2026-06-02T07:53:18.000Z",
  "calories_kcal": 612,
  "raw_data": {},
  "average_heartrate": 162.0,   // omit/null when no HR samples
  "max_heartrate": 178.0
}
```

Wrapper: `{ "activities": [ ... ] }`. Headers: `Authorization: Bearer <token>`, `Accept: application/json`, `Content-Type: application/json`. Dates in UTC ISO-8601 (matches `start.toUtc().toIso8601String()`). HR via `HKStatisticsQuery` with `.discreteAverage` + `.discreteMax`, clamped to 30-250 bpm (mirrors `_fetchHeartRateForWorkout`), omitted when absent.

> Side benefit: the native HR query uses `predicateForObjects(from: workout)` — strictly workout-scoped — which is *more accurate* than the Dart time-window query (resolves a known deferred-polish item that over-counts overlapping samples).

---

## Decisions & edge cases

- **Force-quit caveat (accepted):** if the user swipes the app away in the app switcher, iOS stops background delivery until the next manual launch. This is an OS rule — Strava has the same limitation. The foreground sync remains the guaranteed path; background delivery is an enhancement. Document this in user-facing expectations if needed.
- **Apple Watch only:** `HKWorkout` run samples come from an Apple Watch (or another app that writes workouts to Health). A plain iPhone in a pocket creates no workout object. iPhone-only users without a recorder app simply have nothing to deliver — they fall back to foreground sync (also nothing to sync). No special handling.
- **Latency is best-effort:** `.immediate` is honoured for workouts but delivery is opportunistic (device locked / low-power can delay it). Expect "usually minutes."
- **Dedupe:** anchored query (only-new) + backend upsert on `(user, source, source_activity_id)` = double safety. Re-delivery of the same workout is harmless.
- **User switch on one device:** `clear()` on logout deletes the token and stops the observer; the next `configure()` after a fresh login re-primes. The anchor is per-HealthKit-store (account-agnostic); priming-without-posting on first run means a new account won't get a giant historical batch in the background — its history comes from the foreground onboarding sync as today. (Optionally also reset the saved anchor in `clear()` for cleanliness.)
- **Not Pro:** the AI analysis job is already Pro-gated server-side. A non-Pro user's background POST still ingests the run (free) so history keeps building; no AI/push fires. No client-side gating needed.
- **Anchor storage:** `UserDefaults` key `bg_sync_workout_anchor_v1` (archived `HKQueryAnchor`). Versioned suffix so a future schema change can invalidate it.

---

## Permissions & App Review

- **Entitlement:** `com.apple.developer.healthkit.background-delivery` (self-serve; no Apple approval form).
- **No new user permission prompt** — existing HealthKit read consent covers background delivery.
- **App Review (App Store + first external TestFlight build):**
  - Privacy policy linked in App Store Connect **and** in-app, explicitly stating health data is read (incl. in the background) and used only for training analysis — **not** advertising/data-mining (Guideline 5.1.3).
  - Accurate `NSHealthShareUsageDescription`.
  - Review notes (2-3 sentences): "Background delivery wakes the app to analyse newly-completed runs and notify the user; health data is never shared with third parties or used for ads."
  - No analytics/ad SDK may touch health data.
  - ⚠️ External TestFlight triggers Beta App Review on the **first build of a group** — satisfy the above before external testing, not just at App Store submission. Internal testers (≤100) are exempt.

---

## Testing plan

Background delivery **cannot be tested on the simulator** — physical device required.

1. **Foreground observer fire:** with the app open, finish/add a workout → observer fires → POST → backend row appears. (Fastest dev loop; validates the query + payload + POST.)
2. **Backgrounded app:** background the app (don't force-quit), record a short run on a paired Apple Watch → confirm the run is ingested and the `WorkoutAnalyzed` push arrives without opening the app.
3. **Terminated (not force-quit):** let iOS reclaim the app (or wait) → record a workout → confirm relaunch + delivery.
4. **Force-quit:** confirm delivery does NOT fire (expected) and that foreground sync recovers it on next open.
5. **Priming:** fresh install/login → confirm the first observer fire does not dump the full history (anchor primed, no posting); a subsequent new run does post.
6. **Logout:** `clear()` stops delivery; no posts after logout.
7. **Completion handler:** verify no watchdog crash on slow network (simulate with a throttled connection); anchor not advanced on failure.

Helper for tests 1/5: a tiny debug-only "write a sample HKWorkout" path (or the Apple Health app where possible) avoids needing a real run each cycle.

---

## Effort estimate

~1 to 1.5 weeks, testing-on-device being the long pole:

| Task | Est. |
|---|---|
| `HealthKitBackgroundSync.swift` (observer + anchor + sync + config bridge) | 2-2.5 d |
| `AppDelegate` wiring + entitlement + App ID + pbxproj | 0.5 d |
| Dart `BackgroundSyncService` + 3 wire-in points | 0.5 d |
| Edge cases (priming, logout reset, failure handling) | 0.5 d |
| On-device testing (the 7 scenarios) | 1-2 d |
| App Review prep (privacy policy + notes) | 0.5 d |

**Cost impact:** ~1 cent of AI per analyzed run (Sonnet, mostly cache-hit), Pro-users only. Negligible.

---

## File checklist

**New**
- `app/ios/Runner/HealthKitBackgroundSync.swift`
- `app/lib/features/wearable/services/background_sync_service.dart`

**Changed**
- `app/ios/Runner/AppDelegate.swift` — register `nl.runcoach/bg-sync`; `start()` in `didFinishLaunchingWithOptions`
- `app/ios/Runner/Runner.entitlements` — add background-delivery key
- `app/ios/Runner.xcodeproj/project.pbxproj` — register the new Swift file (×4)
- `app/lib/features/auth/providers/auth_provider.dart` — `configure()` after login + in `loadProfile`; `clear()` in `logout`
- (Apple Developer portal) — enable HealthKit Background Delivery on the App ID

**Unchanged (intentionally)**
- All backend code, `WorkoutAnalyzed` push, `/wearable/activities`, foreground `WorkoutSyncLifecycle`.

---

## Out of scope / future
- GPS route delivery in the background (kept on the foreground backfill path).
- A `BGTaskScheduler` belt-and-suspenders fallback for missed deliveries (optional; not needed for v1).
- Android HealthConnect background sync.
- An in-app `user_notifications` inbox row for analyzed runs.
