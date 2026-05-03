import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

const Duration _introDuration = Duration(milliseconds: 320);
const Curve _introCurve = Curves.easeOutCubic;
const double _introOffsetY = 0.04;
const Duration _introStagger = Duration(milliseconds: 60);

/// Tasteful Apple-style entry: short fade + tiny upward slide, gentle
/// ease-out. Honors the system Reduce Motion setting (renders the child
/// at its final state immediately). Animations always END at the visible
/// rest state, so an interrupted run can never leave the child hidden.
class IntroFx extends StatelessWidget {
  final Widget child;
  final Duration delay;

  const IntroFx({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;
    return child
        .animate(delay: delay)
        .fadeIn(duration: _introDuration, curve: _introCurve)
        .slideY(
          begin: _introOffsetY,
          end: 0,
          duration: _introDuration,
          curve: _introCurve,
        );
  }
}

/// Vertical stack with a staggered Apple-style intro on each child.
/// Use on tab roots and detail-screen content scaffolds.
class IntroColumn extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  final Duration interval;
  final Duration startDelay;

  const IntroColumn({
    super.key,
    required this.children,
    this.spacing = 0,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.interval = _introStagger,
    this.startDelay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final widgets = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0 && spacing > 0) {
        widgets.add(SizedBox(height: spacing));
      }
      final child = children[i];
      widgets.add(
        reduceMotion
            ? child
            : child
                .animate(delay: startDelay + interval * i)
                .fadeIn(duration: _introDuration, curve: _introCurve)
                .slideY(
                  begin: _introOffsetY,
                  end: 0,
                  duration: _introDuration,
                  curve: _introCurve,
                ),
      );
    }
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: widgets,
    );
  }
}
