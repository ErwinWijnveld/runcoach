import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/compliance_colors.dart';

/// Circular compliance ring with the percentage rendered in the centre.
/// Shared between the coach-analysis card on the day detail screen and the
/// hero in the training result screen — keep the visual identical.
class ComplianceRing extends StatelessWidget {
  final double score01;
  final double size;
  final double strokeWidth;
  final TextStyle? textStyle;

  const ComplianceRing({
    super.key,
    required this.score01,
    this.size = 64,
    this.strokeWidth = 5,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = score01.clamp(0.0, 1.0);
    final pct = (clamped * 100).round();
    final color = ComplianceColors.forScore01(clamped);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: clamped,
          color: color,
          strokeWidth: strokeWidth,
        ),
        child: Center(
          child: Text(
            '$pct%',
            style: textStyle ??
                GoogleFonts.ebGaramond(
                  fontSize: size * 0.28,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset(strokeWidth / 2, strokeWidth / 2) &
        Size(size.width - strokeWidth, size.height - strokeWidth);
    final track = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final value = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, track);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      value,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}
