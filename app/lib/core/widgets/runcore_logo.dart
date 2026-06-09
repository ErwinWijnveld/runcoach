import 'package:flutter/cupertino.dart';

import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/runboost_logo.dart';

/// Compatibility shims that keep the old `RunCore*` names but render the
/// RunBoost brand mark + lockup. Existing call sites (header, onboarding, share
/// card) pass `starSize`/`textSize`/`gap`/colors; we map those onto the
/// outlined RunBoost logo so nothing view-side needs to change.
class RunCoreStar extends StatelessWidget {
  final double size;
  final Color? color;

  const RunCoreStar({super.key, this.size = 32, this.color});

  @override
  Widget build(BuildContext context) {
    return RunBoostSpark(size: size, color: color ?? AppColors.rbGold);
  }
}

class RunCoreLogo extends StatelessWidget {
  final double starSize;
  final double textSize;
  final double gap;
  final Color? starColor;
  final Color textColor;

  const RunCoreLogo({
    super.key,
    this.starSize = 30.8,
    this.textSize = 32.42,
    this.gap = 12.97,
    this.starColor,
    this.textColor = AppColors.rbInk,
  });

  @override
  Widget build(BuildContext context) {
    // The outlined logo's "RUNBOOST" cap height is ~130 of its 240 viewBox, so
    // scale the whole lockup to land the wordmark cap height near `textSize`.
    return RunBoostWordmark(
      height: textSize * (240 / 130),
      wordmarkColor: textColor,
      sparkColor: starColor,
    );
  }
}
