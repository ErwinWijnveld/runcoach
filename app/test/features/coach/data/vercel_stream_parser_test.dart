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

    test('parses tool-input-available as toolStart with humanized name', () async {
      final input = _bytes([
        'data: {"type":"tool-input-available","toolName":"SearchStravaActivities"}\n\n',
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
