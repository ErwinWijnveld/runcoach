import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workout_route_service.g.dart';

/// One GPS point on the route polyline. Short keys mirror the native
/// bridge JSON so we don't serialise/deserialise twice.
class WorkoutRoutePoint {
  final double lat;
  final double lng;

  /// Unix epoch in milliseconds. Useful for ordering segments when a
  /// workout had multiple route samples (mid-run pauses).
  final int timestampMs;

  const WorkoutRoutePoint({
    required this.lat,
    required this.lng,
    required this.timestampMs,
  });

  factory WorkoutRoutePoint.fromMap(Map<dynamic, dynamic> raw) {
    return WorkoutRoutePoint(
      lat: (raw['lat'] as num).toDouble(),
      lng: (raw['lng'] as num).toDouble(),
      timestampMs: (raw['t'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        't': timestampMs,
      };
}

/// Reads the GPS polyline of a finished `HKWorkout` via the
/// `nl.runcoach/workout-route` MethodChannel. iOS-only; on any other
/// platform (or when iOS denies permission / has no route data)
/// returns an empty list — never throws.
class WorkoutRouteService {
  static const _channel = MethodChannel('nl.runcoach/workout-route');

  /// Fetch the polyline for a single workout. `workoutUuid` must be the
  /// HKWorkout's `uuid` as String (the same UUID surfaced by the
  /// `health` package's `HealthDataPoint.uuid`).
  ///
  /// Returns an empty list for:
  /// - non-iOS platforms,
  /// - workouts without route data (treadmill / indoor),
  /// - HealthKit auth denied,
  /// - any unexpected native error (logged but swallowed — the share
  ///   card flow falls back to the no-route variant gracefully).
  Future<List<WorkoutRoutePoint>> fetchRoute(String workoutUuid) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return const [];

    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'fetchRoute',
        {'workoutUuid': workoutUuid},
      );
      final pointsRaw = result?['points'] as List? ?? const [];
      return pointsRaw
          .whereType<Map>()
          .map(WorkoutRoutePoint.fromMap)
          .toList(growable: false);
    } on PlatformException catch (e) {
      debugPrint('[WorkoutRouteService] fetchRoute failed: ${e.code} ${e.message}');
      return const [];
    }
  }
}

@Riverpod(keepAlive: true)
WorkoutRouteService workoutRouteService(Ref ref) => WorkoutRouteService();
