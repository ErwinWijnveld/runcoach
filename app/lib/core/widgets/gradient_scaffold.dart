import 'package:flutter/cupertino.dart';
import 'package:app/core/theme/app_theme.dart';

/// Standard scaffold with the warm cream-to-gold onboarding gradient applied
/// across the whole screen. Used as the default background for every primary
/// route so the app has a single coherent look.
class GradientScaffold extends StatelessWidget {
  final Widget child;

  const GradientScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.onboardingGradient),
        child: child,
      ),
    );
  }
}
