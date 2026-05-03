import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:app/core/theme/app_theme.dart';

/// White card with a subtle gold sweep that travels continuously around the
/// rounded border — used to mark AI-generated content (e.g. coach feedback).
/// The animation runs while the widget is mounted; when the route is pushed
/// off-stack the State disposes and the AnimationController stops.
class AiGlowCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color glowColor;
  final Color backgroundColor;
  final Duration duration;

  const AiGlowCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 20,
    this.glowColor = AppColors.secondary,
    this.backgroundColor = AppColors.cardBg,
    this.duration = const Duration(seconds: 8),
  });

  @override
  State<AiGlowCard> createState() => _AiGlowCardState();
}

class _AiGlowCardState extends State<AiGlowCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: const [
            BoxShadow(color: Color(0x08000000), blurRadius: 16),
          ],
        ),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            return CustomPaint(
              foregroundPainter: _GlowBorderPainter(
                progress: _ctrl.value,
                color: widget.glowColor,
                radius: widget.borderRadius,
              ),
              child: child,
            );
          },
          child: Padding(padding: widget.padding, child: widget.child),
        ),
      ),
    );
  }
}

class _GlowBorderPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double radius;

  _GlowBorderPainter({
    required this.progress,
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(0.75),
      Radius.circular(radius - 0.75),
    );

    final fullPath = Path()..addRRect(rrect);

    // Faint continuous base so the card always reads as "AI" even between
    // sweep peaks. Very low alpha — barely visible until the sweep lights it.
    canvas.drawPath(
      fullPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = color.withValues(alpha: 0.14),
    );

    // Walk the perimeter by ARC LENGTH (not angle) so the glow has the same
    // physical width regardless of the rect's aspect ratio. A SweepGradient
    // would compress on the short sides; PathMetric.extractPath gives uniform
    // pixel-length segments along the actual outline.
    final metric = fullPath.computeMetrics().first;
    final perimeter = metric.length;

    const glowSpan = 110.0;
    const segmentCount = 14;
    const peakAlpha = 0.68;
    const segLen = glowSpan / segmentCount;

    final peaks = [
      (progress * perimeter) % perimeter,
      ((progress + 0.5) * perimeter) % perimeter,
    ];

    final pieces = <(Path, double)>[];
    for (int i = 0; i < segmentCount; i++) {
      final t = (i + 0.5) / segmentCount;
      // Triangular falloff: 1 at the centre of the glow, 0 at the edges.
      final fall = 1.0 - (t - 0.5).abs() * 2;
      final alpha = peakAlpha * fall;

      for (final peak in peaks) {
        final centerOffset = (t - 0.5) * glowSpan;
        var start = peak + centerOffset - segLen / 2;
        start = ((start % perimeter) + perimeter) % perimeter;
        final end = start + segLen;

        Path sub;
        if (end <= perimeter) {
          sub = metric.extractPath(start, end);
        } else {
          sub = metric.extractPath(start, perimeter)
            ..addPath(metric.extractPath(0, end - perimeter), Offset.zero);
        }
        pieces.add((sub, alpha));
      }
    }

    // Halo pass — draw all segments to a blur layer so the blur runs ONCE
    // during composite (24+ per-segment MaskFilter blurs would tank the
    // frame budget).
    canvas.saveLayer(
      rect.inflate(8),
      Paint()..imageFilter = ImageFilter.blur(sigmaX: 3, sigmaY: 3),
    );
    for (final (path, alpha) in pieces) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: alpha),
      );
    }
    canvas.restore();

    // Crisp inner highlight (no blur).
    for (final (path, alpha) in pieces) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GlowBorderPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.radius != radius;
}
