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
      totalKmPlanned: (json['total_km_planned'] as num).toDouble(),
      totalKmCompleted: (json['total_km_completed'] as num).toDouble(),
      sessionsCompleted: (json['sessions_completed'] as num).toInt(),
      sessionsTotal: (json['sessions_total'] as num).toInt(),
      complianceAvg: (json['compliance_avg'] as num?)?.toDouble(),
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
      raceDate: json['race_date'] as String,
      weeksUntilRace: (json['weeks_until_race'] as num).toInt(),
    );

Map<String, dynamic> _$ActiveRaceSummaryToJson(_ActiveRaceSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'distance': instance.distance,
      'race_date': instance.raceDate,
      'weeks_until_race': instance.weeksUntilRace,
    };
