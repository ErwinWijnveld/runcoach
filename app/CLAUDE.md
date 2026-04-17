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

The base URL in `lib/core/api/dio_client.dart` must point to the Mac's local IP (NOT `localhost`) when running on a physical device:
```dart
const String baseUrl = 'http://192.168.x.x:8000/api/v1';
```

Find your IP with `ipconfig getifaddr en0`. Also ensure Laravel is serving on all interfaces: `php artisan serve --host=0.0.0.0 --port=8000`.

### Bundle identifier

iOS bundle ID is `com.erwinwijnveld.runcoach` in `ios/Runner.xcodeproj/project.pbxproj`. This matches the developer team signing and must stay unique across the App Store.

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
