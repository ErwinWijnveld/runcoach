import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app/core/theme/app_theme.dart';

class RunCoreStar extends StatelessWidget {
  final double size;
  final Color? color;

  const RunCoreStar({super.key, this.size = 32, this.color});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/runcore_star.svg',
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );
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
    this.textColor = const Color(0xFF000000),
  });

  @override
  Widget build(BuildContext context) {
    // The Figma vector is 19×20 (slightly taller than wide). Match aspect ratio
    // so the star doesn't get distorted next to the text.
    final starHeight = starSize * (20 / 19);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: starSize,
          height: starHeight,
          child: SvgPicture.asset(
            'assets/icons/runcore_star.svg',
            fit: BoxFit.contain,
            colorFilter: starColor != null
                ? ColorFilter.mode(starColor!, BlendMode.srcIn)
                : null,
          ),
        ),
        SizedBox(width: gap),
        Text(
          'RunCore',
          style: RunCoreText.logo(color: textColor, size: textSize),
        ),
      ],
    );
  }
}
