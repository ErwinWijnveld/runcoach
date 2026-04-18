// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_form_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OnboardingFormData _$OnboardingFormDataFromJson(Map<String, dynamic> json) =>
    _OnboardingFormData(
      goalType: $enumDecodeNullable(
        _$OnboardingGoalTypeEnumMap,
        json['goal_type'],
      ),
      goalName: json['goal_name'] as String?,
      distanceMeters: (json['distance_meters'] as num?)?.toInt(),
      targetDate: json['target_date'] as String?,
      goalTimeSeconds: (json['goal_time_seconds'] as num?)?.toInt(),
      prCurrentSeconds: (json['pr_current_seconds'] as num?)?.toInt(),
      daysPerWeek: (json['days_per_week'] as num?)?.toInt(),
      coachStyle: $enumDecodeNullable(
        _$CoachStyleOptionEnumMap,
        json['coach_style'],
      ),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$OnboardingFormDataToJson(_OnboardingFormData instance) =>
    <String, dynamic>{
      'goal_type': _$OnboardingGoalTypeEnumMap[instance.goalType],
      'goal_name': instance.goalName,
      'distance_meters': instance.distanceMeters,
      'target_date': instance.targetDate,
      'goal_time_seconds': instance.goalTimeSeconds,
      'pr_current_seconds': instance.prCurrentSeconds,
      'days_per_week': instance.daysPerWeek,
      'coach_style': _$CoachStyleOptionEnumMap[instance.coachStyle],
      'notes': instance.notes,
    };

const _$OnboardingGoalTypeEnumMap = {
  OnboardingGoalType.race: 'race',
  OnboardingGoalType.pr: 'pr',
  OnboardingGoalType.fitness: 'fitness',
};

const _$CoachStyleOptionEnumMap = {
  CoachStyleOption.balanced: 'balanced',
  CoachStyleOption.strict: 'strict',
  CoachStyleOption.flexible: 'flexible',
};
