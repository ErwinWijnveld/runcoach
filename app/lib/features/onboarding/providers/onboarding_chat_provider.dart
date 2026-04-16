import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/features/coach/models/coach_message.dart';
import 'package:app/features/onboarding/data/onboarding_api.dart';

part 'onboarding_chat_provider.g.dart';

@riverpod
class OnboardingChat extends _$OnboardingChat {
  @override
  Future<List<CoachMessage>> build(String conversationId) async {
    final api = ref.watch(onboardingApiProvider);
    final result = await api.fetchConversation(conversationId);
    final raw = (result as Map<String, dynamic>)['messages'] as List;
    return raw.map((m) => CoachMessage.fromJson(m as Map<String, dynamic>)).toList();
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

    state = AsyncValue.data([...(state.value ?? []), ...newMessages]);
  }
}
