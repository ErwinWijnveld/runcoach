// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_User _$UserFromJson(Map<String, dynamic> json) => _User(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  email: json['email'] as String,
  stravaAthleteId: (json['strava_athlete_id'] as num?)?.toInt(),
  level: json['level'] as String?,
  coachStyle: json['coach_style'] as String?,
  weeklyKmCapacity: (json['weekly_km_capacity'] as num?)?.toDouble(),
);

Map<String, dynamic> _$UserToJson(_User instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'strava_athlete_id': instance.stravaAthleteId,
  'level': instance.level,
  'coach_style': instance.coachStyle,
  'weekly_km_capacity': instance.weeklyKmCapacity,
};
