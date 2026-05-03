# Workout Agent — per-training-day overlay chat

**Status:** in-progress
**Date:** 2026-05-03

## Problem

The schedule single-page (training day detail screen) currently has a "chat with the coach" prompt bar that opens a fresh **general** coach conversation. That conversation has no context about the workout the user just tapped on, and the user has to re-explain. It also reuses the main coach chat list, so a quick "what's this interval?" question pollutes the long-term coach history.

We want a workout-scoped, in-context chat that:

1. Knows everything about THIS training day (target, intervals, completed result + AI feedback if any).
2. Can edit / reschedule THIS day specifically.
3. Can give advice with context from other runs.
4. Refuses to do bigger things (multi-week edits, goal changes, broad coaching) and instead offers to start a coach chat with the question pre-seeded.
5. Lives as a backdrop-blur overlay on the schedule item, persists per-day across opens, and never appears in the main coach chat list.

Most chat UI must be reused — message bubbles, input pill, streaming, retry, proposal cards.

## Approach

### Backend
- **Migration tweak** (in place, pre-launch): add `subject_type` (string nullable) + `subject_id` (unsigned bigint nullable) to `agent_conversations`, with a `(user_id, subject_type, subject_id)` index. Polymorphic pointer; first user is `WorkoutAgent` with `subject_type = 'training_day'`.
- **`WorkoutAgent`** (`app/Ai/Agents/WorkoutAgent.php`) — separate Agent class. Implements `Agent`, `Conversational`, `HasTools`, uses `Promptable` + `RemembersConversations`. Constructor takes `User`. Resolves the bound `TrainingDay` via the conversation's `subject_id` and embeds it in the system prompt: target stats, intervals, status. If the day is completed, also embeds the result (compliance scores, actual distance/pace/HR, AI feedback) — so the agent doesn't have to call a tool to know how the run went.
- **Tool set** — small, mostly reused:
  - `GetRecentRuns`, `SearchActivities`, `GetActivityDetails` (reused as-is from RunCoachAgent for cross-run context)
  - `EditWorkout` (new) — wraps `EditSchedule` with a single `set_day` op pinned to the bound day; goes through the existing `ProposalService` proposal pipeline
  - `RescheduleWorkout` (new) — moves the day; same validation as `TrainingScheduleController::updateDay` (no race day, no completed days)
  - `EscalateToCoach` (new) — pure UI signal, returns `{requires_handoff: true, suggested_prompt: "..."}`. Not stored as a proposal; surfaced via a new `data-handoff` SSE event.
- **`AgentStreamingService`** (`app/Services/AgentStreamingService.php`) — extracted streaming helper. Takes a configured `Agent`, a conversation id, content; runs the SSE loop, emits `data-stats`/`data-chips` for UI tools, runs `ProposalService::detectProposalFromConversation`, and surfaces `data-handoff` when an `EscalateToCoach` tool result appears. `CoachController::sendMessage` and the new `WorkoutChatController::sendMessage` both delegate to it.
- **`WorkoutChatController`** (`app/Http/Controllers/WorkoutChatController.php`):
  - `GET /workout-chat/{trainingDay}` — returns the conversation + messages if one exists for `(user, training_day)`; 204 (or 200 with `data: null`) otherwise.
  - `POST /workout-chat/{trainingDay}/messages` — resolve-or-create the conversation row, then stream via `AgentStreamingService` with a fresh `WorkoutAgent`.
- `CoachController::index` is unchanged — workout conversations have `subject_type IS NOT NULL`, but the coach list filter is `whereNull('context')`, so they'd leak. Add `whereNull('subject_type')` to that query as well.

### Flutter
- **`CoachChatView` is already abstracted** by callbacks (`watchMessages`, `sendMessage`, etc.) — reuse as-is.
- **`CoachMessage`** — add a `handoff` field (nullable string `seedPrompt`). Hydrated by the workout chat provider on `data-handoff`. Not persisted by the API show endpoint either (server doesn't store handoffs as messages).
- **`VercelStreamEvent`** — add `handoff(String seedPrompt)` variant; parser maps `data-handoff` to it.
- **`WorkoutChat` Riverpod notifier** (`features/schedule/providers/workout_chat_provider.dart`) — keyed by `int trainingDayId`. `build()` calls `GET /workout-chat/{id}`; if no conversation, returns empty list. `sendMessage()` mirrors `CoachChat.sendMessage`, hitting the workout endpoint. Handles `data-handoff` by attaching to the current message.
- **`WorkoutChatSheet`** (`features/schedule/widgets/workout_chat_sheet.dart`) — `showGeneralDialog` with `BackdropFilter(blur)`, hosts `CoachChatView` configured with the workout provider's callbacks. Adds an `onHandoff` callback that closes the sheet and calls `startNewCoachChat(context, ref, seedMessage: seed)`.
- **`startNewCoachChat`** — extend to accept optional `seedMessage`; if provided, after navigating, call `sendMessage(seedMessage)` on the new conversation.
- **Training day detail screen** — replace the current `CoachPromptBar.navigateAnimated(onTap: startNewCoachChat)` to instead open `WorkoutChatSheet.show(context, trainingDayId)`.

### Conversation lifetime / completed-day handling
- Workout conversations live forever (default answer to open question 1). Completed days still allow chat — the agent gets the result + AI feedback in its system prompt, mutation tools (`EditWorkout`, `RescheduleWorkout`) refuse via the existing controller validation (training day with result can't be rescheduled; editing a completed day's targets is allowed but pointless — the agent prompt steers away).
- Race day: chat is allowed; `EditWorkout` is allowed for nudges (e.g. notes); `RescheduleWorkout` refuses (existing race-day invariant).

## Out of scope
- `VerifyPlan` after a single-day edit (its constraints assume full plan context).
- Multi-day edits (those are coach territory; agent escalates).
- Workout chat list / browser UI (each chat is owned by a single TrainingDay, opened from that day only).

## Test plan
- Backend: feature test for `WorkoutChatController::index/show` (resolves existing convo, returns null when none), `sendMessage` (creates convo on first send, attaches subject pointer), and `EscalateToCoach` tool surfaces `data-handoff`. Tool tests for `EditWorkout` (creates a proposal with a single set_day op) and `RescheduleWorkout` (refuses race day, refuses completed day).
- Flutter: `flutter analyze` clean. Manual smoke per CLAUDE.md "for UI or frontend changes" rule.
