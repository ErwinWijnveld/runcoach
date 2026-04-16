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
      payload: {},
    );
    final container = ProviderContainer(overrides: [
      coachStreamClientProvider.overrideWithValue(
        _FakeStreamClient([
          const VercelStreamEvent.textDelta('Done'),
          const VercelStreamEvent.proposal(proposal),
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
