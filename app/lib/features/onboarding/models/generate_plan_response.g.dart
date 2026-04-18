// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generate_plan_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GeneratePlanResponse _$GeneratePlanResponseFromJson(
  Map<String, dynamic> json,
) => _GeneratePlanResponse(
  conversationId: json['conversation_id'] as String,
  proposalId: (json['proposal_id'] as num).toInt(),
  weeks: (json['weeks'] as num).toInt(),
);

Map<String, dynamic> _$GeneratePlanResponseToJson(
  _GeneratePlanResponse instance,
) => <String, dynamic>{
  'conversation_id': instance.conversationId,
  'proposal_id': instance.proposalId,
  'weeks': instance.weeks,
};
