// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'strava_activity_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StravaActivitySummary _$StravaActivitySummaryFromJson(
  Map<String, dynamic> json,
) => _StravaActivitySummary(
  id: (json['id'] as num).toInt(),
  stravaId: toInt(json['strava_id']),
  type: json['type'] as String,
  name: json['name'] as String,
  distanceMeters: toInt(json['distance_meters']),
  movingTimeSeconds: toInt(json['moving_time_seconds']),
  elapsedTimeSeconds: toInt(json['elapsed_time_seconds']),
  averageHeartrate: toDoubleOrNull(json['average_heartrate']),
  averageSpeed: toDoubleOrNull(json['average_speed']),
  startDate: json['start_date'] as String,
  summaryPolyline: json['summary_polyline'] as String?,
);

Map<String, dynamic> _$StravaActivitySummaryToJson(
  _StravaActivitySummary instance,
) => <String, dynamic>{
  'id': instance.id,
  'strava_id': instance.stravaId,
  'type': instance.type,
  'name': instance.name,
  'distance_meters': instance.distanceMeters,
  'moving_time_seconds': instance.movingTimeSeconds,
  'elapsed_time_seconds': instance.elapsedTimeSeconds,
  'average_heartrate': instance.averageHeartrate,
  'average_speed': instance.averageSpeed,
  'start_date': instance.startDate,
  'summary_polyline': instance.summaryPolyline,
};
