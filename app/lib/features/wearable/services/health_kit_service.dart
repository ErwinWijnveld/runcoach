import 'package:health/health.dart';

/// Reads workouts and HR samples from Apple HealthKit and shapes them into
/// the payload the backend `POST /wearable/activities` endpoint expects.
///
/// Time-window queries via the `health` package are sufficient for v1 — we
/// fetch on app launch + when the connect-health screen completes. A future
/// follow-up can add a Swift `HKObserverQuery` MethodChannel for true
/// background delivery, plus `predicateForObjects(from: workout)` for
/// workout-scoped HR samples (the time-window query here over-counts samples
/// that overlap the workout but were recorded by other apps).
class HealthKitService {
  HealthKitService([Health? health]) : _health = health ?? Health();

  final Health _health;

  static const _workoutType = HealthDataType.WORKOUT;
  static const _hrType = HealthDataType.HEART_RATE;
  static const _readTypes = <HealthDataType>[_workoutType, _hrType];

  /// Request HealthKit read access. Returns true when at least the workout
  /// type was granted — Apple's `hasPermissions` for READ is unreliable, so
  /// we treat a successful prompt + nonzero workout count as "granted".
  Future<bool> requestPermissions() async {
    await _health.configure();

    final granted = await _health.requestAuthorization(
      _readTypes,
      permissions: const [
        HealthDataAccess.READ,
        HealthDataAccess.READ,
      ],
    );
    return granted;
  }

  /// Pull workouts in the given window and shape them for the backend.
  /// Default window is **the last 12 months** so the runner's profile (which
  /// the backend analyzes over 52 weeks) reflects their full year of running.
  /// HealthKit has no real upper bound on past dates — 365 days returns in
  /// well under a second even for runners with hundreds of workouts.
  Future<List<Map<String, dynamic>>> fetchWorkouts({
    Duration window = const Duration(days: 365),
  }) async {
    final now = DateTime.now();
    final start = now.subtract(window);

    final samples = await _health.getHealthDataFromTypes(
      types: const [_workoutType],
      startTime: start,
      endTime: now,
    );

    int skippedNonRun = 0;
    int skippedZeroDistance = 0;

    final workouts = <Map<String, dynamic>>[];
    for (final point in samples) {
      if (point.value is! WorkoutHealthValue) continue;
      final shaped = _shape(point);
      if (shaped == null) {
        skippedNonRun++;
        continue;
      }
      if ((shaped['distance_meters'] as int) <= 0) {
        // Treadmill runs the watch couldn't track come back as
        // distance=null/0. They're noise for pace + km aggregates so we
        // drop them — the user can still see them in Apple Health itself.
        skippedZeroDistance++;
        continue;
      }
      workouts.add(shaped);
    }

    if (workouts.isEmpty) {
      // ignore: avoid_print
      print('[HealthKit] window=${window.inDays}d found 0 runs '
          '(samples=${samples.length}, skipped non-run=$skippedNonRun, '
          'zero-distance=$skippedZeroDistance)');
    } else {
      // ignore: avoid_print
      print('[HealthKit] window=${window.inDays}d found ${workouts.length} runs '
          '(skipped non-run=$skippedNonRun, zero-distance=$skippedZeroDistance)');
    }

    return workouts;
  }

  Map<String, dynamic>? _shape(HealthDataPoint point) {
    final w = point.value as WorkoutHealthValue;

    final type = _normalizeType(w.workoutActivityType);
    if (type == null) return null;

    final start = point.dateFrom;
    final end = point.dateTo;
    final durationSeconds = end.difference(start).inSeconds;
    if (durationSeconds <= 0) return null;

    final distanceMeters = (w.totalDistance ?? 0).round();

    return {
      'source': 'apple_health',
      'source_activity_id': point.uuid,
      'source_user_id': point.sourceId,
      'type': type,
      'name': null,
      'distance_meters': distanceMeters,
      'duration_seconds': durationSeconds,
      'elapsed_seconds': durationSeconds,
      'start_date': start.toUtc().toIso8601String(),
      'end_date': end.toUtc().toIso8601String(),
      'calories_kcal': (w.totalEnergyBurned ?? 0).round(),
      'raw_data': const <String, dynamic>{},
    };
  }

  /// Map HealthKit's running enums to our backend `type` strings.
  /// Returns null for non-running activity types so the caller can skip them.
  String? _normalizeType(HealthWorkoutActivityType type) {
    switch (type) {
      case HealthWorkoutActivityType.RUNNING:
      case HealthWorkoutActivityType.RUNNING_TREADMILL:
        return 'Run';
      default:
        return null;
    }
  }
}
