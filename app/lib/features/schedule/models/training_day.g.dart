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
  targetKm: toDoubleOrNull(json['target_km']),
  targetPaceSecondsPerKm: toIntOrNull(json['target_pace_seconds_per_km']),
  targetHeartRateZone: toIntOrNull(json['target_heart_rate_zone']),
  intervals: _intervalsFromJson(json['intervals_json']),
  order: toInt(json['order']),
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
      'intervals_json': instance.intervals,
      'order': instance.order,
      'result': instance.result,
    };
