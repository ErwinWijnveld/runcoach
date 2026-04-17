import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Animated RunCore logo star — spins fast, decelerates, pauses briefly,
/// then repeats. Used as the universal "coach is working" spinner in
/// chat thinking cards and loading modals.
class SwooshingStar extends StatefulWidget {
  final double size;

  const SwooshingStar({super.key, this.size = 16});

  @override
  State<SwooshingStar> createState() => _SwooshingStarState();
}

class _SwooshingStarState extends State<SwooshingStar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    _rotation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 2 * math.pi)
            .chain(CurveTween(curve: Curves.easeOutExpo)),
        weight: 90,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(2 * math.pi),
        weight: 10,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotation,
      child: SvgPicture.asset(
        'assets/icons/coach_prompt_star.svg',
        width: widget.size,
        height: widget.size,
      ),
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotation.value,
          child: child,
        );
      },
    );
  }
}
