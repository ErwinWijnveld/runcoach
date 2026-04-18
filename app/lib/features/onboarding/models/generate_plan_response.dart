import 'package:freezed_annotation/freezed_annotation.dart';

part 'generate_plan_response.freezed.dart';
part 'generate_plan_response.g.dart';

@freezed
sealed class GeneratePlanResponse with _$GeneratePlanResponse {
  const factory GeneratePlanResponse({
    @JsonKey(name: 'conversation_id') required String conversationId,
    @JsonKey(name: 'proposal_id') required int proposalId,
    required int weeks,
  }) = _GeneratePlanResponse;

  factory GeneratePlanResponse.fromJson(Map<String, dynamic> json) =>
      _$GeneratePlanResponseFromJson(json);
}
