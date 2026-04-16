import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
sealed class User with _$User {
  const factory User({
    required int id,
    required String name,
    required String email,
    @JsonKey(name: 'strava_athlete_id') int? stravaAthleteId,
    @JsonKey(name: 'coach_style') String? coachStyle,
    @JsonKey(name: 'has_completed_onboarding') @Default(false) bool hasCompletedOnboarding,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
