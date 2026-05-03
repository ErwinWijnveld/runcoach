import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/features/coach/models/coach_chip.dart';
import 'package:app/features/coach/models/coach_proposal.dart';
import 'package:app/features/coach/models/coach_stats_card.dart';

part 'vercel_stream_event.freezed.dart';

@freezed
sealed class VercelStreamEvent with _$VercelStreamEvent {
  const factory VercelStreamEvent.textDelta(String delta) = TextDeltaEvent;
  const factory VercelStreamEvent.textEnd() = TextEndEvent;
  const factory VercelStreamEvent.toolStart(String toolName) = ToolStartEvent;

  // TextEnd is emitted by the SDK but we don't act on it — kept in the union
  // for parser coverage.
  const factory VercelStreamEvent.toolEnd() = ToolEndEvent;
  const factory VercelStreamEvent.proposal(CoachProposal proposal) =
      ProposalEvent;
  const factory VercelStreamEvent.stats(CoachStatsCard stats) = StatsEvent;
  const factory VercelStreamEvent.chips(List<CoachChip> chips) = ChipsEvent;
  const factory VercelStreamEvent.handoff(String suggestedPrompt) =
      HandoffEvent;
  // Server-side direct mutation (e.g. RescheduleWorkout). Tells the client
  // to bust its plan cache so the schedule overview reflects the change
  // when the user navigates back.
  const factory VercelStreamEvent.planChanged() = PlanChangedEvent;
  const factory VercelStreamEvent.error(String message) = ErrorEvent;
  const factory VercelStreamEvent.done() = DoneEvent;
}
