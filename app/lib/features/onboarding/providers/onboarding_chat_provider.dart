import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/features/coach/models/coach_message.dart';
import 'package:app/features/onboarding/data/onboarding_api.dart';

part 'onboarding_chat_provider.g.dart';

@riverpod
class OnboardingChat extends _$OnboardingChat {
  Timer? _poll;

  @override
  Future<List<CoachMessage>> build(String conversationId) async {
    ref.onDispose(() {
      _poll?.cancel();
      _poll = null;
    });

    final messages = await _fetch(conversationId);
    _schedulePollIfWaiting(conversationId, messages);
    return messages;
  }

  Future<List<CoachMessage>> _fetch(String conversationId) async {
    final api = ref.read(onboardingApiProvider);
    final result = await api.fetchConversation(conversationId);
    final raw = (result as Map<String, dynamic>)['messages'] as List;
    return raw
        .map((m) => CoachMessage.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  /// Poll every 2s while the last assistant message is a loading_card
  /// (analysis in progress, plan generation in progress). Stops as soon as
  /// any non-loading assistant message arrives, or when the provider is
  /// disposed.
  void _schedulePollIfWaiting(
    String conversationId,
    List<CoachMessage> messages,
  ) {
    _poll?.cancel();
    _poll = null;

    if (!_isWaiting(messages)) return;

    _poll = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final fresh = await _fetch(conversationId);
        state = AsyncValue.data(fresh);
        if (!_isWaiting(fresh)) {
          timer.cancel();
          _poll = null;
        }
      } catch (_) {
        // Swallow — next tick will retry.
      }
    });
  }

  bool _isWaiting(List<CoachMessage> messages) {
    final lastAssistant = messages
        .where((m) => m.role == 'assistant')
        .toList()
        .reversed
        .firstOrNull;
    return lastAssistant?.content.isEmpty ?? false;
  }

  Future<void> sendMessage(String text, {String? chipValue}) async {
    final existing = state.value ?? [];
    final tempUserMsg = CoachMessage(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      content: text,
      createdAt: DateTime.now().toIso8601String(),
    );
    state = AsyncValue.data([...existing, tempUserMsg]);

    final api = ref.read(onboardingApiProvider);
    final result = await api.reply(conversationId, {
      'text': text,
      'chip_value': chipValue,
    });

    final raw = (result as Map<String, dynamic>)['messages'] as List;
    final newMessages =
        raw.map((m) => CoachMessage.fromJson(m as Map<String, dynamic>)).toList();

    final merged = <CoachMessage>[...(state.value ?? []), ...newMessages];
    state = AsyncValue.data(merged);

    // If the reply kicked off an async job (e.g. plan_generating loading_card),
    // start polling again.
    _schedulePollIfWaiting(conversationId, merged);
  }
}
