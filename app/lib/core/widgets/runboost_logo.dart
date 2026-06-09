import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:app/core/theme/app_theme.dart';

/// The brand's signature forward lean (CSS `skewX(-9deg)` → x += tan(-9°)·y;
/// Matrix4.skewX applies the tan() for us). Used for live Anton text (e.g. the
/// slogan); the logo SVG already has the lean baked into its outlines.
final Matrix4 kRunBoostLean = Matrix4.skewX(-0.158);

/// The RunBoost mark — the four-point "spark". Recolorable via [color].
///
/// Rendered from an inline SVG string (not an asset) so it never depends on the
/// asset manifest. The path is the official brand mark (`brandkit/04-logo-mark`).
class RunBoostSpark extends StatelessWidget {
  final double size;
  final Color color;

  const RunBoostSpark({super.key, this.size = 48, this.color = AppColors.rbGold});

  static const String _markPath =
      'M378.394 381.551C381.022 378.803 381.016 374.792 378.784 371.419C330.402 306.172 329.769 289.287 378.463 225.675C380.989 222.399 380.78 218.178 378.144 215.439C375.508 212.699 371.56 212.6 368.325 215.138C307.465 266.105 291.269 265.499 228.536 215.261C225.294 212.944 221.549 213.056 218.921 215.804C216.294 218.553 216.198 222.458 218.532 225.725C266.912 290.973 267.444 307.963 218.851 371.47C216.326 374.956 216.434 379.072 219.07 381.811C221.706 384.551 225.755 384.755 228.989 382.006C290.762 332.409 305.743 332.174 368.779 381.883C371.92 384.305 375.766 384.299 378.394 381.551Z';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="204 203 191 192"><path d="$_markPath" fill="#E9B638"/></svg>',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

/// The official RunBoost horizontal logo lockup — gold spark + "RUNBOOST".
///
/// Rendered straight from the outlined brand SVG (`assets/icons/runboost_logo.svg`,
/// inlined below). The wordmark is OUTLINED vector paths with the brand's −9°
/// lean already baked in, so there's no font dependency, no `Transform` skew,
/// and nothing to align by hand — it just draws crisp at any [height].
///
/// Defaults to the brand fills (ink wordmark + gold spark) for light surfaces.
/// Override [wordmarkColor] / [sparkColor] for reversed/monochrome lockups
/// (e.g. cream wordmark on a dark surface) — the SVG fills are swapped inline.
class RunBoostWordmark extends StatelessWidget {
  /// Rendered height in logical pixels (width follows the 836:240 viewBox).
  final double height;

  /// Overrides the wordmark (ink) fill. Null keeps the brand ink.
  final Color? wordmarkColor;

  /// Overrides the spark (gold) fill. Null keeps the brand gold.
  final Color? sparkColor;

  const RunBoostWordmark({
    super.key,
    this.height = 54,
    this.wordmarkColor,
    this.sparkColor,
  });

  @override
  Widget build(BuildContext context) {
    var svg = _logoSvg;
    if (wordmarkColor != null) {
      svg = svg.replaceAll('#171206', _hex(wordmarkColor!));
    }
    if (sparkColor != null) {
      svg = svg.replaceAll('#E9B638', _hex(sparkColor!));
    }
    return SvgPicture.string(svg, height: height);
  }
}

/// `#RRGGBB` for the inline-SVG fill swap.
String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// A page/section heading in the brand display style — Anton, UPPERCASE, with
/// the −9° lean. Use for screen titles ("Weekly plan", "Your goals", …).
///
/// Anton sits flush to the top of its line box (far less ascent gap than the
/// old serif/Inter titles), which visually eats the space above the heading.
/// A proportional [topPadding] is baked in by default so breathing room stays
/// consistent everywhere — override per call site if a layout needs less.
class RunBoostHeading extends StatelessWidget {
  final String text;
  final double size;
  final Color color;
  final double height;
  final int? maxLines;
  final TextAlign? textAlign;

  /// Space above the caps. Defaults to ~0.5× the font size — generous breathing
  /// room above the heading (Anton's tight metrics otherwise eat the gap).
  final double? topPadding;

  const RunBoostHeading(
    this.text, {
    super.key,
    this.size = 38,
    this.color = AppColors.rbInk,
    this.height = 1.0,
    this.maxLines,
    this.textAlign,
    this.topPadding,
  });

  @override
  Widget build(BuildContext context) {
    final centered = textAlign == TextAlign.center;
    return Padding(
      padding: EdgeInsets.only(top: topPadding ?? size * 0.5),
      child: Transform(
        alignment: centered ? Alignment.center : Alignment.bottomLeft,
        transform: kRunBoostLean,
        child: Text(
          text.toUpperCase(),
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: maxLines != null ? TextOverflow.ellipsis : null,
          // Even leading centers Anton's caps within the line box, so the
          // heading aligns optically with adjacent icons/text in a Row.
          textHeightBehavior: const TextHeightBehavior(
            leadingDistribution: TextLeadingDistribution.even,
          ),
          style: RunBoostText.display(size: size, color: color, height: height),
        ),
      ),
    );
  }
}

/// The official outlined logo (verbatim from `assets/icons/runboost_logo.svg`).
/// Inlined so it renders without an asset-manifest round-trip.
const String _logoSvg = r'''
<svg width="836" height="240" viewBox="0 0 836 240" fill="none" xmlns="http://www.w3.org/2000/svg">
<g clip-path="url(#clip0_353_56)">
<path d="M178.754 204.995C181.436 202.19 181.43 198.095 179.152 194.652C129.762 128.046 129.116 110.809 178.824 45.8716C181.403 42.5274 181.189 38.2184 178.498 35.4224C175.808 32.6253 171.777 32.5242 168.475 35.1151C106.347 87.1439 89.8136 86.5253 25.7736 35.2407C22.4641 32.8754 18.6411 32.9897 15.9583 35.795C13.2766 38.6013 13.1786 42.5876 15.5612 45.9227C64.9491 112.53 65.4922 129.874 15.8868 194.704C13.3092 198.263 13.4195 202.464 16.1104 205.26C18.8013 208.058 22.9347 208.266 26.2361 205.46C89.296 154.829 104.589 154.589 168.938 205.334C172.145 207.806 176.071 207.8 178.754 204.995Z" fill="#E9B638"/>
<path d="M750.535 183.999L766.928 80.4917H751.526L755.422 55.8887H812.169L808.273 80.4917H792.87L776.476 183.999H750.535Z" fill="#171206"/>
<path d="M700.31 185.164C688.469 185.164 680.381 182.252 676.047 176.429C671.761 170.606 670.625 161.337 672.639 148.623L674.622 136.103H700.268L697.732 152.117C697.263 155.077 697.336 157.406 697.952 159.105C698.624 160.755 700.09 161.58 702.35 161.58C704.708 161.58 706.437 160.9 707.537 159.542C708.686 158.183 709.506 155.951 709.998 152.845C710.62 148.914 710.746 145.639 710.375 143.018C710.012 140.349 709.036 137.826 707.447 135.448C705.915 133.022 703.683 130.207 700.751 127.005L690.836 116.086C683.424 107.982 680.544 98.7135 682.196 88.2803C683.925 77.3618 687.798 69.0395 693.815 63.3133C699.881 57.5872 707.777 54.7241 717.506 54.7241C729.395 54.7241 737.326 57.8541 741.296 64.114C745.316 70.374 746.316 79.8852 744.294 92.6477H717.911L719.306 83.8401C719.582 82.0931 719.282 80.7344 718.404 79.7639C717.575 78.7933 716.3 78.3081 714.581 78.3081C712.517 78.3081 710.902 78.8904 709.735 80.055C708.625 81.1711 707.927 82.6269 707.643 84.4224C707.359 86.2179 707.542 88.159 708.195 90.2456C708.847 92.3323 710.407 94.7343 712.875 97.4518L725.588 111.646C728.139 114.46 730.418 117.445 732.424 120.599C734.438 123.705 735.876 127.344 736.738 131.517C737.607 135.642 737.57 140.689 736.624 146.658C734.718 158.692 730.963 168.131 725.359 174.973C719.812 181.767 711.463 185.164 700.31 185.164Z" fill="#171206"/>
<path d="M627.055 185.164C616.688 185.164 609.241 182.082 604.715 175.919C600.245 169.708 598.936 160.755 600.788 149.06L610.426 88.2075C612.163 77.2405 616.184 68.9182 622.487 63.2405C628.84 57.5629 637.249 54.7241 647.714 54.7241C658.179 54.7241 665.664 57.5629 670.17 63.2405C674.724 68.9182 676.133 77.2405 674.396 88.2075L664.758 149.06C662.905 160.755 658.736 169.708 652.249 175.919C645.82 182.082 637.421 185.164 627.055 185.164ZM631.011 161.58C634.942 161.58 637.503 157.819 638.694 150.297L648.597 87.7707C649.596 81.4623 648.18 78.3081 644.347 78.3081C640.024 78.3081 637.351 81.5351 636.329 87.9891L626.437 150.443C625.807 154.422 625.845 157.285 626.551 159.032C627.264 160.731 628.751 161.58 631.011 161.58Z" fill="#171206"/>
<path d="M553.652 185.164C543.285 185.164 535.839 182.082 531.312 175.919C526.842 169.708 525.534 160.755 527.386 149.06L537.024 88.2075C538.761 77.2405 542.781 68.9182 549.085 63.2405C555.438 57.5629 563.847 54.7241 574.312 54.7241C584.777 54.7241 592.262 57.5629 596.767 63.2405C601.321 68.9182 602.73 77.2405 600.993 88.2075L591.355 149.06C589.503 160.755 585.333 169.708 578.847 175.919C572.417 182.082 564.019 185.164 553.652 185.164ZM557.609 161.58C561.539 161.58 564.1 157.819 565.291 150.297L575.195 87.7707C576.194 81.4623 574.777 78.3081 570.945 78.3081C566.621 78.3081 563.948 81.5351 562.926 87.9891L553.035 150.443C552.404 154.422 552.442 157.285 553.148 159.032C553.862 160.731 555.349 161.58 557.609 161.58Z" fill="#171206"/>
<path d="M450.66 183.999L470.951 55.8887H506.105C515.538 55.8887 522.031 58.1694 525.582 62.7309C529.191 67.2439 530.169 74.717 528.517 85.1502L527.629 90.755C526.676 96.7724 524.798 101.649 521.996 105.386C519.242 109.122 515.537 111.573 510.882 112.738C516.498 114.193 519.862 117.615 520.974 123.001C522.143 128.339 522.117 134.866 520.895 142.581C519.58 150.88 517.645 158.134 515.089 164.346C512.533 170.557 508.919 175.385 504.246 178.831C499.573 182.276 493.429 183.999 485.814 183.999H450.66ZM488.659 104.148H493.966C496.373 104.148 498.067 103.226 499.047 101.382C500.026 99.5384 500.72 97.3304 501.127 94.7585L503.168 81.8747C503.821 77.7499 502.306 75.6875 498.621 75.6875H493.167L488.659 104.148ZM482.166 161.434C488.897 161.434 492.762 158.28 493.761 151.971L496.297 135.958C496.874 132.318 496.762 129.455 495.963 127.368C495.22 125.233 493.325 124.166 490.279 124.166H485.489L479.609 161.288C480.675 161.386 481.527 161.434 482.166 161.434Z" fill="#171206"/>
<path d="M375.489 183.999L395.78 55.8887H422.458L424.679 117.251L434.397 55.8887H459.454L439.164 183.999H413.812L410.986 119.944L400.841 183.999H375.489Z" fill="#171206"/>
<path d="M333.813 185.164C323.004 185.164 315.518 182.179 311.353 176.21C307.197 170.193 306.041 161.361 307.885 149.715L322.746 55.8887H347.95L333.251 148.696C332.913 150.831 332.709 152.893 332.64 154.883C332.578 156.824 332.889 158.425 333.574 159.687C334.258 160.949 335.583 161.58 337.549 161.58C339.563 161.58 341.108 160.973 342.185 159.76C343.269 158.498 344.067 156.873 344.579 154.883C345.139 152.893 345.589 150.831 345.927 148.696L360.626 55.8887H385.831L370.97 149.715C369.126 161.361 365.172 170.193 359.109 176.21C353.054 182.179 344.622 185.164 333.813 185.164Z" fill="#171206"/>
<path d="M232.074 183.999L252.365 55.8887H292.162C298.794 55.8887 303.567 57.393 306.481 60.4016C309.402 63.3618 311.001 67.5351 311.278 72.9215C311.612 78.2594 311.206 84.5436 310.061 91.7741C308.954 98.7619 307.161 104.343 304.683 108.516C302.253 112.689 298.43 115.576 293.214 117.178C297.161 118.003 299.692 120.017 300.806 123.219C301.977 126.374 302.163 130.474 301.363 135.521L293.685 183.999H268.112L276.056 133.847C276.647 130.11 276.226 127.805 274.793 126.932C273.415 126.01 271.007 125.549 267.568 125.549L258.311 183.999H232.074ZM271.232 103.348H277.496C281.083 103.348 283.487 99.4898 284.709 91.7741C285.501 86.7759 285.626 83.5003 285.086 81.9475C284.546 80.3946 283.195 79.6182 281.033 79.6182H274.99L271.232 103.348Z" fill="#171206"/>
</g>
<defs>
<clipPath id="clip0_353_56">
<rect width="836" height="240" fill="white"/>
</clipPath>
</defs>
</svg>
''';
