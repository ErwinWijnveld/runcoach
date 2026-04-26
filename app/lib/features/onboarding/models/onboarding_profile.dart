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

/// One personal record at a standard race distance, computed natively from
/// HealthKit (`HealthKitPersonalRecords.swift` via MethodChannel) and
/// persisted on the user. The onboarding form uses `durationSeconds` to
/// pre-fill goal-time / current-PR fields when the runner picks a distance.
@freezed
sealed class PersonalRecord with _$PersonalRecord {
  const factory PersonalRecord({
    @JsonKey(name: 'duration_seconds', fromJson: toInt) required int durationSeconds,
    @JsonKey(name: 'distance_meters', fromJson: toInt) required int distanceMeters,
    String? date,
  }) = _PersonalRecord;

  factory PersonalRecord.fromJson(Map<String, dynamic> json) =>
      _$PersonalRecordFromJson(json);
}

@freezed
sealed class OnboardingProfile with _$OnboardingProfile {
  const factory OnboardingProfile({
    required String status, // 'ready' | 'syncing'
    OnboardingProfileMetrics? metrics,
    @JsonKey(name: 'narrative_summary') String? narrativeSummary,
    @JsonKey(name: 'analyzed_at') DateTime? analyzedAt,
    /// All-time PRs keyed by '5k' | '10k' | 'half' | 'marathon'. Map values
    /// can be null when no qualifying workout exists for that distance.
    @JsonKey(name: 'personal_records') Map<String, PersonalRecord?>? personalRecords,
  }) = _OnboardingProfile;

  factory OnboardingProfile.fromJson(Map<String, dynamic> json) =>
      _$OnboardingProfileFromJson(json);
}
