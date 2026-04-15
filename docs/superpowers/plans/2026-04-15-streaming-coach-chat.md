# Streaming Coach Chat Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the one-shot JSON response in the AI coach chat with token-by-token SSE streaming + live tool indicators, preserving the existing proposal flow.

**Architecture:** Backend uses Laravel AI SDK's native `$agent->stream()` returning Server-Sent Events in the Vercel AI SDK protocol. The controller wraps the SDK iterator and appends a custom `data-proposal` event after stream completion. Flutter consumes via raw `dio` with `ResponseType.stream`, parses events with a hand-written `VercelStreamParser`, and updates a placeholder assistant message in the existing Riverpod `CoachChat` notifier as deltas arrive.

**Tech Stack:** Laravel 13, `laravel/ai ^0.5.1`, PHPUnit; Flutter, Riverpod (code-gen), Freezed 3.x, Dio.

**Spec:** See `docs/superpowers/specs/2026-04-15-streaming-coach-chat-design.md` for the full design.

---

## File Structure

### Backend (Laravel)

| File | Action | Purpose |
|---|---|---|
| `api/app/Http/Controllers/CoachController.php` | Modify | Replace `sendMessage()` with streaming version |
| `api/tests/Feature/Coach/StreamMessageTest.php` | Create | Feature tests for SSE endpoint |

### Frontend (Flutter)

| File | Action | Purpose |
|---|---|---|
| `app/lib/features/coach/models/coach_message.dart` | Modify | Add `streaming` and `toolIndicator` fields |
| `app/lib/features/coach/models/vercel_stream_event.dart` | Create | Freezed sealed class for parsed events |
| `app/lib/features/coach/data/vercel_stream_parser.dart` | Create | Bytes → typed stream events |
| `app/lib/features/coach/data/coach_stream_client.dart` | Create | Raw dio SSE wrapper + Riverpod provider |
| `app/lib/features/coach/providers/coach_provider.dart` | Modify | Rewrite `sendMessage()` to consume stream |
| `app/lib/features/coach/widgets/message_bubble.dart` | Modify | Render streaming caret + tool indicator pill |
| `app/lib/features/coach/screens/coach_chat_screen.dart` | Modify | Smart auto-scroll on each delta |
| `app/test/features/coach/data/vercel_stream_parser_test.dart` | Create | Parser unit tests |
| `app/test/features/coach/providers/coach_chat_streaming_test.dart` | Create | Provider integration tests with mocked client |
| `app/test/features/coach/widgets/message_bubble_test.dart` | Create | Widget test for streaming + tool pill |

### Out-of-scope confirmations

These are explicitly NOT in this plan (per the spec's "Out of scope" section):
- No Stop / cancel button
- No reconnect or resume logic
- No markdown rendering
- No Reverb / WebSockets
- No backwards-compatible non-streaming endpoint

---

## Task 1: Backend — Streaming endpoint with text-delta flow

**Files:**
- Create: `api/tests/Feature/Coach/StreamMessageTest.php`
- Modify: `api/app/Http/Controllers/CoachController.php`

This task replaces the current `CoachController::sendMessage()` (which returns `JsonResponse`) with a streaming version that returns `StreamedResponse`. The basic test asserts the response is `text/event-stream`, contains `text-delta` events, ends with `[DONE]`, and persists the assistant message.

Note: The existing `CoachChatTest::test_send_message` test (in `api/tests/Feature/CoachChatTest.php:38-61`) asserts the OLD JSON response shape and will break. We delete it as part of this task — the new `StreamMessageTest` covers the same behavior.

- [ ] **Step 1: Create the test directory and feature test file**

Create `api/tests/Feature/Coach/StreamMessageTest.php`:

```php
<?php

namespace Tests\Feature\Coach;

use App\Ai\Agents\RunCoachAgent;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class StreamMessageTest extends TestCase
{
    use LazilyRefreshDatabase;

    private function authUser(): array
    {
        $user = User::factory()->create();
        $token = $user->createToken('api')->plainTextToken;

        return [$user, ['Authorization' => "Bearer $token"]];
    }

    public function test_streams_text_deltas_as_sse(): void
    {
        RunCoachAgent::fake(['Hello there friend.']);

        [$user, $headers] = $this->authUser();

        $created = $this->postJson('/api/v1/coach/conversations', ['title' => 'Test'], $headers);
        $conversationId = $created->json('data.id');

        $response = $this->call(
            'POST',
            "/api/v1/coach/conversations/{$conversationId}/messages",
            ['content' => 'Hi'],
            [],
            [],
            $this->transformHeadersToServerVars($headers),
        );

        $response->assertOk();
        $this->assertStringContainsString(
            'text/event-stream',
            $response->headers->get('Content-Type'),
        );

        $body = $response->streamedContent();

        $this->assertStringContainsString('"type":"text-delta"', $body);
        $this->assertStringContainsString("data: [DONE]\n\n", $body);

        $this->assertDatabaseHas('agent_conversation_messages', [
            'conversation_id' => $conversationId,
            'role' => 'assistant',
            'content' => 'Hello there friend.',
        ]);
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api && php artisan test --compact tests/Feature/Coach/StreamMessageTest.php
```

Expected: FAIL. The current controller returns JSON, so `Content-Type` will be `application/json` and the body won't contain `text-delta`.

- [ ] **Step 3: Replace `sendMessage` in `CoachController` with the streaming version**

Open `api/app/Http/Controllers/CoachController.php` and replace these things:

1. Add this `use` at the top with the other imports:

```php
use Symfony\Component\HttpFoundation\StreamedResponse;
```

2. Replace the entire `sendMessage` method (lines 82-112 today) with:

```php
public function sendMessage(SendMessageRequest $request, string $conversationId): StreamedResponse
{
    $user = $request->user();
    $content = $request->validated()['content'];

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

        $proposal = $this->proposalService
            ->detectProposalFromConversation($user, $conversationId);

        if ($proposal) {
            echo 'data: '.json_encode([
                'type' => 'data-proposal',
                'data' => $proposal->toArray(),
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

- [ ] **Step 4: Delete the old non-streaming test that will now fail**

Open `api/tests/Feature/CoachChatTest.php` and delete the `test_send_message` method (lines 38-61). The new `StreamMessageTest` covers this behavior with the streaming contract.

- [ ] **Step 5: Run both test files to verify pass**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api && php artisan test --compact tests/Feature/Coach/StreamMessageTest.php tests/Feature/CoachChatTest.php
```

Expected: PASS. All tests in both files green.

- [ ] **Step 6: Run pint and full suite**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api && vendor/bin/pint --dirty --format agent && php artisan test --compact
```

Expected: All 45+ tests pass.

- [ ] **Step 7: Commit**

```bash
git add api/app/Http/Controllers/CoachController.php api/tests/Feature/Coach/StreamMessageTest.php api/tests/Feature/CoachChatTest.php
git commit -m "$(cat <<'EOF'
feat(api): stream coach messages as SSE using Laravel AI SDK

Replaces JSON response on POST /coach/conversations/{id}/messages
with a Server-Sent Events stream using the Vercel AI SDK protocol.
Deletes the old non-streaming send-message test; behavior is now
covered by Coach/StreamMessageTest.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Backend — `data-proposal` event emission

**Files:**
- Modify: `api/tests/Feature/Coach/StreamMessageTest.php`

The previous task implemented proposal injection in the controller, but we have no test for it. This task adds a focused test that mocks `ProposalService` to simulate a proposal being detected, and asserts the `data-proposal` event appears in the stream.

- [ ] **Step 1: Add the proposal-emission test to `StreamMessageTest`**

Add this test method to `api/tests/Feature/Coach/StreamMessageTest.php`:

```php
public function test_emits_data_proposal_event_when_proposal_detected(): void
{
    RunCoachAgent::fake(['Schedule created.']);

    [$user, $headers] = $this->authUser();

    $created = $this->postJson('/api/v1/coach/conversations', ['title' => 'T'], $headers);
    $conversationId = $created->json('data.id');

    $proposal = \App\Models\CoachProposal::factory()->create([
        'user_id' => $user->id,
        'agent_message_id' => \Illuminate\Support\Str::uuid()->toString(),
    ]);

    $this->mock(\App\Services\ProposalService::class, function ($mock) use ($proposal) {
        $mock->shouldReceive('detectProposalFromConversation')
            ->once()
            ->andReturn($proposal);
    });

    $response = $this->call(
        'POST',
        "/api/v1/coach/conversations/{$conversationId}/messages",
        ['content' => 'Create a plan'],
        [],
        [],
        $this->transformHeadersToServerVars($headers),
    );

    $response->assertOk();
    $body = $response->streamedContent();

    $this->assertStringContainsString('"type":"data-proposal"', $body);
    $this->assertStringContainsString('"id":'.$proposal->id, $body);
}

public function test_does_not_emit_data_proposal_when_no_proposal_detected(): void
{
    RunCoachAgent::fake(['Just chatting.']);

    [$user, $headers] = $this->authUser();

    $created = $this->postJson('/api/v1/coach/conversations', ['title' => 'T'], $headers);
    $conversationId = $created->json('data.id');

    $this->mock(\App\Services\ProposalService::class, function ($mock) {
        $mock->shouldReceive('detectProposalFromConversation')
            ->once()
            ->andReturn(null);
    });

    $response = $this->call(
        'POST',
        "/api/v1/coach/conversations/{$conversationId}/messages",
        ['content' => 'Hello'],
        [],
        [],
        $this->transformHeadersToServerVars($headers),
    );

    $response->assertOk();
    $body = $response->streamedContent();

    $this->assertStringNotContainsString('"type":"data-proposal"', $body);
    $this->assertStringContainsString("data: [DONE]\n\n", $body);
}
```

- [ ] **Step 2: Run the new tests**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api && php artisan test --compact tests/Feature/Coach/StreamMessageTest.php
```

Expected: All three tests in `StreamMessageTest` pass. The controller code from Task 1 already handles both branches (with and without proposal), so no implementation change is needed here — just verification.

- [ ] **Step 3: Run pint and commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api && vendor/bin/pint --dirty --format agent
git add api/tests/Feature/Coach/StreamMessageTest.php
git commit -m "$(cat <<'EOF'
test(api): cover data-proposal event emission in stream endpoint

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Frontend — Add streaming fields to `CoachMessage` and create `VercelStreamEvent` model

**Files:**
- Modify: `app/lib/features/coach/models/coach_message.dart`
- Create: `app/lib/features/coach/models/vercel_stream_event.dart`

Both are pure Freezed model changes — no behavior to test directly. The verification is `flutter analyze` passing and code generation succeeding. The models will be exercised by the parser tests in Task 4 and provider tests in Task 6.

- [ ] **Step 1: Add `streaming` and `toolIndicator` fields to `CoachMessage`**

Replace the contents of `app/lib/features/coach/models/coach_message.dart` with:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/features/coach/models/coach_proposal.dart';

part 'coach_message.freezed.dart';
part 'coach_message.g.dart';

@freezed
sealed class CoachMessage with _$CoachMessage {
  const factory CoachMessage({
    required String id,
    required String role,
    required String content,
    @JsonKey(name: 'created_at') required String createdAt,
    CoachProposal? proposal,
    @JsonKey(includeFromJson: false, includeToJson: false) String? errorDetail,
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default(false) bool streaming,
    @JsonKey(includeFromJson: false, includeToJson: false) String? toolIndicator,
  }) = _CoachMessage;

  factory CoachMessage.fromJson(Map<String, dynamic> json) =>
      _$CoachMessageFromJson(json);
}
```

The two new fields are excluded from JSON serialization (they are pure UI state) and default to `false` / `null`.

- [ ] **Step 2: Create `VercelStreamEvent` Freezed sealed class**

Create `app/lib/features/coach/models/vercel_stream_event.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/features/coach/models/coach_proposal.dart';

part 'vercel_stream_event.freezed.dart';

@freezed
sealed class VercelStreamEvent with _$VercelStreamEvent {
  const factory VercelStreamEvent.textDelta(String delta) = TextDeltaEvent;
  const factory VercelStreamEvent.toolStart(String toolName) = ToolStartEvent;
  const factory VercelStreamEvent.toolEnd() = ToolEndEvent;
  const factory VercelStreamEvent.proposal(CoachProposal proposal) =
      ProposalEvent;
  const factory VercelStreamEvent.error(String message) = ErrorEvent;
  const factory VercelStreamEvent.done() = DoneEvent;
}
```

No `fromJson` is needed — the parser will construct these directly. No `.g.dart` part either.

- [ ] **Step 3: Run code generation**

```bash
cd /Users/erwinwijnveld/projects/runcoach/app && dart run build_runner build --delete-conflicting-outputs
```

Expected: New `vercel_stream_event.freezed.dart` and updated `coach_message.freezed.dart` / `coach_message.g.dart`. No errors.

- [ ] **Step 4: Run `flutter analyze` to verify clean**

```bash
cd /Users/erwinwijnveld/projects/runcoach/app && flutter analyze
```

Expected: "No issues found!"

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/coach/models/coach_message.dart app/lib/features/coach/models/vercel_stream_event.dart app/lib/features/coach/models/coach_message.freezed.dart app/lib/features/coach/models/coach_message.g.dart app/lib/features/coach/models/vercel_stream_event.freezed.dart
git commit -m "$(cat <<'EOF'
feat(app): add streaming UI fields to CoachMessage and VercelStreamEvent

CoachMessage gains client-only streaming/toolIndicator fields. New
VercelStreamEvent sealed class types parsed SSE events for the
streaming chat flow.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Frontend — `VercelStreamParser` with TDD coverage

**Files:**
- Create: `app/lib/features/coach/data/vercel_stream_parser.dart`
- Create: `app/test/features/coach/data/vercel_stream_parser_test.dart`

The parser converts a `Stream<List<int>>` of HTTP body bytes into a `Stream<VercelStreamEvent>`. It buffers across chunk boundaries (events split mid-chunk are common over cellular), splits on SSE event boundary `\n\n`, strips `data: ` prefix, decodes JSON, maps known Vercel event types, and silently drops unknown types.

- [ ] **Step 1: Write the failing parser tests**

Create `app/test/features/coach/data/vercel_stream_parser_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/coach/data/vercel_stream_parser.dart';
import 'package:app/features/coach/models/vercel_stream_event.dart';

Stream<List<int>> _bytes(List<String> chunks) async* {
  for (final c in chunks) {
    yield utf8.encode(c);
  }
}

void main() {
  group('VercelStreamParser', () {
    final parser = VercelStreamParser();

    test('parses text-delta events', () async {
      final input = _bytes([
        'data: {"type":"text-delta","delta":"Hello"}\n\n',
        'data: {"type":"text-delta","delta":" world"}\n\n',
        'data: [DONE]\n\n',
      ]);

      final events = await parser.parse(input).toList();

      expect(events, [
        const VercelStreamEvent.textDelta('Hello'),
        const VercelStreamEvent.textDelta(' world'),
        const VercelStreamEvent.done(),
      ]);
    });

    test('parses tool-input-start as toolStart with humanized name', () async {
      final input = _bytes([
        'data: {"type":"tool-input-start","toolName":"SearchStravaActivities"}\n\n',
        'data: [DONE]\n\n',
      ]);

      final events = await parser.parse(input).toList();

      expect(events.first, isA<ToolStartEvent>());
      expect(
        (events.first as ToolStartEvent).toolName,
        'Looking up your activities…',
      );
    });

    test('parses tool-output-available as toolEnd', () async {
      final input = _bytes([
        'data: {"type":"tool-output-available","toolCallId":"x"}\n\n',
        'data: [DONE]\n\n',
      ]);

      final events = await parser.parse(input).toList();

      expect(events.first, isA<ToolEndEvent>());
    });

    test('parses error event', () async {
      final input = _bytes([
        'data: {"type":"error","errorText":"boom"}\n\n',
        'data: [DONE]\n\n',
      ]);

      final events = await parser.parse(input).toList();

      expect(events.first, isA<ErrorEvent>());
      expect((events.first as ErrorEvent).message, 'boom');
    });

    test('parses data-proposal event into ProposalEvent', () async {
      final input = _bytes([
        'data: {"type":"data-proposal","data":{"id":42,"type":"create_schedule","status":"pending","payload":{},"created_at":"2026-04-15T00:00:00Z","agent_message_id":"abc","user_id":1}}\n\n',
        'data: [DONE]\n\n',
      ]);

      final events = await parser.parse(input).toList();

      expect(events.first, isA<ProposalEvent>());
      expect((events.first as ProposalEvent).proposal.id, 42);
    });

    test('drops unknown event types silently', () async {
      final input = _bytes([
        'data: {"type":"reasoning-delta","delta":"thinking..."}\n\n',
        'data: {"type":"text-delta","delta":"hi"}\n\n',
        'data: [DONE]\n\n',
      ]);

      final events = await parser.parse(input).toList();

      expect(events, [
        const VercelStreamEvent.textDelta('hi'),
        const VercelStreamEvent.done(),
      ]);
    });

    test('drops malformed JSON lines without crashing', () async {
      final input = _bytes([
        'data: {not valid json\n\n',
        'data: {"type":"text-delta","delta":"recovered"}\n\n',
        'data: [DONE]\n\n',
      ]);

      final events = await parser.parse(input).toList();

      expect(events, [
        const VercelStreamEvent.textDelta('recovered'),
        const VercelStreamEvent.done(),
      ]);
    });

    test('handles event split across multiple chunks', () async {
      final input = _bytes([
        'data: {"type":"text-de',
        'lta","delta":"Hi"}\n\n',
        'data: [DONE]\n\n',
      ]);

      final events = await parser.parse(input).toList();

      expect(events, [
        const VercelStreamEvent.textDelta('Hi'),
        const VercelStreamEvent.done(),
      ]);
    });

    test('skips SSE comment lines beginning with colon', () async {
      final input = _bytes([
        ': keep-alive\n\n',
        'data: {"type":"text-delta","delta":"hi"}\n\n',
        'data: [DONE]\n\n',
      ]);

      final events = await parser.parse(input).toList();

      expect(events, [
        const VercelStreamEvent.textDelta('hi'),
        const VercelStreamEvent.done(),
      ]);
    });
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

```bash
cd /Users/erwinwijnveld/projects/runcoach/app && flutter test test/features/coach/data/vercel_stream_parser_test.dart
```

Expected: FAIL — parser file doesn't exist yet.

- [ ] **Step 3: Implement the parser**

Create `app/lib/features/coach/data/vercel_stream_parser.dart`:

```dart
import 'dart:convert';

import 'package:app/features/coach/models/coach_proposal.dart';
import 'package:app/features/coach/models/vercel_stream_event.dart';

class VercelStreamParser {
  static const _humanizedTools = {
    'SearchStravaActivities': 'Looking up your activities…',
    'GetCurrentSchedule': 'Loading your schedule…',
    'GetRaceInfo': 'Checking your race…',
    'GetComplianceReport': 'Reviewing compliance…',
    'CreateSchedule': 'Building your training plan…',
    'ModifySchedule': 'Adjusting your schedule…',
  };

  Stream<VercelStreamEvent> parse(Stream<List<int>> bytes) async* {
    final buffer = StringBuffer();

    await for (final chunk in bytes.transform(utf8.decoder)) {
      buffer.write(chunk);
      final text = buffer.toString();
      final boundary = text.lastIndexOf('\n\n');
      if (boundary == -1) continue;

      final complete = text.substring(0, boundary + 2);
      final remainder = text.substring(boundary + 2);

      buffer
        ..clear()
        ..write(remainder);

      for (final block in complete.split('\n\n')) {
        if (block.isEmpty) continue;

        for (final line in block.split('\n')) {
          if (line.startsWith(':')) continue;
          if (!line.startsWith('data: ')) continue;

          final payload = line.substring(6);
          if (payload == '[DONE]') {
            yield const VercelStreamEvent.done();
            return;
          }

          final event = _parseEvent(payload);
          if (event != null) yield event;
        }
      }
    }

    final tail = buffer.toString().trim();
    if (tail.startsWith('data: ')) {
      final payload = tail.substring(6);
      if (payload == '[DONE]') {
        yield const VercelStreamEvent.done();
      }
    }
  }

  VercelStreamEvent? _parseEvent(String payload) {
    try {
      final json = jsonDecode(payload) as Map<String, dynamic>;
      final type = json['type'] as String?;
      if (type == null) return null;

      return switch (type) {
        'text-delta' => VercelStreamEvent.textDelta(json['delta'] as String),
        'tool-input-start' => VercelStreamEvent.toolStart(
            _humanize(json['toolName'] as String? ?? ''),
          ),
        'tool-output-available' => const VercelStreamEvent.toolEnd(),
        'error' => VercelStreamEvent.error(
            json['errorText'] as String? ?? 'Unknown error',
          ),
        'data-proposal' => VercelStreamEvent.proposal(
            CoachProposal.fromJson(json['data'] as Map<String, dynamic>),
          ),
        _ => null,
      };
    } catch (_) {
      return null;
    }
  }

  String _humanize(String toolName) =>
      _humanizedTools[toolName] ?? 'Working on it…';
}
```

- [ ] **Step 4: Run the parser tests to verify they pass**

```bash
cd /Users/erwinwijnveld/projects/runcoach/app && flutter test test/features/coach/data/vercel_stream_parser_test.dart
```

Expected: PASS — all 8 tests green.

- [ ] **Step 5: Run `flutter analyze`**

```bash
cd /Users/erwinwijnveld/projects/runcoach/app && flutter analyze
```

Expected: "No issues found!"

- [ ] **Step 6: Commit**

```bash
git add app/lib/features/coach/data/vercel_stream_parser.dart app/test/features/coach/data/vercel_stream_parser_test.dart
git commit -m "$(cat <<'EOF'
feat(app): add VercelStreamParser for SSE chat events

Parses Server-Sent Events emitted by the streaming coach endpoint
into typed VercelStreamEvent values. Tolerates chunked transfers,
malformed JSON, and unknown event types.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Frontend — `CoachStreamClient` and Riverpod provider

**Files:**
- Create: `app/lib/features/coach/data/coach_stream_client.dart`

This is a thin wrapper around `dio` that issues the POST with `responseType: ResponseType.stream` and returns the parsed stream. We don't TDD this directly — it's a shim — but it's exercised end-to-end by the provider test in Task 6.

- [ ] **Step 1: Create the client + provider**

Create `app/lib/features/coach/data/coach_stream_client.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/core/api/dio_client.dart';
import 'package:app/features/coach/data/vercel_stream_parser.dart';
import 'package:app/features/coach/models/vercel_stream_event.dart';

part 'coach_stream_client.g.dart';

class CoachStreamClient {
  final Dio _dio;
  final VercelStreamParser _parser;

  CoachStreamClient(this._dio, [VercelStreamParser? parser])
      : _parser = parser ?? VercelStreamParser();

  Stream<VercelStreamEvent> streamMessage(
    String conversationId,
    String content,
  ) async* {
    final response = await _dio.post<ResponseBody>(
      '/coach/conversations/$conversationId/messages',
      data: {'content': content},
      options: Options(
        responseType: ResponseType.stream,
        headers: {'Accept': 'text/event-stream'},
      ),
    );
    final body = response.data;
    if (body == null) return;
    yield* _parser.parse(body.stream);
  }
}

@riverpod
CoachStreamClient coachStreamClient(Ref ref) {
  return CoachStreamClient(ref.watch(dioProvider));
}
```

`dioProvider` is auto-generated from `Dio dio(Ref ref)` in `app/lib/core/api/dio_client.dart` — the Riverpod code-gen convention. Verified.

- [ ] **Step 2: Run code generation**

```bash
cd /Users/erwinwijnveld/projects/runcoach/app && dart run build_runner build --delete-conflicting-outputs
```

Expected: New `coach_stream_client.g.dart` generated. No errors.

- [ ] **Step 3: Run `flutter analyze`**

```bash
cd /Users/erwinwijnveld/projects/runcoach/app && flutter analyze
```

Expected: "No issues found!"

- [ ] **Step 4: Commit**

```bash
git add app/lib/features/coach/data/coach_stream_client.dart app/lib/features/coach/data/coach_stream_client.g.dart
git commit -m "$(cat <<'EOF'
feat(app): add CoachStreamClient for SSE chat consumption

Wraps dio in stream response mode and pipes the body through
VercelStreamParser. Exposed as coachStreamClientProvider for Riverpod.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Frontend — Rewrite `CoachChat.sendMessage` to consume the stream

**Files:**
- Modify: `app/lib/features/coach/providers/coach_provider.dart`
- Create: `app/test/features/coach/providers/coach_chat_streaming_test.dart`

The provider replaces its current `await api.sendMessage(...)` with a stream subscription. It maintains an optimistic user message, a placeholder assistant message that grows as deltas arrive, and finalizes the placeholder on `done` or `error`.

- [ ] **Step 1: Write the failing provider test**

Create `app/test/features/coach/providers/coach_chat_streaming_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:app/features/coach/data/coach_api.dart';
import 'package:app/features/coach/data/coach_stream_client.dart';
import 'package:app/features/coach/models/vercel_stream_event.dart';
import 'package:app/features/coach/models/coach_proposal.dart';
import 'package:app/features/coach/providers/coach_provider.dart';

class _FakeStreamClient extends CoachStreamClient {
  final List<VercelStreamEvent> events;
  _FakeStreamClient(this.events) : super(Dio());

  @override
  Stream<VercelStreamEvent> streamMessage(String conversationId, String content) {
    return Stream.fromIterable(events);
  }
}

class _FakeCoachApi implements CoachApi {
  @override
  Future<dynamic> getConversation(String id) async => {
        'data': {
          'id': id,
          'title': 'T',
          'messages': <Map<String, dynamic>>[],
        },
      };

  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  test('streams text deltas into placeholder assistant message', () async {
    final container = ProviderContainer(overrides: [
      coachStreamClientProvider.overrideWithValue(
        _FakeStreamClient([
          const VercelStreamEvent.textDelta('Hello'),
          const VercelStreamEvent.textDelta(' world'),
          const VercelStreamEvent.done(),
        ]),
      ),
      coachApiProvider.overrideWithValue(_FakeCoachApi()),
    ]);
    addTearDown(container.dispose);

    final notifier = container.read(coachChatProvider('conv-1').notifier);
    await container.read(coachChatProvider('conv-1').future);

    await notifier.sendMessage('Hi');

    final messages = container.read(coachChatProvider('conv-1')).value!;
    expect(messages.length, 2);
    expect(messages[0].role, 'user');
    expect(messages[0].content, 'Hi');
    expect(messages[1].role, 'assistant');
    expect(messages[1].content, 'Hello world');
    expect(messages[1].streaming, false);
  });

  test('attaches proposal to the assistant message', () async {
    const proposal = CoachProposal(
      id: 1,
      type: 'create_schedule',
      status: 'pending',
      payload: <String, dynamic>{},
    );
    final container = ProviderContainer(overrides: [
      coachStreamClientProvider.overrideWithValue(
        _FakeStreamClient([
          const VercelStreamEvent.textDelta('Done'),
          VercelStreamEvent.proposal(proposal),
          const VercelStreamEvent.done(),
        ]),
      ),
      coachApiProvider.overrideWithValue(_FakeCoachApi()),
    ]);
    addTearDown(container.dispose);

    final notifier = container.read(coachChatProvider('conv-1').notifier);
    await container.read(coachChatProvider('conv-1').future);

    await notifier.sendMessage('Plan it');

    final assistant = container.read(coachChatProvider('conv-1')).value!.last;
    expect(assistant.proposal?.id, 1);
  });

  test('clears toolIndicator when text starts streaming', () async {
    final container = ProviderContainer(overrides: [
      coachStreamClientProvider.overrideWithValue(
        _FakeStreamClient([
          const VercelStreamEvent.toolStart('Looking up your activities…'),
          const VercelStreamEvent.textDelta('Found them.'),
          const VercelStreamEvent.done(),
        ]),
      ),
      coachApiProvider.overrideWithValue(_FakeCoachApi()),
    ]);
    addTearDown(container.dispose);

    final notifier = container.read(coachChatProvider('conv-1').notifier);
    await container.read(coachChatProvider('conv-1').future);

    await notifier.sendMessage('Hi');

    final assistant = container.read(coachChatProvider('conv-1')).value!.last;
    expect(assistant.toolIndicator, isNull);
    expect(assistant.content, 'Found them.');
  });

  test('records errorDetail on error event', () async {
    final container = ProviderContainer(overrides: [
      coachStreamClientProvider.overrideWithValue(
        _FakeStreamClient([
          const VercelStreamEvent.textDelta('partial'),
          const VercelStreamEvent.error('boom'),
          const VercelStreamEvent.done(),
        ]),
      ),
      coachApiProvider.overrideWithValue(_FakeCoachApi()),
    ]);
    addTearDown(container.dispose);

    final notifier = container.read(coachChatProvider('conv-1').notifier);
    await container.read(coachChatProvider('conv-1').future);

    await notifier.sendMessage('Hi');

    final assistant = container.read(coachChatProvider('conv-1')).value!.last;
    expect(assistant.errorDetail, 'boom');
    expect(assistant.streaming, false);
    expect(assistant.content, 'partial');
  });
}
```

The test uses `CoachProposal(id: 1, type: 'create_schedule', status: 'pending', payload: <String, dynamic>{})` — verified against `app/lib/features/coach/models/coach_proposal.dart`: `id` is `int`, `payload` is `Map<String, dynamic>`, no `createdAt` field exists.

- [ ] **Step 2: Run the tests to verify they fail**

```bash
cd /Users/erwinwijnveld/projects/runcoach/app && flutter test test/features/coach/providers/coach_chat_streaming_test.dart
```

Expected: FAIL — provider still calls the old non-streaming API.

- [ ] **Step 3: Rewrite `sendMessage` in the provider**

Replace the `sendMessage` method in `app/lib/features/coach/providers/coach_provider.dart` (lines 28-56 today) with:

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
  var current = CoachMessage(
    id: 'streaming-${DateTime.now().millisecondsSinceEpoch}',
    role: 'assistant',
    content: '',
    createdAt: DateTime.now().toIso8601String(),
    streaming: true,
  );
  state = AsyncData([...before, userMsg, current]);

  try {
    await for (final event in stream.streamMessage(conversationId, content)) {
      current = switch (event) {
        TextDeltaEvent(:final delta) => current.copyWith(
            content: current.content + delta,
            toolIndicator: null,
          ),
        ToolStartEvent(:final toolName) =>
          current.copyWith(toolIndicator: toolName),
        ToolEndEvent() => current,
        ProposalEvent(:final proposal) => current.copyWith(proposal: proposal),
        ErrorEvent(:final message) => current.copyWith(
            errorDetail: message,
            streaming: false,
          ),
        DoneEvent() =>
          current.copyWith(streaming: false, toolIndicator: null),
      };
      state = AsyncData([...before, userMsg, current]);
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

Add the import at the top of the file:

```dart
import 'package:app/features/coach/data/coach_stream_client.dart';
import 'package:app/features/coach/models/vercel_stream_event.dart';
```

The old `import 'package:app/features/coach/data/coach_api.dart';` is still needed because `getConversation` (in the `build` method) uses it.

- [ ] **Step 4: Remove the now-unused `sendMessage` from the Retrofit client**

In `app/lib/features/coach/data/coach_api.dart`, delete the `sendMessage` method (lines 21-25 today):

```dart
@POST('/coach/conversations/{id}/messages')
Future<dynamic> sendMessage(
  @Path() String id,
  @Body() Map<String, dynamic> body,
);
```

The provider no longer calls `api.sendMessage` — it goes through `CoachStreamClient`. Leaving it in the interface would create dead code.

Re-run code generation so `coach_api.g.dart` no longer contains the implementation:

```bash
cd /Users/erwinwijnveld/projects/runcoach/app && dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 5: Run the provider tests to verify they pass**

```bash
cd /Users/erwinwijnveld/projects/runcoach/app && flutter test test/features/coach/providers/coach_chat_streaming_test.dart
```

Expected: PASS — all 4 tests green.

- [ ] **Step 6: Run all tests + analyze**

```bash
cd /Users/erwinwijnveld/projects/runcoach/app && flutter analyze && flutter test
```

Expected: All tests pass, no analyzer issues.

- [ ] **Step 7: Commit**

```bash
git add app/lib/features/coach/providers/coach_provider.dart app/lib/features/coach/data/coach_api.dart app/lib/features/coach/data/coach_api.g.dart app/test/features/coach/providers/coach_chat_streaming_test.dart
git commit -m "$(cat <<'EOF'
feat(app): consume streaming chat events in CoachChat provider

Rewrites sendMessage to subscribe to CoachStreamClient and update
a placeholder assistant message as text-delta, tool, proposal, and
error events arrive. Removes the now-unused non-streaming sendMessage
from the Retrofit CoachApi.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: Frontend — Render streaming caret and tool indicator pill in `MessageBubble`

**Files:**
- Modify: `app/lib/features/coach/widgets/message_bubble.dart`
- Create: `app/test/features/coach/widgets/message_bubble_test.dart`

The bubble needs two visual additions: a blinking caret at the end of streaming text, and a small pill below the bubble showing the current tool indicator.

**Current `MessageBubble` structure** (`app/lib/features/coach/widgets/message_bubble.dart`):
- Outer `Column` (cross-axis end for user, start for assistant) at lines 16-72
- Inside: `Align` + `Container` — the bubble (lines 20-68)
- Inner `Column` with optional `COACH` label (lines 42-54) and `Text(message.content, ...)` (lines 55-64)
- Below the `Align`: optional `_ErrorStrip` (lines 69-70)

Caret integration: replace the `Text(message.content, ...)` (lines 55-64) with a `Text.rich` so we can append a `WidgetSpan` for the blinking caret when streaming.

Pill integration: add a sibling element in the outer `Column` after the `Align` — same alignment as the bubble (assistant-side, left-aligned).

- [ ] **Step 1: Write the failing widget test**

Create `app/test/features/coach/widgets/message_bubble_test.dart`:

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/coach/models/coach_message.dart';
import 'package:app/features/coach/widgets/message_bubble.dart';

CoachMessage _msg({
  required String content,
  bool streaming = false,
  String? toolIndicator,
}) =>
    CoachMessage(
      id: 'm',
      role: 'assistant',
      content: content,
      createdAt: '2026-04-15T00:00:00Z',
      streaming: streaming,
      toolIndicator: toolIndicator,
    );

void main() {
  testWidgets('renders streaming caret when streaming is true',
      (tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: MessageBubble(message: _msg(content: 'Hello', streaming: true)),
      ),
    );

    expect(find.byKey(const Key('streaming-caret')), findsOneWidget);
  });

  testWidgets('does not render caret when streaming is false', (tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: MessageBubble(message: _msg(content: 'Hello', streaming: false)),
      ),
    );

    expect(find.byKey(const Key('streaming-caret')), findsNothing);
  });

  testWidgets('renders tool indicator pill when toolIndicator is set',
      (tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: MessageBubble(
          message: _msg(
            content: '',
            streaming: true,
            toolIndicator: 'Looking up your activities…',
          ),
        ),
      ),
    );

    expect(find.text('Looking up your activities…'), findsOneWidget);
  });

  testWidgets('does not render pill when toolIndicator is null',
      (tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: MessageBubble(
          message: _msg(content: 'Done', streaming: false),
        ),
      ),
    );

    expect(find.byKey(const Key('tool-indicator-pill')), findsNothing);
  });
}
```

- [ ] **Step 2: Run the widget tests to confirm they fail**

```bash
cd /Users/erwinwijnveld/projects/runcoach/app && flutter test test/features/coach/widgets/message_bubble_test.dart
```

Expected: FAIL — caret and pill widgets don't exist yet.

- [ ] **Step 3: Modify `MessageBubble` to render caret and pill**

Replace the entire contents of `app/lib/features/coach/widgets/message_bubble.dart` with:

```dart
import 'package:flutter/cupertino.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/coach/models/coach_message.dart';

class MessageBubble extends StatelessWidget {
  final CoachMessage message;
  final VoidCallback? onRetry;

  const MessageBubble({super.key, required this.message, this.onRetry});

  bool get _isUser => message.role == 'user';
  bool get _failed => message.errorDetail != null;

  @override
  Widget build(BuildContext context) {
    final textColor =
        _isUser ? CupertinoColors.white : AppColors.textPrimary;

    return Column(
      crossAxisAlignment:
          _isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: _isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.only(
              left: _isUser ? 60 : 0,
              right: _isUser ? 0 : 60,
              bottom: _failed ? 4 : 8,
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _isUser ? AppColors.warmBrown : AppColors.lightTan,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(_isUser ? 18 : 4),
                bottomRight: Radius.circular(_isUser ? 4 : 18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_isUser)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      'COACH',
                      style: TextStyle(
                        color: AppColors.warmBrown,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                Text.rich(
                  TextSpan(
                    text: message.content,
                    style: TextStyle(
                      fontSize: 15,
                      color: textColor,
                      height: 1.35,
                    ),
                    children: [
                      if (message.streaming)
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: _BlinkingCaret(
                            key: const Key('streaming-caret'),
                            color: textColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (message.toolIndicator != null)
          Padding(
            key: const Key('tool-indicator-pill'),
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.lightTan,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CupertinoActivityIndicator(radius: 6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    message.toolIndicator!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.warmBrown,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_failed)
          _ErrorStrip(detail: message.errorDetail!, onRetry: onRetry),
      ],
    );
  }
}

class _BlinkingCaret extends StatefulWidget {
  final Color color;
  const _BlinkingCaret({super.key, required this.color});

  @override
  State<_BlinkingCaret> createState() => _BlinkingCaretState();
}

class _BlinkingCaretState extends State<_BlinkingCaret>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Text('▍', style: TextStyle(fontSize: 14, color: widget.color)),
    );
  }
}

class _ErrorStrip extends StatelessWidget {
  final String detail;
  final VoidCallback? onRetry;

  const _ErrorStrip({required this.detail, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 60),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_circle,
            size: 14,
            color: AppColors.danger,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              detail,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.danger,
              ),
              textAlign: TextAlign.end,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 4),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              onPressed: onRetry,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.refresh,
                    size: 14,
                    color: AppColors.warmBrown,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Retry',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.warmBrown,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

The whole file is shown so the implementer doesn't have to reverse-engineer which lines to change. The `_ErrorStrip` private class is unchanged from the original.

- [ ] **Step 4: Run the widget tests to verify they pass**

```bash
cd /Users/erwinwijnveld/projects/runcoach/app && flutter test test/features/coach/widgets/message_bubble_test.dart
```

Expected: PASS — all 4 widget tests green.

- [ ] **Step 5: Run analyze + full test suite**

```bash
cd /Users/erwinwijnveld/projects/runcoach/app && flutter analyze && flutter test
```

Expected: All tests pass, no analyzer issues.

- [ ] **Step 6: Commit**

```bash
git add app/lib/features/coach/widgets/message_bubble.dart app/test/features/coach/widgets/message_bubble_test.dart
git commit -m "$(cat <<'EOF'
feat(app): render streaming caret and tool indicator pill in MessageBubble

Adds a blinking caret to streaming assistant messages and a tan pill
below the bubble showing the current tool indicator.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: Frontend — Smart auto-scroll during streaming + sending state

**Files:**
- Modify: `app/lib/features/coach/screens/coach_chat_screen.dart`

The current screen scrolls to the bottom only after a message is sent. With streaming, we want to auto-scroll on each delta — but only if the user is already near the bottom (so we don't yank their view if they've scrolled up to read earlier messages). We also need to clear the `_sending` flag based on the streaming message's final state, not just when `sendMessage` returns.

- [ ] **Step 1: Update `_send` to keep `_sending` true until the assistant message stops streaming**

In `app/lib/features/coach/screens/coach_chat_screen.dart`, the current `_send` method awaits `notifier.sendMessage(content)`. With the streaming rewrite from Task 6, that future already completes only when the stream ends — so `_sending` is correctly true for the entire stream duration. No change needed here. Just verify by reading `_send` (lines 23-37).

- [ ] **Step 2: Add a listener that auto-scrolls on state changes when at bottom**

In `_CoachChatScreenState`, replace the existing `build` method's body so that we listen to the provider for incremental updates and trigger smart auto-scroll. Inside `build`, before the return statement, add:

```dart
ref.listen<AsyncValue<List<CoachMessage>>>(
  coachChatProvider(widget.conversationId),
  (previous, next) {
    if (next.value == null) return;
    if (!_isNearBottom()) return;
    _scrollToBottom();
  },
);
```

And add this helper method to the State class:

```dart
bool _isNearBottom() {
  if (!_scrollController.hasClients) return true;
  final position = _scrollController.position;
  return (position.maxScrollExtent - position.pixels) < 80;
}
```

You'll need to import `CoachMessage` if not already imported:

```dart
import 'package:app/features/coach/models/coach_message.dart';
```

- [ ] **Step 3: Run analyze**

```bash
cd /Users/erwinwijnveld/projects/runcoach/app && flutter analyze
```

Expected: "No issues found!"

- [ ] **Step 4: Manual smoke test (UI behavior)**

This step requires a running backend + simulator. If you can't run the app right now, mark this step done and verify in Task 9. Otherwise:

```bash
# Terminal 1
cd /Users/erwinwijnveld/projects/runcoach/api && composer run dev

# Terminal 2
cd /Users/erwinwijnveld/projects/runcoach/app && flutter run
```

Send a chat message. Observe:
- Text appears word-by-word
- A blinking caret follows the text
- Tool indicator pills appear when the agent calls tools
- Auto-scroll keeps the new text visible
- Scroll up mid-stream → auto-scroll stops (verify it doesn't yank)

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/coach/screens/coach_chat_screen.dart
git commit -m "$(cat <<'EOF'
feat(app): smart auto-scroll during streaming chat

Listens to chat provider state changes and scrolls to bottom only
when the user is already near the bottom, avoiding view yank when
they've scrolled up to read.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 9: End-to-end smoke test + final cleanup

**Files:**
- (Verification only — possible follow-up edits)

This task is the integration check. Run the full backend + Flutter stack and validate the streaming flow against the design.

- [ ] **Step 1: Verify backend test suite is green**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api && php artisan test --compact
```

Expected: All tests pass (45+ existing + 3 new in `Coach/StreamMessageTest.php`).

- [ ] **Step 2: Verify Flutter test suite is green**

```bash
cd /Users/erwinwijnveld/projects/runcoach/app && flutter analyze && flutter test
```

Expected: No analyzer issues, all tests pass.

- [ ] **Step 3: Run the app against a real backend**

```bash
# Terminal 1
cd /Users/erwinwijnveld/projects/runcoach/api && composer run dev

# Terminal 2
cd /Users/erwinwijnveld/projects/runcoach/app && flutter run
```

Test these scenarios manually in the iOS simulator (or device):

| Scenario | Expected behavior |
|---|---|
| Send a short message ("hi") | Response streams word-by-word with caret |
| Send a message that triggers a tool ("how was last week?") | Tool indicator pill appears during tool call, then disappears as text streams |
| Send a message that creates a proposal ("create a plan for a 10K in 8 weeks") | Tool indicators appear, then text streams, then `ProposalCard` renders |
| Background the app mid-stream, return | Stream may not resume in-app, but on chat reload the full message appears |
| Disable network mid-stream (airplane mode) | Partial text remains, error pill shows on the bubble |
| Scroll up while streaming | View stays where you put it (no yank) |

- [ ] **Step 4: Verify message persistence**

While the simulator is running, send a message. Then in a third terminal:

```bash
cd /Users/erwinwijnveld/projects/runcoach/api && php artisan tinker --execute 'echo \DB::table("agent_conversation_messages")->orderByDesc("created_at")->first()->content;'
```

Expected: The full assistant message text matches what streamed in the UI.

- [ ] **Step 5: Final commit (if any cleanup edits were needed)**

If smoke testing surfaced any issues, fix them and commit. Otherwise this task is complete with no commit.

- [ ] **Step 6: Push and announce completion**

```bash
git push origin main
```

Notify the user that streaming chat is live with a one-line summary of what shipped and how to verify.
