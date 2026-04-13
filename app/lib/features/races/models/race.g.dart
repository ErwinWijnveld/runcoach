// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'race.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Race _$RaceFromJson(Map<String, dynamic> json) => _Race(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  distance: json['distance'] as String,
  customDistanceMeters: (json['custom_distance_meters'] as num?)?.toInt(),
  goalTimeSeconds: (json['goal_time_seconds'] as num?)?.toInt(),
  raceDate: json['race_date'] as String,
  status: json['status'] as String,
);

Map<String, dynamic> _$RaceToJson(_Race instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'distance': instance.distance,
  'custom_distance_meters': instance.customDistanceMeters,
  'goal_time_seconds': instance.goalTimeSeconds,
  'race_date': instance.raceDate,
  'status': instance.status,
};
