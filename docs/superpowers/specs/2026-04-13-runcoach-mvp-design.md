# RunCoach MVP — Design Spec

## Overview

RunCoach is a personal running coach app that connects to Strava to help runners train smarter. Users connect their Strava account, and the app reads their activity history to understand their fitness level. An AI coach generates personalized training schedules for upcoming races, automatically matches completed Strava activities to planned training, and provides coaching feedback — all through a conversational chat interface.

**Target audience:** Recreational and competitive runners who use Strava and want structured, personalized training without hiring a human coach.

## MVP Scope

Core training loop + AI coach as schedule command center:

- Strava OAuth2 authentication + webhook-based activity sync
- User onboarding (level, goal, coach style)
- Race goal setup (distance, target time, date)
- AI-generated training schedules via conversational coach chat
- Weekly plan view with day-by-day training details
- Automatic matching of Strava activities to planned training
- Compliance scoring (planned vs actual performance)
- AI coaching chat with full Strava awareness and schedule management tools
- Filament admin panel (minimal)

**Not in MVP:** Push notifications, i18n (Dutch), real-time WebSockets (Reverb), team/club features.

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile app | Flutter (iOS + Android) |
| State management | Riverpod + Freezed |
| API client | Dio + Retrofit (code-generated) |
| Backend API | Laravel 13 |
| Auth | Laravel Sanctum (token-based) |
| Admin panel | Filament |
| AI integration | Laravel AI SDK (OpenAI initially, swappable) |
| Strava | OAuth2 + Webhooks |
| Queue | Laravel queues (database driver for MVP) |

## Monorepo Structure

```
runcoach/
├── api/              ← Laravel application
├── app/              ← Flutter application
└── docs/             ← Specs, design docs
```

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      FLUTTER MOBILE APP                         │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐      │
│  │ Dashboard  │ │ Schedule  │ │ AI Coach  │ │  Races    │      │
│  └─────┬─────┘ └─────┬─────┘ └─────┬─────┘ └─────┬─────┘      │
│        └──────────────┴──────┬──────┴─────────────┘            │
│                     Riverpod Providers                          │
│                     Retrofit API Client                         │
│                     Dio (Sanctum Token)                         │
└──────────────────────────┬──────────────────────────────────────┘
                           │ HTTPS / REST
                           ▼
┌──────────────────────────────────────────────────────────────────┐
│                      LARAVEL BACKEND                             │
│                                                                  │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────────────────┐│
│  │  API Routes  │  │   Filament   │  │  Strava Webhook Handler ││
│  │  /api/v1/*   │  │   /admin/*   │  │  /webhook/strava        ││
│  └──────┬──────┘  └──────┬───────┘  └───────────┬──────────────┘│
│         │                │                       │               │
│  ┌──────┴────────────────┴───────────────────────┴─────────────┐│
│  │                   Service Layer                              ││
│  │  TrainingScheduleService  StravaSyncService                 ││
│  │  CoachChatService         RaceManagerService                ││
│  └──────┬──────────────────────────────────────────────────────┘│
│         │                                                       │
│  ┌──────┴──────────────────────────────────────────────────────┐│
│  │              Eloquent Models + Database                      ││
│  └──────┬──────────────────────────────┬───────────────────────┘│
│         │                              │                        │
│  ┌──────┴──────────┐        ┌──────────┴──────────┐            │
│  │ Laravel AI SDK   │        │ Strava API (OAuth2) │            │
│  │ (OpenAI / swap)  │        │ + Webhooks          │            │
│  └──────────────────┘        └─────────────────────┘            │
└──────────────────────────────────────────────────────────────────┘
```

### Key Flows

1. **Auth flow:** Flutter → Laravel → Strava OAuth2 → callback → create user + Sanctum token → Flutter stores token
2. **Schedule generation:** User asks coach to create plan → AI SDK tool call generates structured JSON → returned as CoachProposal → user approves → stored as TrainingWeek/TrainingDay models
3. **Activity matching:** Strava webhook fires → queued job fetches full activity → auto-matches to planned training day by date + type → calculates compliance score → generates AI feedback
4. **AI coach chat:** User sends message → Laravel builds context (Strava history, current plan, compliance) → AI SDK call with tool definitions → response + optional tool results returned

---

## Data Model

### User

| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| name | string | |
| email | string | unique |
| strava_athlete_id | bigint | unique, nullable |
| level | enum | beginner, intermediate, advanced, elite |
| coach_style | enum | motivational, analytical, balanced |
| weekly_km_capacity | decimal | Current weekly km the user can handle |
| created_at | timestamp | |

### StravaToken

| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| user_id | FK → User | unique |
| access_token | string | encrypted |
| refresh_token | string | encrypted |
| expires_at | timestamp | |
| athlete_scope | string | Granted OAuth scopes |

### Race

| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| user_id | FK → User | |
| name | string | e.g. "Amsterdam Marathon 2026" |
| distance | enum | 5k, 10k, half_marathon, marathon, custom |
| custom_distance_meters | integer | nullable, only for custom |
| goal_time_seconds | integer | nullable |
| race_date | date | |
| status | enum | planning, active, completed, cancelled |
| created_at | timestamp | |

### TrainingWeek

| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| race_id | FK → Race | |
| week_number | integer | |
| starts_at | date | |
| total_km | decimal | |
| focus | string | e.g. "base building", "tempo development" |
| coach_notes | text | AI-generated weekly insight, nullable |

### TrainingDay

| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| training_week_id | FK → TrainingWeek | |
| date | date | |
| type | enum | easy, tempo, interval, long_run, recovery, rest, mobility |
| title | string | e.g. "8km Tempo" |
| description | string | e.g. "@ 4:45 min/km" |
| target_km | decimal | nullable (rest days) |
| target_pace_seconds_per_km | integer | nullable |
| target_heart_rate_zone | integer | nullable (1-5) |
| intervals_json | json | nullable, structured interval data |
| order | integer | Day order within the week |

### StravaActivity

| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| user_id | FK → User | |
| strava_id | bigint | unique |
| type | string | Strava activity type |
| name | string | |
| distance_meters | integer | |
| moving_time_seconds | integer | |
| elapsed_time_seconds | integer | |
| average_heartrate | decimal | nullable |
| average_speed | decimal | |
| start_date | timestamp | |
| summary_polyline | text | nullable |
| raw_data | json | Full Strava response |
| synced_at | timestamp | |

### TrainingResult

| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| training_day_id | FK → TrainingDay | unique |
| strava_activity_id | FK → StravaActivity | nullable |
| compliance_score | decimal | 1-10 overall score |
| actual_km | decimal | |
| actual_pace_seconds_per_km | integer | |
| actual_avg_heart_rate | decimal | nullable |
| pace_score | decimal | 1-10 |
| distance_score | decimal | 1-10 |
| heart_rate_score | decimal | nullable, 1-10 |
| ai_feedback | text | AI-generated post-activity feedback |
| matched_at | timestamp | |

### CoachConversation

| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| user_id | FK → User | |
| race_id | FK → Race | nullable |
| title | string | |
| created_at | timestamp | |

### CoachMessage

| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| coach_conversation_id | FK → CoachConversation | |
| role | enum | user, assistant |
| content | text | |
| context_snapshot | json | nullable, training context sent to LLM |
| created_at | timestamp | |

### CoachProposal

| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| coach_message_id | FK → CoachMessage | |
| type | enum | create_schedule, modify_schedule, alternative_week |
| payload | json | Proposed schedule changes |
| status | enum | pending, accepted, rejected |
| applied_at | timestamp | nullable |

### Relationships

```
User 1:1 StravaToken
User 1:N Race
User 1:N StravaActivity
User 1:N CoachConversation
Race 1:N TrainingWeek
TrainingWeek 1:N TrainingDay
TrainingDay 1:0..1 TrainingResult
TrainingResult N:1 StravaActivity
CoachConversation 1:N CoachMessage
CoachMessage 1:0..1 CoachProposal
```

---

## API Endpoints

### Auth

| Method | Path | Description |
|---|---|---|
| GET | /auth/strava/redirect | Returns Strava OAuth authorize URL |
| GET | /auth/strava/callback | Exchanges code for tokens, returns Sanctum token |
| POST | /auth/logout | Revokes Sanctum token |

### Profile

| Method | Path | Description |
|---|---|---|
| GET | /profile | Current user profile + stats |
| PUT | /profile | Update level, coach_style, weekly_km_capacity |
| POST | /profile/onboarding | Complete onboarding wizard |

### Dashboard

| Method | Path | Description |
|---|---|---|
| GET | /dashboard | Weekly summary, next training, progress stats, coach insight |

### Races

| Method | Path | Description |
|---|---|---|
| GET | /races | List user's races |
| POST | /races | Create race (simple form path, no schedule) |
| GET | /races/{race} | Race detail + countdown |
| PUT | /races/{race} | Update race goal/date |
| DELETE | /races/{race} | Cancel race |

### Training Schedule

| Method | Path | Description |
|---|---|---|
| GET | /races/{race}/schedule | All weeks for a race |
| GET | /races/{race}/schedule/current | Current week's plan |
| GET | /training-days/{day} | Day detail with intervals |
| GET | /training-days/{day}/result | Compliance result + overlay data |

### Strava

| Method | Path | Description |
|---|---|---|
| POST | /strava/sync | Manual history sync trigger |
| GET | /strava/activities | List synced activities |
| GET | /strava/status | Connection status + last sync |

### AI Coach

| Method | Path | Description |
|---|---|---|
| GET | /coach/conversations | List conversations |
| POST | /coach/conversations | Start new conversation |
| GET | /coach/conversations/{id} | Get messages |
| POST | /coach/conversations/{id}/messages | Send message, get AI reply |
| POST | /coach/proposals/{id}/accept | Accept a proposed schedule change |
| POST | /coach/proposals/{id}/reject | Reject a proposed schedule change |

### Webhook (no auth, Strava-signed)

| Method | Path | Description |
|---|---|---|
| GET | /webhook/strava | Strava verification challenge |
| POST | /webhook/strava | Receive activity events |

---

## Flutter Screen Structure

### Pre-auth screens

| Screen | Purpose | API |
|---|---|---|
| WelcomeScreen | Logo, tagline, "Connect with Strava" CTA | — |
| StravaAuthScreen | WebView for Strava OAuth | /auth/strava/* |
| OnboardingScreen | Level, goal, coach style wizard | POST /profile/onboarding |

### Tab 1: Dashboard

| Screen | Purpose | API |
|---|---|---|
| DashboardScreen | Weekly km total, compliance %, next training card, progress charts, coach insight | GET /dashboard |

### Tab 2: Schedule

| Screen | Purpose | API |
|---|---|---|
| WeeklyPlanScreen | Day-by-day list matching the design screenshot. Status icons, total km header. | GET /races/{race}/schedule/current |
| TrainingDayDetailScreen | Full session details, intervals, pace targets, HR zone guidance | GET /training-days/{day} |
| TrainingResultScreen | Planned vs actual overlay, compliance breakdown, AI feedback | GET /training-days/{day}/result |

### Tab 3: AI Coach

| Screen | Purpose | API |
|---|---|---|
| CoachChatListScreen | Conversations list, new conversation button | GET /coach/conversations |
| CoachChatScreen | Chat UI with message bubbles, quick actions (empty state), proposal cards with Accept/Reject | POST /coach/conversations/{id}/messages |

### Tab 4: Races

| Screen | Purpose | API |
|---|---|---|
| RaceListScreen | Active + past races, add race FAB | GET /races |
| RaceCreateScreen | Name, distance, date, goal time form | POST /races |
| RaceDetailScreen | Countdown, readiness, link to schedule | GET /races/{race} |

---

## Strava Integration

### OAuth Flow

1. Flutter calls `GET /auth/strava/redirect` → receives Strava authorize URL
2. Flutter opens WebView/browser to that URL
3. User approves on Strava → redirects to callback URL
4. Laravel `GET /auth/strava/callback` exchanges code for access + refresh tokens
5. Tokens stored encrypted in StravaToken table
6. User created/updated, webhook subscription registered
7. Sanctum token returned to Flutter
8. Initial activity sync job dispatched

### Webhook Flow

1. Strava sends `POST /webhook/strava` with event payload (owner_id, object_id, aspect_type)
2. Laravel verifies the subscription, returns 200 immediately
3. `ProcessStravaActivity` job dispatched to queue
4. Job refreshes Strava token if expired, fetches full activity detail
5. Activity stored as StravaActivity
6. Auto-matched to planned TrainingDay (by date ± 1 day, then type, then closest distance)
7. Compliance score calculated
8. AI feedback generated and stored on TrainingResult

### Activity Matching Logic

1. Find TrainingDays for the activity's date (± 1 day buffer for timezone/late runs)
2. Filter by compatible type: Strava "Run" → easy, tempo, interval, long_run, recovery
3. If multiple candidates, pick the one with the closest distance target
4. If no match, store the activity as unplanned (no compliance score)

### Compliance Score Calculation

Overall score is a weighted average (1-10):

| Component | Weight | Calculation |
|---|---|---|
| Distance | 30% | Ratio of actual vs target km, capped at 10 |
| Pace | 40% | Deviation from target pace, scaled to 1-10 |
| Heart rate | 30% | Zone match vs target zone |

If heart rate data is missing, weights redistribute to pace (55%) + distance (45%).

### Token Refresh

Strava tokens expire every 6 hours. StravaSyncService checks `expires_at` before every API call and auto-refreshes using the refresh token. If refresh fails, the token is marked invalid and the user is prompted to re-authenticate.

### Strava API Compliance

- "Powered by Strava" attribution on all activity-related screens
- Deep links back to Strava for full activity details
- No caching raw data beyond what the active training plan needs
- Respect rate limits (100 requests/15min, 1000 requests/day)

---

## AI Strategy

### Laravel AI SDK with Tool Calling

The AI coach uses OpenAI via Laravel AI SDK, with tool-use support for schedule management. The provider is swappable via the AI SDK abstraction.

### Coach Tools

| Tool | Description | Needs Approval |
|---|---|---|
| `get_strava_summary` | Returns 4-8 weeks of activity stats (avg km/week, pace, long runs, HR trends) | No |
| `get_current_schedule` | Returns active schedule with compliance results | No |
| `create_schedule` | Generates a full training plan as structured JSON | Yes |
| `modify_schedule` | Changes individual days, swaps workouts, moves rest days | Yes |
| `propose_alternative_week` | Offers 2-3 week variants with trade-offs | Yes |
| `get_compliance_report` | Analyzes performance trends over a period | No |
| `get_race_readiness` | Assesses preparedness for target race | No |

### Approval Flow

Schedule mutations (create, modify, alternative) return a **CoachProposal** — a preview of the changes rendered as a special card in the chat UI with Accept/Reject buttons. Nothing is persisted until the user explicitly approves via `POST /coach/proposals/{id}/accept`.

### Context Injection

Every chat message automatically includes:
- Full Strava activity summary (recent 4-8 weeks)
- Active training schedule + compliance results
- User profile (level, coach_style, weekly_km_capacity)
- Conversation history

The AI never needs to ask for data it already has access to.

### System Prompt Strategy

The system prompt establishes the coach persona, grounded in running methodology (periodization, 80/20 rule, progressive overload). It adapts tone based on the user's `coach_style` preference. The AI is instructed to never invent statistics — all data claims must come from tool calls.

### AI-Generated Content

| Content | Trigger | Storage |
|---|---|---|
| Training schedule | User requests via coach chat | TrainingWeek + TrainingDay (after approval) |
| Post-activity feedback | Webhook processes activity | TrainingResult.ai_feedback |
| Weekly insight | After training completed (queued) | TrainingWeek.coach_notes |
| Chat responses | User sends message | CoachMessage.content |

---

## Filament Admin Panel

Minimal admin interface at `/admin/*` with its own auth guard (separate from Sanctum API auth). Covers:

- User management (view users, Strava connection status)
- Race overview (active plans, completion rates)
- Activity log (recent webhook events, sync status)
- Coach conversation browser (for debugging AI responses)
- System health (queue status, Strava API usage)

---

## Design Language

Based on the provided design screenshot:

- **Color palette:** Warm earth tones — cream/beige backgrounds (#faf8f4), brown/gold accents (#8B7355), muted text
- **Typography:** Clean, modern sans-serif. Bold headings, light descriptions
- **Cards:** Rounded corners, subtle shadows, warm background tints
- **Status indicators:** Checkmarks for completed, lightning bolt for today, moon for upcoming
- **Layout:** Single-column scrollable lists, generous whitespace
- **Coach insight:** Distinct card style with quotation marks, differentiated from training content
- **Bottom navigation:** 4 tabs — Dashboard, Schedule, AI Coach, Races

---

## Flutter Architecture

### State Management (Riverpod + Freezed)

- **Freezed models** for all data classes (User, Race, TrainingWeek, TrainingDay, etc.) with JSON serialization
- **Riverpod providers** for API state, organized by feature:
  - `authProvider` — token storage, auth state
  - `dashboardProvider` — dashboard aggregate data
  - `scheduleProvider` — current week, day details
  - `coachProvider` — conversations, messages, proposals
  - `raceProvider` — race CRUD
  - `stravaProvider` — sync status, activities

### API Layer (Dio + Retrofit)

- Single Dio instance configured with Sanctum token interceptor (auto-attaches Bearer token, handles 401 → redirect to login)
- Retrofit-generated API clients per feature group (AuthApi, DashboardApi, ScheduleApi, CoachApi, RaceApi, StravaApi)
- Freezed models used as request/response types

### Routing

GoRouter for declarative navigation with auth redirect guards.

---

## i18n Preparation

Not in MVP, but the architecture supports it:
- Laravel: use `__()` / `trans()` helpers in API responses for any user-facing strings
- Flutter: use `flutter_localizations` + ARB files. All user-facing strings extracted to localization files
- English is the default and only language for MVP
