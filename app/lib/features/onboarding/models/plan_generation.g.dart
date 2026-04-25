// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_generation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlanGeneration _$PlanGenerationFromJson(Map<String, dynamic> json) =>
    _PlanGeneration(
      id: (json['id'] as num).toInt(),
      status: $enumDecode(_$PlanGenerationStatusEnumMap, json['status']),
      conversationId: json['conversation_id'] as String?,
      proposalId: (json['proposal_id'] as num?)?.toInt(),
      errorMessage: json['error_message'] as String?,
    );

Map<String, dynamic> _$PlanGenerationToJson(_PlanGeneration instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': _$PlanGenerationStatusEnumMap[instance.status]!,
      'conversation_id': instance.conversationId,
      'proposal_id': instance.proposalId,
      'error_message': instance.errorMessage,
    };

const _$PlanGenerationStatusEnumMap = {
  PlanGenerationStatus.queued: 'queued',
  PlanGenerationStatus.processing: 'processing',
  PlanGenerationStatus.completed: 'completed',
  PlanGenerationStatus.failed: 'failed',
};
