import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/features/schedule/models/training_day.dart';

part 'dashboard_data.freezed.dart';
part 'dashboard_data.g.dart';

@freezed
sealed class DashboardData with _$DashboardData {
  const factory DashboardData({
    @JsonKey(name: 'weekly_summary') WeeklySummary? weeklySummary,
    @JsonKey(name: 'next_training') TrainingDay? nextTraining,
    @JsonKey(name: 'active_race') ActiveRaceSummary? activeRace,
    @JsonKey(name: 'coach_insight') String? coachInsight,
  }) = _DashboardData;

  factory DashboardData.fromJson(Map<String, dynamic> json) =>
      _$DashboardDataFromJson(json);
}

@freezed
sealed class WeeklySummary with _$WeeklySummary {
  const factory WeeklySummary({
    @JsonKey(name: 'total_km_planned') required double totalKmPlanned,
    @JsonKey(name: 'total_km_completed') required double totalKmCompleted,
    @JsonKey(name: 'sessions_completed') required int sessionsCompleted,
    @JsonKey(name: 'sessions_total') required int sessionsTotal,
    @JsonKey(name: 'compliance_avg') double? complianceAvg,
  }) = _WeeklySummary;

  factory WeeklySummary.fromJson(Map<String, dynamic> json) =>
      _$WeeklySummaryFromJson(json);
}

@freezed
sealed class ActiveRaceSummary with _$ActiveRaceSummary {
  const factory ActiveRaceSummary({
    required int id,
    required String name,
    required String distance,
    @JsonKey(name: 'race_date') required String raceDate,
    @JsonKey(name: 'weeks_until_race') required int weeksUntilRace,
  }) = _ActiveRaceSummary;

  factory ActiveRaceSummary.fromJson(Map<String, dynamic> json) =>
      _$ActiveRaceSummaryFromJson(json);
}
