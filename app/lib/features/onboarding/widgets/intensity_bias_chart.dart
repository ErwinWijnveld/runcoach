import 'package:flutter/material.dart';
import 'package:app/features/onboarding/models/onboarding_form_data.dart';

const _curveTakeItEasy = <double>[
  0.28, 0.38, 0.48, 0.36, 0.55, 0.62, 0.68, 0.50, 0.72, 0.72, 0.58, 0.44,
];
const _curveStandard = <double>[
  0.30, 0.44, 0.54, 0.40, 0.65, 0.76, 0.84, 0.58, 0.90, 0.84, 0.68, 0.50,
];
const _curvePushMeHarder = <double>[
  0.34, 0.52, 0.66, 0.48, 0.80, 0.92, 1.00, 0.70, 1.00, 0.92, 0.74, 0.56,
];

List<double> _curveFor(IntensityBias bias) => switch (bias) {
      IntensityBias.takeItEasy => _curveTakeItEasy,
      IntensityBias.standard => _curveStandard,
      IntensityBias.pushMeHarder => _curvePushMeHarder,
    };

/// Decorative animated line chart showing the weekly volume "shape" of
/// the runner's plan. Tweens element-wise between three hardcoded curves
/// (350ms `easeInOutCubic`) when [bias] changes. Visual language mirrors
/// `_WeeklyVolumeChart` in `features/coach/widgets/plan_details_sheet.dart`
/// so the runner sees the same chart style they'll get post-acceptance.
class IntensityBiasChart extends StatefulWidget {
  final IntensityBias bias;
  final double height;

  const IntensityBiasChart({
    super.key,
    required this.bias,
    this.height = 130,
  });

  @override
  State<IntensityBiasChart> createState() => _IntensityBiasChartState();
}

class _IntensityBiasChartState extends State<IntensityBiasChart> {
  late List<double> _from = _curveFor(widget.bias);
  late List<double> _to = _curveFor(widget.bias);

  @override
  void didUpdateWidget(covariant IntensityBiasChart old) {
    super.didUpdateWidget(old);
    if (old.bias != widget.bias) {
      setState(() {
        _from = _to;
        _to = _curveFor(widget.bias);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(widget.bias),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
      builder: (context, t, _) {
        final values = List<double>.generate(
          _from.length,
          (i) => _from[i] + (_to[i] - _from[i]) * t,
        );
        return SizedBox(
          height: widget.height,
          width: double.infinity,
          child: CustomPaint(
            painter: _LineChartPainter(values: values),
          ),
        );
      },
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> values;

  _LineChartPainter({required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    const topPad = 6.0;
    const bottomPad = 6.0;
    final usable = size.height - topPad - bottomPad;

    final stepX = size.width / (values.length - 1);
    final coords = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = stepX * i;
      final t = values[i].clamp(0.0, 1.0);
      final y = topPad + (1 - t) * usable;
      coords.add(Offset(x, y));
    }

    final fillPath = Path()..moveTo(coords.first.dx, size.height);
    for (final p in coords) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(coords.last.dx, size.height);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x55D4A84B), Color(0x00D4A84B)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    final linePath = Path()..moveTo(coords.first.dx, coords.first.dy);
    for (final p in coords.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = const Color(0xFFC09437)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    final dotPaint = Paint()..color = const Color(0xFFC09437);
    final dotCorePaint = Paint()..color = Colors.white;
    for (final p in coords) {
      canvas.drawCircle(p, 3.5, dotPaint);
      canvas.drawCircle(p, 1.5, dotCorePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) =>
      old.values != values;
}
