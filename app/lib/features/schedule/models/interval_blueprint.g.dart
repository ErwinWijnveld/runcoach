// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'interval_blueprint.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_IntervalBlueprint _$IntervalBlueprintFromJson(Map<String, dynamic> json) =>
    _IntervalBlueprint(
      warmupSeconds: toIntOrNull(json['warmup_seconds']),
      steps:
          (json['steps'] as List<dynamic>?)
              ?.map((e) => IntervalStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <IntervalStep>[],
      cooldownSeconds: toIntOrNull(json['cooldown_seconds']),
    );

Map<String, dynamic> _$IntervalBlueprintToJson(_IntervalBlueprint instance) =>
    <String, dynamic>{
      'warmup_seconds': instance.warmupSeconds,
      'steps': instance.steps,
      'cooldown_seconds': instance.cooldownSeconds,
    };

_IntervalStep _$IntervalStepFromJson(Map<String, dynamic> json) =>
    _IntervalStep(
      type: json['type'] as String,
      reps: toIntOrNull(json['reps']),
      workDistanceM: toIntOrNull(json['work_distance_m']),
      workDurationSeconds: toIntOrNull(json['work_duration_seconds']),
      workPaceSecondsPerKm: toIntOrNull(json['work_pace_seconds_per_km']),
      recoverySeconds: toIntOrNull(json['recovery_seconds']),
      durationSeconds: toIntOrNull(json['duration_seconds']),
    );

Map<String, dynamic> _$IntervalStepToJson(_IntervalStep instance) =>
    <String, dynamic>{
      'type': instance.type,
      'reps': instance.reps,
      'work_distance_m': instance.workDistanceM,
      'work_duration_seconds': instance.workDurationSeconds,
      'work_pace_seconds_per_km': instance.workPaceSecondsPerKm,
      'recovery_seconds': instance.recoverySeconds,
      'duration_seconds': instance.durationSeconds,
    };
