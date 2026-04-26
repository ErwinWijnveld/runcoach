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
  static const todayHighlight = Color(0xFF8B7355);

  // RunCore design system tokens (Figma)
  static const neutral = Color(0xFFFDF9ED);
  static const neutralHighlight = Color(0xFFF7F3E8);
  static const primary = Color(0xFF1A1A1A);
  static const primaryInk = Color(0xFF1C1C15);
  static const secondary = Color(0xFFE9B638);
  static const tertiary = Color(0xFF8C7A5B);
  static const eyebrow = Color(0xFF4E4635);
  static const inkMuted = Color(0xFF817662);
  static const border = Color(0x148C7A5B);
  static const inputBorder = Color(0xFFE6DDC6);
  static const goldGlow = Color(0xFFF5E0AF);

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

/// Three-font design system: EB Garamond (display/serif), Space Grotesk
/// (UI labels, badges, button caps), Inter (body, stat numbers).
class RunCoreText {
  // ---- Space Grotesk ----

  static TextStyle eyebrow({Color color = AppColors.eyebrow}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 3.6,
        color: color,
      );

  /// Tiny uppercase label like the gold "TODAY" pill.
  static TextStyle badge({Color color = const Color(0xFFFFFFFF)}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: color,
      );

  /// Section eyebrow like "GOAL PROGRESSION".
  static TextStyle sectionEyebrow({Color color = const Color(0xFF785A00)}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.32,
        color: color,
      );

  static TextStyle buttonCaps({Color color = AppColors.neutral}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle tabLabel({required Color color, bool active = false}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 10,
        fontWeight: active ? FontWeight.w700 : FontWeight.w400,
        color: color,
      );

  // ---- EB Garamond ----

  static TextStyle logo({
    Color color = const Color(0xFF000000),
    double size = 32.42,
  }) => GoogleFonts.ebGaramond(
    fontSize: size,
    fontWeight: FontWeight.w500,
    color: color,
  );

  /// Large hero serif (welcome page).
  static TextStyle serifDisplay({
    double size = 55,
    FontStyle style = FontStyle.normal,
    Color color = AppColors.primaryInk,
    double? height,
  }) => GoogleFonts.ebGaramond(
    fontSize: size,
    fontStyle: style,
    fontWeight: FontWeight.w400,
    color: color,
    height: height,
  );

  /// Medium-italic card title (e.g. "Threshold Intervals", "AI Coach").
  static TextStyle serifTitle({
    double size = 36,
    Color color = AppColors.primaryInk,
    double? height,
  }) => GoogleFonts.ebGaramond(
    fontSize: size,
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.w500,
    color: color,
    height: height,
  );

  /// Small italic helper text (e.g. "28 days to go").
  static TextStyle italicSmall({
    double size = 14,
    Color color = AppColors.primaryInk,
  }) => GoogleFonts.ebGaramond(
    fontSize: size,
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.w500,
    color: color,
  );

  // ---- Inter ----

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

class AppTheme {
  static CupertinoThemeData get cupertino {
    return const CupertinoThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.warmBrown,
      primaryContrastingColor: CupertinoColors.white,
      // Transparent so the global gradient set in CupertinoApp.builder
      // (see app.dart) shows through every CupertinoPageScaffold without
      // needing a per-screen wrapper. Individual screens that NEED an
      // opaque surface (modals, cards) still set their own backgrounds.
      scaffoldBackgroundColor: CupertinoColors.transparent,
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
