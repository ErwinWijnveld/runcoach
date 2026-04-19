import 'package:freezed_annotation/freezed_annotation.dart';

part 'onboarding_form_data.freezed.dart';
part 'onboarding_form_data.g.dart';

enum OnboardingGoalType {
  @JsonValue('race')
  race,
  @JsonValue('pr')
  pr,
  @JsonValue('fitness')
  fitness,
  @JsonValue('weight_loss')
  weightLoss,
}

enum CoachStyleOption {
  @JsonValue('balanced')
  balanced,
  @JsonValue('strict')
  strict,
  @JsonValue('flexible')
  flexible,
}

@freezed
sealed class OnboardingFormData with _$OnboardingFormData {
  const factory OnboardingFormData({
    @JsonKey(name: 'goal_type') OnboardingGoalType? goalType,
    @JsonKey(name: 'goal_name') String? goalName,
    @JsonKey(name: 'distance_meters') int? distanceMeters,
    @JsonKey(name: 'target_date') String? targetDate, // YYYY-MM-DD
    @JsonKey(name: 'goal_time_seconds') int? goalTimeSeconds,
    @JsonKey(name: 'pr_current_seconds') int? prCurrentSeconds,
    @JsonKey(name: 'days_per_week') int? daysPerWeek,
    @JsonKey(name: 'preferred_weekdays') List<int>? preferredWeekdays,
    @JsonKey(name: 'coach_style') CoachStyleOption? coachStyle,
    String? notes,
    @JsonKey(name: 'additional_notes') String? additionalNotes,
  }) = _OnboardingFormData;

  factory OnboardingFormData.fromJson(Map<String, dynamic> json) =>
      _$OnboardingFormDataFromJson(json);
}
