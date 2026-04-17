import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/features/auth/providers/auth_provider.dart';
import 'package:app/features/coach/data/coach_api.dart';
import 'package:app/features/coach/data/coach_stream_client.dart';
import 'package:app/features/coach/models/coach_message.dart';
import 'package:app/features/coach/models/conversation.dart';
import 'package:app/features/coach/models/vercel_stream_event.dart';

part 'coach_provider.g.dart';

@riverpod
Future<List<Conversation>> conversations(Ref ref) async {
  final api = ref.watch(coachApiProvider);
  final data = await api.getConversations();
  final list = data['data'] as List;
  return list.map((e) => Conversation.fromJson(e as Map<String, dynamic>)).toList();
}

/// Standalone accept/reject helpers so onboarding can use them without
/// activating [CoachChat] (which would load messages from the wrong endpoint).
@riverpod
class ProposalActions extends _$ProposalActions {
  @override
  void build() {}

  Future<void> accept(int proposalId) async {
    final api = ref.read(coachApiProvider);
    await api.acceptProposal(proposalId);
    await ref.read(authProvider.notifier).loadProfile();
  }

  Future<void> reject(int proposalId) async {
    final api = ref.read(coachApiProvider);
    await api.rejectProposal(proposalId);
  }
}

@riverpod
class CoachChat extends _$CoachChat {
  bool _isStreaming = false;

  @override
  Future<List<CoachMessage>> build(String conversationId) async {
    final api = ref.read(coachApiProvider);
    final data = await api.getConversation(conversationId);
    final convData = data['data'] as Map<String, dynamic>;
    final messagesList = convData['messages'] as List? ?? [];
    return messagesList.map((e) => CoachMessage.fromShowJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> sendMessage(String content, {String? chipValue}) async {
    if (_isStreaming) return;
    _isStreaming = true;

    try {
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
        await for (final event
            in stream.streamMessage(conversationId, content, chipValue: chipValue)) {
          current = switch (event) {
            TextDeltaEvent(:final delta) => current.copyWith(
                content: current.content + delta,
                toolIndicator: null,
              ),
            ToolStartEvent(:final toolName) =>
              current.copyWith(toolIndicator: toolName),
            ToolEndEvent() => current,
            ProposalEvent(:final proposal) =>
              current.copyWith(proposal: proposal),
            StatsEvent(:final stats) =>
              current.copyWith(statsCard: stats),
            ChipsEvent(:final chips) => current.copyWith(chips: chips),
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
    } finally {
      _isStreaming = false;
    }
  }

  Future<void> retry(String messageId) async {
    final messages = state.value ?? [];
    final failed = messages.where((m) => m.id == messageId && m.errorDetail != null).firstOrNull;
    if (failed == null) return;
    state = AsyncData(messages.where((m) => m.id != messageId).toList());
    await sendMessage(failed.content);
  }

  String _humanize(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) return data['message'] as String;
      return switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout => 'Request timed out',
        DioExceptionType.connectionError => 'Cannot reach server',
        _ => 'Server error (${error.response?.statusCode ?? 'network'})',
      };
    }
    return error.toString();
  }

  Future<void> acceptProposal(int proposalId) async {
    final api = ref.read(coachApiProvider);
    await api.acceptProposal(proposalId);
    await ref.read(authProvider.notifier).loadProfile();
  }

  Future<void> rejectProposal(int proposalId) async {
    final api = ref.read(coachApiProvider);
    await api.rejectProposal(proposalId);
  }
}
