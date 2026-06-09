import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/share/painters/route_polyline_painter.dart';
import 'package:app/features/wearable/services/workout_route_service.dart';

WorkoutRoutePoint p(double lat, double lng) =>
    WorkoutRoutePoint(lat: lat, lng: lng, timestampMs: 0);

Animation<double> anim(double v) => AlwaysStoppedAnimation<double>(v);

void main() {
  group('RoutePolylinePainter simplification', () {
    test('keeps start and end of a straight line', () {
      final input = [for (var i = 0; i < 10; i++) p(0.0, i * 0.001)];
      final painter = RoutePolylinePainter(progress: anim(1.0), points: input);
      expect(painter.simplified.first, input.first);
      expect(painter.simplified.last, input.last);
      // Straight line should collapse to just the endpoints.
      expect(painter.simplified.length, lessThanOrEqualTo(2));
    });

    test('caps long routes at maxPoints', () {
      final rng = math.Random(42);
      // Simulate a marathon: ~3000 points with realistic city-block noise.
      final input = <WorkoutRoutePoint>[];
      var lat = 52.36;
      var lng = 4.90;
      for (var i = 0; i < 3000; i++) {
        lat += (rng.nextDouble() - 0.5) * 0.0008;
        lng += (rng.nextDouble() - 0.5) * 0.0008;
        input.add(p(lat, lng));
      }
      final painter =
          RoutePolylinePainter(progress: anim(1.0), points: input, maxPoints: 500);
      expect(painter.simplified.length, lessThanOrEqualTo(501)); // +1 for final
    });

    test('handles 1-point input safely', () {
      final painter =
          RoutePolylinePainter(progress: anim(1.0), points: [p(52.0, 4.0)]);
      expect(painter.simplified.length, 1);
    });

    test('handles empty input safely', () {
      final painter =
          RoutePolylinePainter(progress: anim(1.0), points: const []);
      expect(painter.simplified, isEmpty);
    });
  });

  group('RoutePolylinePainter shouldRepaint', () {
    test('repaints when progress changes', () {
      final pts = [p(0, 0), p(1, 1)];
      final a = RoutePolylinePainter(progress: anim(0.5), points: pts);
      final b = RoutePolylinePainter(progress: anim(0.7), points: pts);
      expect(a.shouldRepaint(b), true);
    });
  });
}
