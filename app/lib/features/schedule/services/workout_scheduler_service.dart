import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:app/features/schedule/models/training_day.dart';

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
  denied,
  unavailable,
  failed;

  static WorkoutScheduleStatus parse(String? raw) {
    switch (raw) {
      case 'scheduled':
        return WorkoutScheduleStatus.scheduled;
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

/// Normalized interval payload ready for the WorkoutKit bridge. Built by
/// [buildIntervalPlan] from a [TrainingDay]'s `intervals` list. Used by
/// both the single-day "Send to watch" button AND the batched auto-sync,
/// so the canonical shape lives in exactly one place.
class IntervalPlan {
  final int? warmupSeconds;
  final int? cooldownSeconds;
  final List<WorkoutIntervalStep> steps;

  const IntervalPlan({
    required this.warmupSeconds,
    required this.cooldownSeconds,
    required this.steps,
  });
}

/// Translate a [TrainingDay]'s `intervals` list into the canonical
/// WorkoutKit payload shape:
///   - warmup hoisted to its own slot, time-based, clamped to [15s, 120s]
///   - work + recovery flow into the IntervalBlock as steps
///   - cooldown hoisted to its own slot, time-based, clamped to [60s, 600s];
///     synthesized at 300s if the segment list lacks one (defensive)
///
/// Pure helper — does NOT call the native bridge. Callers can inspect
/// `steps.isEmpty` to surface a friendly error before invoking the bridge.
/// Returns `null` when the day has no intervals.
IntervalPlan? buildIntervalPlan(TrainingDay day) {
  // Unroll the grouped blueprint to flat segments; the WorkoutKit payload
  // builder + native bridge consume the flat shape unchanged.
  final segments = day.intervals?.expand();
  if (segments == null || segments.isEmpty) return null;

  int? warmupSeconds;
  int? cooldownSeconds;
  final steps = <WorkoutIntervalStep>[];

  for (final segment in segments) {
    switch (segment.kind) {
      case 'warmup':
        if (warmupSeconds != null) break;
        warmupSeconds = (segment.durationSeconds ?? 60).clamp(15, 120);
        break;
      case 'recovery':
        int? duration = segment.durationSeconds;
        if ((duration == null || duration <= 0) &&
            segment.distanceM != null &&
            segment.distanceM! > 0) {
          // Fall back: convert distance to time using a 6:00/km recovery
          // pace (360 sec/km). Conservative — better too long than too short.
          duration = ((segment.distanceM! / 1000) * 360).round();
        }
        duration ??= 90;
        steps.add(WorkoutIntervalStep(
          kind: 'recovery',
          durationSeconds: duration.clamp(15, 600),
        ));
        break;
      case 'cooldown':
        int? duration = segment.durationSeconds;
        if ((duration == null || duration <= 0) &&
            segment.distanceM != null &&
            segment.distanceM! > 0) {
          duration = ((segment.distanceM! / 1000) * 360).round();
        }
        duration ??= 300;
        cooldownSeconds = duration.clamp(60, 600);
        break;
      case 'work':
      default:
        if (segment.distanceM != null && segment.distanceM! > 0) {
          steps.add(WorkoutIntervalStep(
            kind: 'work',
            distanceM: segment.distanceM,
          ));
        } else if (segment.durationSeconds != null &&
            segment.durationSeconds! > 0) {
          steps.add(WorkoutIntervalStep(
            kind: 'work',
            durationSeconds: segment.durationSeconds,
          ));
        }
        break;
    }
  }

  // Cooldown is mandatory in our schema. Synthesize the default if missing.
  cooldownSeconds ??= 300;

  return IntervalPlan(
    warmupSeconds: warmupSeconds,
    cooldownSeconds: cooldownSeconds,
    steps: steps,
  );
}

/// One day to push into a batched [WorkoutSchedulerService.syncDays] call.
/// Mirror of the Swift `syncDays` `days[]` element. Use [DaySyncRequest.fromTrainingDay]
/// to build from a [TrainingDay] — handles distance-only vs interval shape.
class DaySyncRequest {
  final int dayId;
  final DateTime date;
  final double? distanceKm;
  final String? displayName;
  final int? warmupSeconds;
  final int? cooldownSeconds;
  final List<WorkoutIntervalStep>? steps;

  const DaySyncRequest({
    required this.dayId,
    required this.date,
    this.distanceKm,
    this.displayName,
    this.warmupSeconds,
    this.cooldownSeconds,
    this.steps,
  });

  /// Build a request from a [TrainingDay]. Returns `null` when the day
  /// can't be expressed as a watch workout (no distance and no intervals),
  /// or when its date isn't parsable. Callers skip the day in that case.
  static DaySyncRequest? fromTrainingDay(TrainingDay day) {
    final date = _parseYmd(day.date);
    if (date == null) return null;

    final plan = buildIntervalPlan(day);
    if (plan != null && plan.steps.isNotEmpty) {
      return DaySyncRequest(
        dayId: day.id,
        date: date,
        displayName: day.title,
        warmupSeconds: plan.warmupSeconds,
        cooldownSeconds: plan.cooldownSeconds,
        steps: plan.steps,
      );
    }

    final km = day.targetKm;
    if (km != null && km > 0) {
      return DaySyncRequest(dayId: day.id, date: date, distanceKm: km);
    }

    return null;
  }

  Map<String, dynamic> toJson() => {
        'dayId': dayId,
        'date':
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        if (distanceKm != null) 'distanceKm': distanceKm,
        if (displayName != null) 'displayName': displayName,
        if (warmupSeconds != null) 'warmupSeconds': warmupSeconds,
        if (cooldownSeconds != null) 'cooldownSeconds': cooldownSeconds,
        if (steps != null)
          'steps': steps!.map((s) => s.toJson()).toList(growable: false),
      };
}

DateTime? _parseYmd(String raw) {
  final parts = raw.split('-');
  if (parts.length != 3) return null;
  try {
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  } catch (_) {
    return null;
  }
}

/// One result from a batched syncDays call.
enum DaySyncStatus {
  scheduled,
  skipped,
  failed;

  static DaySyncStatus parse(String? raw) {
    switch (raw) {
      case 'scheduled':
        return DaySyncStatus.scheduled;
      case 'skipped':
        return DaySyncStatus.skipped;
      default:
        return DaySyncStatus.failed;
    }
  }
}

class DaySyncResult {
  final int dayId;
  final DaySyncStatus status;
  final String? message;

  const DaySyncResult({
    required this.dayId,
    required this.status,
    this.message,
  });

  factory DaySyncResult.fromJson(Map<String, dynamic> json) => DaySyncResult(
        dayId: (json['dayId'] as num?)?.toInt() ?? 0,
        status: DaySyncStatus.parse(json['status'] as String?),
        message: json['message'] as String?,
      );
}

/// Overall outcome of a batched syncDays call.
enum BatchSyncStatus {
  ok,
  denied,
  unavailable,
  failed;

  static BatchSyncStatus parse(String? raw) {
    switch (raw) {
      case 'ok':
        return BatchSyncStatus.ok;
      case 'denied':
        return BatchSyncStatus.denied;
      case 'unavailable':
        return BatchSyncStatus.unavailable;
      default:
        return BatchSyncStatus.failed;
    }
  }
}

class BatchSyncResult {
  final BatchSyncStatus status;
  final List<DaySyncResult> results;

  const BatchSyncResult({required this.status, required this.results});

  static const BatchSyncResult unavailable = BatchSyncResult(
    status: BatchSyncStatus.unavailable,
    results: [],
  );
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

  /// Batch-schedule N training days in a single native call. Replaces any
  /// previously-scheduled workouts for these dayIds (deterministic UUID
  /// match). Used by the auto-sync flow (plan accept, foreground delta).
  ///
  /// Returns [BatchSyncResult.unavailable] on iOS < 17.4 / Android / web —
  /// callers fall back to the per-day manual button. `denied` means the
  /// user refused the permission prompt; `ok` means each day's individual
  /// status is in `results[]`.
  Future<BatchSyncResult> syncDays(List<DaySyncRequest> days) async {
    if (!_supportsNativeBridge() || days.isEmpty) {
      return BatchSyncResult.unavailable;
    }
    try {
      final raw = await _channel.invokeMethod<dynamic>('syncDays', {
        'days': days.map((d) => d.toJson()).toList(growable: false),
      });
      final map =
          raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
      final status = BatchSyncStatus.parse(map['status'] as String?);
      final results = (map['results'] as List?) ?? const [];
      return BatchSyncResult(
        status: status,
        results: results
            .whereType<Map>()
            .map((r) => DaySyncResult.fromJson(Map<String, dynamic>.from(r)))
            .toList(growable: false),
      );
    } catch (_) {
      // Native bridge errors are best-effort — return failed and let the
      // caller decide whether to surface anything. Auto-sync paths use
      // fire-and-forget, so a swallow is fine.
      return const BatchSyncResult(
        status: BatchSyncStatus.failed,
        results: [],
      );
    }
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

  /// Returns true when the host platform can drive the native bridge.
  /// Tests override this by subclassing the service; production code
  /// gates network/fetch work in [WatchSync] off this getter.
  bool get isSupported => _supportsNativeBridge();

  bool _supportsNativeBridge() {
    if (kIsWeb) return false;
    return Platform.isIOS;
  }

  WorkoutScheduleResult _unavailableResult() {
    // Leave `message` null — the widget falls back to a localized string
    // (schedWatchUnavailableBody) so this UX is i18n-correct.
    return const WorkoutScheduleResult(
      status: WorkoutScheduleStatus.unavailable,
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
      // Native PlatformException messages from Swift are not localized. Let
      // the widget fall back to schedWatchGenericError instead — `null`
      // message → localized fallback.
      return WorkoutScheduleResult(
        status: WorkoutScheduleStatus.failed,
        message: e.message,
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
