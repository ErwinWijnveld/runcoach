// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OnboardingProfileMetrics _$OnboardingProfileMetricsFromJson(
  Map<String, dynamic> json,
) => _OnboardingProfileMetrics(
  weeklyAvgKm: toDoubleOrNull(json['weekly_avg_km']),
  weeklyAvgRuns: toDoubleOrNull(json['weekly_avg_runs']),
  avgPaceSecondsPerKm: toIntOrNull(json['avg_pace_seconds_per_km']),
  sessionAvgDurationSeconds: toIntOrNull(json['session_avg_duration_seconds']),
);

Map<String, dynamic> _$OnboardingProfileMetricsToJson(
  _OnboardingProfileMetrics instance,
) => <String, dynamic>{
  'weekly_avg_km': instance.weeklyAvgKm,
  'weekly_avg_runs': instance.weeklyAvgRuns,
  'avg_pace_seconds_per_km': instance.avgPaceSecondsPerKm,
  'session_avg_duration_seconds': instance.sessionAvgDurationSeconds,
};

_PersonalRecord _$PersonalRecordFromJson(Map<String, dynamic> json) =>
    _PersonalRecord(
      durationSeconds: toInt(json['duration_seconds']),
      distanceMeters: toInt(json['distance_meters']),
      date: json['date'] as String?,
    );

Map<String, dynamic> _$PersonalRecordToJson(_PersonalRecord instance) =>
    <String, dynamic>{
      'duration_seconds': instance.durationSeconds,
      'distance_meters': instance.distanceMeters,
      'date': instance.date,
    };

_OnboardingProfile _$OnboardingProfileFromJson(Map<String, dynamic> json) =>
    _OnboardingProfile(
      status: json['status'] as String,
      metrics: json['metrics'] == null
          ? null
          : OnboardingProfileMetrics.fromJson(
              json['metrics'] as Map<String, dynamic>,
            ),
      narrativeSummary: json['narrative_summary'] as String?,
      analyzedAt: json['analyzed_at'] == null
          ? null
          : DateTime.parse(json['analyzed_at'] as String),
      personalRecords: (json['personal_records'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(
          k,
          e == null ? null : PersonalRecord.fromJson(e as Map<String, dynamic>),
        ),
      ),
    );

Map<String, dynamic> _$OnboardingProfileToJson(_OnboardingProfile instance) =>
    <String, dynamic>{
      'status': instance.status,
      'metrics': instance.metrics,
      'narrative_summary': instance.narrativeSummary,
      'analyzed_at': instance.analyzedAt?.toIso8601String(),
      'personal_records': instance.personalRecords,
    };
