// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TrainingResult _$TrainingResultFromJson(Map<String, dynamic> json) =>
    _TrainingResult(
      id: (json['id'] as num).toInt(),
      complianceScore: (json['compliance_score'] as num).toDouble(),
      actualKm: (json['actual_km'] as num).toDouble(),
      actualPaceSecondsPerKm: (json['actual_pace_seconds_per_km'] as num)
          .toInt(),
      actualAvgHeartRate: (json['actual_avg_heart_rate'] as num?)?.toDouble(),
      paceScore: (json['pace_score'] as num).toDouble(),
      distanceScore: (json['distance_score'] as num).toDouble(),
      heartRateScore: (json['heart_rate_score'] as num?)?.toDouble(),
      aiFeedback: json['ai_feedback'] as String?,
    );

Map<String, dynamic> _$TrainingResultToJson(_TrainingResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'compliance_score': instance.complianceScore,
      'actual_km': instance.actualKm,
      'actual_pace_seconds_per_km': instance.actualPaceSecondsPerKm,
      'actual_avg_heart_rate': instance.actualAvgHeartRate,
      'pace_score': instance.paceScore,
      'distance_score': instance.distanceScore,
      'heart_rate_score': instance.heartRateScore,
      'ai_feedback': instance.aiFeedback,
    };
