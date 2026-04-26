import 'package:freezed_annotation/freezed_annotation.dart';
import 'organization.dart';

part 'membership.freezed.dart';
part 'membership.g.dart';

@freezed
sealed class MembershipCoach with _$MembershipCoach {
  const factory MembershipCoach({
    required int id,
    required String name,
    required String email,
  }) = _MembershipCoach;

  factory MembershipCoach.fromJson(Map<String, dynamic> json) =>
      _$MembershipCoachFromJson(json);
}

@freezed
sealed class Membership with _$Membership {
  const factory Membership({
    required int id,
    required String role,
    required String status,
    Organization? organization,
    MembershipCoach? coach,
    @JsonKey(name: 'invite_email') String? inviteEmail,
    @JsonKey(name: 'invited_at') String? invitedAt,
    @JsonKey(name: 'requested_at') String? requestedAt,
    @JsonKey(name: 'joined_at') String? joinedAt,
  }) = _Membership;

  factory Membership.fromJson(Map<String, dynamic> json) =>
      _$MembershipFromJson(json);
}

extension MembershipX on Membership {
  bool get isActive => status == 'active';
  bool get isInvited => status == 'invited';
  bool get isRequested => status == 'requested';
  bool get isClient => role == 'client';
  bool get isCoach => role == 'coach';
  bool get isOrgAdmin => role == 'org_admin';
}
