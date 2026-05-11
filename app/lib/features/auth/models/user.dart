import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/core/utils/json_converters.dart';
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
    @JsonKey(name: 'intensity_bias') @Default('standard') String intensityBias,
    @JsonKey(name: 'has_completed_onboarding') @Default(false) bool hasCompletedOnboarding,
    @JsonKey(name: 'heart_rate_zones') List<HrZone>? heartRateZones,
    // 'default' | 'derived_empirical' | 'derived_age' | 'manual' — drives
    // the subtitle copy on the onboarding zones step + the "Recompute"
    // button's confirm-overwrite affordance in the menu sheet.
    @JsonKey(name: 'heart_rate_zones_source') String? heartRateZonesSource,
    // Manually-picked DOB (persisted by HeartRateZonesController
    // whenever a date_of_birth is sent in the derive body). Drives:
    //   - prefill of the DOB sheet on Recompute,
    //   - backend's age computation when no DOB in the request body,
    //   - the yearly birthday push (`SendBirthdayZoneReminders`).
    // Use the calendar-date converters so we don't drift by ±1 day in
    // negative-UTC zones (Eloquent's `date` cast emits `…T00:00:00Z`,
    // which DateTime.parse would interpret as UTC midnight and lower
    // by tz offset).
    @JsonKey(
      name: 'date_of_birth',
      fromJson: dateFromJson,
      toJson: dateToJson,
    )
    DateTime? dateOfBirth,
    @JsonKey(name: 'pending_plan_generation') PlanGeneration? pendingPlanGeneration,
    @JsonKey(name: 'current_membership') Membership? currentMembership,
    @JsonKey(name: 'pending_invites') @Default([]) List<Membership> pendingInvites,
    @JsonKey(name: 'pending_requests') @Default([]) List<Membership> pendingRequests,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
