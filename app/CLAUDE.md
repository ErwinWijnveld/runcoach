# RunCoach Flutter App

Mobile app for **RunCoach** — personal AI running coach. iOS-only at the moment because activity data comes from Apple HealthKit and auth uses Sign in with Apple. See `../CLAUDE.md` for the monorepo overview and `../api/CLAUDE.md` for the backend.

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (iOS-only in production — Android requires HealthConnect work + Sign in with Apple alternative) |
| State management | Riverpod with `@riverpod` code generation |
| Models | Freezed 3.x with `sealed class` syntax, JSON serialization |
| API client | Dio + Retrofit (code-generated per feature) |
| Routing | GoRouter with auth redirect guards |
| Secure storage | `flutter_secure_storage` (Sanctum token) |
| Auth | `sign_in_with_apple` (native iOS dialog → identity-token JWT → backend) |
| Wearable data | `health` (Apple HealthKit reads, Android Health Connect later), `permission_handler` |

**Important:** This project does NOT use `riverpod_lint` or `custom_lint` (version conflicts with Freezed 3.x). Don't add them.

## Project structure (feature-first)

```
app/lib/
├── main.dart                      — App entry, ProviderScope
├── app.dart                       — CupertinoApp.router setup (see note below about localization delegates)
├── core/
│   ├── api/
│   │   ├── dio_client.dart        — Dio singleton with baseUrl + interceptor
│   │   └── auth_interceptor.dart  — Attaches Sanctum token, clears on 401
│   ├── storage/
│   │   └── token_storage.dart     — flutter_secure_storage wrapper
│   ├── theme/
│   │   └── app_theme.dart         — Warm earth-tone theme + AppColors
│   └── utils/
│       └── json_converters.dart   — Safe num/String converters for JSON
├── router/
│   └── app_router.dart            — GoRouter with auth redirect + bottom nav shell
└── features/
    ├── auth/                      — Welcome, Apple Sign-In, profile
    ├── wearable/                  — HealthKit reads + ingestion API
    │   ├── data/wearable_api.dart           — POST /wearable/activities
    │   └── services/health_kit_service.dart — `health` package wrapper
    ├── onboarding/                — Connect-health, overview, form, generating
    ├── dashboard/                 — Home tab with weekly summary
    ├── schedule/                  — Weekly plan, day detail, compliance result
    ├── coach/                     — AI chat list, chat UI, message bubbles, proposals
    ├── goals/                     — Goal list, create, detail
    └── organization/              — Connections, find org, invite detail
```

Each feature folder has this internal structure:
```
feature/
├── data/        — Retrofit API client + provider
├── models/      — Freezed data classes
├── providers/   — Riverpod providers (state/actions)
├── screens/     — UI screens
└── widgets/     — (optional) feature-specific widgets
```

## Key architectural decisions

### 1. Riverpod with `@riverpod` code generation

All providers use the code-gen syntax, not the manual `Provider`/`StateNotifierProvider`. Example:
```dart
@riverpod
Future<List<Race>> races(Ref ref) async {
  final api = ref.watch(raceApiProvider);
  // ...
}

@riverpod
class CoachChat extends _$CoachChat {
  @override
  Future<List<CoachMessage>> build(String conversationId) async { ... }
}
```

Run `dart run build_runner build --delete-conflicting-outputs` after changes.

### 1b. Mutator providers — capture deps before the await

Any `@riverpod` mutator method that does `await api.X(); ref.read(other).Y();` will eventually crash with **"Cannot use the Ref of X after it has been disposed"** the moment the host widget unmounts mid-request (e.g. user taps Apply in a sheet, then dismisses or navigates before the API responds — autoDispose tears the provider down → the post-await `ref.read` runs on a disposed ref). Symptom: a Cupertino "Couldn't match that run" alert with the dispose stack.

**Rule**: in any mutator that awaits, capture every cross-provider handle BEFORE the first `await`. The captured object reference stays valid through the async gap because the target provider has its own lifetime (and `PlanVersion` is `keepAlive: true` regardless). Example:

```dart
Future<TrainingResult> match({...}) async {
  final api = ref.read(scheduleApiProvider);
  final planVersion = ref.read(planVersionProvider.notifier);   // capture before await
  final response = await api.matchActivity(...);
  planVersion.bump();                                            // ← safe, no ref.read here
  return TrainingResult.fromJson(...);
}
```

If the mutator ALSO writes its own `state =` after the await (i.e. surfaces loading/error via `AsyncValue<T>`), guard each post-await state setter with `if (!ref.mounted) return;` — the captured-deps trick doesn't help with `state` because that's the disposed Notifier's own setter. Canonical references: `features/schedule/providers/schedule_provider.dart` (state-less mutators) + `features/goals/providers/goal_provider.dart::GoalActions::createGoal` (mutator with state).

### 2. Freezed 3.x with `sealed class`

All models must use `sealed class` (not just `class`) — this is a Freezed 3.x requirement. Example:
```dart
@freezed
sealed class Race with _$Race {
  const factory Race({ ... }) = _Race;
  factory Race.fromJson(Map<String, dynamic> json) => _$RaceFromJson(json);
}
```

### 3. MySQL decimal fields need safe converters

The backend returns decimal columns (`total_km`, `compliance_score`, etc.) as **strings**, not numbers. All `double` and `int` fields in Freezed models that come from decimal/numeric MySQL columns must use safe converters from `core/utils/json_converters.dart`:

```dart
@JsonKey(name: 'total_km', fromJson: toDouble) required double totalKm,
@JsonKey(name: 'target_km', fromJson: toDoubleOrNull) double? targetKm,
@JsonKey(name: 'order', fromJson: toInt) required int order,
```

Without these, you'll get runtime errors like `type 'String' is not a subtype of type 'num' in type cast`.

### 4. Retrofit API return types

All Retrofit methods return `Future<dynamic>` (not `Future<Map<String, dynamic>>`) because the generator produces invalid code for `Map<String, dynamic>` return types. The providers handle parsing:

```dart
@GET('/dashboard')
Future<dynamic> getDashboard();
```

Exception: methods that return a known Freezed model directly (like `Future<DashboardData>`) work fine — only `Map<String, dynamic>` returns are problematic.

### 5. Conversation IDs are UUIDs (strings)

The AI coach conversation IDs come from the Laravel AI SDK and are UUIDs (36-char strings). Do NOT use `int` for conversation IDs anywhere:
- `Conversation.id` is `String`
- `CoachMessage.id` is `String`
- Route params: `state.pathParameters['conversationId']!` (no `int.parse`)
- API client: `@Path() String id` for conversation endpoints

### 5b. CupertinoApp + Material widgets

`app.dart` is a `CupertinoApp.router`, but we reuse Material widgets (`ElevatedButton`, `showModalBottomSheet`, etc.) throughout the coach UI. For these to work, `localizationsDelegates` in `app.dart` MUST include `DefaultMaterialLocalizations.delegate` alongside the Cupertino + Widgets delegates. Without it, `showModalBottomSheet` silently no-ops (no error visible to the user).

### 5c. Coach stream parsing (Vercel AI protocol)

`features/coach/data/vercel_stream_parser.dart` reads Server-Sent-Events from `/coach/conversations/{id}/messages` and yields Freezed `VercelStreamEvent` variants:
- `text-delta` → appended to `CoachMessage.content`
- `tool-input-available` → `toolStart(toolName)` → maps to a humanized label (`_humanizedTools`) and sets `CoachMessage.toolIndicator` (shown as `ThinkingCard` below the bubble while the tool runs)
- `tool-output-available` → `toolEnd()`
- `data-stats` → backend forwards `PresentRunningStats` output, rendered as `StatsCardBubble`
- `data-chips` → backend forwards `OfferChoices` output, rendered as `ChipSuggestionsRow` (now always appends a disabled "or type your own" chip)
- `data-proposal` → `ProposalCard` under the assistant bubble; its "View details" button opens `PlanDetailsSheet` which fetches `GET /coach/proposals/{id}/explanation` (AI-generated name + prose, cached server-side)

`CoachMessage.fromShowJson` normalizes historic `tool_results`: it accepts BOTH the list shape (older/OpenAI) and the map-keyed-by-step-index shape (Anthropic), and decodes `result` when it arrives as a JSON-encoded string.

### 6. Auth + onboarding flow

1. User taps "Sign in with Apple" on `WelcomeScreen` → routes to `/auth/apple`
2. `AppleAuthScreen` calls `SignInWithApple.getAppleIDCredential(scopes: [email, fullName])` — native iOS dialog
3. Apple returns an `identityToken` (JWT). The screen also captures `givenName`/`familyName`/`email` IF this is the first sign-in for this user (Apple omits them on subsequent sign-ins)
4. `authProvider.loginWithApple(identityToken, email, name)` posts to `/auth/apple` and stores the returned Sanctum bearer in `flutter_secure_storage`
5. **Error surfacing:** `loginWithApple` swallows backend errors into `AsyncValue.error(...)` and returns. `AppleAuthScreen` reads the auth state AFTER the call — if `hasError` it surfaces the message instead of navigating, otherwise the router takes over
6. `AuthInterceptor` attaches `Authorization: Bearer $token` to every subsequent request
7. Router redirect rules:
   - Not logged in → `/auth/welcome`
   - Logged in + `!hasCompletedOnboarding` + no pending plan → `/onboarding` (which redirects to `/onboarding/connect-health`)
   - Pending plan generation queued/processing/failed → `/onboarding/generating`
   - Pending plan generation completed → `/coach/chat/{conversation_id}`
   - Otherwise → whatever was requested

**Onboarding flow (new user):**
1. `/onboarding/connect-health` — `OnboardingConnectHealthScreen` requests Apple Health read permission via `HealthKitService.requestPermissions()`, pulls the last 90 days of running workouts, batches to `POST /wearable/activities`, then advances to overview
2. `/onboarding/overview` — `OnboardingOverviewScreen` shows 4 stat cards + a one-line AI narrative computed from the freshly ingested activities
3. `/onboarding/form` — multi-step form (goal type/distance/race-name/race-date/goal-time/days-per-week/preferred-weekdays/coach-style)
4. `/onboarding/generating` — polls `GET /onboarding/plan-generation/latest` every 3s while the queue worker runs the agent loop (~60-110s)
5. `/coach/chat/{conversation_id}` — final destination, `ProposalCard` rendered inside the agent chat

Note: Level and weekly km capacity are derived by the backend from the synced run history — onboarding only asks for coach style (motivational/analytical/balanced) plus race specifics.

### 7. Design system

Warm earth-tone palette in `core/theme/app_theme.dart`:
- `AppColors.cream` (#FAF8F4) — main background
- `AppColors.warmBrown` (#8B7355) — primary accent
- `AppColors.gold` (#D4A84B) — secondary accent
- `AppColors.cardBg` (#FFF9F0) — card background
- `AppColors.lightTan` (#F5F0E8) — input backgrounds, dividers

**Compliance colors** live in `core/theme/compliance_colors.dart` — single source of truth for the score → color mapping (≥0.80 success green, ≥0.50 secondary gold, <0.50 danger red). Use `ComplianceColors.forScore01(double)` for normalized 0-1 input or `forScore10(double?)` for the raw 0-10 scale stored on `TrainingResult` (returns null when the score is null, e.g. heartRateScore on runs without HR). When tweaking thresholds or colors, edit ONLY this file — every screen that renders a compliance indicator (training day stat tiles, coach analysis ring, training result bars) reads from here.

**Card + CTA pattern** (canonical reference: `features/schedule/widgets/training_day_action_buttons.dart` + `features/notifications/widgets/notifications_sheet.dart`). Every "content card with primary action" in the app uses this language — match it for new surfaces:
- **Card surface**: `CupertinoColors.white` background, `BorderRadius.circular(24)`, `EdgeInsets.all(20)`, optional subtle shadow `BoxShadow(color: Color(0x0A37280F), blurRadius: 12, offset: Offset(0, 2))`. Do NOT use `AppColors.cardBg` for primary cards — that cream tint reads as a secondary surface (used for inline rows inside the profile sheet).
- **Eyebrow tag** (small label above the title): pill with `AppColors.goldGlow` bg, `EdgeInsets.symmetric(horizontal: 8, vertical: 3)`, `BorderRadius.circular(6)`, text `GoogleFonts.spaceGrotesk(10pt, w700, letterSpacing: 0.8, color: AppColors.eyebrow)`.
- **Title**: italic Garamond — `GoogleFonts.ebGaramond(22-32pt, w500, italic, color: AppColors.primaryInk, height: 1.05-1.15)`.
- **Body**: `GoogleFonts.publicSans(14pt, height: 1.45, color: AppColors.inkMuted)`.
- **Primary CTA**: `ElevatedButton` (NOT `CupertinoButton.filled` — wrong color, system blue) with `backgroundColor: AppColors.secondary` (gold), `foregroundColor: AppColors.neutral`, vertical padding 14-16, `BorderRadius.circular(14-16)`, `elevation: 0`. Label is uppercase `GoogleFonts.spaceGrotesk(12pt, w700, letterSpacing: 0.8)`.
- **Secondary action** (Dismiss / Cancel): same shape, `backgroundColor: AppColors.lightTan`, `foregroundColor: AppColors.primaryInk`. Sits left of the primary, half its flex.

Bottom nav has 4 tabs: Dashboard, Schedule, AI Coach, Goals.

### 8. Floating bottom nav + floating CoachPromptBar — scroll bottom padding

The shell's bottom nav (`_RunCoreBottomNav` in `router/app_router.dart`) is a platform-aware floating bar stacked OVER the routed child inside `MainShell`.
- **iOS (native)**: renders `CNTabBar` from the `cupertino_native` package, which hosts a real `UITabBar` via `UiKitView`. On iOS 26+ this surfaces Apple's Liquid Glass material; on iOS 14–25 it degrades to the pre-26 translucent UITabBar. Icons are SF Symbols (`square.grid.2x2.fill`, `calendar`, `sparkles`, `trophy.fill`). Requires `ios/Podfile` deployment target ≥ 14.0.
- **Web / Android / desktop**: falls back to a Flutter `BackdropFilter(ImageFilter.blur)` approximation with SVG + Material icons and a custom press-state `GestureDetector`. Liquid Glass can't be faithfully reproduced without the native bridge.

The dispatch happens in `_RunCoreBottomNav.build`: `if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) → _NativeIosTabBar else → Flutter fallback`. Tab routes are defined once in the `_tabRoutes` const so both paths stay in sync. Five tab screens (`dashboard`, `weekly_plan`, `goal_list`, `goal_detail`, `training_day_detail`) additionally stack a floating `CoachPromptBar` just above the nav via `Positioned(bottom: kBottomNavContentHeight)`.

Because both the nav and the prompt bar float ON TOP of scroll content (no Expanded/Column push-up), every scroll view / list / Column on these screens MUST reserve bottom space or the last row sits permanently hidden under a floating bar. Use the constants exported from `router/app_router.dart`:

| Constant | Value | Use on |
|---|---|---|
| `kBottomNavContentHeight` | 58 | `Positioned(bottom: ...)` for the prompt bar; Stack offsets |
| `kBottomNavReservedHeight` | 92 | Scroll/list bottom padding on tab screens WITHOUT a floating prompt bar (coach chat list, training_result) |
| `kFloatingPromptBarHeight` | 68 | Internal only — summed into the constant below |
| `kBottomStackedReservedHeight` | 160 | Scroll/list bottom padding on tab screens WITH the floating prompt bar (dashboard, weekly_plan, goal_list, goal_detail, training_day_detail) |

Canonical pattern for a tab screen with a floating prompt bar:

```dart
return GradientScaffold(
  child: Stack(
    children: [
      SafeArea(
        bottom: false,
        child: Column(children: [
          AppHeader(),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, kBottomStackedReservedHeight),
            child: ...,
          )),
        ]),
      ),
      Positioned(
        left: 0, right: 0,
        bottom: kBottomNavContentHeight,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: CoachPromptBar.navigateAnimated(onTap: ..., animatedSuggestions: ...),
          ),
        ),
      ),
    ],
  ),
);
```

The bar itself (`core/widgets/coach_prompt_bar.dart`) is a white pill (`borderRadius: 999`) with a subtle `BoxShadow(0,1,2, #37280F @ 4%)` and NO border. Hot reload picks up padding changes; SVG asset changes need hot restart (flutter_svg caches by path).

**Short-content screens** (`goal_detail` when a goal has no training plan, etc.) otherwise leave a big gradient gap between the last content item and the floating prompt bar, which looks "fucked". Use `LayoutBuilder` + `ConstrainedBox(minHeight: constraints.maxHeight)` + `IntrinsicHeight` + a `Spacer()` before the last actionable item so the column stretches to viewport height and distributes empty space into the `Spacer` (anchoring the final action just above the prompt bar). When content IS long, `IntrinsicHeight` falls back to natural size and the scroll view handles overflow. See `goal_detail_screen.dart` for the canonical example.

### 9. Detail / push ("doorklik") screens — how we do them

Detail screens (training day, training result, coach chat, goal detail) are pushed OVER the tab shell with their own full-screen iOS slide transition. They must NOT show the tab bar, they must cover the screen edge-to-edge, and their own `CoachPromptBar` (if any) docks at the bottom — never floats.

**Route setup.** Declare the detail route as a NESTED `GoRoute` inside the tab's shell route, with `parentNavigatorKey: _rootNavigatorKey`, and wrap the builder in `HidesBottomNav`:

```dart
GoRoute(
  path: '/schedule',
  pageBuilder: (_, _) => const NoTransitionPage(child: WeeklyPlanScreen()),
  routes: [
    GoRoute(
      path: 'day/:dayId',
      parentNavigatorKey: _rootNavigatorKey,  // pushes on root nav
      builder: (_, state) => HidesBottomNav(   // hides the shell tab bar
        child: TrainingDayDetailScreen(
          dayId: int.parse(state.pathParameters['dayId']!),
        ),
      ),
    ),
  ],
),
```

- `parentNavigatorKey: _rootNavigatorKey` makes this route push on the root navigator so it gets the iOS slide transition and covers the shell chrome.
- `HidesBottomNav` flips the `_bottomNavHidden` `ValueNotifier` in `app_router.dart` on mount, restoring it on dispose. The shell's `MainShell` listens via `ValueListenableBuilder` and removes the `_RunCoreBottomNav` from the widget tree so the native `CNTabBar` UiKitView (and its shadow) can't bleed through the push animation.
- There is also a secondary path-based check (`MainShell._isTabRoot`) as a fallback, but **always use `HidesBottomNav`** — the URL check isn't reliable for every nested-push combo and is brittle if route paths ever change.

**Screen layout.** Detail screens use a Column + Expanded + docked bottom-bar pattern (NOT the floating `Positioned` pattern the tab roots use). This guarantees the gradient reaches the bottom edge of the device, the prompt bar sits above the home indicator, and nothing floats on top of scroll content.

```dart
return GradientScaffold(
  child: SafeArea(
    bottom: false,                          // let the docked bar handle bottom inset
    child: Column(
      children: [
        _BackButton(),                      // custom back chevron, top-left
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: ...,
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: CoachPromptBar.navigateAnimated(
              onTap: () => startNewCoachChat(context, ref),
              animatedSuggestions: ...,
            ),
          ),
        ),
      ],
    ),
  ),
);
```

Canonical examples: `training_day_detail_screen.dart`, `goal_detail_screen.dart`, `coach_chat_screen.dart` (the docked bar in chat is the input pill, not the navigate bar, but the Column/Expanded/SafeArea scaffolding is identical).

**Short-content detail screens** still use the `LayoutBuilder + IntrinsicHeight + Spacer()` trick from section 8 inside the `Expanded` so the last action (e.g. Delete goal) anchors just above the prompt bar instead of floating mid-screen. See `goal_detail_screen.dart`.

**Prompt bar on any screen (tab or detail) always starts a NEW chat.** Call `startNewCoachChat(context, ref)` from `features/coach/providers/coach_provider.dart` — it creates a fresh conversation server-side, invalidates `conversationsProvider`, and `context.push('/coach/chat/<id>')`. Don't take users to the chat list.

**Full-height gradient.** `GradientScaffold` paints the cream→gold gradient edge-to-edge. Do NOT wrap it in a `Scaffold` or `CupertinoPageScaffold` that has its own background — the shell's `CupertinoPageScaffold` is `CupertinoColors.transparent` precisely so this gradient can show through on every route.

### 10. Push notifications (APNs, iOS-only)

Native MethodChannel bridge instead of `firebase_messaging` — keeps Firebase out of the project. Spec: `../docs/superpowers/specs/2026-04-26-push-notifications.md`.

**Pieces:**
- `ios/Runner/PushNotifications.swift` — singleton `PushNotifications.shared` that owns the `nl.runcoach/push` MethodChannel + acts as `UNUserNotificationCenterDelegate`. Methods Dart→Native: `requestPermission`, `registerForRemoteNotifications`, `getInitialPayload`. Methods Native→Dart: `onToken`, `onTokenError`, `onPushTapped`.
- `ios/Runner/AppDelegate.swift` — overrides `didRegisterForRemoteNotificationsWithDeviceToken` / `didFailToRegister...` and forwards to the singleton. Stashes `launchOptions[.remoteNotification]` for cold-launch tap routing.
- `ios/Runner/Runner.entitlements` — `aps-environment = development` (Apple substitutes the prod environment server-side for App Store builds, so the dev value covers both).
- `lib/features/push/services/push_service.dart` — Dart wrapper. Riverpod-provided (`pushServiceProvider`, `keepAlive: true`). API: `requestPermissionAndRegister()`, `registerIfPermitted()`, `unregister()`, `consumeInitialPayload()`. Static `routeFromPayload({type, conversation_id, ...})` returns the deep-link path for a payload type — extend this when new push types are added on the backend.
- `lib/features/push/data/devices_api.dart` — Retrofit client for `POST /devices` + `DELETE /devices`.

**Wire-in points (don't move these without thinking through opt-in rate / signed-out-device safety):**
- Onboarding form submit (`onboarding_form_screen.dart::_submit`) — fires `requestPermissionAndRegister()` right before `context.go('/onboarding/generating')`. Apple's prompt is one-shot, so we ask AFTER the user has experienced enough value to want it (the prompt comes ~30s after sign-in). Asking on first launch tanks opt-in to ~30%.
- Cold-start re-register (`auth_provider.dart::loadProfile`) — `registerIfPermitted()` runs after the profile loads. No-op if the user previously denied; otherwise refreshes `last_seen_at` server-side.
- Logout (`auth_provider.dart::logout`) — `unregister()` runs BEFORE `api.logout()` so the bearer is still valid for the `DELETE /devices` call.
- Tap routing (`app.dart`) — sets `pushService.onTap` on first build to call `router.go(PushService.routeFromPayload(payload))`. Cold-launch payload is drained in a post-frame callback after the auth state finishes loading (the router redirect would otherwise fight the deep link).

**iOS Developer Portal one-time setup:** the App ID `com.erwinwijnveld.runcoach` must have the **Push Notifications** capability enabled at developer.apple.com → Identifiers. The SSL Certificate buttons in the same panel are NOT used (we authenticate with a `.p8` token, not a `.p12` certificate).

**Cannot be tested on the iOS Simulator.** The simulator never receives real APNs pushes. iOS 16+ supports a local-only `xcrun simctl push <udid> <bundle-id> <payload.json>` for routing testing, but that bypasses the entire APNs / .p8 / Pushok stack — it only tests `userNotificationCenter(_:willPresent:)` and tap handling. End-to-end testing requires a physical iPhone with a sandbox build.

**Adding a new push type:**
1. Backend side per `../api/CLAUDE.md` → "Push notifications" (new `Notification` class + dispatcher).
2. Add the routing case to `PushService.routeFromPayload()` so taps on the new type land on the right screen.
3. (Optional) Suppress in-app banner when the user is already on the destination — handle in the `onTap` setter in `app.dart` (compare current location with target route).

### 11. Send to watch (WorkoutKit, iOS 17+)

Native MethodChannel bridge `nl.runcoach/workout` (`ios/Runner/WorkoutScheduling.swift`, registered in `AppDelegate.didInitializeImplicitFlutterEngine`). Three Dart→Native methods:

- **`scheduleRun`** — `SingleGoalWorkout(activity:.running, location:.outdoor, goal:.distance(km, .kilometers))` for non-interval days. Args: `{date, distanceKm, dayId}`.
- **`scheduleIntervals`** — `CustomWorkout` with `warmup` (time-only `WorkoutStep` if provided), one `IntervalBlock` of work/recovery `IntervalStep`s, and a time-only `cooldown`. Args: `{date, dayId, displayName, warmupSeconds, cooldownSeconds, steps:[{kind, distanceM, durationSeconds}]}`.
- **`rescheduleIfPresent`** — fire-and-forget watch sync. Looks up our scheduled plan by deterministic UUID, removes from old date, schedules at new date. Silent no-op when nothing to do or auth not granted (does NOT prompt). Args: `{date, dayId}`.

All return `{status: 'scheduled'|'duplicate'|'denied'|'unavailable'|'failed'|'moved'|'skipped', message}`.

**Identity tracking** (iOS 17.4+): every `WorkoutPlan` is created with a deterministic UUID derived from the `TrainingDay.id`: `00000000-0000-0000-0000-{dayId masked to 48 bits as 12 hex chars}` (see `WorkoutScheduling.uuidForDay`). The mask prevents 64-bit overflow from breaking the UUID format. Identity tracking lets us:
- de-dup ONLY against ourselves (other apps' workouts on the same day are allowed),
- find-and-replace when sending the same TrainingDay to a different date,
- auto-move on reschedule via `rescheduleIfPresent`.

On iOS 17.0–17.3, custom IDs aren't available → no de-dup, no auto-reschedule. Multiple sends per day end up as multiple watch entries (rare audience in 2026).

**Cooldown is required by schema** (`api/CLAUDE.md` → "Interval session rules"). The screen's `_buildIntervalPlan` defensively synthesizes a 300s cooldown if a row's `intervals_json` lacks one (covers pre-rule data). Distance-based recoveries are converted to seconds via 360 sec/km recovery pace. Cooldown segments are hoisted to the `cooldownSeconds` arg, never sent as steps.

**Reschedule auto-syncs the watch**: `reschedule_day_sheet.dart::_save` awaits `WorkoutSchedulerService.rescheduleIfPresent` after a successful `PATCH /training-days/{day}`. Awaited (not unawaited) to avoid a race with a quick follow-up Send-to-watch tap.

**Cannot be tested on the iOS Simulator.** WorkoutKit + Fitness app sync only work on real hardware.

**Pbxproj entries:** `WorkoutScheduling.swift` is registered in `Runner.xcodeproj/project.pbxproj` in 3 places (PBXBuildFile, PBXFileReference, PBXGroup, PBXSourcesBuildPhase). When adding new `.swift` files in `ios/Runner/`, replicate the pattern of `HealthKitPersonalRecords.swift` / `PushNotifications.swift` there or `flutter run` fails with "Cannot find 'X' in scope".

### 12. Reschedule day sheet

`reschedule_day_sheet.dart` is a `showCupertinoModalPopup` with a custom Cupertino calendar grid (NOT Material's `CalendarDatePicker` — that has ripples and looks Android-y). Today is highlighted with a gold ring (`AppColors.secondary`), the picked date with a filled brown disc (`AppColors.primary`). Trigger: top-right ellipsis on the day-detail screen → action sheet → "Reschedule".

After a successful PATCH, the sheet:
1. Invalidates `trainingDayDetailProvider` / `scheduleProvider` / `currentWeekProvider` so the schedule views re-fetch.
2. Awaits `WorkoutSchedulerService.rescheduleIfPresent(dayId, newDate)` so the watch entry follows the move.
3. Pops itself.

The calendar guards against `lastDate < today` (defensive fallback) and clamps `_selected` so out-of-range initial dates don't crash the displayMonth.

### 13. Training day detail layout (status-aware)

`training_day_detail_screen.dart` renders different bodies depending on `TrainingDayStatus`:

| Status | Stat tiles (top) | Action buttons | Coach analysis card | Synced activity card | Notes section |
|---|---|---|---|---|---|
| upcoming / today / missed | target only | full-width Send to watch | — | — | shown if description present |
| completed | target + actual underneath in per-section compliance color (`ComplianceColors.forScore10`) | hidden | combined card with ring %, COMPLIANCE label, AI feedback excerpt, arrow → result detail screen | — (folded INTO the analysis card) | hidden |

`TrainingDayStatTiles` takes 3 `StatTileData` records (`target`, optional `actual`, optional `actualColor`). The screen builds them via `_distanceTile / _paceTile / _hrZoneTile` helpers — target value is always shown big, actual sits small underneath in the compliance color when a result exists.

`coach_analysis_card.dart` replaces the older split between "Coach analysis" + "Synced activity" sections. Wrapped in `_CoachAnalysisSection` (ConsumerWidget) which polls `trainingDayAiFeedbackProvider` only while `result.aiFeedback` is null. Tapping the card OR the "Open ›" link OR the dark arrow all route to `/schedule/day/{id}/result` so the user has multiple obvious ways in.

When changing this layout, keep these invariants:
- Send to watch is hidden for completed days (no point scheduling a past run on the watch).
- Stat tiles always show TARGET as the primary value — the actual goes underneath. NEVER swap them or you'll regress the "what was I supposed to do" affordance.
- Per-section colors come from `result.distanceScore / paceScore / heartRateScore` (NOT the overall `complianceScore`) so the runner sees which dimension drove the score.

**Interval pace tile**: on `type=='interval'` days `TrainingDay.targetPaceSecondsPerKm` is null by design (the day-level field doesn't apply to intervals — see `api/CLAUDE.md` → "Interval pace contract"). Read the displayed value via the `TrainingDayPaceX` extension's `displayPaceSecondsPerKm` getter instead — it returns the work-set average (mean of `kind=work` segment paces) for intervals and the day-level field for everything else. The pace tile also hides its `actual` value on intervals: a full-run avg that mixes warmup + recovery + cooldown isn't comparable to per-rep work pace and would render as a misleading "fail" colour. The training-result screen's `_TargetVsActualSection` doesn't need similar treatment because it already hides the pace row when the target is null.

### 14. Notifications inbox (action-required items)

Header bell + bottom-sheet inbox + cold-start reminder for items the runner must act on. Backed by the API's `user_notifications` table (see `api/CLAUDE.md` → "Notifications inbox" for backend details).

**Pieces:**
- `lib/features/notifications/models/user_notification.dart` — Freezed model
- `lib/features/notifications/data/notifications_api.dart` — Retrofit (list/accept/dismiss)
- `lib/features/notifications/providers/notifications_provider.dart`:
  - `notificationsProvider` — `keepAlive: true` `AsyncNotifier<List<UserNotification>>`. `accept(id)` / `dismiss(id)` → `ref.invalidateSelf()` after API call.
  - `pendingNotificationCountProvider` — derived count for the bell badge, defaults to 0 on loading/error so the badge doesn't flicker.
- `lib/features/notifications/widgets/notifications_sheet.dart` — `showNotificationsSheet(context)` opens a Cupertino bottom sheet with a list of `_NotificationCard`s.

**`AppHeader` bell (`lib/core/widgets/app_header.dart`)**: 18×18 `BoxShape.circle` red dot positioned over the icon when count > 0. Single digit shows literal number, ≥10 shows `9+`. Fixed 1:1 box so it stays a perfect circle regardless of digit width.

**Boot popup (`lib/app.dart::_BootPopupHost`)**: mounted INSIDE the router via `CupertinoApp.router(builder: ...)` so its dialog has a Navigator ancestor. Watches `authProvider`; once auth resolves to a non-null user, fires once per app launch — fetches `notificationsProvider.future`, and if the list is non-empty pops a `CupertinoAlertDialog` with `Later` / `View` buttons. View → `showNotificationsSheet`. The single-fire flag (`_fired`) is per widget lifetime, so logout-and-back-in within the same app session won't re-fire (matches the "once per cold start" UX).

**Card action pattern** (`_NotificationCard`):
- Always: white card, gold-glow eyebrow pill with the type label, italic Garamond title, Public Sans body
- Always: bottom row with `DISMISS` (left, 1× flex, `lightTan`) + `APPLY` (right, 2× flex, gold `secondary`) primary CTAs
- Per-type tertiary action (full-width below the row, `_TertiaryButton`): conditionally rendered when the type warrants it. **For `pace_adjustment`**: `Edit HR Zones` with edit icon → `showHeartRateZonesSheet(context)`. The principle: if the notification's underlying cause has a calibration UI, surface that UI as a tertiary action so the runner can address the root cause rather than just patching the symptom.

**Adding a new notification type:**
1. Backend produces the row with a new `type` string + `action_data` shape (see `api/CLAUDE.md`).
2. (Optional) extend `_typeLabel` switch in `notifications_sheet.dart` for a humanised eyebrow label — falls through to `replaceAll('_', ' ').toUpperCase()` if not added.
3. (Optional) add a tertiary action arm in `_NotificationCard.build` (the `if (n.type == 'pace_adjustment')` block) when the type has a calibration sheet to surface.

### 15. Screen intro animations

Tasteful Apple-style entry animations on tab roots and detail screens. Two helpers in `lib/core/widgets/intro_fx.dart`:

- **`IntroFx`** — wraps a single widget with a 320ms fade + 4% upward slide (`Curves.easeOutCubic`). Use on detail screens where the whole content panel should drift in as one unit.
- **`IntroColumn`** — a `Column` with a 60ms stagger between children. Use on tab roots with a small number of cards.

Both honor `MediaQuery.disableAnimations` (renders the child at its final state when Reduce Motion is on) and always end at the visible rest state — an interrupted run can never leave content hidden.

Currently applied to: `dashboard_screen.dart` (staggered cards), `weekly_plan_screen.dart` (whole `_WeekPages`, plays once on mount — page-view swipes between weeks are unaffected), `training_day_detail_screen.dart`, `coach_chat_list_screen.dart`, `goal_list_screen.dart`, `goal_detail_screen.dart`. **Don't** wrap the detail screen scaffold itself when GoRouter pushes it on `_rootNavigatorKey` — the iOS slide-in already covers entry; animate the inner content panel instead. **Don't** stagger every row of an unbounded `ListView.builder`; intros fire per build and replay during scroll recycling.

Backed by `flutter_animate` (zero codegen, no `build_runner` involvement, so safe alongside Freezed 3.x / no-`custom_lint`).

## Running and building

```bash
# iOS simulator
flutter run

# List connected devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Rebuild code generation (Freezed, Riverpod, Retrofit)
dart run build_runner build --delete-conflicting-outputs

# Watch mode for codegen
dart run build_runner watch

# Analyze
flutter analyze

# Tests
flutter test
```

### Physical device setup

The base URL is read from a `--dart-define` in `lib/core/api/dio_client.dart`. Default is `http://localhost:8001/api/v1` — fine for the simulator, useless on a physical iPhone (the iPhone's `localhost` is the iPhone, not your Mac).

**Use `bash scripts/run-dev.sh`** instead of plain `flutter run` for physical-device testing. It auto-detects the Mac's LAN IP via `ipconfig getifaddr en0` (then `en1` for Ethernet), injects `--dart-define=API_BASE_URL=http://<ip>:8001/api/v1`, and forwards any extra flags to `flutter run`. Override the port with `PORT=8000 bash scripts/run-dev.sh` or the URL entirely with `API_BASE_URL=https://... bash scripts/run-dev.sh`.

**Simulator runs need SDKROOT** (handled automatically by `run-dev.sh`): when `-d <id>` resolves to a known simulator (checked via `xcrun simctl list devices`), the script exports `SDKROOT=iphonesimulator` before invoking `flutter run`. This works around a Flutter native_assets bug that otherwise compiles `package:objective_c` (transitive dep of `cupertino_native`) for `arm64-apple-ios` instead of `arm64-apple-ios-simulator`, leading to an `objective_c.framework` dlopen failure on launch (`"Couldn't resolve native function 'DOBJC_initializeApi'"` plus `"Target native_assets required define SdkRoot but it was not provided"`). Always go through `run-dev.sh` for simulator runs — calling `flutter run -d <sim-id>` directly will resurrect the bug.

Make sure Laravel binds to all interfaces:
```bash
cd ../api
php artisan serve --host=0.0.0.0 --port=8001
```

If the iPhone shows `Connection refused` even with the script, check (a) you're on the same Wi-Fi network and (b) the Mac's firewall isn't blocking incoming connections on port 8001.

### Bundle identifier + Apple capabilities

iOS bundle ID is `com.erwinwijnveld.runcoach` in `ios/Runner.xcodeproj/project.pbxproj`. This matches the developer team signing AND the `aud` claim the backend expects on Apple identity tokens (`config('services.apple.bundle_id')`).

Two capabilities are baked into the project:
- **Sign in with Apple** — `com.apple.developer.applesignin` (Default scope) in `ios/Runner/Runner.entitlements`
- **HealthKit** — `com.apple.developer.healthkit` (with empty `healthkit.access` array meaning "all granted types") in the same file

Both are referenced by `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;` on all 3 Runner build configs (Debug/Release/Profile). The `SystemCapabilities` flags in `TargetAttributes` are cosmetic (Xcode UI only).

**One-time Apple Developer portal setup:** the same two capabilities must ALSO be enabled on the App ID `com.erwinwijnveld.runcoach` at [developer.apple.com/account/resources/identifiers](https://developer.apple.com/account/resources/identifiers). Without that, code signing fails with "provisioning profile doesn't include the entitlement". With Automatic Signing, Xcode regenerates the profile automatically once the App ID is updated.

Required Info.plist usage strings (already set):
- `NSHealthShareUsageDescription` — copy shown in the iOS read-permission prompt
- `NSHealthUpdateUsageDescription` — required even though we don't write to HealthKit

**Deferred capabilities** (when adding background HealthKit delivery):
- `com.apple.developer.healthkit.background-delivery` entitlement
- `Background Modes` capability + check `Background fetch` + `Background processing`
- App Store Review will ask for justification — describe the use case in the submission notes

### Release builds + TestFlight

Three scripts in `app/scripts/` handle dev + release:

- **`bash scripts/run-dev.sh`** — auto-injects the Mac's LAN IP for `flutter run` against the local backend on a physical iPhone. See "Physical device setup" above.
- **`bash scripts/build-ios.sh`** — runs `flutter build ipa --release --dart-define=API_BASE_URL=https://runcoach.free.laravel.cloud/api/v1`. Override the URL with `API_BASE_URL=... bash scripts/build-ios.sh`.
- **`bash scripts/upload-ios.sh`** — validates + uploads to App Store Connect via `xcrun altool`. Credentials already configured on this machine (`APP_STORE_CONNECT_API_KEY_ID` + `APP_STORE_CONNECT_ISSUER_ID` in `~/.zshrc`, `.p8` key in `~/.appstoreconnect/private_keys/`). Just run the script.

Full release flow + prereqs are documented in `../CLAUDE.md` → Deployment.

Before every upload, bump the `+N` build number in `pubspec.yaml` — App Store Connect rejects duplicate build numbers.

Icon and splash are generated from `app/assets/icon.png` via `flutter_launcher_icons` + `flutter_native_splash` (configs in `pubspec.yaml`). Regenerate after swapping the source:
```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Conventions

- **Always use `ConsumerWidget` or `ConsumerStatefulWidget`** for screens that read providers.
- **Navigation**: use `context.go('/path')` (replace) or `context.push('/path')` (stack push) from GoRouter.
- **Optimistic UI**: the coach chat adds the user's message immediately with a `temp-${timestamp}` id, then adds the assistant reply when the API returns. On error, the user message is kept.
- **Error handling in providers**: use `AsyncValue.error(e, st)` pattern. Screens consume via `when()`.
- **No print statements** — `avoid_print` lint is enabled.

## Testing

- Full test suite: `flutter test`
- Flutter analyze must be clean before commits: `flutter analyze`
- Provider tests and widget tests live in `test/` mirroring the `lib/` structure

## Troubleshooting

- **"int.parse on UUID"** error in go_router → conversation IDs must be `String`, check you're not casting them to int
- **"type 'String' is not a subtype of type 'num'"** → a MySQL decimal field needs `fromJson: toDouble` converter
- **"Invalid schema for function"** from the AI provider → the backend tool schema is missing `->required()` on some param (fix in api/)
- **"View Details" / modal button does nothing** → `showModalBottomSheet` requires `DefaultMaterialLocalizations.delegate` in `app.dart`. Missing delegate = silent no-op.
- **"`_Map<String, dynamic>` is not a subtype of `List<dynamic>?`"** when opening an old conversation → Anthropic stores `tool_results` keyed by step index (JSON object), not as an array. Use/update `CoachMessage.fromShowJson`-style normalization.
- **Code gen not working** → run `dart run build_runner build --delete-conflicting-outputs` (the `--delete-conflicting-outputs` part matters)
- **Tab bar visible / its shadow lingers on a detail screen** → the detail route's builder isn't wrapped in `HidesBottomNav`. See section 9 for the pattern.
- **Gradient background doesn't reach the bottom on a detail screen** → using `Stack + Positioned` for the prompt bar instead of `Column + Expanded + docked SafeArea`. Switch to the Column pattern (section 9).
- **Sign-in flow ends up back on `/auth/welcome` with no error visible** → `loginWithApple` swallows backend errors into `AsyncValue.error(...)` and returns; without an error guard the screen would navigate to `/dashboard` and the router silently bounces to welcome. `AppleAuthScreen` now reads the auth state after the call and surfaces the error inline. If you see this regress, check `apple_auth_screen.dart`.
- **`DioException [connection error]: Connection refused, address = localhost, port = …`** on a physical iPhone → you ran `flutter run` instead of `bash scripts/run-dev.sh`. The default URL points at `localhost:8001`, which on the iPhone means *the iPhone itself*. Use the wrapper script to inject the Mac's LAN IP.
- **Apple Sign-In dialog opens but returns a 401 from the backend** → check (a) `services.apple.bundle_id` in the API matches the iOS bundle id `com.erwinwijnveld.runcoach`, (b) the device clock is correct (Apple JWTs have tight expiry), (c) `tail -f api/storage/logs/laravel.log` for the `InvalidAppleIdentityTokenException` message (it spells out which validation step failed: signature/issuer/audience/expiry).
- **HealthKit permission prompt never appears** → first check Info.plist has `NSHealthShareUsageDescription`. Then check the App ID has the HealthKit capability enabled at developer.apple.com — if not, the system silently no-ops the request. Apple's `hasPermissions(READ)` always returns null/false for privacy reasons even after grant; don't rely on it as a check.
- **`showCupertinoDialog` from a top-level callback never appears** → `RunCoachApp.context` sits ABOVE `CupertinoApp.router`'s Navigator, so `Navigator.of(...)` can't find a route. `routerDelegate.navigatorKey.currentContext` is also wrong — that's the Navigator widget's OWN context, and `Navigator.of(context)` only walks ANCESTORS, so it skips the navigator itself. Fix: mount the dialog-triggering widget INSIDE the router via the `CupertinoApp.router(builder: (context, child) => ...)` callback — that `context` has the Navigator as an ancestor. Canonical reference: `app.dart::_BootPopupHost` for the cold-start notifications reminder. Same gotcha applies to `showCupertinoModalPopup`.
- **`Couldn't resolve native function 'DOBJC_initializeApi' in 'package:objective_c/objective_c.dylib'`** at runtime on the iOS simulator (often paired with the warning `Target native_assets required define SdkRoot but it was not provided`) → Flutter's native_assets generator built the device slice for `cupertino_native`'s `objective_c` dependency instead of the simulator slice, so dlopen can't load the framework. Two parts to the fix: (a) clear the stale cache once with `rm -rf .dart_tool/flutter_build .dart_tool/native_assets* build/native_assets build/native_hooks build/ios`, and (b) launch via `bash scripts/run-dev.sh -d <sim-id>` so SDKROOT=iphonesimulator gets exported (auto-detected by the script). Direct `flutter run -d <sim-id>` will reproduce the bug.
