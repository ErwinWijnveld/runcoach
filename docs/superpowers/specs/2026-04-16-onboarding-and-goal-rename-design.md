# Onboarding flow + Race → Goal rename — design spec

**Status:** Draft
**Date:** 2026-04-16
**Author:** Erwin Wijnveld (with Claude)
**Design reference:** [Figma — RunCore onboarding frame 51:453](https://www.figma.com/design/gokobgpFRmZph0Jyr1W4tE/RunCore?node-id=51-453)

---

## 1. Problem

Today, the first-time experience after Strava OAuth is a minimal form: three optional/required text fields (`coach_style`, `level`, `weekly_km_capacity`) on `OnboardingScreen`. The user lands on the dashboard with no goal, no plan, and no sense that the coach knows anything about them.

We want the first interaction to feel like meeting a coach who's already looked at your running. It should:
- Analyze the user's last 12 months of Strava activity.
- Show that analysis as rich stats (not a wall of text).
- Ask what they're working toward, via four quick-reply options.
- Branch into a short follow-up per option and end with a training plan proposal.
- Replace the current `OnboardingScreen` entirely.

At the same time: the product concept is a **Goal**, not necessarily a race. "General fitness" and "Get faster at 5k" are goals too. The existing `Race` model is too narrow. We're renaming `Race` → `Goal` across the codebase (backend + Flutter, ~1829 references) and generalizing the schema so a Goal can optionally have a target date and distance.

---

## 2. Goals / Non-goals

### Goals
- Replace the current `OnboardingScreen` with a chat-shaped onboarding flow.
- Pre-compute a 12-month running analysis into `user_running_profiles` (cached, reusable by dashboard/weekly insights later).
- Support four branches: **Race coming up**, **General fitness**, **Get faster**, **Not sure yet**.
- End three of the branches with a `CreateSchedule` tool call producing a proposal the user can accept.
- Rename `Race` → `Goal` end-to-end (DB, models, API, Flutter).
- Reuse `/coach/chat` components — onboarding is the chat screen with different scaffold chrome.

### Non-goals
- Profile refresh cadence (future work).
- Re-running onboarding after completion.
- Editing the active plan inside onboarding (uses existing `ModifySchedule`).
- Multi-goal users (still one active goal at a time).
- i18n, push notifications, admin funnel view.
- New streaming transport — onboarding rides on whatever chat transport exists.

---

## 3. End-to-end flow

```
Strava OAuth connect
        │
        ▼
 user.has_completed_onboarding == false ?
        │ yes
        ▼
/onboarding  (scripted chat UI, same components as /coach/chat)

  1. Loading card: "Analysing Strava Data"
  2. Narrative bubble + 2×2 stats card
  3. "Anything you're training for?" + 4 chips
        │
  ┌─────┼─────┬──────────┬──────────────┐
  ▼     ▼     ▼          ▼
 Race  General Get       Not sure yet ──→ scripted goodbye
  │    fitness faster                     has_completed_onboarding = true
  ▼    ▼      ▼                           navigate to /dashboard
 free  chip:  chip: distance
 text: days/  (5k/10k/half/marathon/custom)
 race  wk     │
 name, (2-6)  ▼
 date,        free text: current PR + target
 time,        │
 etc.         chip: days/wk (2-6)
  │           │
  └─────┴─────┴──────┐
                     ▼
           chip: coach_style (strict/balanced/flexible)
                     │
                     ▼
           Loading card: "Working on your plan"
           (agent runs CreateSchedule)
                     │
                     ▼
           Proposal card (Figma layout)
                     │
                     ▼
           User taps ACCEPT
                     │
                     ▼
           ProposalService.apply → Goal + TrainingWeeks created
           users.has_completed_onboarding = true
           Navigate to /dashboard
```

### Message flow (Race path example)

| # | Source    | messageType         | Content |
|---|-----------|---------------------|---------|
| 1 | scripted  | `loading_card`      | "Analysing Strava Data" |
| 2 | scripted  | `text`              | narrative (LLM one-shot, grounded on metrics) |
| 3 | scripted  | `stats_card`        | 4 metrics: weekly_avg_km, weekly_avg_runs, avg_pace, session_avg_duration |
| 4 | scripted  | `text`              | "Anything you're training for, or want to work toward?" |
| 5 | scripted  | `chip_suggestions`  | [Race coming up, General fitness, Get faster, Not sure yet] |
| 6 | user      | `text`              | "Race coming up!" (with `chip_value=race`) |
| 7 | scripted  | `text`              | "Alright, let's get you going! To create the plan I need… Send me something like: 'City 10K, 12 sep 2025, goal 55:00, 4 days/week'" |
| 8 | user      | `text`              | free-text race details |
| 9 | scripted  | `chip_suggestions`  | coach_style chips |
| 10 | user     | `text`              | "Balanced" (with `chip_value=balanced`) |
| 11 | scripted | `loading_card`      | "Working on your plan" |
| 12 | agent    | `proposal_card`     | proposal payload |

The whole flow is one **persistent `agent_conversation`** (`context='onboarding'`). Pre-branch bot messages are scripted by `OnboardingController`; post-branch, the same conversation flips into real agent mode to call `CreateSchedule`.

---

## 4. Data model changes

### 4.1 Rename Race → Goal (pre-launch, edit migrations in place)

**Approach:** edit existing migration files directly, rename filenames where applicable; user runs `php artisan migrate:fresh`. No "rename" migrations are added. (Pre-launch only.)

**Backend:**
- `races` table → `goals`. `race_date` → `target_date`. All `race_id` FK columns renamed to `goal_id` (`training_weeks`, etc.).
- `Race` model → `Goal`. Relations: `Goal::trainingWeeks()`, `User::goals()`.
- Tool: `GetRaceInfo` → `GetGoalInfo`. Instructions and all callers updated.
- All PHP code referencing "Race" swept (~1829 refs across PHP + Dart).

**Flutter:**
- `Race` freezed class → `Goal`. Feature folder `app/lib/features/races/` → `features/goals/`.
- Route `/races` → `/goals`. Bottom nav label already "Goals" in Figma.
- All UI strings updated.

### 4.2 Schema additions for onboarding

`users` table:
- **Add** `has_completed_onboarding` boolean, default `false`. Replaces `coachStyle == null` as the onboarding gate.
- **Drop** `level` and `weekly_km_capacity` — derived from the profile now.
- **Keep** `coach_style` (asked in the new chat onboarding).

`goals` table (renamed from `races`):
- **Add** `type` enum: `race` | `general_fitness` | `pr_attempt`.
- **Change** `target_date` (renamed from `race_date`) to **nullable**.
- **Change** `distance` to **nullable**.
- `custom_distance_meters` already nullable.
- `goal_time_seconds` already nullable.

New `user_running_profiles` table:
- `user_id` FK, unique
- `analyzed_at` timestamp
- `data_start_date`, `data_end_date`
- `metrics` JSON: `{weekly_avg_km, weekly_avg_runs, avg_pace_seconds_per_km, session_avg_duration_seconds, total_runs_12mo, total_distance_km_12mo, consistency_score, long_run_trend, pace_trend}`
- `narrative_summary` text — LLM-generated one-shot paragraph, grounded on the metrics
- `created_at`, `updated_at`

`agent_conversations` table:
- **Add** `context` nullable string — `'onboarding'` for the hidden onboarding convo; `NULL` for regular chat. Coach chat listings filter `WHERE context IS NULL`.

### 4.3 CreateSchedule tool contract

The tool is generalized to produce non-race goals:

| Param                    | Current         | New                                    |
|--------------------------|-----------------|----------------------------------------|
| `race_name`              | required        | → `goal_name` (required)                |
| `distance`               | required enum   | `required()->nullable()`                |
| `custom_distance_meters` | nullable        | unchanged                               |
| `goal_time_seconds`      | required, nullable | unchanged                            |
| `race_date`              | required        | → `target_date`, `required()->nullable()` |
| `schedule`               | required JSON   | unchanged                               |
| `goal_type`              | —               | **new**, required enum (`race`, `general_fitness`, `pr_attempt`) |

Handler creates a `Goal` row with `type = goal_type`, applies the schedule.

---

## 5. Backend architecture

### 5.1 `RunningProfileService`
`api/app/Services/RunningProfileService.php`

```
analyze(User $user): UserRunningProfile
  1. Fetch 12 months of running activities via StravaClient (paginate, rate-limit aware).
  2. Compute metrics (pure PHP aggregation):
     - weekly_avg_km, weekly_avg_runs
     - avg_pace_seconds_per_km (across all runs)
     - session_avg_duration_seconds
     - total_runs_12mo, total_distance_km_12mo
     - consistency_score (% of weeks with ≥1 run)
     - long_run_trend ('improving'|'flat'|'declining')
     - pace_trend (same)
  3. Call LLM once (via AI SDK) with the metrics object in context, produce a short narrative summary ("consistent weeks, healthy easy pace, clear progression…"). Temperature low, no tool use.
  4. Upsert user_running_profiles row.
  5. Return the model.
```

### 5.2 `AnalyzeRunningProfileJob`
`api/app/Jobs/AnalyzeRunningProfileJob.php`

Parameters: `conversationId`, `userId`.

Flow:
1. Call `RunningProfileService::analyze()`.
2. On success, append 4 scripted messages to `agent_conversation_messages` with `role='assistant'`, correct `meta.message_type`, and payloads:
   - `text` — `narrative_summary`
   - `stats_card` — the 4 core metrics (payload JSON)
   - `text` — "Anything you're training for, or want to work toward?"
   - `chip_suggestions` — the 4 branch chips
3. Advance `agent_conversations.meta.onboarding_step` to `awaiting_branch`.
4. On failure: swap the `loading_card` message to an error variant with a retry action; update step to `analysis_failed`.

### 5.3 `OnboardingController`
`api/app/Http/Controllers/OnboardingController.php`

| Endpoint                                              | Purpose |
|-------------------------------------------------------|---------|
| `POST /v1/onboarding/start`                           | Idempotent. Creates (or returns existing) onboarding conversation, seeds `loading_card`, dispatches `AnalyzeRunningProfileJob`. Returns `{conversation_id, messages: [loading_card]}`. |
| `POST /v1/onboarding/conversations/{id}/messages`     | User reply (chip tap or free text). Body: `{text, chip_value?}`. Routes based on `onboarding_step`, classifies free text against chips if needed (via a small LLM call), appends user + next scripted bot messages, advances step. Returns `{messages: [...newly appended]}`. At `awaiting_coach_style` completion, transitions to `plan_generating` and invokes the agent (reusing the existing coach-chat agent invocation) to call `CreateSchedule`. |
| `POST /v1/onboarding/abandon`                         | "Not sure yet" path. Appends scripted goodbye bot message, sets `users.has_completed_onboarding = true`, no goal created. Returns `{messages: [goodbye]}`. |

**Async message delivery.** The analyze job runs out-of-band and appends new messages to the conversation. The Flutter client subscribes via the **existing** `GET /v1/coach/conversations/{id}/messages` (polling with lightweight `since` cursor) — same mechanism the regular chat screen uses today. When the streaming-coach-chat spec lands, onboarding picks it up for free since it uses the same endpoints and components. No onboarding-specific transport.

Proposal accept piggybacks on the **existing** `/v1/coach/proposals/{id}/accept` — that handler additionally flips `has_completed_onboarding = true` when the proposal's conversation has `context='onboarding'`.

### 5.4 Onboarding step machine

Tracked as `agent_conversations.meta.onboarding_step`:

```
pending_analysis
  → awaiting_branch
    → awaiting_race_details            (Race)
    → awaiting_fitness_days            (General fitness)
    → awaiting_faster_distance         (Get faster)
        → awaiting_faster_pr_target
        → awaiting_faster_days
  → awaiting_coach_style
  → plan_generating
  → plan_proposed
  → completed
  → abandoned                          (Not sure yet)
  → analysis_failed                    (retry branch)
```

The controller's handler is a switch on this state.

### 5.5 Free-text-to-chip classifier

When the user types free text at a chip-based step, the server runs a small LLM classifier grounded on the current step's chip options. Prompt: *"User wrote: '{text}'. Options: [{labels}]. Which option's value best matches, or NONE?"*. Returns structured output (JSON with chosen chip value or null). If NONE, the bot re-prompts with the chips; otherwise proceeds as if the chip were tapped.

### 5.6 Agent updates

- New tool `GetRunningProfile` — reads the cached `user_running_profiles` row; used in future chats so the agent doesn't need to re-analyze.
- `RunCoachAgent::instructions()` updated to: (a) know about goal types, (b) know about `GetRunningProfile`, (c) handle the onboarding-context case where coach_style + race details are already captured in prior scripted messages — agent just parses + calls `CreateSchedule`.

### 5.7 Auth router redirect

Updated in `app/lib/router/app_router.dart`: check `!user.hasCompletedOnboarding` instead of `coachStyle == null`.

---

## 6. Flutter architecture

### 6.1 `CoachMessage` — extended

`app/lib/features/coach/models/coach_message.dart`:

```dart
@freezed sealed class CoachMessage {
  const factory CoachMessage({
    required String id,
    required String role,
    required String content,
    @JsonKey(name: 'message_type') @Default('text') String messageType,
    @JsonKey(name: 'message_payload') Map<String, dynamic>? messagePayload,
    @JsonKey(name: 'created_at') required String createdAt,
    CoachProposal? proposal,
    String? errorDetail,
    @Default(false) bool streaming,
    String? toolIndicator,
  }) = _CoachMessage;
}
```

### 6.2 `MessageBubble` — type switch

`app/lib/features/coach/widgets/message_bubble.dart` becomes a switch on `messageType`:

- `text` → existing `GptMarkdown` bubble (unchanged).
- `loading_card` → **reuses the existing `ThinkingCard`** widget (`app/lib/features/coach/widgets/thinking_card.dart`). It already matches the Figma design exactly — radial gold gradient + white base, EB Garamond headline, swooshing star icon, pulsing opacity, asymmetric corner radius. The `message_payload.label` is passed into its `label` parameter. Used for both "Analysing Strava Data" and "Working on your plan" — no new widget needed.
- `stats_card` → new `StatsCardBubble` — wraps existing bot bubble; inside, a 2×2 grid of metric tiles (uppercase tracking label, serif number at 24px).
- `chip_suggestions` → new `ChipSuggestionsRow` — right-aligned flex-wrap of white pills. Tap calls `sendMessage(conversationId, text: chip.label, chipValue: chip.value)`.
- `proposal_card` → updated `ProposalCard` matching Figma: compact `Weekly km | Weekly runs` summary + `VIEW DETAILS` ghost + `ACCEPT PLAN` (yellow `#E9B638`) / `ADJUST` (black). Expand-to-details opens the full week-by-week view.

### 6.3 `CoachChatView` — extracted

To share with onboarding, the core of `CoachChatScreen` (message list + chat input + scroll behavior) is extracted into `CoachChatView(conversationId: ..., inputEnabled: ...)`. Both `/coach/chat/:id` and `/onboarding` mount it; they differ only in scaffold chrome.

### 6.4 `OnboardingShell`

`app/lib/features/onboarding/screens/onboarding_shell.dart`:
- Scaffold: no bottom nav, no back button.
- AppBar: centered RunCore logo (reuse existing logo widget).
- Body: `CoachChatView(conversationId: <onboarding_conv_id>)`.
- Input: same chat input as regular chat.

### 6.5 Providers

- `onboardingConversationProvider` — Riverpod, auto-generated. Calls `/v1/onboarding/start` on first access, caches the conversation id, feeds into `messagesProvider(id)`.
- Chip tap → calls existing `coachChatProvider.sendMessage(id, text, chipValue)`.

### 6.6 Router

`app/lib/router/app_router.dart`:
- Redirect: `if (loggedIn && user.hasCompletedOnboarding == false && location != '/onboarding') → /onboarding`.
- Remove old `coachStyle == null` check.
- Add `/onboarding` route rendering `OnboardingShell`.
- Delete old `/auth/onboarding` route + files.

### 6.7 "Not sure yet" path

Chip value `skip` → backend returns a scripted goodbye bot message and sets `has_completed_onboarding=true`. Flutter refreshes the auth user; router auto-redirects to `/dashboard`.

### 6.8 Proposal accept path

Reuses existing accept handler. On success, Flutter refetches the auth user (now `has_completed_onboarding=true`); router auto-redirects to `/dashboard`.

---

## 7. Edge cases

| Case | Behavior |
|---|---|
| Strava fetch fails (token/rate limit/network) | Loading card swaps to error variant with "Retry" button. After 3 retries, offer "Skip analysis" — show branch chips without stats. |
| User has <4 weeks / zero running history | Proceed normally. Narrative LLM gets sparse metrics and adapts ("just getting started — that's great"). Stats card shows what's there. |
| Narrative LLM call fails/times out | Fall back to a canned sentence: *"Here's your last 12 months."* Never blocks onboarding. |
| App killed mid-flow | `agent_conversation` + `onboarding_step` persist. Router still forces `/onboarding` on relaunch. Chat history renders the prior scripted messages; user continues. |
| User types free text instead of tapping a chip | Server runs the small LLM classifier against the current step's chip options. Match → proceed; no match → re-prompt with chips. |
| Proposal rejected / "Adjust" tapped | Opens free text to the agent in the same conversation. Agent iterates via `ModifySchedule`. Onboarding only completes on accept. |
| Accept during onboarding | Existing accept handler flips `has_completed_onboarding = true` when proposal's conversation has `context='onboarding'`. |

---

## 8. Testing

### Backend (PHPUnit, `LazilyRefreshDatabase`)
- `RunningProfileServiceTest` — mocked Strava client; assert metric computation for full year, sparse history, and zero activities. Assert narrative LLM is called exactly once and fallback fires on failure.
- `AnalyzeRunningProfileJobTest` — asserts the 4 expected bot messages are appended in order with correct `message_type` and step transitions.
- `OnboardingControllerTest` — one test per step transition in the `onboarding_step` state machine, plus the "Not sure yet" abandon path, plus proposal accept flipping `has_completed_onboarding`.
- `RunCoachAgentTest` — `CreateSchedule` accepts nullable `target_date`/`distance`; `goal_type` flows through; `GetGoalInfo` and `GetRunningProfile` tool schemas validate.
- `ChipClassifierTest` — free-text-to-chip mapping for expected phrasings ("a race", "just wanna stay fit", "get faster at 5k", "idk").

### Flutter
- `flutter analyze` must pass.
- No provider tests introduced (none exist yet; deferred per `CLAUDE.md`).

### Manual verification (golden path)
1. Fresh user, Strava OAuth → lands on `/onboarding`.
2. Loading card → stats card + narrative → branch chips appear.
3. Tap "Race coming up!" → race prompt; send free text; coach_style chips.
4. Tap "Balanced" → "Working on your plan" → proposal card.
5. Tap "Accept plan" → `/dashboard`; `goals` row exists with `type=race`; plan is active.
6. Relaunch app — not forced to `/onboarding`.
7. Repeat for General fitness, Get faster, "Not sure yet".
8. Kill app mid-flow → relaunch resumes from last bot message.

---

## 9. Rollout

- Pre-launch, no production data. Safe to rewrite migrations.
- Edit `races` migration → rename to `goals`, add `type`, make `target_date`/`distance` nullable. Rename the migration filename.
- Edit `users` migration → add `has_completed_onboarding`, drop `level` + `weekly_km_capacity`.
- Add new `create_user_running_profiles_table` migration.
- Add `context` column migration for `agent_conversations`.
- Run `php artisan migrate:fresh`.
- Delete `OnboardingScreen`, `/auth/onboarding` route, `ProfileController::onboarding`, and related onboarding form files.
- Update `RunCoachAgent::instructions()`.

---

## 10. Deferred

- Profile refresh cadence (weekly cron or on-demand stale check).
- Streaming SSE for the analysis job (rides on standard chat transport until streaming spec lands).
- Admin view of onboarding funnel / conversion metrics.
- "Reset my coach" / redo onboarding UI.
- Dutch copy / i18n.

---

## 11. Appendix — scripted bot copy

### "Not sure yet" goodbye
> "No stress. Your running history is in and I've got it from here. Whenever you want to set a goal, just ask me — I'll be on the coach tab."

### Race path happy path

1. "Analysing Strava Data" *(loading_card)*
2. *(LLM narrative — example)*: "I've gone through your last year of running. The picture is good — consistent weeks, healthy easy pace, and a clear progression in your long runs. Here's the snapshot:"
3. *(stats_card)* — weekly_avg_km, weekly_avg_runs, avg_pace, session_avg_duration
4. "Anything you're training for, or want to work toward?"
5. *(chips)* — Race coming up! / General fitness / Get faster / Not sure yet
6. *(user chooses Race coming up!)*
7. "Alright, let's get you going!\n\nTo create the plan, I need 3 things:\n  1. Race name\n  2. Race date\n  3. Goal time, if you have one\n\nOptional but helpful:\n  • Race distance if it's not obvious from the name\n  • How many days/week you want to run\n  • Any injuries or days you can't train\n\nSend me something like: \"City 10K, 12th of september 2025, goal 55:00, 4 days/week\""
8. *(user sends free text)*
9. "One last thing — how do you want me to coach you?"
10. *(chips)* — Strict — hold me to it / Balanced / Flexible — adapt to my life
11. *(user chooses)*
12. "Working on your plan" *(loading_card)*
13. *(proposal_card)*
