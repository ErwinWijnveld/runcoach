import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:app/features/wearable/services/workout_route_service.dart';

/// Renders a GPS route as an abstract gold polyline on a [CustomPainter].
///
/// Visual choices:
/// - Pure path render — no map tiles, no labels. Cream background lets
///   the polyline carry the visual weight.
/// - Linear gradient stroke: gold → orange (matches app accent).
/// - 8px stroke with rounded caps + joins.
/// - Lat/lng normalised into a centered, padded bounding box (the
///   "frame" param) preserving aspect ratio — so a 3km loop and a
///   42km city marathon both fill the same visual area.
/// - Start/end markers are small discs; rendered when [progress] > 0
///   (start) and [progress] >= 1 (end) so the intro-animation can
///   pop them in at the right moment.
/// - [progress] in [0, 1] drives a stroke-draw intro animation. The
///   path is computed once and clipped per frame via
///   `Path.computeMetrics()` + `extractPath`.
///
/// Douglas-Peucker simplification is applied once at construction time,
/// not per repaint, so dragging an animation slider stays smooth even
/// for marathon-length routes.
class RoutePolylinePainter extends CustomPainter {
  /// Animation progress in [0, 1]. 0 = nothing drawn; 1 = full polyline
  /// + both markers visible.
  final double progress;

  /// Simplified points in display order (start → end).
  final List<WorkoutRoutePoint> simplified;

  /// Pre-computed bounding box of [simplified] in lat/lng space.
  /// Stored on the painter so a window resize doesn't re-walk the array.
  final double _minLat;
  final double _maxLat;
  final double _minLng;
  final double _maxLng;

  RoutePolylinePainter({
    required this.progress,
    required List<WorkoutRoutePoint> points,
    double simplificationEpsilon = 0.0001,
    int maxPoints = 500,
  })  : simplified =
            _simplify(points, simplificationEpsilon, maxPoints),
        _minLat = _bbox(points).$1,
        _maxLat = _bbox(points).$2,
        _minLng = _bbox(points).$3,
        _maxLng = _bbox(points).$4;

  @override
  void paint(Canvas canvas, Size size) {
    if (simplified.length < 2) return;

    // Aspect-correct projection: pick the smaller of the two scale
    // factors so the polyline fits inside [size] without distortion.
    // We render into 90% of the box to leave gentle breathing room
    // around the markers.
    const pad = 0.05;
    final usable = Size(size.width * (1 - 2 * pad), size.height * (1 - 2 * pad));
    final offset = Offset(size.width * pad, size.height * pad);

    final latRange = math.max(_maxLat - _minLat, 1e-9);
    final lngRange = math.max(_maxLng - _minLng, 1e-9);
    final scale = math.min(usable.width / lngRange, usable.height / latRange);

    // Centering offset: half the leftover space goes on each side.
    final renderedW = lngRange * scale;
    final renderedH = latRange * scale;
    final dx = (usable.width - renderedW) / 2;
    final dy = (usable.height - renderedH) / 2;

    Offset project(WorkoutRoutePoint p) {
      final x = (p.lng - _minLng) * scale + dx + offset.dx;
      // Lat increases northward → flip Y so north is "up" on screen.
      final y = (_maxLat - p.lat) * scale + dy + offset.dy;
      return Offset(x, y);
    }

    // Build the path once per repaint. Even at 500 points this is
    // a few microseconds.
    final fullPath = Path();
    fullPath.moveTo(project(simplified.first).dx, project(simplified.first).dy);
    for (var i = 1; i < simplified.length; i++) {
      final p = project(simplified[i]);
      fullPath.lineTo(p.dx, p.dy);
    }

    // Clip the path to the animated progress fraction. computeMetrics
    // walks the path lazily, so we cap iterations at one metric (our
    // path is a single subpath).
    Path drawnPath;
    if (progress >= 1.0) {
      drawnPath = fullPath;
    } else if (progress <= 0.0) {
      drawnPath = Path();
    } else {
      drawnPath = Path();
      for (final metric in fullPath.computeMetrics()) {
        final extracted = metric.extractPath(0, metric.length * progress);
        drawnPath.addPath(extracted, Offset.zero);
      }
    }

    // Gold gradient stroke (matches app accent palette).
    final start = project(simplified.first);
    final end = project(simplified.last);
    final gradient = ui.Gradient.linear(
      start,
      end,
      const [Color(0xFFE9B638), Color(0xFFD4831F)],
    );
    final strokePaint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    canvas.drawPath(drawnPath, strokePaint);

    // Start marker — solid gold disc, appears once stroke leaves the
    // origin (very small progress > 0 is enough).
    if (progress > 0.02) {
      final startPaint = Paint()
        ..color = const Color(0xFFE9B638)
        ..isAntiAlias = true;
      canvas.drawCircle(start, 7, startPaint);
      canvas.drawCircle(
        start,
        7,
        Paint()
          ..color = const Color(0xFF1C1C15).withValues(alpha: 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..isAntiAlias = true,
      );
    }

    // End marker — gold ring (hollow), only when the stroke arrives.
    if (progress >= 0.98) {
      canvas.drawCircle(
        end,
        7,
        Paint()
          ..color = const Color(0xFFFAF8F4)
          ..isAntiAlias = true,
      );
      canvas.drawCircle(
        end,
        7,
        Paint()
          ..color = const Color(0xFFD4831F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..isAntiAlias = true,
      );
    }
  }

  @override
  bool shouldRepaint(covariant RoutePolylinePainter old) {
    return old.progress != progress ||
        !identical(old.simplified, simplified);
  }

  /// Douglas-Peucker simplification, then hard cap on max points.
  /// Marathon GPS streams can have 3-5k points; we want a ceiling
  /// around 500 for smooth animation + small file size.
  static List<WorkoutRoutePoint> _simplify(
    List<WorkoutRoutePoint> points,
    double epsilon,
    int maxPoints,
  ) {
    if (points.length <= 2) return List.unmodifiable(points);

    final keep = List<bool>.filled(points.length, false);
    keep[0] = true;
    keep[points.length - 1] = true;
    _dpRecurse(points, 0, points.length - 1, epsilon, keep);

    final simplified = <WorkoutRoutePoint>[];
    for (var i = 0; i < points.length; i++) {
      if (keep[i]) simplified.add(points[i]);
    }

    // If DP still left us above the cap (rare on long marathon
    // routes), uniformly down-sample.
    if (simplified.length <= maxPoints) {
      return List.unmodifiable(simplified);
    }
    final stride = simplified.length / maxPoints;
    final out = <WorkoutRoutePoint>[];
    for (var i = 0; i < maxPoints; i++) {
      out.add(simplified[(i * stride).floor()]);
    }
    if (out.last != simplified.last) out.add(simplified.last);
    return List.unmodifiable(out);
  }

  /// Iterative-ish Douglas-Peucker — recursion depth = log N which is
  /// fine for any realistic GPS stream.
  static void _dpRecurse(
    List<WorkoutRoutePoint> points,
    int start,
    int end,
    double epsilon,
    List<bool> keep,
  ) {
    if (end <= start + 1) return;
    double maxDist = 0;
    int maxIdx = start;
    final a = points[start];
    final b = points[end];
    for (var i = start + 1; i < end; i++) {
      final d = _perpendicularDistance(points[i], a, b);
      if (d > maxDist) {
        maxDist = d;
        maxIdx = i;
      }
    }
    if (maxDist > epsilon) {
      keep[maxIdx] = true;
      _dpRecurse(points, start, maxIdx, epsilon, keep);
      _dpRecurse(points, maxIdx, end, epsilon, keep);
    }
  }

  /// Perpendicular distance from `p` to the line `a→b` in lat/lng
  /// space. Treating lat/lng as Euclidean for simplification is fine
  /// at the city-block scale we render at.
  static double _perpendicularDistance(
    WorkoutRoutePoint p,
    WorkoutRoutePoint a,
    WorkoutRoutePoint b,
  ) {
    final dx = b.lng - a.lng;
    final dy = b.lat - a.lat;
    if (dx == 0 && dy == 0) {
      final ddx = p.lng - a.lng;
      final ddy = p.lat - a.lat;
      return math.sqrt(ddx * ddx + ddy * ddy);
    }
    final num = (dy * p.lng - dx * p.lat + b.lng * a.lat - b.lat * a.lng).abs();
    final denom = math.sqrt(dx * dx + dy * dy);
    return num / denom;
  }

  /// Walk the full point list once at construction to find the bounding
  /// box. Returns (minLat, maxLat, minLng, maxLng).
  static (double, double, double, double) _bbox(List<WorkoutRoutePoint> points) {
    if (points.isEmpty) return (0, 0, 0, 0);
    var minLat = points.first.lat;
    var maxLat = points.first.lat;
    var minLng = points.first.lng;
    var maxLng = points.first.lng;
    for (final p in points) {
      if (p.lat < minLat) minLat = p.lat;
      if (p.lat > maxLat) maxLat = p.lat;
      if (p.lng < minLng) minLng = p.lng;
      if (p.lng > maxLng) maxLng = p.lng;
    }
    return (minLat, maxLat, minLng, maxLng);
  }
}
