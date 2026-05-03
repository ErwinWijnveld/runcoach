# Workout Agent — implementation plan

Spec: `docs/superpowers/specs/2026-05-03-workout-agent.md`

Order is important — backend lands first so the Flutter side has something to call.

## Backend

### Step 1 — Schema
- [ ] Edit `api/database/migrations/2026_04_13_193942_create_agent_conversations_table.php`:
  - add `$table->string('subject_type')->nullable();`
  - add `$table->unsignedBigInteger('subject_id')->nullable();`
  - add `$table->index(['user_id', 'subject_type', 'subject_id']);`
- [ ] `php artisan migrate:fresh` (per project convention; safe pre-launch).

### Step 2 — New tools
- [ ] `api/app/Ai/Tools/EscalateToCoach.php` — schema: `{suggested_prompt: string}`. Returns `json_encode(['display' => 'handoff', 'requires_handoff' => true, 'suggested_prompt' => ...])`. The `display` field lets the streaming service detect it just like `stats_card` / `chip_suggestions`.
- [ ] `api/app/Ai/Tools/EditWorkout.php` — schema: `{fields: string (JSON-encoded set_day fields)}`. Internally constructs `[{'op':'set_day','week':<derived>,'day_of_week':<derived>,'fields':...}]` against the active goal and delegates to `EditSchedule::handle` (or its underlying logic). Returns the same `requires_approval: true` payload.
  - Resolution: load the bound `TrainingDay` (passed in via constructor), compute its `week_number` via `trainingWeek` and `day_of_week` via `date->dayOfWeekIso`. Find the active goal id. Then call into the `EditSchedule` tool by instantiating it and passing the `goal_id`+`operations`.
- [ ] `api/app/Ai/Tools/RescheduleWorkout.php` — schema: `{date: string YYYY-MM-DD}`. Resolves the bound day, applies the same validation as `TrainingScheduleController::updateDay` (no race day, no completed day, date in goal range), updates the row + reassigns to matching week, returns `{rescheduled: true, date, training_day_id}`.

### Step 3 — WorkoutAgent
- [ ] `api/app/Ai/Agents/WorkoutAgent.php` — class similar to `RunCoachAgent`. Constructor: `User $user`. `instructions()` queries the conversation's `subject_id` (where `subject_type = 'training_day'`), eager loads `TrainingDay` with `result.wearableActivity` + `trainingWeek.goal`, and embeds:
  - Today's date.
  - Day target: date, type, target_km, target_pace_seconds_per_km, target_heart_rate_zone, intervals_json (formatted).
  - Status (upcoming / today / missed / completed).
  - If completed: actual stats (compliance_score, actual_km, actual_pace, actual_avg_hr, distance_score, pace_score, heart_rate_score) AND `result.ai_feedback`.
  - Hard scope rules: only this workout. Anything broader (multi-day plan changes, goal type/distance/date changes, deep coaching about other runs that goes beyond context) → call `escalate_to_coach` with a one-sentence `suggested_prompt` summarising the user's request; do NOT attempt the change yourself.
  - Tone + brevity (mirror coach style preference from `$user->coach_style`).
  - Always call `escalate_to_coach` rather than refusing in prose.
- [ ] `tools()` returns: `[GetRecentRuns, SearchActivities, GetActivityDetails, EditWorkout (if planMutationsAllowed), RescheduleWorkout (if planMutationsAllowed), EscalateToCoach]`.

### Step 4 — Streaming service refactor
- [ ] `api/app/Services/AgentStreamingService.php`. Method `stream(Agent $agent, string $conversationId, User $user, string $content): \Generator`. Yields the same SSE strings the inline code in `CoachController::sendMessage` yields today, and post-stream calls `ProposalService::detectProposalFromConversation` and emits `data-proposal`. Also emits `data-handoff` on `display === 'handoff'`.
- [ ] `CoachController::sendMessage` — replace inline streaming with a call into `AgentStreamingService`.
- [ ] `CoachController::index` — add `->whereNull('subject_type')` to keep workout chats out.

### Step 5 — WorkoutChatController + routes
- [ ] `api/app/Http/Controllers/WorkoutChatController.php`:
  - `show(Request $request, int $trainingDayId)` — confirm day belongs to user; look up agent_conversations row by `(user_id, subject_type='training_day', subject_id=$dayId)`. If exists, return same shape as `CoachController::show`; else `{data: null}`.
  - `sendMessage(SendMessageRequest, int $trainingDayId)` — confirm day belongs to user; resolve-or-create the conversation row (UUID + DB insert with title = "Workout chat" + subject_type/id); call `AgentStreamingService::stream` with a fresh `WorkoutAgent`.
- [ ] Routes:
  - `GET workout-chat/{trainingDay}` → `show`
  - `POST workout-chat/{trainingDay}/messages` → `sendMessage`

### Step 6 — Tests
- [ ] `tests/Feature/Http/WorkoutChatControllerTest.php` — show returns null when no convo; first sendMessage creates convo with subject pointer; subject_type filter excludes from `/coach/conversations`.
- [ ] `tests/Feature/Tools/RescheduleWorkoutTest.php` — refuses race day, refuses completed day, succeeds on a normal day, reassigns week.
- [ ] `tests/Feature/Tools/EditWorkoutTest.php` — produces a `CoachProposal` with a single set_day op.
- [ ] `tests/Feature/Tools/EscalateToCoachTest.php` — tool returns the `requires_handoff` payload (cheap unit-style feature test).
- [ ] `tests/Feature/Ai/WorkoutAgentInstructionsTest.php` — instructions include the day's target stats and (if completed) AI feedback.
- [ ] Run `php artisan test --compact` and `vendor/bin/pint --dirty --format agent`.

## Flutter

### Step 7 — Refactor: handoff plumbing
- [ ] `coach_message.dart` — add `String? handoffSeedPrompt` (transient, not serialized).
- [ ] `vercel_stream_event.dart` — add `handoff(String seedPrompt)` variant.
- [ ] `vercel_stream_parser.dart` — map `data-handoff` → `HandoffEvent(json['data']['suggested_prompt'])`. Add humanized label for `EscalateToCoach`, `EditWorkout`, `RescheduleWorkout`.
- [ ] `coach_chat_view.dart` — accept optional `Future<void> Function(WidgetRef, String seedPrompt)? onHandoff`; if `msg.handoffSeedPrompt != null` and callback is present, render a tile under the bubble like the existing proposal card pattern: "Ask the full coach about this →" → calls `onHandoff(ref, msg.handoffSeedPrompt!)`.
- [ ] Run `dart run build_runner build --delete-conflicting-outputs`.

### Step 8 — Workout chat provider + API
- [ ] `features/schedule/data/workout_chat_api.dart` — Retrofit `getWorkoutChat(int trainingDayId)` + the streaming endpoint URL constant. Reuse `CoachStreamClient` parameterised by URL — extract a method `streamRaw(String url, body)` so both can share it. (Or simpler: keep two stream methods, the workout one just hits the workout URL.)
- [ ] `features/schedule/providers/workout_chat_provider.dart` — `WorkoutChat` notifier, `build(int trainingDayId)`. Mirrors `CoachChat`. Adds `HandoffEvent` handling: appends `handoffSeedPrompt` to the current streaming message.

### Step 9 — Sheet UI
- [ ] `features/schedule/widgets/workout_chat_sheet.dart` — `static Future<void> show(BuildContext, int trainingDayId)`. Implementation: `showGeneralDialog` with `barrierDismissible: true`, custom `pageBuilder` returning a `Stack`:
  - `Positioned.fill(BackdropFilter(blur: 20, child: ColoredBox(black @ 30%)))` for the backdrop
  - bottom-anchored card (~85% height) containing `CoachChatView` configured to read/send via `WorkoutChat(trainingDayId)` and pass `onHandoff` → close + `startNewCoachChat(context, ref, seedMessage: seed)`.
  - swipe-down dismiss via a draggable handle row at the top + `onClose` chevron.
- [ ] `startNewCoachChat` (in `coach_provider.dart`) — accept optional `String? seedMessage`. After `context.push('/coach/chat/$id')`, fire `ref.read(coachChatProvider(id).notifier).sendMessage(seedMessage!)` if present.

### Step 10 — Wire into training day detail
- [ ] `training_day_detail_screen.dart` — change `CoachPromptBar.navigateAnimated(onTap: () => startNewCoachChat(context, ref), ...)` to `onTap: () => WorkoutChatSheet.show(context, day.id)`. Suggestions stay as-is.

### Step 11 — Verify
- [ ] `flutter analyze` clean.
- [ ] `flutter test` passes.
- [ ] Manual smoke (per CLAUDE.md): open a day, ask "what's this interval session for?", get an answer; ask "make it 3km shorter", see the proposal card; ask "build me a marathon plan" → handoff CTA appears; tap it → coach chat opens with that question pre-sent.
