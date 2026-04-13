// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_day.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TrainingDay _$TrainingDayFromJson(Map<String, dynamic> json) => _TrainingDay(
  id: (json['id'] as num).toInt(),
  date: json['date'] as String,
  type: json['type'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  targetKm: (json['target_km'] as num?)?.toDouble(),
  targetPaceSecondsPerKm: (json['target_pace_seconds_per_km'] as num?)?.toInt(),
  targetHeartRateZone: (json['target_heart_rate_zone'] as num?)?.toInt(),
  intervalsJson: json['intervals_json'] as Map<String, dynamic>?,
  order: (json['order'] as num).toInt(),
  result: json['result'] == null
      ? null
      : TrainingResult.fromJson(json['result'] as Map<String, dynamic>),
);

Map<String, dynamic> _$TrainingDayToJson(_TrainingDay instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date,
      'type': instance.type,
      'title': instance.title,
      'description': instance.description,
      'target_km': instance.targetKm,
      'target_pace_seconds_per_km': instance.targetPaceSecondsPerKm,
      'target_heart_rate_zone': instance.targetHeartRateZone,
      'intervals_json': instance.intervalsJson,
      'order': instance.order,
      'result': instance.result,
    };
