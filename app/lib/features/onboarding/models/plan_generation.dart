import 'package:freezed_annotation/freezed_annotation.dart';

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
    @JsonKey(name: 'error_message') String? errorMessage,
  }) = _PlanGeneration;

  factory PlanGeneration.fromJson(Map<String, dynamic> json) =>
      _$PlanGenerationFromJson(json);
}
