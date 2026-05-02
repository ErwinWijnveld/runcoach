import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workout_scheduler_service.g.dart';

/// Outcome of a `scheduleRun` call. Surfaces the native bridge's status verb
/// so the UI can pick the right copy + icon without the service deciding it.
class WorkoutScheduleResult {
  final WorkoutScheduleStatus status;
  final String? message;

  const WorkoutScheduleResult({required this.status, this.message});
}

enum WorkoutScheduleStatus {
  scheduled,
  duplicate,
  denied,
  unavailable,
  failed;

  static WorkoutScheduleStatus parse(String? raw) {
    switch (raw) {
      case 'scheduled':
        return WorkoutScheduleStatus.scheduled;
      case 'duplicate':
        return WorkoutScheduleStatus.duplicate;
      case 'denied':
        return WorkoutScheduleStatus.denied;
      case 'unavailable':
        return WorkoutScheduleStatus.unavailable;
      default:
        return WorkoutScheduleStatus.failed;
    }
  }
}

/// One step inside an interval session sent to WorkoutKit. `kind` is either
/// 'work' or 'recovery' (warmup is passed separately, cooldowns are dropped).
/// Set exactly ONE of [distanceM] / [durationSeconds] for work reps; recovery
/// is always time-based per app convention.
class WorkoutIntervalStep {
  final String kind;
  final int? distanceM;
  final int? durationSeconds;

  const WorkoutIntervalStep({
    required this.kind,
    this.distanceM,
    this.durationSeconds,
  });

  Map<String, dynamic> toJson() => {
        'kind': kind,
        'distanceM': distanceM,
        'durationSeconds': durationSeconds,
      };
}

/// Bridge to the native `nl.runcoach/workout` MethodChannel. Only iOS 17+
/// supports WorkoutKit scheduling; on web/Android/older iOS this returns
/// `unavailable` immediately so the caller can show a friendly message
/// instead of a platform exception.
class WorkoutSchedulerService {
  static const _channel = MethodChannel('nl.runcoach/workout');

  Future<WorkoutScheduleResult> scheduleRun({
    required int dayId,
    required DateTime date,
    required double distanceKm,
  }) async {
    if (!_supportsNativeBridge()) {
      return _unavailableResult();
    }

    return _invoke('scheduleRun', {
      'dayId': dayId,
      'date': _ymd(date),
      'distanceKm': distanceKm,
    });
  }

  /// Schedules a CustomWorkout with intervals. Per app convention warmup is
  /// OPTIONAL and time-based, cooldown is REQUIRED and time-based, recovery
  /// is always time-based. These rules are also enforced server-side by
  /// `PlanOptimizerService::normalizeIntervals`, but we re-enforce here so
  /// old TrainingDay rows still get sent in the canonical shape.
  Future<WorkoutScheduleResult> scheduleIntervals({
    required int dayId,
    required DateTime date,
    String? displayName,
    int? warmupSeconds,
    int? cooldownSeconds,
    required List<WorkoutIntervalStep> steps,
  }) async {
    if (!_supportsNativeBridge()) {
      return _unavailableResult();
    }

    return _invoke('scheduleIntervals', {
      'dayId': dayId,
      'date': _ymd(date),
      'displayName': displayName,
      'warmupSeconds': warmupSeconds,
      'cooldownSeconds': cooldownSeconds,
      'steps': steps.map((s) => s.toJson()).toList(growable: false),
    });
  }

  /// Best-effort: if the watch already has a scheduled workout for this
  /// TrainingDay, move it to [newDate]. Silent no-op when the user never
  /// sent it to the watch, when permission was denied, or on iOS < 17.4.
  /// Errors are swallowed — the watch is a side-channel, the app DB is
  /// the source of truth.
  Future<void> rescheduleIfPresent({
    required int dayId,
    required DateTime newDate,
  }) async {
    if (!_supportsNativeBridge()) return;

    try {
      await _channel.invokeMethod<dynamic>('rescheduleIfPresent', {
        'dayId': dayId,
        'date': _ymd(newDate),
      });
    } catch (_) {
      // Silent — see method docstring.
    }
  }

  bool _supportsNativeBridge() {
    if (kIsWeb) return false;
    return Platform.isIOS;
  }

  WorkoutScheduleResult _unavailableResult() {
    return const WorkoutScheduleResult(
      status: WorkoutScheduleStatus.unavailable,
      message: 'Sending workouts to your watch is only available on iOS.',
    );
  }

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<WorkoutScheduleResult> _invoke(
    String method,
    Map<String, dynamic> args,
  ) async {
    try {
      final raw = await _channel.invokeMethod<dynamic>(method, args);
      final map =
          raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
      return WorkoutScheduleResult(
        status: WorkoutScheduleStatus.parse(map['status'] as String?),
        message: map['message'] as String?,
      );
    } on PlatformException catch (e) {
      return WorkoutScheduleResult(
        status: WorkoutScheduleStatus.failed,
        message: e.message ?? 'Native bridge error.',
      );
    } catch (e) {
      return WorkoutScheduleResult(
        status: WorkoutScheduleStatus.failed,
        message: '$e',
      );
    }
  }
}

@Riverpod(keepAlive: true)
WorkoutSchedulerService workoutSchedulerService(Ref ref) =>
    WorkoutSchedulerService();
