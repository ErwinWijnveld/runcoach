// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TrainingResult _$TrainingResultFromJson(Map<String, dynamic> json) =>
    _TrainingResult(
      id: (json['id'] as num).toInt(),
      complianceScore: toDouble(json['compliance_score']),
      actualKm: toDouble(json['actual_km']),
      actualPaceSecondsPerKm: toInt(json['actual_pace_seconds_per_km']),
      actualAvgHeartRate: toDoubleOrNull(json['actual_avg_heart_rate']),
      paceScore: toDouble(json['pace_score']),
      distanceScore: toDouble(json['distance_score']),
      heartRateScore: toDoubleOrNull(json['heart_rate_score']),
      aiFeedback: json['ai_feedback'] as String?,
      wearableActivity: json['wearable_activity'] == null
          ? null
          : WearableActivitySummary.fromJson(
              json['wearable_activity'] as Map<String, dynamic>,
            ),
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
      'wearable_activity': instance.wearableActivity,
    };
