# Streaming Coach Chat — Design Spec

**Date:** 2026-04-15
**Status:** Approved, ready for implementation plan
**Scope:** Replace one-shot JSON response in the AI coach chat with token-by-token streaming + live tool indicators.

## Problem

Today, when a user sends a message to the AI coach, the Flutter app calls `POST /api/v1/coach/conversations/{id}/messages` and waits 5–30 seconds for the full JSON response. The UI shows a spinner the entire time. Long agent loops (multi-tool calls hitting the Strava API) feel broken because nothing visible happens.

Three concrete problems:

1. **No perceived progress.** Users can't tell whether the coach is thinking, working, or stuck.
2. **No transparency on what the agent is doing.** When the agent calls `SearchStravaActivities` and waits 3 seconds for Strava, the user has no idea why it's slow.
3. **Long waits feel like errors.** A 25-second wait with no feedback reads as "broken" to most users, even when the eventual response is good.

## Solution

Use the Laravel AI SDK's native streaming (`$agent->stream()`), which emits server-sent events using the [Vercel AI SDK stream protocol](https://ai-sdk.dev/docs/ai-sdk-ui/stream-protocol). The Flutter app consumes the stream via `dio` with `ResponseType.stream`, parses events with a small `VercelStreamParser`, and incrementally updates the UI.

Tool calls produce ephemeral "indicator pills" ("Looking up your activities…") so the user sees real progress while the agent works. The `CoachProposal` flow is preserved by injecting a custom `data-proposal` event after the SDK stream completes.

The decision-defining choices made during brainstorming:
- **UX scope:** text streaming + tool indicators (B), not full reasoning visibility
- **Cancellation:** fire-and-forget (A) — no Stop button, server completes regardless of client state
- **Approach:** SDK native streaming + Vercel protocol (Approach 1) — not custom protocol, not Reverb

## Architecture

```
┌─────────────────────────────────────────────────┐
│ Flutter                                         │
│                                                 │
│  CoachChatScreen                                │
│       │                                         │
│       ▼ sendMessage(content)                   │
│  CoachChat (Riverpod notifier)                  │
│       │                                         │
│       ▼                                         │
│  CoachStreamClient (raw dio)                    │
│       │                                         │
│       ▼ POST .../messages/stream                │
│  ┌────────────────────────────────────────────┐ │
│  │ VercelStreamParser (bytes → typed events)  │ │
│  └────────────────────────────────────────────┘ │
│       │                                         │
│       ▼ Stream<VercelStreamEvent>              │
│  CoachChat updates state per event              │
└─────────────────────────────────────────────────┘
                       │
                       │ HTTP SSE (text/event-stream)
                       ▼
┌─────────────────────────────────────────────────┐
│ Laravel API                                     │
│                                                 │
│  CoachController::sendMessage                   │
│       │                                         │
│       ▼ response()->stream(closure)             │
│  ┌────────────────────────────────────────────┐ │
│  │ foreach ($agent->stream($content) ...)     │ │
│  │   yield Vercel-formatted SSE line          │ │
│  │ ProposalService::detect...                 │ │
│  │ yield data-proposal event                  │ │
│  │ yield [DONE]                               │ │
│  └────────────────────────────────────────────┘ │
│       │                                         │
│       ▼                                         │
│  RunCoachAgent (unchanged)                      │
│       │                                         │
│       ▼                                         │
│  RemembersConversations persists message        │
│  in agent_conversation_messages                 │
└─────────────────────────────────────────────────┘
```

## Wire protocol

### Endpoint

`POST /api/v1/coach/conversations/{conversation}/messages` — same path as today, but now returns `text/event-stream` instead of JSON. Old JSON-returning behavior is removed (no clients other than this app).

**Request body:** `{"content": "..."}` (unchanged)

**Response headers:**
- `Content-Type: text/event-stream`
- `Cache-Control: no-cache, no-transform`
- `X-Accel-Buffering: no` (disables nginx buffering)

**Response body framing:** `data: <json>\n\n` per event, terminated by `data: [DONE]\n\n`. This is the Vercel AI SDK stream protocol.

### Event types we emit

| Vercel `type` | Source | UI rendering |
|---|---|---|
| `start` | SDK (StreamStart) | Ignored |
| `text-start` | SDK (TextStart) | Ignored |
| `text-delta` | SDK (TextDelta) | Append `delta` to current bubble's content; clear tool indicator |
| `text-end` | SDK (TextEnd) | Ignored |
| `tool-input-available` | SDK (ToolCall) | Set tool indicator pill |
| `tool-output-available` | SDK (ToolResult) | (No-op — keep pill until next text-delta to avoid flicker) |
| `error` | SDK (Error) | Show error pill, mark message non-streaming |
| `finish` | SDK (StreamEnd) | Ignored |
| `data-proposal` | **Custom (us)** | Attach `CoachProposal` to current bubble, render `ProposalCard` |

### Event types we ignore for v1

- `reasoning-start` / `reasoning-delta` / `reasoning-end` — model "thinking" tokens. Out of scope per Approach B.
- `citation` — not used by current providers in our setup.
- `provider-tool-event` — not used.

The parser silently discards unknown event types so future SDK additions don't crash the client.

### `data-proposal` event shape

```json
{
  "type": "data-proposal",
  "data": {
    "id": 42,
    "type": "create_schedule",
    "status": "pending",
    "payload": { ... },
    "created_at": "2026-04-15T10:23:45Z"
  }
}
```

The `data` field is the `CoachProposal` Eloquent model serialized as JSON — same shape as the `proposal` field in today's history endpoint response. The client deserializes it into the existing `CoachProposal` Freezed model.

## Backend

### `CoachController::sendMessage` rewrite

Replaces the existing method (`api/app/Http/Controllers/CoachController.php`). New signature returns `StreamedResponse`:

```php
public function sendMessage(SendMessageRequest $request, string $conversationId): StreamedResponse
{
    $user = $request->user();
    $content = $request->validated()['content'];

    // Verify conversation belongs to user (matches existing endpoint)
    DB::table('agent_conversations')
        ->where('id', $conversationId)
        ->where('user_id', $user->id)
        ->firstOrFail();

    return response()->stream(function () use ($user, $conversationId, $content) {
        ignore_user_abort(true);
        set_time_limit(0);

        $stream = RunCoachAgent::make(user: $user)
            ->continue($conversationId, as: $user)
            ->stream($content);

        foreach ($stream as $event) {
            $payload = $event->toVercelProtocolArray();
            if (! empty($payload)) {
                echo 'data: '.json_encode($payload)."\n\n";
                ob_flush();
                flush();
            }
        }

        $proposal = app(ProposalService::class)
            ->detectProposalFromConversation($user, $conversationId);

        if ($proposal) {
            echo 'data: '.json_encode([
                'type' => 'data-proposal',
                'data' => $proposal->toArray(),  // Eloquent model serialization
            ])."\n\n";
            ob_flush();
            flush();
        }

        echo "data: [DONE]\n\n";
        ob_flush();
        flush();
    }, 200, [
        'Content-Type' => 'text/event-stream',
        'Cache-Control' => 'no-cache, no-transform',
        'X-Accel-Buffering' => 'no',
    ]);
}
```

### Why this works

1. **Persistence is automatic.** `RemembersConversations` is part of `RunCoachAgent`. The trait's persistence hooks fire when the SDK stream iterator finishes (inside `StreamableAgentResponse::getIterator()` after the foreach completes — see `vendor/laravel/ai/src/Responses/StreamableAgentResponse.php:122-155`). The `then()` callbacks run before the foreach unwinds, so by the time we call `detectProposalFromConversation()`, the latest assistant message + `tool_results` are already persisted in `agent_conversation_messages`.

2. **`ignore_user_abort(true) + set_time_limit(0)`.** If the Flutter client disconnects mid-stream, PHP keeps iterating to completion. The SDK still persists the full message and the proposal still gets created. Trade-off: one OpenAI call always runs to completion, which costs tokens whether the user sees the result or not. Per Approach A (fire-and-forget), this is the right trade.

3. **Single endpoint, single contract.** No separate "stream" path, no feature flag, no fallback to non-streaming. Solo developer, single client app. YAGNI.

### What we don't change in the backend

- `RunCoachAgent` class — no changes
- `ProposalService::detectProposalFromConversation()` — no changes
- `CoachProposal` model + migrations — no changes
- All other routes (`/proposals/{id}/accept`, `/conversations`, etc.) — no changes
- Database schema — no changes

### Backend dependencies on SDK behavior

This design depends on three SDK behaviors. If any are wrong, the implementation plan needs to verify and adjust:

1. `StreamEvent::toVercelProtocolArray()` exists on every event class. *(Verified — see `vendor/laravel/ai/src/Responses/Concerns/CanStreamUsingVercelProtocol.php`.)*
2. `RemembersConversations` persists the assistant message + tool_results during stream completion, not only during `prompt()`. *(Strongly implied by SDK design; needs a quick implementation-time test.)*
3. `RunCoachAgent::fake([...])` produces stream-iterable events for tests. *(Needs verification — fallback is to test with a stubbed gateway.)*

## Frontend

### File map

New files:
- `app/lib/features/coach/data/coach_stream_client.dart` — raw dio SSE client
- `app/lib/features/coach/data/vercel_stream_parser.dart` — bytes → typed events
- `app/lib/features/coach/models/vercel_stream_event.dart` — Freezed sealed class
- `test/features/coach/data/vercel_stream_parser_test.dart`
- `test/features/coach/providers/coach_chat_streaming_test.dart`

Modified files:
- `app/lib/features/coach/models/coach_message.dart` — add `streaming`, `toolIndicator`
- `app/lib/features/coach/providers/coach_provider.dart` — rewrite `sendMessage`
- `app/lib/features/coach/widgets/message_bubble.dart` — render streaming caret + tool pill
- `app/lib/features/coach/screens/coach_chat_screen.dart` — minor (auto-scroll on each delta if at-bottom)

### `VercelStreamEvent` (Freezed sealed class)

```dart
@freezed
sealed class VercelStreamEvent with _$VercelStreamEvent {
  const factory VercelStreamEvent.textDelta(String delta) = _TextDelta;
  const factory VercelStreamEvent.toolStart(String toolName) = _ToolStart;
  const factory VercelStreamEvent.toolEnd() = _ToolEnd;
  const factory VercelStreamEvent.proposal(CoachProposal proposal) = _Proposal;
  const factory VercelStreamEvent.error(String message) = _Error;
  const factory VercelStreamEvent.done() = _Done;
}
```

Unknown Vercel `type` values are dropped silently in the parser.

### `VercelStreamParser`

```dart
class VercelStreamParser {
  Stream<VercelStreamEvent> parse(Stream<List<int>> bytes) async* {
    final lineBuffer = StringBuffer();
    await for (final chunk in bytes.transform(utf8.decoder)) {
      lineBuffer.write(chunk);
      // Split on \n\n (SSE event boundary)
      // For each event: strip "data: ", handle [DONE], JSON-decode, map to VercelStreamEvent
      // Tolerate split chunks across decode boundaries (incomplete lines stay in buffer)
    }
  }
}
```

Implementation notes for the plan:
- Buffer must handle an event split across two HTTP chunks (common over cellular).
- Comment lines (starting with `:`) are skipped per SSE spec.
- The `[DONE]` sentinel emits `VercelStreamEvent.done()` and ends the stream.
- Malformed JSON in a `data:` line is logged (in debug builds) and dropped; the stream continues.

### Tool name humanization

Lives in the parser, not the UI:

```dart
String _humanizeTool(String toolName) => switch (toolName) {
  'SearchStravaActivities' => 'Looking up your activities…',
  'GetCurrentSchedule'     => 'Loading your schedule…',
  'GetRaceInfo'            => 'Checking your race…',
  'GetComplianceReport'    => 'Reviewing compliance…',
  'CreateSchedule'         => 'Building your training plan…',
  'ModifySchedule'         => 'Adjusting your schedule…',
  _                        => 'Working on it…',
};
```

The UI just renders whatever string the event carries.

### `CoachStreamClient`

Bypasses Retrofit (which has poor SSE support). Wraps `dio` directly:

```dart
class CoachStreamClient {
  final Dio _dio;
  CoachStreamClient(this._dio);

  Stream<VercelStreamEvent> streamMessage(String conversationId, String content) async* {
    final response = await _dio.post<ResponseBody>(
      '/coach/conversations/$conversationId/messages',
      data: {'content': content},
      options: Options(
        responseType: ResponseType.stream,
        headers: {'Accept': 'text/event-stream'},
      ),
    );
    final body = response.data!;
    yield* VercelStreamParser().parse(body.stream);
  }
}
```

A Riverpod provider exposes a single instance backed by the existing `dioClient`.

### `CoachMessage` model — additions

```dart
@freezed
sealed class CoachMessage with _$CoachMessage {
  const factory CoachMessage({
    required String id,
    required String role,
    required String content,
    required String createdAt,
    @Default(false) bool streaming,
    String? toolIndicator,
    CoachProposal? proposal,
    String? errorDetail,
  }) = _CoachMessage;

  factory CoachMessage.fromJson(Map<String, dynamic> json) =>
      _$CoachMessageFromJson(json);
}
```

`streaming` and `toolIndicator` are client-only — never serialized to/from the backend (default values handle missing JSON keys).

### `CoachChat` provider — rewrite of `sendMessage`

```dart
Future<void> sendMessage(String content) async {
  final stream = ref.read(coachStreamClientProvider);
  final before = state.value ?? [];

  final userMsg = CoachMessage(
    id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
    role: 'user',
    content: content,
    createdAt: DateTime.now().toIso8601String(),
  );
  final placeholderId = 'streaming-${DateTime.now().millisecondsSinceEpoch}';
  final placeholder = CoachMessage(
    id: placeholderId,
    role: 'assistant',
    content: '',
    createdAt: DateTime.now().toIso8601String(),
    streaming: true,
  );
  state = AsyncData([...before, userMsg, placeholder]);

  CoachMessage current = placeholder;
  try {
    await for (final event in stream.streamMessage(conversationId, content)) {
      current = switch (event) {
        _TextDelta(:final delta) => current.copyWith(
            content: current.content + delta,
            toolIndicator: null,
          ),
        _ToolStart(:final toolName) => current.copyWith(toolIndicator: toolName),
        _ToolEnd() => current,
        _Proposal(:final proposal) => current.copyWith(proposal: proposal),
        _Error(:final message) => current.copyWith(
            errorDetail: message,
            streaming: false,
          ),
        _Done() => current.copyWith(streaming: false, toolIndicator: null),
      };
      state = AsyncData([
        ...before,
        userMsg,
        current,
      ]);
    }
  } catch (e) {
    state = AsyncData([
      ...before,
      userMsg,
      current.copyWith(streaming: false, errorDetail: _humanize(e)),
    ]);
  }
}
```

### UI changes

`MessageBubble`:
- When `message.streaming == true`, render a thin blinking caret (`▍`) at the end of the text. Use `AnimatedOpacity` or a `TweenAnimationBuilder` with a 600ms cycle.
- When `message.toolIndicator != null`, render a small pill below the bubble: tan background (`AppColors.lightTan`), brown text (`AppColors.warmBrown`), 13px font, rounded 12px, with leading spinner.

`CoachChatScreen`:
- Auto-scroll runs on each state change, but only if the user is already within ~80px of the bottom (avoid yanking the view if they've scrolled up to read earlier messages).
- `_ChatInput`'s `_sending` flag stays — set when stream starts, clear on `done` or `error`. Send button disabled during stream.

## Persistence & history reload

- The SDK persists the **complete** assistant message (text + `tool_calls` + `tool_results`) into `agent_conversation_messages` after the stream iterator finishes.
- `streaming` and `toolIndicator` are **never persisted** — they're ephemeral UI state.
- History reload (`GET /coach/conversations/{id}`) returns clean text + `proposal` for past assistant messages, exactly as today. Reloaded messages always have `streaming: false`, `toolIndicator: null` (defaults).
- If the user closes the app mid-stream, `ignore_user_abort(true)` keeps the server iterating. On reopen + history reload, the user sees the full message — they missed the typing animation but didn't miss content.

## Edge cases

| Case | Behavior |
|---|---|
| Network drops mid-stream | `await for` throws. Catch path marks placeholder `streaming: false`, attaches `errorDetail: 'Connection lost — refresh to see full reply'`. Server continues to completion; next history reload shows full text. |
| User navigates away mid-stream | Riverpod disposes the provider; the dio stream subscription is cancelled. Server keeps running. Same as above on return. |
| OpenAI / tool error mid-stream | SDK emits `error` event. Bubble shows partial text + error pill. User can tap retry (existing flow). |
| User sends second message during stream | Send button disabled while `_sending == true`. Cannot happen for v1. |
| Markdown / code blocks in response | Stays plain text. Markdown rendering is out of scope. |
| Two simultaneous chat sessions on different devices | Out of scope for v1. Last-write-wins via existing conversation flow; streaming doesn't change this. |
| Provider returns `[DONE]` without any deltas | Placeholder finalizes with empty content. Renders as an empty assistant bubble. Acceptable for v1; could add empty-state messaging later. |
| Custom `data-proposal` event missing or malformed | Parser drops it silently. User sees text response without proposal card — same as if the agent didn't propose anything. |

## Testing

### Backend

`tests/Feature/Coach/StreamMessageTest.php`:
- Asserts response is `text/event-stream` with correct headers.
- Reads the streamed body, asserts presence of `text-delta` events and final `[DONE]`.
- Asserts `agent_conversation_messages` has the persisted assistant message after stream ends.
- Asserts `data-proposal` event is emitted when the agent's response triggers a `CreateSchedule` tool call (use a fake that injects a tool call).

If `RunCoachAgent::fake()` doesn't support stream events, fall back to a small `FakeStreamingTextGateway` that emits canned events.

### Frontend

`test/features/coach/data/vercel_stream_parser_test.dart`:
- Feed canned SSE bytes (including events split across chunks). Assert emitted events.
- Feed malformed JSON in a `data:` line. Assert it's dropped, stream continues.
- Feed `[DONE]`. Assert `done()` event and stream completion.

`test/features/coach/providers/coach_chat_streaming_test.dart`:
- Mock `CoachStreamClient` to emit a known sequence of events.
- Assert state transitions: placeholder appears → deltas accumulate → tool indicator appears/disappears → proposal attaches → `streaming: false` on done.

`test/features/coach/widgets/message_bubble_test.dart`:
- One test: streaming message renders caret. Final message does not.

## Out of scope (YAGNI)

These are explicitly **not** part of v1:

- Stop button / cancellation
- Resume on disconnect / reconnect logic
- Persisting tool indicators in history (replay on reload)
- Markdown rendering in messages
- Reasoning-token visibility
- Reverb / WebSocket infrastructure
- Multi-device sync of in-progress streams
- Backwards-compatible non-streaming endpoint (legacy fallback)
- Per-message regenerate / "try again with different model"

Each can be added later without breaking the protocol or schema.

## Open questions / risks

1. **`RemembersConversations` persistence during stream.** Strongly implied by the SDK's design (the `then()` callbacks run on iterator completion), but needs a quick test in the implementation to confirm the message lands in `agent_conversation_messages` with full `tool_results`.

2. **`RunCoachAgent::fake()` and stream events.** If the SDK fake doesn't produce stream-iterable events, we'll need a small test gateway. Not blocking — fallback exists.

3. **PHP buffering on production.** `ob_flush()` + `flush()` should work, but the production server (FrankenPHP / Laravel Octane / nginx + php-fpm) may add its own buffering. The `X-Accel-Buffering: no` header handles nginx; need to verify whatever the production setup is.

4. **iOS background suspension during stream.** If the user backgrounds the app mid-stream, dio's HTTP connection may be killed by iOS. Server still completes; on resume the user reloads history. Acceptable per Approach A.

5. **Token cost of `ignore_user_abort(true)`.** Every started message costs full OpenAI tokens whether the user sees the response or not. For v1 with low traffic this is fine. If usage grows, we revisit.
