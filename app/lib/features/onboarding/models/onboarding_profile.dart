import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/core/utils/json_converters.dart';

part 'onboarding_profile.freezed.dart';
part 'onboarding_profile.g.dart';

@freezed
sealed class OnboardingProfileMetrics with _$OnboardingProfileMetrics {
  const factory OnboardingProfileMetrics({
    @JsonKey(name: 'weekly_avg_km', fromJson: toDoubleOrNull) double? weeklyAvgKm,
    @JsonKey(name: 'weekly_avg_runs', fromJson: toDoubleOrNull) double? weeklyAvgRuns,
    @JsonKey(name: 'avg_pace_seconds_per_km', fromJson: toIntOrNull) int? avgPaceSecondsPerKm,
    @JsonKey(name: 'session_avg_duration_seconds', fromJson: toIntOrNull) int? sessionAvgDurationSeconds,
  }) = _OnboardingProfileMetrics;

  factory OnboardingProfileMetrics.fromJson(Map<String, dynamic> json) =>
      _$OnboardingProfileMetricsFromJson(json);
}

@freezed
sealed class OnboardingProfile with _$OnboardingProfile {
  const factory OnboardingProfile({
    required String status, // 'ready' | 'syncing'
    OnboardingProfileMetrics? metrics,
    @JsonKey(name: 'narrative_summary') String? narrativeSummary,
    @JsonKey(name: 'analyzed_at') DateTime? analyzedAt,
  }) = _OnboardingProfile;

  factory OnboardingProfile.fromJson(Map<String, dynamic> json) =>
      _$OnboardingProfileFromJson(json);
}
