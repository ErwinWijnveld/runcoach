import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/features/coach/data/coach_stream_client.dart';
import 'package:app/features/coach/models/coach_message.dart';
import 'package:app/features/coach/models/vercel_stream_event.dart';
import 'package:app/features/schedule/data/schedule_api.dart';
import 'package:app/features/schedule/providers/plan_version_provider.dart';

part 'workout_chat_provider.g.dart';

/// Per-training-day chat. Mirrors `CoachChat` (same SSE shape) but is
/// keyed by `trainingDayId` and hits the `/workout-chat/{day}` endpoints.
/// The conversation is created lazily on the first sendMessage server-side,
/// so `build()` returns an empty list when no chat exists yet.
@riverpod
class WorkoutChat extends _$WorkoutChat {
  bool _isStreaming = false;

  @override
  Future<List<CoachMessage>> build(int trainingDayId) async {
    final api = ref.read(scheduleApiProvider);
    final data = await api.getWorkoutChat(trainingDayId);
    final convData = data['data'];
    if (convData == null) return [];
    final messagesList =
        (convData as Map<String, dynamic>)['messages'] as List? ?? [];
    return messagesList
        .map((e) => CoachMessage.fromShowJson(e as Map<String, dynamic>))
        .toList();
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
        await for (final event in stream.streamPath(
          '/workout-chat/$trainingDayId/messages',
          content,
          chipValue: chipValue,
        )) {
          current = switch (event) {
            TextDeltaEvent(:final delta) => current.copyWith(
              content: current.content + delta,
              toolIndicator: null,
            ),
            TextEndEvent() => current.toolIndicator == null
                ? current.copyWith(toolIndicator: 'Thinking')
                : current,
            ToolStartEvent(:final toolName) =>
              current.copyWith(toolIndicator: toolName),
            ToolEndEvent() => current,
            ProposalEvent(:final proposal) =>
              current.copyWith(proposal: proposal),
            StatsEvent(:final stats) =>
              current.copyWith(statsCard: stats),
            ChipsEvent(:final chips) => current.copyWith(chips: chips),
            HandoffEvent(:final suggestedPrompt) =>
              current.copyWith(handoffPrompt: suggestedPrompt),
            PlanChangedEvent() => () {
              // Server-side direct mutation (e.g. RescheduleWorkout). Bust
              // the plan cache so the schedule overview reflects the change
              // when the user closes the sheet.
              ref.read(planVersionProvider.notifier).bump();
              return current;
            }(),
            ErrorEvent(:final message) => current.copyWith(
              errorDetail: message,
              streaming: false,
              toolIndicator: null,
            ),
            DoneEvent() =>
              current.copyWith(streaming: false, toolIndicator: null),
          };
          state = AsyncData([...before, userMsg, current]);
        }
        if (current.streaming) {
          state = AsyncData([
            ...before,
            userMsg,
            current.copyWith(
              streaming: false,
              toolIndicator: null,
              errorDetail: 'Connection interrupted. Tap retry.',
            ),
          ]);
        }
      } catch (e) {
        state = AsyncData([
          ...before,
          userMsg,
          current.copyWith(
            streaming: false,
            toolIndicator: null,
            errorDetail: _humanize(e),
          ),
        ]);
      }
    } finally {
      _isStreaming = false;
    }
  }

  Future<void> retry(String messageId) async {
    final messages = state.value ?? [];
    final failed = messages
        .where((m) => m.id == messageId && m.errorDetail != null)
        .firstOrNull;
    if (failed == null) return;
    state = AsyncData(messages.where((m) => m.id != messageId).toList());
    await sendMessage(failed.content);
  }

  String _humanize(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      return switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout =>
          'Request timed out',
        DioExceptionType.connectionError => 'Cannot reach server',
        _ => 'Server error (${error.response?.statusCode ?? 'network'})',
      };
    }
    return error.toString();
  }
}

