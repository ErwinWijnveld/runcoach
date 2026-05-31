import 'package:freezed_annotation/freezed_annotation.dart';

part 'plan_evaluation.freezed.dart';
part 'plan_evaluation.g.dart';

@freezed
sealed class PlanEvaluation with _$PlanEvaluation {
  const factory PlanEvaluation({
    required int id,
    @JsonKey(name: 'user_id') required int userId,
    @JsonKey(name: 'goal_id') required int goalId,
    @JsonKey(name: 'training_week_id') int? trainingWeekId,
    @JsonKey(name: 'scheduled_for') required String scheduledFor,
    /// One of: pending, processing, ready, no_change_needed, accepted, dismissed.
    required String status,
    @JsonKey(name: 'report_markdown') String? reportMarkdown,
    @JsonKey(name: 'proposal_id') int? proposalId,
    @JsonKey(name: 'notification_id') int? notificationId,
    @JsonKey(name: 'triggered_at') String? triggeredAt,
    @JsonKey(name: 'completed_at') String? completedAt,
    /// Eager-loaded by the detail endpoint — carries the `EditActivePlan`
    /// CoachProposal (with `payload`) when `proposalId` is non-null.
    Map<String, dynamic>? proposal,
  }) = _PlanEvaluation;

  factory PlanEvaluation.fromJson(Map<String, dynamic> json) =>
      _$PlanEvaluationFromJson(json);
}
