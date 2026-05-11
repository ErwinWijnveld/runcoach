import 'package:flutter/material.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/onboarding/models/onboarding_form_data.dart';

const _curveTakeItEasy = <double>[
  0.30, 0.40, 0.50, 0.38, 0.55, 0.62, 0.68, 0.52, 0.72, 0.72, 0.58, 0.42, 0.22,
];
const _curveStandard = <double>[
  0.35, 0.48, 0.58, 0.42, 0.68, 0.78, 0.85, 0.60, 0.88, 0.82, 0.66, 0.46, 0.24,
];
const _curvePushMeHarder = <double>[
  0.40, 0.55, 0.68, 0.50, 0.80, 0.92, 1.00, 0.72, 1.00, 0.90, 0.72, 0.50, 0.26,
];

List<double> _curveFor(IntensityBias bias) => switch (bias) {
      IntensityBias.takeItEasy => _curveTakeItEasy,
      IntensityBias.standard => _curveStandard,
      IntensityBias.pushMeHarder => _curvePushMeHarder,
    };

/// Decorative animated bar curve showing the runner's weekly volume
/// progression. Bars tween element-wise (350ms `easeInOutCubic`) when
/// [bias] changes. Values are illustrative — no real plan computation.
/// The last bar is rendered in `AppColors.gold` to represent race day;
/// the rest in `AppColors.warmBrown`.
class IntensityBiasChart extends StatefulWidget {
  final IntensityBias bias;
  final double height;

  const IntensityBiasChart({
    super.key,
    required this.bias,
    this.height = 140,
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
        return CustomPaint(
          size: Size.fromHeight(widget.height),
          painter: _BarsPainter(values: values),
        );
      },
    );
  }
}

class _BarsPainter extends CustomPainter {
  final List<double> values;

  _BarsPainter({required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const gap = 4.0;
    final barWidth = (size.width - gap * (values.length - 1)) / values.length;
    final lastIdx = values.length - 1;

    final buildPaint = Paint()..color = AppColors.warmBrown;
    final racePaint = Paint()..color = AppColors.gold;

    for (var i = 0; i < values.length; i++) {
      final h = (values[i].clamp(0.0, 1.0)) * size.height;
      final x = i * (barWidth + gap);
      final y = size.height - h;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, h),
        const Radius.circular(3),
      );
      canvas.drawRRect(rect, i == lastIdx ? racePaint : buildPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarsPainter oldDelegate) =>
      oldDelegate.values != values;
}
