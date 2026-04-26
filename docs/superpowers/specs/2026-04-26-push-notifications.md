# Push notifications (iOS, APNs-direct)

**Status:** design proposed, awaiting approval
**Author:** Erwin + Claude
**Date:** 2026-04-26

## Problem

Plan generation runs as a background queue job (`GeneratePlan`, ~60–110 s). Today the Flutter app shows a polling loading screen and only sees the result if the user keeps the app foregrounded. If they background it (lock the phone, open another app) they never know the plan is ready until they re-open RunCoach. Same for any other long-running async task we add later (weekly insight, activity feedback, coach reply on a slow turn).

## Goal

Send a push notification to the user's device the moment plan generation completes (or fails). Lay groundwork so any future server-side event (`GenerateActivityFeedback`, `GenerateWeeklyInsight`, coach proposal ready) can fire a push with one extra line in the dispatching job.

Single-channel for now: **APNs direct from Laravel**. Android is on the roadmap but a full Android port is a much larger lift (HealthConnect, alternative auth) — push is cleanly separable and we'll add an FCM channel when Android lands. See **Migration path** at the bottom.

## Non-goals

- Android push (deferred until Android port).
- Rich notifications (images, custom UI). Plain title+body+deeplink only.
- Notification categories / actions ("Accept plan" buttons). Tapping opens the app at the right route, that's it.
- In-app notification center / unread inbox. The chat already serves that role for coach replies.
- Marketing pushes / scheduled engagement nudges. Only event-driven, user-initiated work for v1.
- Silent / background data pushes (`content-available: 1`). Pure user-visible alerts.

## Design

### Apple Developer (one-time setup)

1. **APNs auth key.** Apple Developer → Keys → "+" → enable Apple Push Notifications service (APNs) → download `.p8` file. ONE key per team, never expires unless revoked. Store the `.p8` plus its Key ID and Team ID in Laravel's secrets.
2. **App ID capability.** developer.apple.com → Identifiers → `com.erwinwijnveld.runcoach` → tick "Push Notifications". Same flow we already used for Sign in with Apple + HealthKit.
3. **Entitlement.** Add `aps-environment = development` (debug) / `production` (release) to `app/ios/Runner/Runner.entitlements`. Xcode auto-detects which based on build configuration when the entitlement value is `development`; for App Store builds Apple substitutes the production environment server-side. We'll set it to `development` in the file and rely on that.
4. **Info.plist.** Already does NOT need a usage string for push (that prompt is built-in). Optional: add `UIBackgroundModes` → `remote-notification` later if/when we want silent background delivery; not in v1.

### Backend

#### `device_tokens` table (new)

```
id                bigint pk
user_id           bigint fk → users (cascade on delete)
token             string                — APNs device token, hex 64-char today, but APNs has hinted at variable length, store as VARCHAR(255)
platform          string                — 'ios' for now; 'android' added later
app_version       string nullable       — e.g. "1.0.0+7", helps debug "this token came from a build that no longer exists"
last_seen_at      timestamp             — bumped on every register call so we can prune stale tokens
created_at, updated_at

unique(user_id, token)                  — one row per (user, token)
index(token)                            — for APNs feedback / `Unregistered` cleanup lookups
```

Eloquent: `App\Models\DeviceToken`, fillable, `belongsTo(User::class)`, plus `User::deviceTokens(): HasMany`.

#### Registration endpoint

```
POST /api/v1/devices                                          (auth:sanctum)
body: { token: "abc…", platform: "ios", app_version: "1.0.0+7" }
202 No Content
```

Idempotent: `DeviceToken::updateOrCreate(['user_id', 'token'], [...])`, bumping `last_seen_at` to `now()`. App calls this on every cold start — keeps `last_seen_at` fresh, lets us prune devices last seen > N months ago later.

```
DELETE /api/v1/devices                                        (auth:sanctum)
body: { token: "abc…" }
204 No Content
```

For sign-out: deletes the row so a logged-out device stops receiving pushes for the previous user. Called from Flutter when `authProvider.logout()` runs.

Controller: `App\Http\Controllers\DeviceTokenController` — two methods, store + destroy.

#### Notification channel

Install:
```bash
composer require laravel-notification-channels/apn
```

`config/services.php` → add `apn` block with `key_id`, `team_id`, `private_key_path`, `production` (false for dev/local, true otherwise — keyed off `APP_ENV`). Env vars: `APN_KEY_ID`, `APN_TEAM_ID`, `APN_PRIVATE_KEY_PATH` (filesystem path inside the deployed app, with the `.p8` file uploaded as a secret on Laravel Cloud).

Pure-PHP package, no native extensions, talks APNs HTTP/2 directly. Trusted, ~1.4k stars.

#### Notification classes

Two notifications mapping to the only two new outcomes for v1:

`app/Notifications/PlanGenerationCompleted.php`
- `via($notifiable)` → `[ApnChannel::class]`
- `toApn($notifiable)` → builds an `ApnMessage` with title `"Your training plan is ready"`, body `"{coach style} plan for {goal_name or distance}. Open to review."`, custom payload `{ type: "plan_generation_completed", conversation_id: "uuid" }` for deep linking.
- Constructor takes the `PlanGeneration $row` (or just the `conversation_id` + `proposal_id` to keep it serializable).

`app/Notifications/PlanGenerationFailed.php`
- Same shape. Title `"Plan generation hit a snag"`, body `"Tap to try again."`, payload `{ type: "plan_generation_failed" }`.

Both implement `routeNotificationForApn()` on the User model — returns the user's array of token strings (`$user->deviceTokens->where('platform', 'ios')->pluck('token')->all()`).

#### Wire into `GeneratePlan`

Two new lines, in `app/Jobs/GeneratePlan.php`:

```php
public function handle(OnboardingPlanGeneratorService $generator): void
{
    // ... existing code …
    $row->update([
        'status' => PlanGenerationStatus::Completed,
        'conversation_id' => $result['conversation_id'],
        'proposal_id' => $result['proposal_id'],
        'completed_at' => now(),
    ]);

    $row->user->notify(new PlanGenerationCompleted($result['conversation_id']));   // ← NEW
}

public function failed(Throwable $e): void
{
    // ... existing code …
    $row->update([
        'status' => PlanGenerationStatus::Failed,
        'error_message' => $e->getMessage(),
        'completed_at' => now(),
    ]);

    $row->user->notify(new PlanGenerationFailed());                                 // ← NEW
}
```

Both notifications implement `ShouldQueue` so the APNs HTTP call runs on the queue worker, not in the request thread. This matters: a single APNs round-trip is fast (~50 ms) but if the user has 3 devices and APNs is having a bad day, a synchronous `notify()` could stall the job's `handle()` return for seconds.

#### Stale token cleanup

APNs returns a `410 Unregistered` response when a token belongs to an app that's been deleted, or when the token has been invalidated (user disabled push in Settings). The `laravel-notification-channels/apn` package surfaces this via the `NotificationFailed` event with a reason. Add a listener `App\Listeners\PruneInvalidApnsToken` that deletes the offending `device_tokens` row when the reason is `Unregistered` or `BadDeviceToken`. Auto-discovered from its `handle(NotificationFailed $event)` signature, same pattern as `RecordAgentTokenUsage`.

### Flutter

#### Permission prompt timing

**Apple's rule:** asking for notification permission immediately on first launch tanks opt-in rate (~30%). Ask after the user has experienced enough value to want the prompt (~60%+).

Where: at the end of onboarding, on the first show of `OnboardingGeneratingScreen`. Right when the user clicks "Generate my plan" we call:

```dart
await FlutterLocalNotifications().requestPermission();
// or via UNUserNotificationCenter MethodChannel — we'll pick the package below
```

If the user denies, we don't pester. We surface a banner-card on the dashboard later ("Get notified when your plan's ready" → opens iOS Settings) only if they have a pending plan generation AND no APNs token registered.

#### Package choice

Two reasonable picks, both maintained:

| Package | Pros | Cons |
|---|---|---|
| `firebase_messaging` | Industry default, handles APNs token retrieval + FCM fallback later | Drags in Firebase setup we explicitly chose to avoid in option A |
| `flutter_apns_only` | No Firebase dependency, pure APNs registration | Smaller community, last release ~Q3 2025 |

We'll go with **a thin native MethodChannel** in `ios/Runner/AppDelegate.swift` instead — same approach we already use for HealthKit personal records. Two channels: one to request permission + register, one to handle delivery callbacks. Saves a Pod dependency and keeps the iOS layer fully under our control. ~80 lines of Swift, well-documented Apple territory.

For local notifications (foreground display while the app is open) we don't need a separate package — when an APNs message arrives in foreground, our `userNotificationCenter(_:willPresent:)` delegate decides whether to show it as a banner or surface in-app via `MethodChannel.invokeMethod('onPushReceived', payload)`.

#### Token registration flow

```
App cold-start
  └── auth state hydrated, user signed in
        └── PushService.registerIfPermitted()
              ├── current settings == authorized?
              │     └── yes → request APNs registration
              │           └── didRegisterForRemoteNotificationsWithDeviceToken
              │                 └── MethodChannel → Dart → POST /devices
              └── no → no-op (user denied or hasn't been asked yet)
```

After onboarding's "Generate my plan" tap:
```
PushService.requestPermissionAndRegister()
  └── UNUserNotificationCenter.requestAuthorization
        └── on grant: registerForRemoteNotifications + POST /devices
        └── on deny:  store rejected=true in shared prefs (suppresses re-prompt)
```

#### Tap handling

Payload shape from the backend (in the `aps.alert` + custom keys):
```json
{
  "aps": { "alert": { "title": "...", "body": "..." }, "sound": "default" },
  "type": "plan_generation_completed",
  "conversation_id": "uuid-v4-string"
}
```

`UIApplicationDelegate.didReceiveRemoteNotification` → forwards via MethodChannel to `PushService.onTap(payload)` → routes:

| `type` | route |
|---|---|
| `plan_generation_completed` | `/coach/chat/{conversation_id}` |
| `plan_generation_failed`    | `/onboarding/generating` (which auto-shows error UI) |
| (anything else)             | `/dashboard` (safe default) |

Cold-launch case: when the app is launched FROM a tap, `application(_:didFinishLaunchingWithOptions:)` receives the payload via `launchOptions[.remoteNotification]`. Stash it in a static var, replay it after `runApp()` and the auth state is hydrated.

#### Sign-out

`authProvider.logout()` already POSTs `/auth/logout` and clears the secure-storage token. Add: `await PushService.unregister()` which calls `DELETE /api/v1/devices` with the current APNs token, then `UIApplication.unregisterForRemoteNotifications()`. Order matters: backend delete first (uses the token to scope the row), then iOS unregister.

### Filament admin (optional, easy to add)

Add a "Send test notification" button on the User detail page in Filament for debugging. Calls a controller that sends a `TestPushNotification` to the user. Five lines of code. Only enabled in `local` env.

## Flow diagrams

**Plan completion:**
```
GeneratePlan job ends
  ↓
$user->notify(new PlanGenerationCompleted($cid))
  ↓ ShouldQueue → re-enqueued
Notification worker picks up
  ↓
For each device_tokens row:
  POST https://api.push.apple.com/3/device/{token}
       headers: apns-topic=com.erwinwijnveld.runcoach, authorization=bearer <jwt>
       body: { aps: {...}, type, conversation_id }
  ↓ 200 OK → done
  ↓ 410 Unregistered → NotificationFailed event → PruneInvalidApnsToken deletes row
```

**Cold-start tap:**
```
User taps banner → iOS launches RunCoach with launchOptions[.remoteNotification]
  ↓ AppDelegate stashes payload
  ↓ Flutter boots, ProviderScope hydrates auth
  ↓ Router redirect resolves (signed in + onboarded)
  ↓ PushService replays stashed payload via MethodChannel
  ↓ context.go('/coach/chat/{conversation_id}')
```

## Testing

### Backend

- `tests/Feature/Http/DeviceTokenControllerTest.php` — POST + DELETE happy paths, dedup on `(user_id, token)`, requires auth.
- `tests/Feature/Notifications/PlanGenerationCompletedTest.php` — assert `Notification::fake()` then `$user->notify(new …)`; confirm the rendered `ApnMessage` has the right title/body/payload.
- `tests/Feature/Jobs/GeneratePlanTest.php` — extend existing test: `Notification::fake()`, run job, assert `Notification::assertSentTo($user, PlanGenerationCompleted::class)`. Same for `failed()`.
- `tests/Feature/Listeners/PruneInvalidApnsTokenTest.php` — fire a `NotificationFailed` event with reason `Unregistered`, assert the matching `device_tokens` row is gone.

### Flutter

- No automated tests (matches existing project conventions).
- Manual QA checklist:
  - Fresh install → no permission prompt before form submit.
  - Tap "Generate my plan" → permission dialog appears.
  - Allow → background the app → wait for plan completion → banner appears.
  - Tap banner → lands on `/coach/chat/{conversation_id}` with the proposal.
  - Sign out → trigger another plan generation by signing in to a different test user → no banner on the previous device.
  - Deny push, then re-enable in Settings → re-cold-start → banner works.

### Apple Push Notifications sandbox

For local + TestFlight testing, the development APNs server (`api.development.push.apple.com`) is used by the package when `services.apn.production` is false. Production builds (signed via App Store) go to the production server. The same `.p8` key works against both — Apple Developer doesn't issue separate sandbox/prod keys.

## Migration path: adding FCM later (Android)

When we get serious about Android:

1. Install `laravel-notification-channels/fcm-with-new-http-v1` (or `kreait/firebase-php` if we want raw control).
2. Add `'platform' => 'android'` rows to `device_tokens` (column already exists, no migration).
3. Each `Notification` class adds an `FcmChannel` to its `via()` array, plus a `toFcm()` method building the FCM payload (mirrors `toApn()`, slightly different shape).
4. Routing: `User::routeNotificationForFcm()` returns the Android tokens.
5. Flutter: add Firebase project, drop `GoogleService-Info.plist` + `google-services.json`, swap or supplement the native MethodChannel with `firebase_messaging`. Yes this introduces the Firebase setup we'd skipped — that's the deliberate trade.

The schema, controllers, and notification classes carry over with zero changes — only an extra channel per notification and an Android token type.

## Open questions

- Do we want to throttle push for users who keep the app foregrounded throughout plan generation? (i.e. if WebSocket / SSE was in front of us, we'd skip the push since they're already watching.) **Decision:** no throttling for v1. Simpler, push is the safety net. The Flutter foreground handler can choose to suppress the banner if the user is already on `/onboarding/generating` or `/coach/chat/{cid}`.
- TTL on APNs payload (`apns-expiration` header)? Default = 0 = "deliver immediately or drop". For plan completion, "deliver as soon as the device wakes up within the next few hours" feels right → set `apns-expiration` to `now() + 4 hours`. Makes the message survive a brief offline window.
- Per-user push preferences (mute notifications without disabling at OS level)? Not v1. Add a `users.push_preferences` JSON column when a second push category lands and someone wants weekly insights muted but plan readiness on.
