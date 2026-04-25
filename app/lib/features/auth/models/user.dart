import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/features/onboarding/models/plan_generation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
sealed class User with _$User {
  const factory User({
    required int id,
    required String name,
    required String email,
    @JsonKey(name: 'strava_athlete_id') int? stravaAthleteId,
    @JsonKey(name: 'strava_profile_url') String? stravaProfileUrl,
    @JsonKey(name: 'coach_style') String? coachStyle,
    @JsonKey(name: 'has_completed_onboarding') @Default(false) bool hasCompletedOnboarding,
    @JsonKey(name: 'pending_plan_generation') PlanGeneration? pendingPlanGeneration,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
