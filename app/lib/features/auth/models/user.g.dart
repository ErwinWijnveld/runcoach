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
  coachStyle: json['coach_style'] as String?,
  hasCompletedOnboarding: json['has_completed_onboarding'] as bool? ?? false,
);

Map<String, dynamic> _$UserToJson(_User instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'strava_athlete_id': instance.stravaAthleteId,
  'coach_style': instance.coachStyle,
  'has_completed_onboarding': instance.hasCompletedOnboarding,
};
