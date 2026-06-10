// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recent_run.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RecentRun _$RecentRunFromJson(Map<String, dynamic> json) => _RecentRun(
  run: WearableActivitySummary.fromJson(json['run'] as Map<String, dynamic>),
  trainingDayId: toIntOrNull(json['training_day_id']),
  complianceScore: toDoubleOrNull(json['compliance_score']),
);

Map<String, dynamic> _$RecentRunToJson(_RecentRun instance) =>
    <String, dynamic>{
      'run': instance.run,
      'training_day_id': instance.trainingDayId,
      'compliance_score': instance.complianceScore,
    };
