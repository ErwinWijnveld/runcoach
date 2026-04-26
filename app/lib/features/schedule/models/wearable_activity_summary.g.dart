// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wearable_activity_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WearableActivitySummary _$WearableActivitySummaryFromJson(
  Map<String, dynamic> json,
) => _WearableActivitySummary(
  id: (json['id'] as num).toInt(),
  source: json['source'] as String,
  sourceActivityId: json['source_activity_id'] as String,
  type: json['type'] as String,
  name: json['name'] as String?,
  distanceMeters: toInt(json['distance_meters']),
  durationSeconds: toInt(json['duration_seconds']),
  elapsedSeconds: toIntOrNull(json['elapsed_seconds']),
  averagePaceSecondsPerKm: toInt(json['average_pace_seconds_per_km']),
  averageHeartrate: toDoubleOrNull(json['average_heartrate']),
  maxHeartrate: toDoubleOrNull(json['max_heartrate']),
  elevationGainMeters: toIntOrNull(json['elevation_gain_meters']),
  caloriesKcal: toIntOrNull(json['calories_kcal']),
  startDate: json['start_date'] as String,
  endDate: json['end_date'] as String?,
);

Map<String, dynamic> _$WearableActivitySummaryToJson(
  _WearableActivitySummary instance,
) => <String, dynamic>{
  'id': instance.id,
  'source': instance.source,
  'source_activity_id': instance.sourceActivityId,
  'type': instance.type,
  'name': instance.name,
  'distance_meters': instance.distanceMeters,
  'duration_seconds': instance.durationSeconds,
  'elapsed_seconds': instance.elapsedSeconds,
  'average_pace_seconds_per_km': instance.averagePaceSecondsPerKm,
  'average_heartrate': instance.averageHeartrate,
  'max_heartrate': instance.maxHeartrate,
  'elevation_gain_meters': instance.elevationGainMeters,
  'calories_kcal': instance.caloriesKcal,
  'start_date': instance.startDate,
  'end_date': instance.endDate,
};
