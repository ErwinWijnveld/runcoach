import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/core/utils/json_converters.dart';
import 'package:app/features/schedule/models/training_day.dart';

part 'dashboard_data.freezed.dart';
part 'dashboard_data.g.dart';

@freezed
sealed class DashboardData with _$DashboardData {
  const factory DashboardData({
    @JsonKey(name: 'weekly_summary') WeeklySummary? weeklySummary,
    @JsonKey(name: 'next_training') TrainingDay? nextTraining,
    @JsonKey(name: 'active_goal') ActiveGoalSummary? activeGoal,
    @JsonKey(name: 'coach_insight') String? coachInsight,
  }) = _DashboardData;

  factory DashboardData.fromJson(Map<String, dynamic> json) =>
      _$DashboardDataFromJson(json);
}

@freezed
sealed class WeeklySummary with _$WeeklySummary {
  const factory WeeklySummary({
    @JsonKey(name: 'total_km_planned', fromJson: toDouble) required double totalKmPlanned,
    @JsonKey(name: 'total_km_completed', fromJson: toDouble) required double totalKmCompleted,
    @JsonKey(name: 'sessions_completed', fromJson: toInt) required int sessionsCompleted,
    @JsonKey(name: 'sessions_total', fromJson: toInt) required int sessionsTotal,
    @JsonKey(name: 'compliance_avg', fromJson: toDoubleOrNull) double? complianceAvg,
  }) = _WeeklySummary;

  factory WeeklySummary.fromJson(Map<String, dynamic> json) =>
      _$WeeklySummaryFromJson(json);
}

@freezed
sealed class ActiveGoalSummary with _$ActiveGoalSummary {
  const factory ActiveGoalSummary({
    required int id,
    required String type,
    required String name,
    String? distance,
    @JsonKey(name: 'target_date') String? targetDate,
    @JsonKey(name: 'weeks_until_target_date', fromJson: toIntOrNull) int? weeksUntilTargetDate,
  }) = _ActiveGoalSummary;

  factory ActiveGoalSummary.fromJson(Map<String, dynamic> json) =>
      _$ActiveGoalSummaryFromJson(json);
}
