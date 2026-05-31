# RunCoach

Personal AI running coach app. iOS-first with Sign in with Apple + Apple HealthKit for activity data. The data layer is wearable-agnostic (`wearable_activities` table with a `source` enum) so Garmin, Polar, Strava etc. can be added later — likely via [Open Wearables](https://openwearables.io). Users get AI-generated training plans for upcoming races, automatic activity matching with compliance scoring, and an agentic coach chat that has full access to their synced run history.

## Repository Structure

Monorepo with three top-level directories:

```
runcoach/
├── api/     — Laravel 13 backend (see api/CLAUDE.md)
├── app/     — Flutter mobile app (see app/CLAUDE.md)
└── docs/    — Design specs and implementation plans
    └── superpowers/
        ├── specs/   — Feature design specs
        └── plans/   — Step-by-step implementation plans
```

**Always consult the relevant `CLAUDE.md` when working in that directory:**
- Working in `api/` → read `api/CLAUDE.md` for Laravel conventions, the AI agent system, wearable ingestion
- Working in `app/` → read `app/CLAUDE.md` for Flutter architecture, state management, design system

## What the app does

1. User signs in with Apple (native iOS dialog → identity-token exchange → Sanctum bearer)
2. App requests Apple Health read access, pulls the last 90 days of running workouts, and pushes them to the backend
3. New workouts get pushed by the app on every visit to the connect-health screen (background-delivery via `HKObserverQuery` is a deferred polish)
4. User talks to an AI coach that has full access to their synced run history (`wearable_activities`) and can create personalized training plans
5. Training plans auto-match each ingested activity to a planned session with compliance scoring (pace/distance/HR)
6. User gets per-run AI feedback and weekly insights

## High-level architecture

```
┌──────────────────────┐        ┌────────────────────────────┐
│   Flutter Mobile App │ HTTPS  │   Laravel 13 API           │
│   (iOS only — uses   │────────│                            │        ┌──────────┐
│    HealthKit)        │        │  • Sanctum token auth      │────────│ Anthropic│
│  • Riverpod          │        │  • Sign in with Apple      │        │  API     │
│  • Freezed models    │        │    (firebase/php-jwt)      │        └──────────┘
│  • Retrofit + Dio    │        │  • Laravel AI SDK agent    │
│  • GoRouter          │        │  • MySQL + Filament admin  │        ┌──────────┐
│  • health package    │        │  • Queue (database driver) │────────│ Apple    │
│  • sign_in_with_apple│        │                            │        │ JWKS     │
└──────────────────────┘        └────────────────────────────┘        └──────────┘
       │
       │ HKWorkout reads on-device
       ▼
┌──────────────────┐
│  Apple HealthKit │
└──────────────────┘
```

### Data flow
- **Auth**: Flutter `sign_in_with_apple` → identity token (JWT) → `POST /auth/apple` → backend verifies signature against Apple's JWKS (`AppleIdentityTokenVerifier`, cached 1h), upserts user by `apple_sub`, returns Sanctum bearer → stored in `flutter_secure_storage`
- **Activity ingestion**: `OnboardingConnectHealthScreen` (and any future periodic sync) calls `HealthKitService.fetchWorkouts()` → batches to `POST /wearable/activities` → backend upserts on `(source, source_activity_id)` → dispatches `ProcessWearableActivity` job per row → matches to active training day + scores compliance → queues `GenerateActivityFeedback` + `GenerateWeeklyInsight`
- **Onboarding plan generation**: `POST /onboarding/generate-plan` returns 202 + a `plan_generations` row id → `GeneratePlan` job runs the agent loop in the worker (~60-110s) → Flutter `OnboardingGeneratingScreen` polls `GET /onboarding/plan-generation/latest` every 3s → on completion navigates to `/coach/chat/{conversation_id}`. The `pending_plan_generation` field on `/profile` + auth responses lets the router resume the loading screen on cold start
- **AI Coach**: user message → `RunCoachAgent` (Laravel AI SDK) → agent autonomously calls tools (`GetRecentRuns`, `SearchActivities`, `GetActivityDetails`, `GetCurrentSchedule`, `CreateSchedule`, etc. — all read from local DB, no live external API) → response + optional proposal returned
- **Schedule proposals**: `CreateSchedule`/`ModifySchedule` tools return `requires_approval: true` payloads → detected in `tool_results` of the agent's message → stored as `CoachProposal` → user accepts/rejects → `ProposalService` applies changes

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile | Flutter, Riverpod (code gen), Freezed, Dio + Retrofit, GoRouter, flutter_secure_storage |
| Backend | Laravel 13, Sanctum, laravel/ai (agent SDK), Filament 4 admin |
| Database | MySQL |
| Queue | Laravel queues (database driver) |
| AI | Anthropic `claude-sonnet-4-6` by default (swappable via Laravel AI SDK `AI_PROVIDER`/`AI_MODEL`) |
| Dev tools | Laravel Boost (MCP + skills), Pint, PHPUnit, Filament admin |

## Key Architectural Decisions

### 1. Agentic coach with Laravel AI SDK (not custom tool loop)
The coach was initially a custom `CoachChatService` that manually orchestrated OpenAI tool calls. It was refactored to use **Laravel AI SDK's `Agent` contract** with `RemembersConversations` trait. This means:
- Conversations persist automatically in `agent_conversations` / `agent_conversation_messages` tables
- The SDK handles the agent loop (tool calling, iteration limits)
- Tool results are stored in `agent_conversation_messages.tool_results` JSON column
- Proposal detection queries that column after the prompt completes

### 2. Wearable-agnostic local mirror
Activities live in the local `wearable_activities` table with a `source` enum (`apple_health`, `strava`, `garmin`, `polar`, …). The Flutter app pushes them via `POST /wearable/activities`; AI tools query the local DB only — no live external calls. Adding a new provider (e.g. Open Wearables for Garmin/Polar) is a backend service that writes rows with a different `source` value; the schema, AI tools, and onboarding flow don't change. See `api/CLAUDE.md` → "Wearable ingestion" for the table shape.

### 3. Proposal/approval flow for mutations
Schedule creation and modification return proposals that require user approval before being persisted. The AI tools (`CreateSchedule`, `ModifySchedule`) return JSON payloads with `requires_approval: true` — they never mutate state directly. `ProposalService::apply()` handles persistence only after user acceptance.

### 4. UUIDs for conversation IDs
Conversation IDs are UUIDs (36-char strings) because the Laravel AI SDK uses them. Do NOT use `int` for conversation IDs anywhere in the codebase — not in the Flutter models, route params, or API clients.

### 5. Tool schemas — required-on-every-param
All Tool schemas must declare `->required()` on every parameter. For optional params, use `->required()->nullable()`. This was originally for OpenAI strict mode but we keep it for provider portability; Anthropic is fine with it.

### 5b. Anthropic integration quirks (Laravel AI SDK v0.5.1)
Two HTTP middlewares live in `api/app/Ai/Support/` and patch every outgoing Anthropic request via `Http::globalRequestMiddleware` (registered in `AppServiceProvider`):
- **`AnthropicToolInputSanitizer`** — fixes a SDK round-trip bug where `tool_use.input` is serialized as `[]` instead of `{}` for tools with no arguments (PHP can't distinguish empty JSON object vs array after `json_decode(assoc=true)`). Anthropic rejects the `[]` form with a 400.
- **`AnthropicPromptCaching`** — adds `cache_control: ephemeral` to the last tool definition, which caches `system` + all `tools` on the Anthropic side. For multi-turn conversations (onboarding, coach) this cuts input token cost ~10× from turn 2 onward. Cache hits appear in the `token_usages` table as `cache_read_input_tokens`.

### 5a. Agent tool design benchmark
When adding or refactoring AI tools, consult **[r-huijts/strava-mcp](https://github.com/r-huijts/strava-mcp)** ([tools folder](https://github.com/r-huijts/strava-mcp/tree/main/src/tools)) as a reference for tool shape. We don't actually call Strava — but the MCP's tool boundaries (one per use case, narrow params, opinionated descriptions) are a good model. Key takeaways — elaborated in `api/CLAUDE.md` under "Tool design guidelines":
- One tool per *use case*, not per endpoint (separate "latest N" from "ranged query")
- All optional params use `required()->nullable()` with handler-side defaults
- Tool descriptions explicitly list matching queries AND counter-examples ("DO NOT use for X, use `<other_tool>` instead")
- Param descriptions include format hints (`"YYYY-MM-DD, e.g. '2025-01-01'"`) and guardrails (`"max 50"`)
- Pre-compute aggregates in the response so the agent doesn't sum rows itself
- Always update `RunCoachAgent::instructions()` when adding a tool — tell the agent when to pick it vs the others

### 6. MySQL decimal columns return strings
Fields like `total_km`, `target_km`, `compliance_score` come back as strings from MySQL decimal columns. The Flutter Freezed models use custom `fromJson` converters (`app/lib/core/utils/json_converters.dart`) to safely handle both string and number JSON values.

## Running locally

### Backend
```bash
cd api
composer run dev                                # Laravel + queue worker + logs + vite
# OR for physical device testing (binds to 0.0.0.0):
php artisan serve --host=0.0.0.0 --port=8001
```

### Flutter app
```bash
cd app

# Simulator (default API_BASE_URL = http://localhost:8001/api/v1):
flutter run

# Physical iPhone — auto-detects the Mac's LAN IP and injects API_BASE_URL:
bash scripts/run-dev.sh                          # uses en0 (Wi-Fi), then en1
PORT=8000 bash scripts/run-dev.sh                # override the backend port
bash scripts/run-dev.sh -d <device-id>           # extra flags pass through
```

`scripts/run-dev.sh` removes the need to hand-edit `lib/core/api/dio_client.dart` whenever the LAN IP changes. The default fallback in `dio_client.dart` is `http://localhost:8001/api/v1` — fine for the simulator, useless on a physical device.

### Required env vars (api/.env)
- `APPLE_BUNDLE_ID` — defaults to `com.erwinwijnveld.runcoach`. Must match the iOS bundle id; the backend rejects any Apple identity token whose `aud` claim doesn't equal this string.
- `ANTHROPIC_API_KEY` — for the AI coach
- `AI_MODEL` — defaults to `claude-sonnet-4-6`
- `AI_PROVIDER` — defaults to `anthropic`
- `ADMIN_EMAILS` — optional comma-separated list of emails allowed into Filament admin at `/admin` (empty + local env = any logged-in user)
- `ADMIN_SEED_EMAIL` / `ADMIN_SEED_PASSWORD` — defaults `admin@runcoach.local` / `admin`, used by `AdminUserSeeder`

**No Strava env vars** — the Strava OAuth + webhook layer was removed. If/when Strava comes back via Open Wearables, the OW credentials live there, not here.

## Deployment

### Backend — Laravel Cloud
Prod API lives at **https://runcoach.free.laravel.cloud** (see `.laravel-cloud/README.md` for the full monorepo workaround).

- **Repo layout quirk**: Laravel Cloud only detects Laravel apps at the repo root, so a copy of `api/composer.lock` sits at the root purely for framework detection. If `api/composer.lock` changes, re-run `cp api/composer.lock composer.lock` and commit both. CI enforces this via `.github/workflows/composer-lock-sync.yml`.
- **Build command** (set in Cloud → Environment → Deployments): `bash .laravel-cloud/build.sh`. The script moves `api/` contents into the deployment root, then runs `composer install --no-dev` + `npm ci && npm run build`.
- **Deploy command**: `php artisan migrate --force && php artisan config:cache && php artisan route:cache && php artisan event:cache`
- **PHP settings**: `api/public/.user.ini` bumps `memory_limit=512M` and `max_execution_time=150` for web; `api/bootstrap/app.php` sets `memory_limit` for CLI (queue workers).
- **Env vars** to set in Cloud: `APP_KEY`, `APP_URL=https://runcoach.free.laravel.cloud`, `DB_*`, `APPLE_BUNDLE_ID=com.erwinwijnveld.runcoach`, `ANTHROPIC_API_KEY`, `AI_MODEL=claude-sonnet-4-6`, `AI_PROVIDER=anthropic`, optional `ADMIN_EMAILS`.

### iOS — TestFlight
Bundle ID `com.erwinwijnveld.runcoach`, team `GL5A9BW27X`. Flutter reads the API URL from `--dart-define=API_BASE_URL=...`; dev builds fall back to the LAN IP in `app/lib/core/api/dio_client.dart`.

Scripts in `app/scripts/`:
- **`build-ios.sh`** — runs `flutter build ipa --release --dart-define=API_BASE_URL=https://runcoach.free.laravel.cloud/api/v1`. Output: `app/build/ios/ipa/RunCoach.ipa`.
- **`upload-ios.sh`** — validates + uploads the IPA to App Store Connect via `xcrun altool`. Already configured on this machine — `APP_STORE_CONNECT_API_KEY_ID` + `APP_STORE_CONNECT_ISSUER_ID` are exported in `~/.zshrc`, and the `.p8` key is at `~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8`. Just run the script — no need to re-export anything.

Each release: bump `version: 1.0.0+N` in `app/pubspec.yaml` (the `+N` build number MUST increase every upload), then `bash scripts/build-ios.sh && bash scripts/upload-ios.sh`. Processing in App Store Connect takes 15–30 min before the build surfaces in the TestFlight tab.

### One-time iOS setup already done
- App Icon generated via `flutter_launcher_icons` from `app/assets/icon.png` (1024×1024 PNG, alpha stripped for iOS per App Store rules).
- Launch screen via `flutter_native_splash` (cream background #FAF8F4, icon centered).
- `CFBundleDisplayName=RunCoach`, `CFBundleName=RunCoach`, `ITSAppUsesNonExemptEncryption=false` (skips the export-compliance prompt on every upload since we only use HTTPS/TLS).
- **Sign in with Apple + HealthKit capabilities**: `app/ios/Runner/Runner.entitlements` contains `com.apple.developer.applesignin` (Default scope) + `com.apple.developer.healthkit` (with empty `healthkit.access` array = "all granted types"). All three Runner build configs (Debug/Release/Profile) reference this file via `CODE_SIGN_ENTITLEMENTS`. The same two capabilities must ALSO be enabled on the App ID `com.erwinwijnveld.runcoach` at [developer.apple.com/account/resources/identifiers](https://developer.apple.com/account/resources/identifiers) — without that, code signing fails with "provisioning profile doesn't include the entitlement".
- **Info.plist usage strings** for HealthKit: `NSHealthShareUsageDescription` (read-permission prompt copy) + `NSHealthUpdateUsageDescription` (we don't write).

## Workflow conventions

- **Design specs** go in `docs/superpowers/specs/YYYY-MM-DD-<topic>.md`
- **Implementation plans** go in `docs/superpowers/plans/YYYY-MM-DD-<topic>.md`
- Use Laravel Boost MCP tools (`search-docs`, `database-schema`) when working in api/
- Before implementing anything non-trivial, write a spec first, then a plan
- Commit often, descriptive messages, never commit without running tests first
- **Keep CLAUDE.md current.** After any relatively-large change (new feature, new endpoint, new native bridge, schema change, agent-prompt rule change, deployment quirk), append a concise bullet to the relevant CLAUDE.md (`./CLAUDE.md` for cross-cutting, `api/CLAUDE.md` for backend, `app/CLAUDE.md` for Flutter/iOS). One sentence + file:line pointer is enough — the goal is the *next* session can reconstruct the decision without re-reading every file. Skip for trivial fixes.

### "Noteer voor testen"

On "Noteer voor testen" (or variants), create **ONE** page in the Notion "Te Testen App" database (`collection://35dbc504-7e65-8001-8892-000bc07bcab4`) via `notion-create-pages`: `Name` = short title (≤8 words), body = korte beschrijving van feature, daaronder beknopt stappenplan met numbered list (één actie per regel; gebruik `## H2` sub-headings als er meerdere flows in zitten, bv. Happy path / Edge cases). Ack met de Notion-link, geen body in chat.

**Never split a single feature's test cases across multiple database rows.** Even when there are 8+ verification steps, they belong inside the body of one page — splitting them produces 12 separate rows in "Te Testen App" that the user has to manually clean up. One feature → one row → checkbox list inside.

### Never auto-push, build, or upload

Stop at the local commit. Wait for an explicit per-turn instruction before any of:

- `git push` to any remote (especially `main`)
- `bash scripts/build-ios.sh` (creates the IPA)
- `bash scripts/upload-ios.sh` (sends to TestFlight — burns a build number)

A previous "push to main" or "build and push iOS" instruction authorizes THAT one round-trip, not all future ones. After a follow-up edit, wait again — even when the previous turn ended with a successful upload. Each TestFlight upload propagates to App Store Connect and can't be cleanly undone.

## Testing

- **Backend**: `cd api && php artisan test --compact` — ~295 tests, all using `LazilyRefreshDatabase`
- **Flutter**: `cd app && flutter analyze && flutter test`
- Full test suite must pass before commits

## Filament admin

- Panel mounted at `/admin` (see `api/app/Providers/Filament/AdminPanelProvider.php`)
- Log in with seeded admin (`php artisan db:seed --class=AdminUserSeeder` → `admin@runcoach.local` / `admin`)
- Access gated via `User::canAccessPanel()` — `local` env allows any user, others require email in `ADMIN_EMAILS`
- Resources:
  - **Users** (`/admin/users`) — full user list (email/name/Pro status/Pro-until/onboarded). Per-row action group grants comp Pro (1 month / 1 year via `EntitlementSyncService::grantComp`) or revokes it (`::expire`). Read-only otherwise (no create — users come from Sign in with Apple). Use this to comp a tester whose RevenueCat purchase can't complete (e.g. Paid Apps Agreement still processing). Files: `app/Filament/Resources/Users/`. Test: `tests/Feature/Filament/UserResourceProActionsTest.php`.
  - **Token Usage** (`/admin/token-usages`) — tracks per-call token spend for every agent. Filter by context (`coach`, `onboarding`, `activity_feedback`, `weekly_insight`, `plan_explanation`, `running_narrative`), user, model. Dashboard widgets show totals this week, tokens by context, and top users. Rows are written by `App\Listeners\RecordAgentTokenUsage` which is auto-discovered from its `handle(AgentPrompted|AgentStreamed $event)` signature — DO NOT also register it manually via `Event::listen` or every call gets logged twice.

## Coach panel (separate from /admin)

Second Filament panel mounted at `/coach` (see `api/app/Providers/Filament/CoachPanelProvider.php`) for coaches managing their organization's runners. Pages: `GoalSchedule` (per-runner schedule editor), `OrganizationSettings`. Resources: `Clients`, `Coaches`. Has its own theme (`api/resources/css/filament/coach/theme.css`) compiled by Vite. Auth gating differs from `/admin` — coaches are scoped to their organization's runners only (see `User::canAccessPanel()` for the discriminator).

## Current state

Fully functional MVP on the `apple-health` branch:
- Sign in with Apple via `firebase/php-jwt` (verifies against Apple's JWKS, cached 1h)
- Apple HealthKit ingestion via Flutter `health` package + `POST /wearable/activities`
- Wearable-agnostic schema (`wearable_activities` with `source` enum) ready for Garmin/Polar via Open Wearables later
- AI coach with 13 tools: `GetRunningProfile`, `PresentRunningStats`, `OfferChoices`, `GetRecentRuns`, `SearchActivities`, `GetActivityDetails`, `GetCurrentSchedule`, `GetCurrentProposal`, `GetGoalInfo`, `GetComplianceReport`, `CreateSchedule`, `ModifySchedule`/`EditSchedule`, `VerifyPlan` (the last three only when plan-mutations are allowed for the user's org)
- Agentic onboarding flow (RunCoachAgent with `agent_conversations.context = 'onboarding'` branches the system prompt through `RunCoachAgent::onboardingInstructions()`)
- Plan proposal with AI-generated explanation modal (`PlanExplanationAgent` + `/coach/proposals/{id}/explanation`, cached 7 days per proposal)
- Past-dated training days in week 1 are dropped in `ProposalService::applyCreateSchedule` (safety rail)
- Filament admin with token-usage dashboard
- Push notifications via APNs-direct (`laravel-notification-channels/apn` + native iOS MethodChannel, NO Firebase). Triggers: plan generation completion + failure. Spec: `docs/superpowers/specs/2026-04-26-push-notifications.md`. See `api/CLAUDE.md` → "Push notifications" and `app/CLAUDE.md` → section 10.
- **Reschedule training days** via `PATCH /training-days/{day}` — re-assigns to the matching `TrainingWeek`, refuses race-day moves and days with a result. UI: top-right Cupertino action sheet on the day-detail screen + custom calendar in `reschedule_day_sheet.dart`.
- **Send to watch** via WorkoutKit (iOS 17+) — native bridge `nl.runcoach/workout` schedules `SingleGoalWorkout` for basic runs and `CustomWorkout` for intervals. iOS 17.4+ uses deterministic UUIDs per `TrainingDay` so multiple workouts per day from other apps don't collide, and rescheduling auto-moves the watch entry. See `app/CLAUDE.md` → section 11.
- **Watch auto-sync** — accepting a plan, rescheduling a day, or accepting a plan-mutating notification now ships the next 7 active days to the watch in one batch (Swift `syncDays` + Flutter `WatchSyncService`). App foreground triggers a delta-only resync of days the coach edited server-side since the last sync (compares `TrainingDay.updated_at` vs `shared_preferences` `lastSyncedAt`). Manual per-day button still works as force-resync; the old "already on your watch" duplicate prompt is gone — every press always replaces. iOS 17.0–17.3 falls back to manual-only (no identity tracking → can't safely batch). Plan: `docs/superpowers/plans/2026-05-19-watch-auto-sync.md`.
- **Interval rules** (enforced in `PlanOptimizerService::normalizeIntervals` + agent prompt): warmup optional/time-based (≤120s, default 60s), recovery always time-based (default 90s), cooldown REQUIRED at the end and time-based (60-600s, default 300s); cooldown synthesized when the agent omits it. Distance-based recoveries are converted to seconds via the recovery pace. See `api/CLAUDE.md` → "Interval session rules".
- **HR-zone auto-derivation** — `POST /profile/heart-rate-zones/derive` (`HeartRateZonesController`) computes the 5-zone table from age (Tanaka 208−0.7·age) + optional Karvonen with resting HR + optional upward correction from observed peaks (Garmin model). DOB is read from HealthKit when granted, otherwise the runner picks it once via a Cupertino date wheel — backend persists `users.date_of_birth`, prefills next time. `users.heart_rate_zones_source` enum tracks origin (`default` / `derived_empirical` (legacy) / `derived_age` / `manual`). Onboarding has a confirmation step at `/onboarding/zones` (now AFTER `/onboarding/overview` — see the zones-step bullet below); the menu HR sheet has a "Recompute" button. Spec: `docs/superpowers/specs/2026-05-08-hr-zones-auto-derive.md`.
- **Self-reported onboarding baseline** — `/onboarding/overview` is now an editable 2-field form (avg weekly km + easy pace). Wearable users see prefilled + 🔒 locked values with a "may degrade your plan" confirmation alert to override; no-wearable users fill in directly (both required). Stored on `users.self_reported_weekly_km` / `self_reported_easy_pace_seconds_per_km` / `self_reported_stats_at` and injected as **Tier 0** in `FitnessSnapshotService::snapshot` (overrides cascade when non-null). Spec: `docs/superpowers/specs/2026-05-11-onboarding-self-reported-stats-design.md`.
- **Zones step repositioned + restyled** — `/onboarding/zones` now sits AFTER `/onboarding/overview` (the baseline screen), not after connect-health. Screen has three runtime states: HR-confirmed (zones table + rich subtitle), DOB-known (big DOB row + collapsed advanced section), no-DOB (auto-opens Cupertino DOB picker + Continue disabled until pick). Beginners can pick a birth date and tap through without ever seeing a bpm table. Spec: `docs/superpowers/specs/2026-05-11-zones-step-restyle-design.md`.
- **Onboarding intensity-bias slider** — new form step (Easier / Standard / Harder) at position 11/12 with animated line-chart preview matching `_WeeklyVolumeChart` from `plan_details_sheet.dart`. Biases `PlanAmbitionAnalyzer` output ±1 via `AmbitionAssessment::applyBias()` against an extended 5-tier `EffectiveAmbitionLevel` (Conservative 1.45× → AllIn 1.95×). Persisted on `users.intensity_bias`; `TrainingPlanBuilder` consumes `peakVolumeMultiplier` + `weeklyGrowthRatio` + `qualityPaceRampGain` from the post-bias assessment. Spec: `docs/superpowers/specs/2026-05-11-onboarding-intensity-bias-design.md`.
- **Onboarding runner-level tone signal** — new form step (Beginner / Intermediate / Advanced / Sub-Elite / Elite) at position 11/13 (between coach-style and intensity). Five UI tiers collapse to three `RunnerToneBucket` cases (Novice / Standard / Expert) via `RunnerLevel::toneBucket()`. Persisted on `users.runner_level` (default `'intermediate'`). Read by both `OnboardingAgent` (via priming-message line `- runner_level: <level> (tone: <bucket>)`) and `RunCoachAgent` (directly from `$user->runner_level->toneBucket()`). Shapes coach phrasing AND the interval blueprint: Expert tier (Advanced/SubElite/Elite) uses 4×800 → 5×1000 → 4×1200 + 4×600 sharpener instead of the Novice/Standard 5×400 → 5×800 → 6×800 + 4×400 sharpener. See `api/CLAUDE.md` for the full progression table. Spec: `docs/superpowers/specs/2026-05-11-onboarding-runner-level-design.md`.
- **Yearly birthday push** — `plan:remind-birthday` runs daily at 09:00 Europe/Amsterdam, dispatches `BirthdayZoneCheckReminder` to users whose DOB matches today. Tap → `/profile/heart-rate-zones` opens the HR-zone editor sheet so the runner can refresh zones now that their Tanaka prior shifted by ~0.7 bpm.
- **Notifications inbox** — generic `user_notifications` table backs the header bell + cold-start "Action required" popup (`app/lib/app.dart::_maybeShowNotificationsReminder`). Currently single type: `plan_evaluation`, emitted by the 2-week mid-plan check-in flow.
- **Mid-plan evaluations (2-week check-in)** — `TrainingPlanBuilder::scheduleEvaluations()` inserts a `plan_evaluations` row at the end of every even build week (skipping the taper window). Daily 19:00 `plan:run-evaluations` cron dispatches `GeneratePlanEvaluation` for any due row; `PlanEvaluationAgent` (Sonnet, one-shot, tools `GetRecentRuns` + `GetComplianceReport` + `GetCurrentSchedule` + `AdjustPlan` when `planMutationsAllowed`) writes a markdown report and — if data warrants — emits an `EditActivePlan` proposal via the existing AdjustPlan path. Job creates a `user_notifications` row + APNs push (`PlanEvaluationReady`); body differs by whether a proposal was produced. Tap → `/schedule/evaluation/{id}` (`EvaluationDetailScreen` shows markdown + embedded `PlanContent` diff). Accept routes through `ProposalService::apply` (reusing the standard plan-edit flow); dismiss cascades to mark the linked `PlanEvaluation`. Evaluation cards also appear inline in the weekly schedule via `EvaluationCard` (`app/lib/features/schedule/widgets/evaluation_card.dart`). Replaces the old `PaceAdjustmentEvaluator`-driven per-run notifications. Plan: `docs/superpowers/plans/2026-05-22-plan-evaluations.md`.
- **New-plan via card, not chat-flow** — `RunCoachAgent` no longer walks runners through `offer_choices` chips to build a plan. Asking for a new plan triggers `ProposeNewPlanCard` (`data-new-plan` SSE) → Flutter `NewPlanCard` widget → tap navigates to `/onboarding/form?for=new-plan&step=goal_type`. `OnboardingFormScreen` accepts a `startStep` query param and wipes the form provider on re-entry. `BuildPlan` is no longer in `RunCoachAgent`'s toolset (kept in `OnboardingAgent` for the form-driven path).
- **Shareable run card** — on the first app-open after a run is AI-analyzed, `_BootPopupHost._maybeShowCelebration` (`app/lib/app.dart`) pops a 9:16 share-card sheet (`RunCelebrationSheet`) with the route as an animated gold polyline, the verdict (first `**bold**` sentence from `ai_feedback`), and 5 KPIs. Marked celebrated via `shared_preferences['last_celebrated_activity_id_v1']` so it fires once per run. Tap "Share" → `RepaintBoundary.toImage()` → PNG → `share_plus` iOS share sheet. Inline `_ShareThisRunButton` on the training-day detail screen re-opens it on demand. Routes come from a native `HKWorkoutRouteQuery` Swift bridge (`ios/Runner/WorkoutRoute.swift`, channel `nl.runcoach/workout-route`), persisted in `wearable_activities.raw_data.route` and surfaced via `GET /wearable/activities/{id}/route`. The celebration trigger uses `GET /share/celebratable-run?since_activity_id=` to find the latest analyzed run < 7d old. One-time route backfill for the past 30d fires from `workout_sync_lifecycle.dart::_maybeSync` (gated by `route_backfill_done_v1` flag) so older runs become shareable. Spec: `docs/superpowers/specs/2026-05-22-shareable-run-card.md`. Plan: `docs/superpowers/plans/2026-05-22-shareable-run-card.md`.
- **Schedule-week pop-up chat** — tap on the `/schedule` floating prompt-bar opens `ScheduleWeekChatSheet` (`app/lib/features/schedule/widgets/schedule_week_chat_sheet.dart`) — same BackdropFilter shell as `WorkoutChatSheet` but talks to `RunCoachAgent` via the regular `/coach/conversations/*` endpoints. The conversation gets `subject_type='training_week' + subject_id=<week.id>` on lazy-create (first send), and `RunCoachAgent::instructions()` injects a `## Current view context` block with the week's days/targets/results so the agent answers contextually without burning a tool call. One conversation per `(user, training_week_id)`: re-opening the sheet for the same week loads existing messages via the new `GET /schedule/weeks/{week}/chat` lookup. `CoachController::index` allows `subject_type IS NULL OR 'training_week'` so these chats surface in the normal chat list (workout chats remain hidden). The visible week is lifted from `_WeekPages` to `WeeklyPlanScreen` via `onWeekChanged`. Plan: `docs/superpowers/plans/2026-05-19-schedule-overview-chat.md`.
- **i18n full stack (Phase 1+2+3+4 — complete)** — Backend resolves locale per request via `SetLocale` middleware (`api/app/Http/Middleware/SetLocale.php`): `users.locale` > `Accept-Language` > fallback. Push notifications, `TrainingType::label()`, and validation errors auto-localize via `__()`; User implements `HasLocalePreference` so queue workers respect `$user->locale`. Flutter uses the official `flutter_localizations` + `intl` + ARB + `flutter gen-l10n` (strings in `app/lib/l10n/app_{en,nl}.arb`), `appLocaleProvider` auto-detects from device (`languageCode == 'nl'` → Dutch, else English) and persists override in `shared_preferences`, and Dio sends `Accept-Language` on every request. Phase 3 (UI string extraction, ~700 strings via `context.l10n.*`) is complete. Phase 4 (agent localization) ships as `App\Ai\Support\LanguageDirective::current()` — appended to all 5 agent system prompts; system prompts themselves stay English so the Anthropic prompt-cache stays shared across locales. Spec: `docs/superpowers/specs/2026-05-12-i18n-multilingual-research.md`, plan: `docs/superpowers/plans/2026-05-12-i18n-foundation.md`.
- Flutter app: Dashboard, Schedule, AI Coach, Goals tabs

**Branch state:** `main` is the legacy Strava implementation, preserved. `strava` (remote) is the snapshot of pre-migration state. `apple-health` contains the migration to Apple Sign-In + HealthKit + wearable-agnostic schema.

**Deferred polish (not blocking MVP):**
- `HKObserverQuery` + `enableBackgroundDelivery` Swift MethodChannel for true background sync (today the app pushes on connect-health screen visit)
- `HKQuery.predicateForObjects(from: workout)` for workout-scoped HR samples (today the `health` package's time-window query is used; over-counts samples that overlap a workout but were recorded by other apps)
- `HKWorkoutRouteQuery` for GPS polylines (we don't render maps)
- Open Wearables integration for Garmin/Polar/Strava (per `docs/superpowers/specs/2026-04-26-...` if a spec exists)
- Weekly credit quotas, Reverb WebSocket streaming, provider tests for Flutter, Android port (HealthConnect + Sign-in alternative + FCM channel — push schema/code is already cross-platform-ready).
