import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/features/coach/data/coach_api.dart';
import 'package:app/features/coach/models/conversation.dart';
import 'package:app/features/coach/models/coach_message.dart';

part 'coach_provider.g.dart';

@riverpod
Future<List<Conversation>> conversations(Ref ref) async {
  final api = ref.watch(coachApiProvider);
  final data = await api.getConversations();
  final list = data['data'] as List;
  return list.map((e) => Conversation.fromJson(e as Map<String, dynamic>)).toList();
}

@riverpod
class CoachChat extends _$CoachChat {
  @override
  Future<List<CoachMessage>> build(String conversationId) async {
    final api = ref.read(coachApiProvider);
    final data = await api.getConversation(conversationId);
    final convData = data['data'] as Map<String, dynamic>;
    final messagesList = convData['messages'] as List? ?? [];
    return messagesList.map((e) => CoachMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> sendMessage(String content) async {
    final api = ref.read(coachApiProvider);
    final current = state.value ?? [];

    // Add user message optimistically
    final userMsg = CoachMessage(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      content: content,
      createdAt: DateTime.now().toIso8601String(),
    );
    state = AsyncData([...current, userMsg]);

    try {
      final data = await api.sendMessage(conversationId, {'content': content});
      final responseData = data['data'] as Map<String, dynamic>;

      // Backend returns { message: { role, content }, proposal: ... }
      final msgData = responseData['message'] as Map<String, dynamic>?;
      if (msgData != null) {
        final assistantMsg = CoachMessage(
          id: 'resp-${DateTime.now().millisecondsSinceEpoch}',
          role: msgData['role'] as String? ?? 'assistant',
          content: msgData['content'] as String? ?? '',
          createdAt: DateTime.now().toIso8601String(),
        );
        state = AsyncData([...current, userMsg, assistantMsg]);
      }
    } catch (e) {
      // On error, keep the user message but show error state
      state = AsyncData([...current, userMsg]);
      rethrow;
    }
  }

  Future<void> acceptProposal(int proposalId) async {
    final api = ref.read(coachApiProvider);
    await api.acceptProposal(proposalId);
  }

  Future<void> rejectProposal(int proposalId) async {
    final api = ref.read(coachApiProvider);
    await api.rejectProposal(proposalId);
  }
}
