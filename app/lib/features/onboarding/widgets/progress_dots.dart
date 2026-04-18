import 'package:flutter/cupertino.dart';
import 'package:app/core/theme/app_theme.dart';

/// Horizontal row of small dots showing progress through a stepped form.
/// Current step is filled gold; past steps are filled dark; future steps
/// are a muted outline.
class ProgressDots extends StatelessWidget {
  final int total;
  final int current; // zero-based

  const ProgressDots({super.key, required this.total, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(total, (i) {
        final color = i < current
            ? AppColors.primaryInk
            : (i == current ? AppColors.secondary : AppColors.border);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Container(
            width: i == current ? 24 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}
