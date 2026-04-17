// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_interval.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TrainingInterval _$TrainingIntervalFromJson(Map<String, dynamic> json) =>
    _TrainingInterval(
      kind: json['kind'] as String,
      label: json['label'] as String,
      distanceM: toIntOrNull(json['distance_m']),
      durationSeconds: toIntOrNull(json['duration_seconds']),
      targetPaceSecondsPerKm: toIntOrNull(json['target_pace_seconds_per_km']),
    );

Map<String, dynamic> _$TrainingIntervalToJson(_TrainingInterval instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'label': instance.label,
      'distance_m': instance.distanceM,
      'duration_seconds': instance.durationSeconds,
      'target_pace_seconds_per_km': instance.targetPaceSecondsPerKm,
    };
