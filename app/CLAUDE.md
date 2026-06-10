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
- `data-proposal` → `ProposalCard` under the assistant bubble — single gold "View Details" CTA (Accept lives in the modal). `PlanDetailsSheet` has a sticky Accept/Adjust footer (Adjust just closes the sheet + focuses the chat input — no proactive reject; the agent's `AdjustPlan` auto-targets the still-pending proposal), a fixed-height `CustomPaint` weekly-volume line chart (race week stripped, scaled to data range), and revamped `_WeekCard` (gold-glow focus-eyebrow + italic Garamond "Week N" title + per-row day pill + km/pace metrics). When `proposal.payload['ambition']` is present (server-set by `AmbitionAssessment::toFeasibilityPayload()` for goals with a measurable target), the modal renders `_FeasibilityZoneBar` between header and top-stats — italic verdict label + big % (zone-coloured: green ≥70, gold 40-69, red <40), red-amber-green linear-gradient track with a black pointer, axis labels `Onhaalbaar / Stretch / Goed`, and a one-line detail. On `verdict_zone == 'unrealistic'` the sticky footer flips to a full-width red "ADJUST GOAL FOR REALISTIC PLAN" primary CTA with "Accept anyway" demoted to tan below; tap routes through `onAdjust(prefill: ambition['adjust_prefill'])` → chat input receives prefilled Dutch text + focus. The `onAdjust` callback signature is `Future<void> Function({String? prefill})?` — non-unrealistic callsites pass null. Skipped on revision proposals (those carry `diff` and use the existing revision view). Spec: `../docs/superpowers/specs/2026-05-12-plan-feasibility-analysis-design.md`.

  **Plan rendering — shared widget** (`coach/widgets/plan_content.dart`): the visual content (header + ambition bar + top stats + weekly-volume chart + week cards, OR the diff-revision view when `payload['diff']` is non-empty) lives once as `PlanContent`, reading a raw `Map<String, dynamic>` shaped like `proposal.payload`. The revision view (`plan_revision_content.dart`) renders each edited day as two stacked diff lines — red `VOOR`/`BEFORE` chip + red text for the old state, green `NA`/`AFTER` chip + green text for the stored state (tokens `AppColors.danger(Bg)` / `successInk`/`successBg`) — instead of one merged "A → B" string; identical before/after collapses to the green line only. Tests: `test/features/coach/widgets/plan_revision_content_test.dart`. `PlanDetailsSheet` is a thin wrapper around it (drag handle + sticky Accept/Adjust footer). Inactive-and-active goal previews use `goals/widgets/goal_plan_sheet.dart` with the same `PlanContent` + a Close-only footer; the goal-side data is converted to the same map shape via `goals/utils/goal_to_payload.dart::goalToPlanPayload(Goal, List<TrainingWeek>)` (derives `day_of_week` from `TrainingDay.date`). `goal_detail_screen.dart`'s "View schedule" row opens `GoalPlanSheet` for both active AND inactive goals — never navigates to `/schedule`. The Schedule tab is for interactive use (mark complete, etc.); the popup is the canonical preview.
- `data-new-plan` → `NewPlanCard` widget rendered under the assistant bubble. Tap navigates to `/onboarding/form?for=new-plan&step=goal_type` (returning user enters the form at goal-type with a fresh provider; replaces the in-chat `offer_choices` chip flow for new plans).

**Onboarding chat lock + priming-message hide** (`coach_chat_screen.dart`): when the runner is dropped into the onboarding coach chat (post-paywall or post-admin-grant), the screen is **locked** — no Back chevron, iOS swipe-back disabled via `PopScope(canPop: false)`. The lock is on while `authProvider.value.pendingPlanGeneration?.conversationId == conversationId` (only set during the completed-but-unaccepted onboarding window; once the proposal is accepted it goes null and the chat unlocks). Separately, the agent's **priming first user message** (the kickoff prompt) is hidden ONLY in the onboarding conversation: `CoachChatView.hideFirstUserMessage` drops the first `role=='user'` message from the rendered list (view-only, provider data untouched). Onboarding is detected via `conversationIsOnboardingProvider(id)` which reads the show endpoint's `context` field (`GET /coach/conversations/{id}` now returns `context`; CoachController::show) — robust on cold-start deep links since the chat list excludes onboarding convos.

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
2. `/onboarding/overview` — `OnboardingOverviewScreen` is an editable 2-field baseline form (avg weekly km + easy pace via dual-wheel Cupertino picker). Wearable users see prefilled values with a 🔒 lock icon; tapping unlock shows a "this may degrade your plan" `CupertinoAlertDialog` before allowing edits. No-wearable users fill the fields directly (both required, Continue gated on touched-state). Submit POSTs to `/onboarding/self-reported-stats` before navigating to zones — locked-untouched fields send null (cascade wins), edited fields send their value (overrides cascade). Widgets: `widgets/locked_stat_field.dart` (lock pattern + confirmation), `widgets/pace_wheel_picker.dart` (dual-wheel sheet). Spec: `../docs/superpowers/specs/2026-05-11-onboarding-self-reported-stats-design.md`.
3. `/onboarding/zones` — `OnboardingZonesScreen` has three runtime states selected from `user.dateOfBirth` + `user.heartRateZonesSource` + an `onboardingDerivedZonesProvider` carried over from connect-health: (A) **HR-confirmed** when the cascade had empirical signal — full bpm table + "based on N runs" subtitle; (B) **DOB-known** — big DOB row, collapsed "Show zones (advanced)" link with `HrZonesReadonlyList`; (C) **no-DOB** — Cupertino DOB picker auto-opens on first frame, Continue disabled until pick. After Continue → `/onboarding/form`. Title is "Your training zones" (not "heart rate") across all states. Spec: `../docs/superpowers/specs/2026-05-11-zones-step-restyle-design.md`.
4. `/onboarding/form` — multi-step form (goal type → distance → race-name/race-date/goal-time → days-per-week → preferred-weekdays → **run-type ranking** → coach-style → **runner-level** → **intensity** → review). The intensity step (Easier / Standard / Harder) renders an animated line chart (`widgets/intensity_bias_chart.dart`) that mirrors the `_WeeklyVolumeChart` in the plan-details modal — three hardcoded normalised curves tween element-wise (350ms `easeInOutCubic`). Bias is persisted on `users.intensity_bias` server-side; the curve itself is decorative (no backend preview call). See `docs/superpowers/specs/2026-05-11-onboarding-intensity-bias-design.md` and the root CLAUDE.md bullet. The **runner-level** step is a plain `ChoiceGroup<RunnerLevel>` with five identity-cue cards (Beginner → Elite); persisted on `users.runner_level`, drives agent communication tone only (no plan effect). Review row only shows when non-default. Spec: `docs/superpowers/specs/2026-05-11-onboarding-runner-level-design.md`.
5. `/onboarding/generating` — polls `GET /onboarding/plan-generation/latest` every 2s while the queue worker runs the deterministic builder + AI reply (~5-15s)
6. `/coach/chat/{conversation_id}` — final destination, `ProposalCard` rendered inside the agent chat

The form's **run-type ranking** step is a `ReorderableListView` showing `Easy / Tempo / Intervals / Long runs` as drag-able cards (entire card is the drag target via `ReorderableDragStartListener`, no long-press needed). Top = favourite, bottom = least preferred. The order maps to `run_type_preferences` in the request payload as a list of canonical strings (`easy` / `tempo` / `interval` / `long_run`) which the backend's `TrainingPlanBuilder` reads to bias quality-slot type, easy→quality upgrades at 5+ days/week, and the long-run length cap. See `lib/features/onboarding/screens/onboarding_form_screen.dart::_RunTypePreferencesStep` and `RunTypePreferenceOption` enum.

The **generating screen** estimates duration via `_estimateSeconds` based on whether `additional_notes` is set: ~8s without notes (build + reply), ~16s with notes (the AI may call `adjust_onboarding_plan` for injuries / preferences). Plan length doesn't affect runtime — the deterministic builder is ~20ms regardless of weeks.

Note: Level and weekly km capacity are derived by the backend from the synced run history — onboarding only asks for coach style (motivational/analytical/balanced) plus race specifics + run-type ranking.

**Router redirect ordering** (`app_router.dart` redirect callback): the rule order matters. `isLoggedIn && isAuthRoute → /dashboard` MUST run AFTER the onboarding-incomplete check, otherwise a fresh user who just signed in via dev-login / Apple Sign-In gets shortcut to `/dashboard` and never sees onboarding. The current order is: (1) `!isLoggedIn && !isAuthRoute → /auth/welcome`, (2) pending plan-generation routing, (3) `hasCompletedOnboarding == false → /onboarding`, (4) `isLoggedIn && isAuthRoute → /dashboard` as final fallback.

**Web onboarding skip:** HealthKit is unavailable in browser, so the `/onboarding/connect-health` screen would just sit on a permission prompt that never resolves. The router has two `kIsWeb` guards that skip it: (a) `/onboarding` redirects to `/onboarding/overview` instead of `/onboarding/connect-health`, and (b) a direct hit on `/onboarding/connect-health` bounces to `/onboarding/overview` (zones comes after overview now). The backend `DevOnboardingSeeder` pre-populates wearable activities + age-derived HR zones for the dev user so the downstream screens have real data (see `api/CLAUDE.md` → "Local dev seed"). On native iOS the connect-health screen still runs normally — the skip is web-only.

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

**RunBoost rebrand (global house style — Brand Guidelines Edition 01).** The brand is **Anton** (hero display, UPPERCASE, leaned −9°), **Inter** (body/UI/titles — the workhorse), **Space Mono** (kickers/eyebrows/technical labels). **No serif anywhere** (EB Garamond is retired). Exact palette tokens on `AppColors`: `rbInk #171206`, `rbGold #E9B638`, `rbCream #FDF9ED`, `rbGoldDeep #C9971F` (gold for type on light bg), `rbGoldSoft #F8E4AE`, `rbStone #8A7547`. So far the **global** layer is migrated: `RunCoreText` now maps serif→Inter and kickers→Space Mono (method names unchanged, every call site inherits); `AppColors.primaryInk` is the brand ink; and the logo component `RunCoreLogo`/`RunCoreStar` (`core/widgets/runcore_logo.dart`) now renders the outlined RunBoost lockup/spark from `core/widgets/runboost_logo.dart` (`RunBoostWordmark` draws `assets/icons/runboost_logo.svg` inlined; `wordmarkColor`/`sparkColor` swap the SVG fills for reversed/mono lockups). `RunBoostText` (in `app_theme.dart`) holds the Anton display + Space Mono kicker helpers. **Page/section headings** use the `RunBoostHeading` widget (`runboost_logo.dart`) — Anton, UPPERCASE, −9° lean — now applied to the Schedule / Coach-list / Goals tab titles and the dashboard `_TodayCard` title; use it for any new screen title. **Titles migrated to Anton:** every screen/section/card/sheet title now uses `RunBoostHeading` (tabs, detail heroes, onboarding, plan/schema presentation in `plan_content.dart`, sheets, cards, paywall, coach empty-state, dashboard cards). Remaining `GoogleFonts.ebGaramond` is intentional — only **numbers** (`compliance_ring`, training-result pace/distance/time values) and one onboarding **caption**, NOT titles. Welcome screen keeps its bespoke Anton slogan (gold hit-block on "SMARTER,"). **Still using old fonts (later pass):** body/label `GoogleFonts.spaceGrotesk` / `publicSans` calls in feature screens, and the Card+CTA snippet below still documents the OLD title font.

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

Native MethodChannel bridge `nl.runcoach/workout` (`ios/Runner/WorkoutScheduling.swift`, registered in `AppDelegate.didInitializeImplicitFlutterEngine`). The watch is kept in sync **automatically** — runners no longer have to press a per-day button before going running. The manual button remains as a force-resync for one day at a time.

**Auto-sync triggers (Flutter side, all routed through `WatchSyncService` in `features/schedule/services/watch_sync_service.dart`):**
- **Plan accept** (`coach_provider.dart::ProposalActions.accept` + `CoachChat.acceptProposal`) → `syncUpcoming(7)`. First place the WorkoutKit permission prompt fires for most runners.
- **Reschedule day** (`reschedule_day_sheet.dart::_save`) → `syncUpcoming(7)` (replaces the old `rescheduleIfPresent` single-day call).
- **Notification accept** (`notifications_provider.dart::Notifications.accept`) → `syncUpcoming(7)` (covers pace-adjustment cascades and any future plan-mutating notification type).
- **App foreground** (`workout_sync_lifecycle.dart::_maybeSync`) → `syncDeltas()` — re-ships only days whose server-side `TrainingDay.updated_at` is newer than the locally-stored `lastSyncedAt[dayId]` (in `shared_preferences` under `watch_synced_at_v1`). No-op when nothing changed.

**Native methods:**
- **`syncDays`** (batch, iOS 17.4+) — used by `WatchSyncService`. One auth gate + one `scheduledWorkouts` read for up to N days. Args: `{days: [{dayId, date, distanceKm?, displayName?, warmupSeconds?, cooldownSeconds?, steps?}, ...]}`. Returns `{status: 'ok'|'denied'|'unavailable', results: [{dayId, status: 'scheduled'|'skipped'|'failed', message?}]}`.
- **`scheduleRun` / `scheduleIntervals`** (per-day) — backing the manual Send-to-watch button. Always replace any prior plan with the same `dayId` UUID (the old `.duplicate` short-circuit was removed — content edits now propagate). Return `{status: 'scheduled'|'denied'|'unavailable'|'failed', message?}`.
- **`rescheduleIfPresent`** — kept for backward compat but no longer called by the app code. `reschedule_day_sheet` now goes through `WatchSyncService.syncUpcoming`. Remove the native method if it's still unused after a release cycle.

**Identity tracking** (iOS 17.4+): every `WorkoutPlan` carries a deterministic UUID derived from `TrainingDay.id`: `00000000-0000-0000-0000-{dayId masked to 48 bits as 12 hex chars}` (`WorkoutScheduling.uuidForDay`). The mask prevents 64-bit overflow from breaking the UUID format. Without it the parse would silently fall back to a random UUID and defeat identity tracking. With it, `syncDays` and the per-day methods can find-and-replace our own scheduled plan without disturbing other apps' workouts on the same day.

**iOS 17.0–17.3 fallback:** no identity tracking, so `syncDays` returns `status=unavailable` outright (would otherwise create duplicate entries on every batch). The manual per-day button still works — multiple sends just stack up as multiple entries until the runner prunes them in the Fitness app. Rare audience in 2026.

**Permission UX:** the WorkoutKit prompt fires the first time `syncUpcoming` runs (almost always at plan-accept). Earlier surfaces (the manual button) still trigger it too if they get there first. The auth state is read once at the top of the batch; subsequent days in the same call don't re-prompt.

**Interval payload shape** (canonical reference: `buildIntervalPlan` in `workout_scheduler_service.dart`, top-level — used by BOTH the manual button and the batched auto-sync, so the rules live in exactly one place):
- Warmup hoisted to its own slot, time-based, clamped to [15s, 120s].
- Work + recovery flow into the IntervalBlock as steps.
- Cooldown hoisted to its own slot, time-based, clamped to [60s, 600s]; synthesized at 300s if the day's `intervals_json` lacks one (defensive — covers pre-rule data).
- Distance-based recoveries are converted to seconds via 360 sec/km. Cooldown segments are NEVER sent as steps.

**Cannot be tested on the iOS Simulator.** WorkoutKit + Fitness app sync only work on real hardware. Unit tests for `WatchSyncService` (`test/features/schedule/services/watch_sync_service_test.dart`) mock the scheduler service so the delta-detection logic and 7-day clamp are covered without the bridge.

**Pbxproj entries:** `WorkoutScheduling.swift` is registered in `Runner.xcodeproj/project.pbxproj` in 3 places (PBXBuildFile, PBXFileReference, PBXGroup, PBXSourcesBuildPhase). When adding new `.swift` files in `ios/Runner/`, replicate the pattern of `HealthKitPersonalRecords.swift` / `PushNotifications.swift` there or `flutter run` fails with "Cannot find 'X' in scope".

**Plan:** `docs/superpowers/plans/2026-05-19-watch-auto-sync.md`.

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

**Interval data is the GROUPED blueprint** — `TrainingDay.intervals` is an `IntervalBlueprint` (`lib/features/schedule/models/interval_blueprint.dart`): `{warmupSeconds, steps:[IntervalStep block|rep|rest], cooldownSeconds}`, mirroring the backend. "4×800 then 4×400" = two block steps. The parser (`training_day.dart::_intervalsFromJson`) reads the grouped Map and folds a legacy flat List for unmigrated rows. `IntervalBlueprint.expand()` unrolls to a flat `List<TrainingInterval>` so the existing `TrainingIntervalsTable` effort-chart + send-to-watch (`buildIntervalPlan`) keep working unchanged (native WorkoutKit still receives flat steps; native `IntervalBlock(iterations:)` is a deferred refinement).

**Interval pace tile**: on `type=='interval'` days `TrainingDay.targetPaceSecondsPerKm` is null by design (the day-level field doesn't apply to intervals — see `api/CLAUDE.md` → "Interval pace contract"). Read the displayed value via the `TrainingDayPaceX` extension's `displayPaceSecondsPerKm` getter instead — it returns the work-set average (mean of `kind=work` segment paces) for intervals and the day-level field for everything else. The pace tile also hides its `actual` value on intervals: a full-run avg that mixes warmup + recovery + cooldown isn't comparable to per-rep work pace and would render as a misleading "fail" colour. The training-result screen's `_TargetVsActualSection` doesn't need similar treatment because it already hides the pace row when the target is null.

**Knowingly-duplicated work-set-avg logic in `PlanDetailsSheet`** (`features/coach/widgets/plan_details_sheet.dart::_displayPaceSeconds`): the proposal modal renders directly from `proposal.payload` (raw `Map<String, dynamic>`), so it can't reuse the `TrainingDayPaceX` extension which is bound to the Freezed `TrainingDay` model. The helper inlines the same mean-of-work-segment-paces rule — keep the two in sync when changing the contract.

### 14. HR-zone auto-derivation + onboarding step

Backend computes the 5-zone table from the runner's own data; the app surfaces it in two places (full backend details in `api/CLAUDE.md` → "HR-zone auto-derivation"):

**Onboarding step** (`/onboarding/zones`, AFTER `/onboarding/overview` — see section 6 for the full flow order):
- `OnboardingConnectHealthScreen` ingests workouts → reads `dateOfBirth` + `restingHeartRate` from HealthKit (best-effort, both null on permission denial) → calls `auth.deriveHeartRateZones(...)` → sets `onboardingDerivedZonesProvider` (`StateProvider<DerivedZones?>`-style codegen notifier in `features/onboarding/providers/onboarding_derived_zones_provider.dart`) → `context.go('/onboarding/overview')`. Failure is non-blocking — routes anyway with the provider holding null.
- `OnboardingZonesScreen` reads `user.dateOfBirth` + `user.heartRateZonesSource` + the provider to pick one of three state-bodies (`_HrConfirmedBody` / `_DobKnownBody` / `_NoDobBody`). State-C auto-opens the DOB picker once on first frame; state-B shows a big DOB row + collapsed advanced section with `HrZonesReadonlyList` + Edit link; state-A keeps the full bpm table + rich subtitle. Continue → `/onboarding/form`. Edit-zones → opens the same `HeartRateZonesSheet` used in the menu.
- Read-only display widget `lib/core/widgets/hr_zones_readonly_list.dart` is shared between the onboarding screen and any future non-editable surface (matches the visual language of the editable sheet).

**Recompute button in `HeartRateZonesSheet`** (menu → HR Zones):
- Sits above the Max HR field as a subtle pill ("Recompute from your runs"). Tapping reads DOB + RHR from HealthKit, **always shows the shared `showBirthDatePickerSheet`** (Cupertino date wheel) prefilled with HealthKit DOB → stored `user.dateOfBirth` → 30y-ago default. After Done it calls the derive endpoint, mirrors the result into the editable fields, and shows a notice line ("Updated — max ~191 bpm (estimated from age 35).").
- The notice is informational; the user still needs to hit Save to persist their values (which flips source back to `manual` because the values went through the editable form). Save = "I confirm these numbers"; the Recompute button = "redo the math".
- Network failures surface inline via `_error`; the sheet stays open.

**Shared DOB picker** (`lib/core/widgets/birth_date_picker.dart`) — `showBirthDatePickerSheet(context, {DateTime? initial})`. Modal popup with Cancel / "Date of birth" title / Done header + a `CupertinoDatePicker` in date mode. Used in three places: (1) onboarding zones screen when `source = 'default'`, (2) HR sheet recompute, (3) the deep-link landing screen for the birthday push.

**Yearly birthday push** (`birthday_zone_check`) — backend dispatches `BirthdayZoneCheckReminder` daily at 09:00 to users whose `date_of_birth` matches today. `PushService.routeFromPayload` maps it to `/profile/heart-rate-zones`, a thin `HeartRateZonesRouteScreen` (in `features/auth/screens/`) that opens the HR sheet on mount and falls back to `/dashboard` after dismiss. Tap → confirm/recompute zones in one motion.

**`User.heartRateZonesSource`** (Freezed string, mirrors `users.heart_rate_zones_source`): `'default' | 'derived_empirical' | 'derived_age' | 'manual'`. Drives subtitle copy on the onboarding screen and is exposed via `/profile`.

**`DerivedZones`** model (`lib/features/auth/models/derived_zones.dart`) is the wire shape for the derive response: `zones`, `source`, `maxHr`, `sampleCount`, `age`, `restingHeartRate`. All optional fields are null when the corresponding signal wasn't available.

Spec: `../docs/superpowers/specs/2026-05-08-hr-zones-auto-derive.md`.

### 15. Notifications inbox (action-required items)

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
- Per-type tertiary action (full-width below the row, `_TertiaryButton`): conditionally rendered when the type warrants it. **For `plan_evaluation`**: `View full report` with doc icon → pops the sheet + `context.push('/schedule/evaluation/${evaluation_id}')` so the runner can read the AI markdown report before deciding.

**Adding a new notification type:**
1. Backend produces the row with a new `type` string + `action_data` shape (see `api/CLAUDE.md`).
2. (Optional) extend `_typeLabel` switch in `notifications_sheet.dart` for a humanised eyebrow label — falls through to `replaceAll('_', ' ').toUpperCase()` if not added.
3. (Optional) add a tertiary action arm in `_NotificationCard.build` (the `if (n.type == 'plan_evaluation')` block) when the type has supporting context worth surfacing on the card.

**Plan evaluations** (2-week check-in): `PlanEvaluation` rows live alongside training days on the active goal. `EvaluationCard` (`features/schedule/widgets/evaluation_card.dart`) renders them inline in `weekly_plan_screen.dart` — distinct white card with gold-glow eyebrow, no km/pace tiles, status glyph + status title + `scheduled_for` + `Open` CTA. Statuses: `pending` / `processing` (non-tappable), `ready` / `no_change_needed` / `accepted` / `dismissed` (tap → `/schedule/evaluation/{id}`). `EvaluationDetailScreen` shows the markdown report via `GptMarkdown` plus, when present, an embedded `PlanContent` widget over the proposal payload — same diff-rendering as the coach-chat revision card. Apply/Dismiss CTAs route through `NotificationsProvider.accept`/`dismiss` for the linked notification so the existing watch-sync side-effect + proposal-apply fires. Endpoints: `GET /plan-evaluations` (list for active goal), `GET /plan-evaluations/{id}` (full detail with eager-loaded proposal). Plan: `docs/superpowers/plans/2026-05-22-plan-evaluations.md`.

### 16. Screen intro animations

Tasteful Apple-style entry animations on tab roots and detail screens. Two helpers in `lib/core/widgets/intro_fx.dart`:

- **`IntroFx`** — wraps a single widget with a 320ms fade + 4% upward slide (`Curves.easeOutCubic`). Use on detail screens where the whole content panel should drift in as one unit.
- **`IntroColumn`** — a `Column` with a 60ms stagger between children. Use on tab roots with a small number of cards.

Both honor `MediaQuery.disableAnimations` (renders the child at its final state when Reduce Motion is on) and always end at the visible rest state — an interrupted run can never leave content hidden.

Currently applied to: `dashboard_screen.dart` (staggered cards), `weekly_plan_screen.dart` (whole `_WeekPages`, plays once on mount — page-view swipes between weeks are unaffected), `training_day_detail_screen.dart`, `coach_chat_list_screen.dart`, `goal_list_screen.dart`, `goal_detail_screen.dart`. **Don't** wrap the detail screen scaffold itself when GoRouter pushes it on `_rootNavigatorKey` — the iOS slide-in already covers entry; animate the inner content panel instead. **Don't** stagger every row of an unbounded `ListView.builder`; intros fire per build and replay during scroll recycling.

Backed by `flutter_animate` (zero codegen, no `build_runner` involvement, so safe alongside Freezed 3.x / no-`custom_lint`).

### 17. i18n (locale state + ARB plumbing)

Official Flutter stack: `flutter_localizations` (SDK) + `intl` + ARB files + `flutter gen-l10n`. Configured by `l10n.yaml` at the project root (`nullable-getter: false`). Strings live in `lib/l10n/app_en.arb` (template) + `lib/l10n/app_nl.arb`. The generator output (`app_localizations.dart` + `app_localizations_{en,nl}.dart`) lives in `lib/l10n/` and IS committed to git (the modern Flutter default after `synthetic-package` was deprecated). Codegen auto-runs on `flutter pub get` / `flutter run`.

`appLocaleProvider` (`lib/core/i18n/locale_provider.dart`, `@Riverpod(keepAlive: true)`) is the single source of truth for the app's active locale. On first launch it reads `PlatformDispatcher.locales` and returns Dutch only when one of the device's preferred languages is Dutch (`languageCode == 'nl'`) — country code intentionally ignored. Reasoning is in the design doc: Belgian francophones (`fr_BE`) should get English, Dutch expats abroad (`nl_DE`) should get Dutch, English-speaking Dutch natives (`en_NL`) should get English. The user's *language* signal already encodes intent; the country code is a regional/formatting signal only. User overrides persist in `shared_preferences` under `app_locale_override`. `setOverride(null)` reverts to auto-detection.

Side-effects of `setOverride`: writes `currentAppLocaleTag` (top-level mutable in `lib/core/i18n/current_locale.dart`, read by the Dio interceptor on each request) AND `appDateLocale` (existing global in `lib/core/utils/date_formatter.dart`, used by the `formatDate` helpers). Then **fire-and-forget** `PUT /profile` to push the choice to the backend so `users.locale` follows along — the local override applies instantly regardless of network state.

`CupertinoApp.router` in `app.dart` wires `locale: appLocaleProvider.value`, `localizationsDelegates: AppLocalizations.localizationsDelegates`, `supportedLocales: AppLocalizations.supportedLocales`. `AppLocalizations.localizationsDelegates` transitively includes `GlobalMaterialLocalizations.delegate` (so `showModalBottomSheet` etc. continue to work — see section 5b).

**Widget access**: `context.l10n.appTitle` via the `BuildContextL10n` extension in `lib/core/i18n/build_context_l10n.dart`. **Non-widget access** (services, providers that compose user-visible strings): `ref.watch(appLocalizationsProvider)` returns `Future<AppLocalizations>` and rebuilds when the locale changes.

**Backend communication**: `LocaleInterceptor` (`lib/core/api/locale_interceptor.dart`, registered before `AuthInterceptor` in `dio_client.dart`) adds `Accept-Language: <BCP-47>` to every outgoing request. The Laravel `SetLocale` middleware reads it and sets `App::setLocale()` per request so validation errors, push notifications dispatched in that request's flow, and agent output (Phase 4) all come back in the runner's language.

**Phase 3 (UI string extraction) is complete** — all user-facing copy in `features/**/` and `core/widgets/**/` reads from `context.l10n.*`. Both ARB files (`app_en.arb` / `app_nl.arb`) carry the full key set; `flutter gen-l10n` re-runs on `flutter pub get`.

**Settings → Language picker** (`lib/core/widgets/language_picker_sheet.dart`) is mounted in the profile menu via `_SettingRow(icon: CupertinoIcons.globe, …, onTap: showLanguagePickerSheet)`. Three options: English, Nederlands, System default (auto-detect). Tapping a language calls `appLocaleProvider.notifier.setOverride(locale)` → instant UI re-render + fire-and-forget `PUT /profile`.

**Localized error strings via sentinel codes** (`lib/features/coach/utils/coach_error_codes.dart`) — client-side errors (Dio timeouts, connection refused, server-status fallbacks) are stored on `CoachMessage.errorDetail` as opaque sentinel codes (`__coach_err:request_timed_out__`, `__coach_err:server_status:404__`, etc.) instead of pre-translated strings. `localizedCoachError(context, detail)` resolves them at widget build time. Server-provided error strings pass through unchanged (backend already honours `Accept-Language`). Pattern lets locale changes live-update without rewriting message-store rows.

**Tool-name localization in coach stream** — `VercelStreamParser` emits raw tool names (`get_recent_runs`, `build_plan`, etc.); `message_bubble.dart` maps them to localized "Thinking…" labels via a switch. Adding a new tool: add an ARB key + a switch arm; the parser stays untouched.

Spec: `../docs/superpowers/specs/2026-05-12-i18n-multilingual-research.md`. Phase 1+2 plan: `../docs/superpowers/plans/2026-05-12-i18n-foundation.md`. Phase 4 (agent localization via `LanguageDirective`) is documented in `../api/CLAUDE.md` → "i18n (locale resolution + translation files)".

### 18. Lapsed-user hard paywall

Onboarded runners with no active Pro entitlement (a lapsed subscriber, an admin-revoked user, or a **pre-subscriptions grandfathered** user who finished onboarding before subscriptions shipped) are hard-gated to `/paywall` on every cold start. Without this they'd reach the full app shell but coach chat 402s and AI run-analysis silently no-ops (the job-level `isPro()` guard) — a broken half-state.

- **Router gate** (`app_router.dart` redirect): `isLoggedIn && hasCompletedOnboarding == true && pending == null && entitlement.resolved && !entitlement.isPro && location != '/paywall' → '/paywall'`. Sits AFTER the pending-plan-generation block and the onboarding-incomplete block, so fresh-onboarding flows take priority.
- **No flash for payers**: gated on `ProEntitlementState.resolved` (hand-written field on the state class — NOT freezed). Set true only once `/subscriptions/sync` (or the client fallback) returns a definitive answer. The entitlement sync is async on cold start, so without `resolved` a paying user would briefly bounce to `/paywall` before the sync confirms Pro. With it, a Pro user is never flashed; a non-Pro user sees the dashboard shell for ~the sync latency, then lands on the paywall. If the sync fails (offline), `resolved` stays false → the user is NOT locked out by a transient network blip.
- **Screen** (`features/subscriptions/screens/paywall_screen.dart`): a *bare* paywall — unlike `PlanPreviewScreen` there's no freshly-generated plan to tease. Value-prop copy (`paywallLapsedTitle` / `paywallLapsedSubtitle` l10n keys) + the RevenueCat sheet auto-presented on mount + a fallback "Unlock" CTA that re-opens it (matters while RevenueCat Error 23 / Paid-Apps-Agreement processing blocks the sheet). On purchase/restore → `syncFromServer(fromPurchase: true)` → `/dashboard`. `PopScope(canPop: false)` — hard, no skip. Debug builds show a "Simulate payment" button (dev-activate → `/dashboard`).
- **Run ingestion stays free**: the gate is on AI endpoints (`require.pro`), NOT `POST /wearable/activities`, so a locked user's history keeps building — they get full value the moment they resubscribe.
- **Admin unblock**: grant Pro via `/admin/users` (see `../CLAUDE.md`); next cold-start sync flips `resolved + isPro` and the gate releases to `/dashboard`.

### 19. Off-plan runs ("buiten schema")

Runs that didn't auto-match a planned session (backend now matches on the exact date only — see `../api/CLAUDE.md` → "Off-plan run linking") surface as **blue** entries the runner can link.

- **Model**: `TrainingWeek.unplannedRuns` (`List<WearableActivitySummary>?`, JSON `unplanned_runs`) — reuses the existing summary model, no new model.
- **Schedule** (`weekly_plan_screen.dart`): `_WeekBody` merges planned days + off-plan runs into one weekday-ordered list (`_WeekEntry`); off-plan rows render as `_UnplannedRunTile` — a blue clone of `_DayTile` (blue halo, plus glyph, distance·pace subtitle). Tap → `showUnplannedRunSheet(context, run:, goalId:)`.
- **Sheet** (`features/schedule/widgets/unplanned_run_sheet.dart`): two-state `showCupertinoModalPopup`. Details (run stats + blue "Koppel aan training" CTA) → picker ("Kies een training") listing uncompleted, non-race sessions within **±7 days** of the run (computed client-side from `scheduleProvider(goalId)`; the plan's last-dated/race day is excluded). Tap a row → `LinkUnplannedRun` mutator → `POST /wearable/activities/{id}/link-day` → the chosen session **relocates onto the run's date** + is scored, `planVersion.bump()` refreshes everything. No watch-sync (the day lands in the past).
- **Dashboard** (`dashboard_screen.dart`): `_CellState.unplanned` colours an otherwise-rest weekday slot blue in BOTH the 7-day bar chart and the multi-week matrix (`_buildWeekCells` overlay, `targetKm` from the run's distance so the bar has height), plus an "Off-plan" `_LegendDot`.
- **Tokens**: `AppColors.offPlan` (#3E72C7) + `AppColors.offPlanGlow`. **l10n**: `schedOffPlan*`, `dashLegendUnplanned`, `commonBack`.

### 20. HealthKit background auto-sync (Strava-style)

New runs auto-sync to the backend while the app is backgrounded/terminated, so the AI analysis + the existing `WorkoutAnalyzed` push are ready before the runner opens the app. The Flutter foreground sync (`WorkoutSyncLifecycle`) stays as the guaranteed fallback. Spec: `../docs/superpowers/specs/2026-06-02-healthkit-background-sync.md`.

- **Native is the whole engine.** `ios/Runner/HealthKitBackgroundSync.swift` owns an `HKObserverQuery` on `workoutType()` with `enableBackgroundDelivery(.immediate)`, fetches only new runs via an `HKAnchoredObjectQuery`, builds the payload **in Swift** (mirrors `health_kit_service.dart::_shape()`), and POSTs to `/wearable/activities` with `URLSession` — because the Dart engine isn't running on a background launch (`flutter/flutter#103384`). HR avg/max via workout-scoped `HKStatisticsQuery(predicateForObjects(from:))` (more accurate than the Dart time-window read). **No backend changes, no new push types** — downstream (match → score → AI → `WorkoutAnalyzed`) is unchanged.
- **Config bridge** `nl.runcoach/bg-sync` (Dart `BackgroundSyncService`, `features/wearable/services/background_sync_service.dart`): Dart hands native the two things it can't see — `baseUrl` (from `dio_client.dart`) + the Sanctum `token`. `configure` stores baseUrl in `UserDefaults` + token in the **Keychain** (`kSecAttrAccessibleAfterFirstUnlock`, so a locked-device wake can authenticate) and arms the observer; `clear` wipes the token + stops delivery. Wired in `auth_provider.dart`: `configure` after login (dev + Apple) and in `loadProfile` (cold start); `clear` in `logout` + `deleteAccount`. iOS-only no-op via `defaultTargetPlatform`.
- **Observer re-armed every launch** from `AppDelegate.didFinishLaunchingWithOptions` (`HealthKitBackgroundSync.shared.start()`) — observers don't survive launches; `start()` is a no-op until credentials are configured. Channel registered in `didInitializeImplicitFlutterEngine` (plugin name `"BackgroundSync"`).
- **Anchor priming** (`bg_sync_workout_anchor_v1` in UserDefaults): first fire with no anchor records a baseline WITHOUT posting, so the background path never replays history (foreground sync owns backfill). Anchor only advances on a 2xx POST (failed POST retries next wake). `clear()` resets the anchor so a new login re-primes.
- **Caveats** (documented in the spec): force-quit suspends delivery until the next manual launch (same as Strava); only Apple Watch users (or apps that write `HKWorkout`) have runs to deliver; `.immediate` latency is best-effort. **Pbxproj**: `HealthKitBackgroundSync.swift` registered in the 4 standard spots (IDs `AB10A1B8…BGSYN` / `AB10A1B9…BGSYN`). **Cannot be tested on the simulator.**

### 21. Edit-day sheet + interval block editor

`edit_day_sheet.dart` (opened from the day-detail action sheet, hidden for completed days) PATCHes `/training-days/{id}` directly — no proposal flow. It branches on `day.type`:

- **Regular days**: distance + pace wheel rows.
- **Interval days**: `interval_blueprint_editor.dart` — warm-up row (0 = none, ≤120s), one card per work block (reps 1–30, distance 100–2000m or time per rep, pace wheel, recovery), add/remove block (min 1 enforced by the backend's normalize), cool-down row (60–600s), and a live "Distance (auto)" footer. Day-level distance/pace are NOT sent for interval days — the backend derives `target_km` from the stored blueprint (saving-hook invariant) and the response carries it back.
- **Coach-authored standalone rep/rest steps** render as locked rows and pass through unchanged (lossless for pyramids).
- `IntervalBlueprint.estimateTotalKm()` (on the model) mirrors the PHP estimator constant-for-constant; `test/features/schedule/models/interval_blueprint_estimate_test.dart` uses the exact PHP test vectors so the implementations can't diverge. Editor behaviour: `test/features/schedule/widgets/interval_blueprint_editor_test.dart`. Spec: `../docs/superpowers/specs/2026-06-10-app-interval-editor-design.md`.

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

**HealthKit background delivery** is now implemented — see section 19. The `com.apple.developer.healthkit.background-delivery` entitlement is in `Runner.entitlements`; it must ALSO be enabled on the App ID at developer.apple.com (HealthKit → Background Delivery). No `Background Modes` / `UIBackgroundModes` are needed for pure `HKObserverQuery` delivery (common misconception). App Store / first external-TestFlight review needs a privacy-policy + a one-line justification in the review notes.

### Release builds + TestFlight

Three scripts in `app/scripts/` handle dev + release:

- **`bash scripts/run-dev.sh`** — auto-injects the Mac's LAN IP for `flutter run` against the local backend on a physical iPhone. See "Physical device setup" above.
- **`bash scripts/build-ios.sh`** — runs `flutter build ipa --release --dart-define=API_BASE_URL=https://runcoach.laravel.cloud/api/v1`. Override the URL with `API_BASE_URL=... bash scripts/build-ios.sh`.
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
- **Asserting heading copy**: `RunBoostHeading` renders its text UPPERCASE (brand contract, pinned in `test/core/widgets/runboost_heading_test.dart`), so `find.text('Week 2 check-in')` finds nothing. Use `findHeading(...)` / `findHeadingContaining(...)` from `test/helpers/finders.dart` — they match the l10n-cased copy on the widget, leaving the case transform owned by the design system.
- **Never let a test reach the real `AuthApi`/Dio stack**: `AuthInterceptor` reads `flutter_secure_storage` (MissingPluginException in tests) and unit tests would otherwise fire real HTTP at a running dev backend. Override `authApiProvider` with a recording fake (see `test/core/i18n/locale_provider_test.dart`). The interceptor itself now rejects with a catchable `DioException` when token storage throws (instead of hanging the request + leaking an unhandled zone error — `test/core/api/auth_interceptor_test.dart`).

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
