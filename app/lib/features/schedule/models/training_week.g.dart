// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_week.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TrainingWeek _$TrainingWeekFromJson(Map<String, dynamic> json) =>
    _TrainingWeek(
      id: (json['id'] as num).toInt(),
      raceId: (json['race_id'] as num).toInt(),
      weekNumber: (json['week_number'] as num).toInt(),
      startsAt: json['starts_at'] as String,
      totalKm: (json['total_km'] as num).toDouble(),
      focus: json['focus'] as String,
      coachNotes: json['coach_notes'] as String?,
      trainingDays: (json['training_days'] as List<dynamic>?)
          ?.map((e) => TrainingDay.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TrainingWeekToJson(_TrainingWeek instance) =>
    <String, dynamic>{
      'id': instance.id,
      'race_id': instance.raceId,
      'week_number': instance.weekNumber,
      'starts_at': instance.startsAt,
      'total_km': instance.totalKm,
      'focus': instance.focus,
      'coach_notes': instance.coachNotes,
      'training_days': instance.trainingDays,
    };
