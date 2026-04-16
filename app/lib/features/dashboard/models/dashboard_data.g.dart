// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DashboardData _$DashboardDataFromJson(
  Map<String, dynamic> json,
) => _DashboardData(
  weeklySummary: json['weekly_summary'] == null
      ? null
      : WeeklySummary.fromJson(json['weekly_summary'] as Map<String, dynamic>),
  nextTraining: json['next_training'] == null
      ? null
      : TrainingDay.fromJson(json['next_training'] as Map<String, dynamic>),
  activeRace: json['active_race'] == null
      ? null
      : ActiveRaceSummary.fromJson(json['active_race'] as Map<String, dynamic>),
  coachInsight: json['coach_insight'] as String?,
);

Map<String, dynamic> _$DashboardDataToJson(_DashboardData instance) =>
    <String, dynamic>{
      'weekly_summary': instance.weeklySummary,
      'next_training': instance.nextTraining,
      'active_race': instance.activeRace,
      'coach_insight': instance.coachInsight,
    };

_WeeklySummary _$WeeklySummaryFromJson(Map<String, dynamic> json) =>
    _WeeklySummary(
      totalKmPlanned: toDouble(json['total_km_planned']),
      totalKmCompleted: toDouble(json['total_km_completed']),
      sessionsCompleted: toInt(json['sessions_completed']),
      sessionsTotal: toInt(json['sessions_total']),
      complianceAvg: toDoubleOrNull(json['compliance_avg']),
    );

Map<String, dynamic> _$WeeklySummaryToJson(_WeeklySummary instance) =>
    <String, dynamic>{
      'total_km_planned': instance.totalKmPlanned,
      'total_km_completed': instance.totalKmCompleted,
      'sessions_completed': instance.sessionsCompleted,
      'sessions_total': instance.sessionsTotal,
      'compliance_avg': instance.complianceAvg,
    };

_ActiveRaceSummary _$ActiveRaceSummaryFromJson(Map<String, dynamic> json) =>
    _ActiveRaceSummary(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      distance: json['distance'] as String,
      targetDate: json['target_date'] as String,
      weeksUntilRace: toInt(json['weeks_until_race']),
    );

Map<String, dynamic> _$ActiveRaceSummaryToJson(_ActiveRaceSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'distance': instance.distance,
      'target_date': instance.targetDate,
      'weeks_until_race': instance.weeksUntilRace,
    };
