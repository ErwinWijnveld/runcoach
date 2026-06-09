import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const cream = Color(0xFFFAF8F4);
  static const warmBrown = Color(0xFF8B7355);
  static const darkBrown = Color(0xFF5C4D3C);
  static const lightTan = Color(0xFFF5F0E8);
  static const gold = Color(0xFFD4A84B);
  static const cardBg = Color(0xFFFFF9F0);
  static const textPrimary = Color(0xFF2D2D2D);
  static const textSecondary = Color(0xFF888888);
  static const success = Color(0xFF4CAF50);
  static const danger = Color(0xFF8F3A3A);
  static const dangerBg = Color(0xFFFBE9E3);
  static const todayHighlight = Color(0xFF8B7355);

  // RunCore design system tokens (Figma)
  static const neutral = Color(0xFFFDF9ED);
  static const neutralHighlight = Color(0xFFF7F3E8);
  static const primary = Color(0xFF1A1A1A);
  // Brand "Ink" (#171206) — primary text & dark surfaces.
  static const primaryInk = Color(0xFF171206);
  static const secondary = Color(0xFFE9B638);
  static const tertiary = Color(0xFF8C7A5B);
  static const eyebrow = Color(0xFF4E4635);
  static const inkMuted = Color(0xFF817662);
  static const border = Color(0x148C7A5B);
  static const inputBorder = Color(0xFFE6DDC6);
  static const goldGlow = Color(0xFFF5E0AF);

  // RunBoost brand tokens (Brand Guidelines · Edition 01). The exact palette
  // from the brand book — used for the rebranded welcome/marketing surfaces.
  // Proportion guide: ~60% Cream / 28% Ink / 12% Gold.
  static const rbInk = Color(0xFF171206); // Primary — text & dark backgrounds
  static const rbGold = Color(0xFFE9B638); // Accent — the spark, emphasis
  static const rbCream = Color(0xFFFDF9ED); // Base — light surface
  static const rbGoldDeep = Color(0xFFC9971F); // Gold type on light backgrounds
  static const rbGoldSoft = Color(0xFFF8E4AE); // Tint — washes & fills
  static const rbStone = Color(0xFF8A7547); // Muted — captions & hairlines

  /// Off-plan ("buiten schema") run accent — a calm blue that reads as "extra,
  /// not yet linked". Parallel to the gold (`secondary` + `goldGlow`) pair.
  static const offPlan = Color(0xFF3E72C7);
  static const offPlanGlow = Color(0xFFD8E6FB);

  /// Warm cream → gold gradient used on the onboarding overview screen.
  static const onboardingGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.7, 1.0],
    colors: [
      Color(0xFFFDF9ED),
      Color(0xFFFCEFC8),
      Color(0xFFF8E4AE),
    ],
  );
}

/// RunBoost type system (Brand Guidelines · Edition 01): Inter (body, UI,
/// titles — the workhorse), Space Mono (kickers/eyebrows, technical labels),
/// Anton (reserved for hero display — applied at call sites with the −9° lean,
/// see [RunBoostText]). No serif anywhere. Method names are unchanged so every
/// existing call site keeps working; only the underlying families changed.
class RunCoreText {
  // ---- Space Mono (kickers / eyebrows / technical labels) ----

  static TextStyle eyebrow({Color color = AppColors.eyebrow}) =>
      GoogleFonts.spaceMono(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 3.6,
        color: color,
      );

  /// Tiny uppercase label like the gold "TODAY" pill.
  static TextStyle badge({Color color = const Color(0xFFFFFFFF)}) =>
      GoogleFonts.spaceMono(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: color,
      );

  /// Section eyebrow like "GOAL PROGRESSION".
  static TextStyle sectionEyebrow({Color color = const Color(0xFF785A00)}) =>
      GoogleFonts.spaceMono(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 1.32,
        color: color,
      );

  // ---- Inter (UI labels, buttons, tabs) ----

  static TextStyle buttonCaps({Color color = AppColors.neutral}) =>
      GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle tabLabel({required Color color, bool active = false}) =>
      GoogleFonts.inter(
        fontSize: 10,
        fontWeight: active ? FontWeight.w700 : FontWeight.w400,
        color: color,
      );

  // ---- Inter (titles / display — replaces the old serif) ----

  static TextStyle logo({
    Color color = AppColors.primaryInk,
    double size = 32.42,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: FontWeight.w700,
    color: color,
  );

  /// Large hero title (was serif). Pass `style: FontStyle.italic` for emphasis.
  static TextStyle serifDisplay({
    double size = 55,
    FontStyle style = FontStyle.normal,
    Color color = AppColors.primaryInk,
    double? height,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontStyle: style,
    fontWeight: FontWeight.w700,
    color: color,
    height: height,
  );

  /// Medium card title (e.g. "Threshold Intervals", "AI Coach"). Upright by
  /// default; pass `style: FontStyle.italic` for emphasis.
  static TextStyle serifTitle({
    double size = 36,
    Color color = AppColors.primaryInk,
    double? height,
    FontStyle style = FontStyle.normal,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontStyle: style,
    fontWeight: FontWeight.w700,
    color: color,
    height: height,
  );

  /// Small italic helper text (e.g. "28 days to go").
  static TextStyle italicSmall({
    double size = 14,
    Color color = AppColors.primaryInk,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.w500,
    color: color,
  );

  // ---- Inter (body, stats) ----

  /// Stat label (e.g. "DISTANCE").
  static TextStyle statLabel({Color color = AppColors.inkMuted}) =>
      GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.96,
        color: color,
      );

  /// Stat value (e.g. "8.2 km", "4:45").
  static TextStyle statValue({
    Color color = AppColors.primaryInk,
    double size = 24,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: FontWeight.w600,
    color: color,
  );

  /// Stat value suffix / muted body (e.g. "min/km").
  static TextStyle statSuffix({Color color = AppColors.inkMuted}) =>
      GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
      );

  /// Body / placeholder (e.g. "Ask your coach...").
  static TextStyle body({
    Color color = AppColors.tertiary,
    double size = 14,
    FontWeight weight = FontWeight.w500,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: weight,
    color: color,
  );
}

/// RunBoost brand typography (Brand Guidelines · Edition 01).
/// Display: Anton (uppercase, italic-lean via skew — Anton ships no true
/// italic). Detail/labels: Space Mono. Body: Inter (shared with [RunCoreText]).
class RunBoostText {
  /// The brand's signature italic lean, applied as a horizontal skew.
  static const double slantDegrees = 9;

  /// Big Anton display headline / wordmark text. UPPERCASE, tight leading.
  static TextStyle display({
    double size = 64,
    Color color = AppColors.rbInk,
    double height = 0.9,
    double letterSpacing = 0.5,
  }) => GoogleFonts.anton(
    fontSize: size,
    height: height,
    letterSpacing: letterSpacing,
    color: color,
  );

  /// Mono kicker / technical label (e.g. "YOUR AI RUNCOACH").
  static TextStyle kicker({
    double size = 12,
    Color color = AppColors.rbStone,
    double letterSpacing = 3.4,
    FontWeight weight = FontWeight.w700,
  }) => GoogleFonts.spaceMono(
    fontSize: size,
    fontWeight: weight,
    letterSpacing: letterSpacing,
    color: color,
  );
}

class AppTheme {
  static CupertinoThemeData get cupertino {
    return const CupertinoThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.warmBrown,
      primaryContrastingColor: CupertinoColors.white,
      scaffoldBackgroundColor: AppColors.cream,
      barBackgroundColor: Color(0xE6FAF8F4),
      textTheme: CupertinoTextThemeData(
        primaryColor: AppColors.textPrimary,
        textStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          letterSpacing: -0.2,
        ),
        navLargeTitleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        navTitleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        navActionTextStyle: TextStyle(
          color: AppColors.warmBrown,
          fontSize: 17,
        ),
        actionTextStyle: TextStyle(
          color: AppColors.warmBrown,
          fontSize: 17,
        ),
        tabLabelTextStyle: TextStyle(
          fontSize: 10,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}

class AppRadius {
  static const card = 16.0;
  static const chip = 8.0;
  static const pill = 12.0;
  static const button = 12.0;
}

class AppInsets {
  static const EdgeInsets screen = EdgeInsets.all(16);
  static const EdgeInsets card = EdgeInsets.all(20);
}
