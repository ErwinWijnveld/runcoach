import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/features/coach/data/coach_api.dart';
import 'package:app/features/coach/data/coach_stream_client.dart';
import 'package:app/features/coach/models/coach_message.dart';
import 'package:app/features/coach/models/vercel_stream_event.dart';
import 'package:app/features/coach/providers/coach_provider.dart';
import 'package:app/features/coach/utils/coach_error_codes.dart';
import 'package:app/features/schedule/data/schedule_api.dart';
import 'package:app/features/schedule/providers/plan_version_provider.dart';

part 'schedule_week_chat_provider.g.dart';

/// Per-training-week chat using the regular RunCoachAgent. Keyed by
/// (weekId, weekTitle) so the sheet can pre-set the title (e.g. "Week 3
/// (12-18 May)") that will be stored on the conversation row when it
/// gets lazy-created on the first send.
///
/// Unlike [WorkoutChat], this provider talks to the normal coach
/// endpoints (`/coach/conversations/*`) so the conversation surfaces in
/// the regular chat list and is re-openable from `/coach/chat/{id}`.
@riverpod
class ScheduleWeekChat extends _$ScheduleWeekChat {
  bool _isStreaming = false;
  String? _conversationId;
  bool _resolvingConversation = false;

  @override
  Future<List<CoachMessage>> build(int weekId, String weekTitle) async {
    final scheduleApi = ref.read(scheduleApiProvider);
    final lookup = await scheduleApi.getWeekChat(weekId);
    final data = lookup['data'];
    if (data == null) {
      _conversationId = null;
      return [];
    }
    final cid = (data as Map<String, dynamic>)['id'] as String;
    _conversationId = cid;

    // We have a conversation — fetch its messages via the normal coach
    // endpoint so the shape (incl. proposals + tool_results) matches
    // what CoachChatView expects.
    final coachApi = ref.read(coachApiProvider);
    final convo = await coachApi.getConversation(cid);
    final convoData = convo['data'] as Map<String, dynamic>;
    final messages = (convoData['messages'] as List? ?? const [])
        .map((e) => CoachMessage.fromShowJson(e as Map<String, dynamic>))
        .toList();
    return messages;
  }

  /// Public accessor so the sheet can route to `/coach/chat/{id}` if the
  /// runner wants to switch out of the modal into the full chat view.
  String? get conversationId => _conversationId;

  Future<String> _ensureConversation() async {
    final existing = _conversationId;
    if (existing != null) return existing;

    if (_resolvingConversation) {
      // Race-safety: two send taps before the first creation completes
      // would otherwise create two conversations.
      while (_resolvingConversation) {
        await Future<void>.delayed(const Duration(milliseconds: 30));
      }
      return _conversationId!;
    }

    _resolvingConversation = true;
    try {
      final api = ref.read(coachApiProvider);
      final response = await api.createConversation({
        'title': weekTitle,
        'subject_type': 'training_week',
        'subject_id': weekId,
      });
      final id = (response['data'] as Map<String, dynamic>)['id'] as String;
      _conversationId = id;
      // New conversation will show up in the chats list — refresh it so
      // the runner sees it immediately when they leave the sheet.
      ref.invalidate(conversationsProvider);
      return id;
    } finally {
      _resolvingConversation = false;
    }
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

      String cid;
      try {
        cid = await _ensureConversation();
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
        return;
      }

      var supersededBefore = before;
      try {
        await for (final event
            in stream.streamMessage(cid, content, chipValue: chipValue)) {
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
            ProposalEvent(:final proposal) => () {
                supersededBefore = _markPriorProposalsRejected(
                  supersededBefore,
                  proposal.id,
                );
                return current.copyWith(proposal: proposal);
              }(),
            StatsEvent(:final stats) =>
              current.copyWith(statsCard: stats),
            ChipsEvent(:final chips) => current.copyWith(chips: chips),
            HandoffEvent(:final suggestedPrompt) =>
              current.copyWith(handoffPrompt: suggestedPrompt),
            PlanChangedEvent() => () {
                ref.read(planVersionProvider.notifier).bump();
                return current;
              }(),
            NewPlanCardEvent(:final entryPoint) =>
              current.copyWith(newPlanEntryPoint: entryPoint),
            ErrorEvent(:final message) => current.copyWith(
                errorDetail: message,
                streaming: false,
                toolIndicator: null,
              ),
            DoneEvent() =>
              current.copyWith(streaming: false, toolIndicator: null),
          };
          state = AsyncData([...supersededBefore, userMsg, current]);
        }
        if (current.streaming) {
          state = AsyncData([
            ...supersededBefore,
            userMsg,
            current.copyWith(
              streaming: false,
              toolIndicator: null,
              errorDetail: CoachErrorCodes.connectionInterrupted,
            ),
          ]);
        }
      } catch (e) {
        state = AsyncData([
          ...supersededBefore,
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

  List<CoachMessage> _markPriorProposalsRejected(
    List<CoachMessage> messages,
    int newProposalId,
  ) {
    var changed = false;
    final next = <CoachMessage>[];
    for (final m in messages) {
      final p = m.proposal;
      if (p != null && p.id != newProposalId && p.status == 'pending') {
        changed = true;
        next.add(m.copyWith(proposal: p.copyWith(status: 'rejected')));
      } else {
        next.add(m);
      }
    }
    return changed ? next : messages;
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
          CoachErrorCodes.requestTimedOut,
        DioExceptionType.connectionError => CoachErrorCodes.cannotReachServer,
        _ => CoachErrorCodes.serverStatus(error.response?.statusCode),
      };
    }
    return error.toString();
  }
}
