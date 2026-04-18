import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/features/onboarding/models/onboarding_form_data.dart';

part 'onboarding_form_provider.g.dart';

/// Holds the user's choices while they step through the onboarding form.
/// Values accumulate across steps; the generating screen reads the final
/// snapshot and posts it.
@Riverpod(keepAlive: true)
class OnboardingForm extends _$OnboardingForm {
  @override
  OnboardingFormData build() => const OnboardingFormData();

  void setGoalType(OnboardingGoalType type) {
    state = state.copyWith(goalType: type);
  }

  void setGoalName(String? name) {
    state = state.copyWith(goalName: (name != null && name.trim().isEmpty) ? null : name);
  }

  void setDistance(int meters) {
    state = state.copyWith(distanceMeters: meters);
  }

  void setTargetDate(String iso) {
    state = state.copyWith(targetDate: iso);
  }

  void setGoalTime(int seconds) {
    state = state.copyWith(goalTimeSeconds: seconds);
  }

  void setPrCurrent(int? seconds) {
    state = state.copyWith(prCurrentSeconds: seconds);
  }

  void setDaysPerWeek(int days) {
    state = state.copyWith(daysPerWeek: days);
  }

  void setCoachStyle(CoachStyleOption style) {
    state = state.copyWith(coachStyle: style);
  }

  void setNotes(String? notes) {
    state = state.copyWith(notes: (notes != null && notes.trim().isEmpty) ? null : notes);
  }

  /// Strip fields that aren't relevant for the chosen goal type. Called
  /// before posting to keep the payload tight.
  Map<String, dynamic> toPayload() {
    final json = state.toJson();
    final goalType = state.goalType;

    if (goalType != OnboardingGoalType.race) {
      json.remove('goal_name');
      json.remove('target_date');
    }
    if (goalType == OnboardingGoalType.fitness) {
      json.remove('distance_meters');
      json.remove('goal_time_seconds');
      json.remove('pr_current_seconds');
    }
    if (goalType != OnboardingGoalType.pr) {
      json.remove('pr_current_seconds');
    }
    // Remove null values for cleanliness (Laravel treats missing and null
    // the same for `nullable`, but this keeps the logs clean).
    json.removeWhere((_, v) => v == null);

    return json;
  }

  void reset() {
    state = const OnboardingFormData();
  }
}
