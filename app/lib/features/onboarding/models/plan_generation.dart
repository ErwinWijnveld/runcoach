import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/features/coach/models/coach_proposal.dart';

part 'plan_generation.freezed.dart';
part 'plan_generation.g.dart';

enum PlanGenerationStatus {
  @JsonValue('queued') queued,
  @JsonValue('processing') processing,
  @JsonValue('completed') completed,
  @JsonValue('failed') failed,
}

@freezed
sealed class PlanGeneration with _$PlanGeneration {
  const factory PlanGeneration({
    required int id,
    required PlanGenerationStatus status,
    @JsonKey(name: 'conversation_id') String? conversationId,
    @JsonKey(name: 'proposal_id') int? proposalId,
    /// Full proposal (payload included) so the plan-preview / paywall screen
    /// can render the rich plan teaser without hitting the require.pro-gated
    /// coach endpoints. Null until generation produces a proposal.
    CoachProposal? proposal,
    @JsonKey(name: 'error_message') String? errorMessage,
  }) = _PlanGeneration;

  factory PlanGeneration.fromJson(Map<String, dynamic> json) =>
      _$PlanGenerationFromJson(json);
}
