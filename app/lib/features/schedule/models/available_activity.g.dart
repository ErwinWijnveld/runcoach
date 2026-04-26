// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'available_activity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AvailableActivity _$AvailableActivityFromJson(Map<String, dynamic> json) =>
    _AvailableActivity(
      wearableActivityId: (json['wearable_activity_id'] as num).toInt(),
      source: json['source'] as String,
      name: json['name'] as String,
      startDate: json['start_date'] as String?,
      distanceKm: toDouble(json['distance_km']),
      durationSeconds: toInt(json['duration_seconds']),
      averagePaceSecondsPerKm: toIntOrNull(json['average_pace_seconds_per_km']),
      averageHeartRate: toDoubleOrNull(json['average_heart_rate']),
      matchedTrainingDayId: (json['matched_training_day_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AvailableActivityToJson(_AvailableActivity instance) =>
    <String, dynamic>{
      'wearable_activity_id': instance.wearableActivityId,
      'source': instance.source,
      'name': instance.name,
      'start_date': instance.startDate,
      'distance_km': instance.distanceKm,
      'duration_seconds': instance.durationSeconds,
      'average_pace_seconds_per_km': instance.averagePaceSecondsPerKm,
      'average_heart_rate': instance.averageHeartRate,
      'matched_training_day_id': instance.matchedTrainingDayId,
    };
