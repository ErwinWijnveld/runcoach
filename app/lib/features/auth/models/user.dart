import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/features/onboarding/models/plan_generation.dart';
import 'package:app/features/organization/models/membership.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
sealed class User with _$User {
  const factory User({
    required int id,
    required String name,
    required String email,
    @JsonKey(name: 'apple_sub') String? appleSub,
    @JsonKey(name: 'coach_style') String? coachStyle,
    @JsonKey(name: 'has_completed_onboarding') @Default(false) bool hasCompletedOnboarding,
    @JsonKey(name: 'pending_plan_generation') PlanGeneration? pendingPlanGeneration,
    @JsonKey(name: 'current_membership') Membership? currentMembership,
    @JsonKey(name: 'pending_invites') @Default([]) List<Membership> pendingInvites,
    @JsonKey(name: 'pending_requests') @Default([]) List<Membership> pendingRequests,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
