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

/// Training-day types the runner can rank in the onboarding "favourite
/// runs" step. Wire values match the backend's `TrainingType` enum so
/// the ranking can flow through `run_type_preferences` straight into
/// `App\Services\Onboarding\TrainingPlanBuilder`.
enum RunTypePreferenceOption {
  @JsonValue('easy')
  easy,
  @JsonValue('tempo')
  tempo,
  @JsonValue('interval')
  interval,
  @JsonValue('long_run')
  longRun,
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
    @JsonKey(name: 'run_type_preferences')
    List<RunTypePreferenceOption>? runTypePreferences,
  }) = _OnboardingFormData;

  factory OnboardingFormData.fromJson(Map<String, dynamic> json) =>
      _$OnboardingFormDataFromJson(json);
}
