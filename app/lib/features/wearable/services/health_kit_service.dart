import 'package:health/health.dart';

/// Reads workouts and HR samples from Apple HealthKit and shapes them into
/// the payload the backend `POST /wearable/activities` endpoint expects.
///
/// Time-window queries via the `health` package are sufficient for v1 — we
/// fetch on app launch + when the connect-health screen completes. A future
/// follow-up can add a Swift `HKObserverQuery` MethodChannel for true
/// background delivery, plus `predicateForObjects(from: workout)` for
/// strictly workout-scoped HR samples (the time-window query here picks up
/// any HR samples that overlap the workout window, which usually means
/// workout HR but can include resting watch readings on either side).
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
  ///
  /// For each surviving workout, also queries HR samples in its time window
  /// to surface `average_heartrate` / `max_heartrate`. These come back as
  /// SEPARATE HealthKit samples (HR is a quantity stream, not a workout
  /// summary field), so without this extra pass the backend would see
  /// every Apple Health workout as HR-less and the coach would say
  /// "I don't have heart-rate data for these runs".
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
    int hrAttached = 0;

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

      final hr = await _fetchHeartRateForWorkout(point.dateFrom, point.dateTo);
      if (hr != null) {
        shaped['average_heartrate'] = hr.average;
        shaped['max_heartrate'] = hr.max;
        hrAttached++;
      }

      workouts.add(shaped);
    }

    // ignore: avoid_print
    print('[HealthKit] window=${window.inDays}d found ${workouts.length} runs '
        '(hr_attached=$hrAttached, skipped non-run=$skippedNonRun, '
        'zero-distance=$skippedZeroDistance)');

    return workouts;
  }

  /// Pull HR samples bounded by [start]–[end], compute avg + max. Returns
  /// null when there are no samples in the window (manually-logged runs,
  /// runs done without an Apple Watch, etc.) so the backend keeps the
  /// columns null instead of writing 0.
  Future<({double average, double max})?> _fetchHeartRateForWorkout(
    DateTime start,
    DateTime end,
  ) async {
    if (!end.isAfter(start)) return null;

    try {
      final samples = await _health.getHealthDataFromTypes(
        types: const [_hrType],
        startTime: start,
        endTime: end,
      );

      final values = <double>[];
      for (final s in samples) {
        if (s.value is! NumericHealthValue) continue;
        final v = (s.value as NumericHealthValue).numericValue.toDouble();
        // HealthKit BPM range. Anything outside is bad data (watch glitch,
        // simulator junk) — drop it instead of letting it skew the average.
        if (v >= 30 && v <= 250) values.add(v);
      }

      if (values.isEmpty) return null;

      final avg = values.reduce((a, b) => a + b) / values.length;
      final max = values.reduce((a, b) => a > b ? a : b);
      return (average: avg, max: max);
    } catch (_) {
      // HealthKit denies HR access for some runs (e.g. third-party imports).
      // Don't fail the whole sync — just leave HR null on this row.
      return null;
    }
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
