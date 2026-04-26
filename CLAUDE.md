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

## Testing

- **Backend**: `cd api && php artisan test --compact` — ~295 tests, all using `LazilyRefreshDatabase`
- **Flutter**: `cd app && flutter analyze && flutter test`
- Full test suite must pass before commits

## Filament admin

- Panel mounted at `/admin` (see `api/app/Providers/Filament/AdminPanelProvider.php`)
- Log in with seeded admin (`php artisan db:seed --class=AdminUserSeeder` → `admin@runcoach.local` / `admin`)
- Access gated via `User::canAccessPanel()` — `local` env allows any user, others require email in `ADMIN_EMAILS`
- Resources:
  - **Token Usage** (`/admin/token-usages`) — tracks per-call token spend for every agent. Filter by context (`coach`, `onboarding`, `activity_feedback`, `weekly_insight`, `plan_explanation`, `running_narrative`), user, model. Dashboard widgets show totals this week, tokens by context, and top users. Rows are written by `App\Listeners\RecordAgentTokenUsage` which is auto-discovered from its `handle(AgentPrompted|AgentStreamed $event)` signature — DO NOT also register it manually via `Event::listen` or every call gets logged twice.

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
- Flutter app: Dashboard, Schedule, AI Coach, Goals tabs

**Branch state:** `main` is the legacy Strava implementation, preserved. `strava` (remote) is the snapshot of pre-migration state. `apple-health` contains the migration to Apple Sign-In + HealthKit + wearable-agnostic schema.

**Deferred polish (not blocking MVP):**
- `HKObserverQuery` + `enableBackgroundDelivery` Swift MethodChannel for true background sync (today the app pushes on connect-health screen visit)
- `HKQuery.predicateForObjects(from: workout)` for workout-scoped HR samples (today the `health` package's time-window query is used; over-counts samples that overlap a workout but were recorded by other apps)
- `HKWorkoutRouteQuery` for GPS polylines (we don't render maps)
- Open Wearables integration for Garmin/Polar/Strava (per `docs/superpowers/specs/2026-04-26-...` if a spec exists)
- Weekly credit quotas, push notifications, Dutch i18n, Reverb WebSocket streaming, provider tests for Flutter.
