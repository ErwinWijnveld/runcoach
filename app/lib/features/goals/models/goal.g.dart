// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Goal _$GoalFromJson(Map<String, dynamic> json) => _Goal(
  id: (json['id'] as num).toInt(),
  type: json['type'] as String,
  name: json['name'] as String,
  distance: json['distance'] as String?,
  customDistanceMeters: (json['custom_distance_meters'] as num?)?.toInt(),
  goalTimeSeconds: (json['goal_time_seconds'] as num?)?.toInt(),
  targetDate: json['target_date'] as String?,
  status: json['status'] as String,
);

Map<String, dynamic> _$GoalToJson(_Goal instance) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'name': instance.name,
  'distance': instance.distance,
  'custom_distance_meters': instance.customDistanceMeters,
  'goal_time_seconds': instance.goalTimeSeconds,
  'target_date': instance.targetDate,
  'status': instance.status,
};
