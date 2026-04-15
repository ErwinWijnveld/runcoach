import 'package:flutter/cupertino.dart';

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
  static const danger = Color(0xFFD0504E);
  static const todayHighlight = Color(0xFF8B7355);
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
