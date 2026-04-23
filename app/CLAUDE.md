# RunCoach Flutter App

Mobile app for **RunCoach** — personal AI running coach with Strava integration. See `../CLAUDE.md` for the monorepo overview and `../api/CLAUDE.md` for the backend.

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (iOS + Android, web is not configured by default) |
| State management | Riverpod with `@riverpod` code generation |
| Models | Freezed 3.x with `sealed class` syntax, JSON serialization |
| API client | Dio + Retrofit (code-generated per feature) |
| Routing | GoRouter with auth redirect guards |
| Secure storage | `flutter_secure_storage` (Sanctum token) |
| Strava OAuth | `webview_flutter` |

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
    ├── auth/                      — Welcome, Strava OAuth, onboarding
    ├── dashboard/                 — Home tab with weekly summary
    ├── schedule/                  — Weekly plan, day detail, compliance result
    ├── coach/                     — AI chat list, chat UI, message bubbles, proposals
    └── races/                     — Race list, create, detail
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

### 6. Auth flow

1. User taps "Connect with Strava" on `WelcomeScreen`
2. `StravaAuthScreen` fetches authorize URL from backend, opens WebView
3. WebView intercepts the callback URL with `?code=xxx`
4. `authProvider.loginWithStrava(code)` exchanges for Sanctum token
5. Token stored in `flutter_secure_storage` via `TokenStorage`
6. `AuthInterceptor` attaches `Authorization: Bearer $token` to every request
7. Router redirects to `/auth/onboarding` if `user.coachStyle == null`, else `/dashboard`

Note: Level and weekly km capacity are determined by the backend from Strava data — onboarding only asks for coach style (motivational/analytical/balanced).

### 7. Design system

Warm earth-tone palette in `core/theme/app_theme.dart`:
- `AppColors.cream` (#FAF8F4) — main background
- `AppColors.warmBrown` (#8B7355) — primary accent
- `AppColors.gold` (#D4A84B) — secondary accent
- `AppColors.cardBg` (#FFF9F0) — card background
- `AppColors.lightTan` (#F5F0E8) — input backgrounds, dividers

Bottom nav has 4 tabs: Dashboard, Schedule, AI Coach, Races.

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

The base URL is read from a `--dart-define` in `lib/core/api/dio_client.dart`, falling back to a hardcoded LAN IP for `flutter run`:
```dart
const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://192.168.178.31:8000/api/v1',
);
```
Update the fallback to your Mac's LAN IP (`ipconfig getifaddr en0`) when testing on a physical iPhone. Also ensure Laravel is serving on all interfaces: `php artisan serve --host=0.0.0.0 --port=8000`. Simulator works with the LAN IP too.

### Bundle identifier

iOS bundle ID is `com.erwinwijnveld.runcoach` in `ios/Runner.xcodeproj/project.pbxproj`. This matches the developer team signing and must stay unique across the App Store.

### Release builds + TestFlight

Two scripts in `app/scripts/` handle the release pipeline. Full flow + prereqs are documented in `../CLAUDE.md` → Deployment.

- **`bash scripts/build-ios.sh`** — runs `flutter build ipa --release --dart-define=API_BASE_URL=https://runcoach.free.laravel.cloud/api/v1`. Override the URL with `API_BASE_URL=... bash scripts/build-ios.sh`.
- **`bash scripts/upload-ios.sh`** — validates + uploads to App Store Connect via `xcrun altool`. Credentials already configured on this machine (`APP_STORE_CONNECT_API_KEY_ID` + `APP_STORE_CONNECT_ISSUER_ID` in `~/.zshrc`, `.p8` key in `~/.appstoreconnect/private_keys/`). Just run the script.

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
- **Tab bar visible / its shadow lingers on a detail screen** → the detail route's builder isn't wrapped in `HidesBottomNav`. See section 9 for the pattern. The underlying cause is the native `CNTabBar` UiKitView — its shadow bleeds through the iOS push transition unless the widget is removed from the tree before the animation starts.
- **Gradient background doesn't reach the bottom on a detail screen** → you're using `Stack + Positioned` for the prompt bar instead of `Column + Expanded + docked SafeArea`. Switch to the Column pattern (section 9). Tab roots can use the floating `Positioned` pattern because they reserve scroll padding via `kBottomStackedReservedHeight`; detail screens can't because they have no tab bar beneath the prompt bar.
