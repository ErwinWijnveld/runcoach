import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/features/auth/models/hr_zone.dart';
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
    @JsonKey(name: 'heart_rate_zones') List<HrZone>? heartRateZones,
    // 'default' | 'derived_empirical' | 'derived_age' | 'manual' — drives
    // the subtitle copy on the onboarding zones step + the "Recompute"
    // button's confirm-overwrite affordance in the menu sheet.
    @JsonKey(name: 'heart_rate_zones_source') String? heartRateZonesSource,
    // Manually-entered birth year (persisted by HeartRateZonesController
    // whenever an age is sent in the derive body). When set, the HR
    // sheet's recompute button skips the manual age dialog — the
    // backend resolves age from this on its own.
    @JsonKey(name: 'birth_year') int? birthYear,
    @JsonKey(name: 'pending_plan_generation') PlanGeneration? pendingPlanGeneration,
    @JsonKey(name: 'current_membership') Membership? currentMembership,
    @JsonKey(name: 'pending_invites') @Default([]) List<Membership> pendingInvites,
    @JsonKey(name: 'pending_requests') @Default([]) List<Membership> pendingRequests,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
