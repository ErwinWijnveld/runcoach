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
  /// Default window is the last 90 days (matches what Strava sync used to do).
  Future<List<Map<String, dynamic>>> fetchWorkouts({
    Duration window = const Duration(days: 90),
  }) async {
    final now = DateTime.now();
    final start = now.subtract(window);

    final samples = await _health.getHealthDataFromTypes(
      types: const [_workoutType],
      startTime: start,
      endTime: now,
    );

    final workouts = samples
        .where((s) => s.value is WorkoutHealthValue)
        .map(_shape)
        .whereType<Map<String, dynamic>>()
        .toList();

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
