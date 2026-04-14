# RunCoach

Personal AI running coach app that connects to Strava. Users get AI-generated training plans for upcoming races, automatic activity matching with compliance scoring, and an agentic coach chat with full access to their Strava data.

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
- Working in `api/` → read `api/CLAUDE.md` for Laravel conventions, the AI agent system, Strava integration
- Working in `app/` → read `app/CLAUDE.md` for Flutter architecture, state management, design system

## What the app does

1. User connects Strava via OAuth2
2. Backend syncs 3 months of running history + listens to webhooks for new activities
3. User talks to an AI coach that has full access to their Strava data (any time period via the API) and can create personalized training plans
4. Training plans auto-match completed Strava activities to planned sessions with compliance scoring (pace/distance/HR)
5. User gets per-run AI feedback and weekly insights

## High-level architecture

```
┌──────────────────────┐        ┌────────────────────────────┐        ┌─────────┐
│   Flutter Mobile App │ HTTPS  │   Laravel 13 API           │  HTTPS │ Strava  │
│   (iOS + Android)    │────────│                            │────────│ API     │
│                      │        │  • Sanctum token auth      │        └─────────┘
│  • Riverpod          │        │  • Laravel AI SDK Agent    │
│  • Freezed models    │        │  • MySQL                   │        ┌─────────┐
│  • Retrofit + Dio    │        │  • Queue (database driver) │────────│ OpenAI  │
│  • GoRouter          │        │                            │        │ API     │
└──────────────────────┘        └────────────────────────────┘        └─────────┘
```

### Data flow
- **Auth**: Flutter → `/auth/strava/redirect` → Strava OAuth WebView → callback → Sanctum token stored in secure storage
- **Activity sync**: Strava webhook → `ProcessStravaActivity` job → stores activity + matches to planned training day + scores compliance → `GenerateActivityFeedback` job generates AI feedback
- **AI Coach**: User message → `RunCoachAgent` (Laravel AI SDK) → agent autonomously calls tools (SearchStravaActivities, GetCurrentSchedule, CreateSchedule, etc.) → response + optional proposal returned
- **Schedule proposals**: `CreateSchedule`/`ModifySchedule` tools return `requires_approval: true` payloads → detected in `tool_results` of the agent's message → stored as `CoachProposal` → user accepts/rejects → `ProposalService` applies changes

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile | Flutter, Riverpod (code gen), Freezed, Dio + Retrofit, GoRouter, flutter_secure_storage |
| Backend | Laravel 13, Sanctum, laravel/ai (agent SDK), openai-php/laravel |
| Database | MySQL |
| Queue | Laravel queues (database driver) |
| AI | OpenAI (swappable via Laravel AI SDK providers) |
| Dev tools | Laravel Boost (MCP + skills), Pint, PHPUnit |

## Key Architectural Decisions

### 1. Agentic coach with Laravel AI SDK (not custom tool loop)
The coach was initially a custom `CoachChatService` that manually orchestrated OpenAI tool calls. It was refactored to use **Laravel AI SDK's `Agent` contract** with `RemembersConversations` trait. This means:
- Conversations persist automatically in `agent_conversations` / `agent_conversation_messages` tables
- The SDK handles the agent loop (tool calling, iteration limits)
- Tool results are stored in `agent_conversation_messages.tool_results` JSON column
- Proposal detection queries that column after the prompt completes

### 2. Strava API as a tool, not a local mirror
Instead of caching all Strava data locally, `SearchStravaActivities` queries the Strava API directly with flexible date ranges. This means the agent can answer questions about ANY time period (e.g. "how was last April?") without us syncing years of data. We keep only ~3 months locally for webhook-matched training compliance.

### 3. Proposal/approval flow for mutations
Schedule creation and modification return proposals that require user approval before being persisted. The AI tools (`CreateSchedule`, `ModifySchedule`) return JSON payloads with `requires_approval: true` — they never mutate state directly. `ProposalService::apply()` handles persistence only after user acceptance.

### 4. UUIDs for conversation IDs
Conversation IDs are UUIDs (36-char strings) because the Laravel AI SDK uses them. Do NOT use `int` for conversation IDs anywhere in the codebase — not in the Flutter models, route params, or API clients.

### 5. OpenAI strict mode compliance
All Tool schemas must declare `->required()` on every parameter. For optional params, use `->required()->nullable()` — this satisfies OpenAI strict mode while allowing null values.

### 6. MySQL decimal columns return strings
Fields like `total_km`, `target_km`, `compliance_score` come back as strings from MySQL decimal columns. The Flutter Freezed models use custom `fromJson` converters (`app/lib/core/utils/json_converters.dart`) to safely handle both string and number JSON values.

## Running locally

### Backend
```bash
cd api
composer run dev     # Starts Laravel + queue worker + logs + vite
# OR for physical device testing:
php artisan serve --host=0.0.0.0 --port=8000
```

### Flutter app
```bash
cd app
flutter run          # iOS simulator / connected device
```

**Physical device note:** The Flutter app's base URL in `app/lib/core/api/dio_client.dart` must be set to the Mac's local IP (not `localhost`) when testing on a physical iPhone.

### Required env vars (api/.env)
- `STRAVA_CLIENT_ID` / `STRAVA_CLIENT_SECRET` — from [strava.com/settings/api](https://www.strava.com/settings/api), set Authorization Callback Domain to `localhost`
- `STRAVA_WEBHOOK_VERIFY_TOKEN` — any random string
- `OPENAI_API_KEY` — for the AI coach

## Workflow conventions

- **Design specs** go in `docs/superpowers/specs/YYYY-MM-DD-<topic>.md`
- **Implementation plans** go in `docs/superpowers/plans/YYYY-MM-DD-<topic>.md`
- Use Laravel Boost MCP tools (`search-docs`, `database-schema`) when working in api/
- Before implementing anything non-trivial, write a spec first, then a plan
- Commit often, descriptive messages, never commit without running tests first

## Testing

- **Backend**: `cd api && php artisan test --compact` — 45 tests, all using `LazilyRefreshDatabase`
- **Flutter**: `cd app && flutter analyze && flutter test`
- Full test suite must pass before commits

## Current state

Fully functional MVP:
- Strava OAuth + webhook sync working
- AI coach with 6 tools: SearchStravaActivities, GetCurrentSchedule, GetRaceInfo, GetComplianceReport, CreateSchedule, ModifySchedule
- Agentic plan creation flow (ask clarifying questions → fetch Strava data → analyze → propose → generate)
- Flutter app: Dashboard, Schedule, AI Coach, Races tabs

**Not yet implemented:** Filament admin panel, push notifications, Dutch i18n, Reverb WebSocket streaming, provider tests for Flutter.
