// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_User _$UserFromJson(Map<String, dynamic> json) => _User(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  email: json['email'] as String,
  appleSub: json['apple_sub'] as String?,
  coachStyle: json['coach_style'] as String?,
  intensityBias: json['intensity_bias'] as String? ?? 'standard',
  runnerLevel: json['runner_level'] as String? ?? 'intermediate',
  hasCompletedOnboarding: json['has_completed_onboarding'] as bool? ?? false,
  heartRateZones: (json['heart_rate_zones'] as List<dynamic>?)
      ?.map((e) => HrZone.fromJson(e as Map<String, dynamic>))
      .toList(),
  heartRateZonesSource: json['heart_rate_zones_source'] as String?,
  dateOfBirth: dateFromJson(json['date_of_birth']),
  pendingPlanGeneration: json['pending_plan_generation'] == null
      ? null
      : PlanGeneration.fromJson(
          json['pending_plan_generation'] as Map<String, dynamic>,
        ),
  currentMembership: json['current_membership'] == null
      ? null
      : Membership.fromJson(json['current_membership'] as Map<String, dynamic>),
  pendingInvites:
      (json['pending_invites'] as List<dynamic>?)
          ?.map((e) => Membership.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  pendingRequests:
      (json['pending_requests'] as List<dynamic>?)
          ?.map((e) => Membership.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$UserToJson(_User instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'apple_sub': instance.appleSub,
  'coach_style': instance.coachStyle,
  'intensity_bias': instance.intensityBias,
  'runner_level': instance.runnerLevel,
  'has_completed_onboarding': instance.hasCompletedOnboarding,
  'heart_rate_zones': instance.heartRateZones,
  'heart_rate_zones_source': instance.heartRateZonesSource,
  'date_of_birth': dateToJson(instance.dateOfBirth),
  'pending_plan_generation': instance.pendingPlanGeneration,
  'current_membership': instance.currentMembership,
  'pending_invites': instance.pendingInvites,
  'pending_requests': instance.pendingRequests,
};
