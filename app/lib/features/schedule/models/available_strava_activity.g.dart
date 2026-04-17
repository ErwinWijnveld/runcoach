// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'available_strava_activity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AvailableStravaActivity _$AvailableStravaActivityFromJson(
  Map<String, dynamic> json,
) => _AvailableStravaActivity(
  stravaActivityId: (json['strava_activity_id'] as num).toInt(),
  name: json['name'] as String,
  startDate: json['start_date'] as String?,
  distanceKm: toDouble(json['distance_km']),
  movingTimeSeconds: toInt(json['moving_time_seconds']),
  averagePaceSecondsPerKm: toIntOrNull(json['average_pace_seconds_per_km']),
  averageHeartRate: toDoubleOrNull(json['average_heart_rate']),
  matchedTrainingDayId: (json['matched_training_day_id'] as num?)?.toInt(),
);

Map<String, dynamic> _$AvailableStravaActivityToJson(
  _AvailableStravaActivity instance,
) => <String, dynamic>{
  'strava_activity_id': instance.stravaActivityId,
  'name': instance.name,
  'start_date': instance.startDate,
  'distance_km': instance.distanceKm,
  'moving_time_seconds': instance.movingTimeSeconds,
  'average_pace_seconds_per_km': instance.averagePaceSecondsPerKm,
  'average_heart_rate': instance.averageHeartRate,
  'matched_training_day_id': instance.matchedTrainingDayId,
};
