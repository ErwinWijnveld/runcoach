// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analyzing_run.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AnalyzingRun _$AnalyzingRunFromJson(Map<String, dynamic> json) =>
    _AnalyzingRun(
      wearableActivityId: (json['wearableActivityId'] as num).toInt(),
      status: $enumDecode(_$AnalyzingRunStatusEnumMap, json['status']),
      startedAt: DateTime.parse(json['startedAt'] as String),
      trainingDayId: (json['trainingDayId'] as num?)?.toInt(),
      trainingResultId: (json['trainingResultId'] as num?)?.toInt(),
      complianceScore: (json['complianceScore'] as num?)?.toDouble(),
      actualKm: (json['actualKm'] as num?)?.toDouble(),
      aiFeedback: json['aiFeedback'] as String?,
    );

Map<String, dynamic> _$AnalyzingRunToJson(_AnalyzingRun instance) =>
    <String, dynamic>{
      'wearableActivityId': instance.wearableActivityId,
      'status': _$AnalyzingRunStatusEnumMap[instance.status]!,
      'startedAt': instance.startedAt.toIso8601String(),
      'trainingDayId': instance.trainingDayId,
      'trainingResultId': instance.trainingResultId,
      'complianceScore': instance.complianceScore,
      'actualKm': instance.actualKm,
      'aiFeedback': instance.aiFeedback,
    };

const _$AnalyzingRunStatusEnumMap = {
  AnalyzingRunStatus.pending: 'pending',
  AnalyzingRunStatus.matched: 'matched',
  AnalyzingRunStatus.analyzed: 'analyzed',
  AnalyzingRunStatus.unmatched: 'unmatched',
};
