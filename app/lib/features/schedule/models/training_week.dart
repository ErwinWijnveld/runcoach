import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/core/utils/json_converters.dart';
import 'package:app/features/schedule/models/training_day.dart';
import 'package:app/features/schedule/models/wearable_activity_summary.dart';

part 'training_week.freezed.dart';
part 'training_week.g.dart';

@freezed
sealed class TrainingWeek with _$TrainingWeek {
  const factory TrainingWeek({
    required int id,
    @JsonKey(name: 'goal_id') required int goalId,
    @JsonKey(name: 'week_number') required int weekNumber,
    @JsonKey(name: 'starts_at') required String startsAt,
    @JsonKey(name: 'total_km', fromJson: toDouble) required double totalKm,
    required String focus,
    @JsonKey(name: 'coach_notes') String? coachNotes,
    @JsonKey(name: 'training_days') List<TrainingDay>? trainingDays,

    /// Runs that fell within this week but matched no planned session
    /// ("buiten schema"). Surfaced as blue tiles the runner can link.
    @JsonKey(name: 'unplanned_runs') List<WearableActivitySummary>? unplannedRuns,
  }) = _TrainingWeek;

  factory TrainingWeek.fromJson(Map<String, dynamic> json) =>
      _$TrainingWeekFromJson(json);
}
