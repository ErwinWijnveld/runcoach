// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'membership.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MembershipCoach _$MembershipCoachFromJson(Map<String, dynamic> json) =>
    _MembershipCoach(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      email: json['email'] as String,
    );

Map<String, dynamic> _$MembershipCoachToJson(_MembershipCoach instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
    };

_Membership _$MembershipFromJson(Map<String, dynamic> json) => _Membership(
  id: (json['id'] as num).toInt(),
  role: json['role'] as String,
  status: json['status'] as String,
  organization: json['organization'] == null
      ? null
      : Organization.fromJson(json['organization'] as Map<String, dynamic>),
  coach: json['coach'] == null
      ? null
      : MembershipCoach.fromJson(json['coach'] as Map<String, dynamic>),
  inviteEmail: json['invite_email'] as String?,
  invitedAt: json['invited_at'] as String?,
  requestedAt: json['requested_at'] as String?,
  joinedAt: json['joined_at'] as String?,
);

Map<String, dynamic> _$MembershipToJson(_Membership instance) =>
    <String, dynamic>{
      'id': instance.id,
      'role': instance.role,
      'status': instance.status,
      'organization': instance.organization,
      'coach': instance.coach,
      'invite_email': instance.inviteEmail,
      'invited_at': instance.invitedAt,
      'requested_at': instance.requestedAt,
      'joined_at': instance.joinedAt,
    };
