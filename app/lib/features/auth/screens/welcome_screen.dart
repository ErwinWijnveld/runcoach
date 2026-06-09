import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:go_router/go_router.dart';
import 'package:app/core/i18n/build_context_l10n.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/gradient_scaffold.dart';
import 'package:app/core/widgets/intro_fx.dart';
import 'package:app/core/widgets/runboost_logo.dart';

/// RunBoost welcome / sign-in screen. Centered on the signature cream→gold
/// gradient: the eyebrow, the Anton logo lockup, the Anton slogan (with one
/// gold hit-block word), and the Sign in with Apple CTA. Brand: Guidelines ·
/// Edition 01 — Anton / Inter / Space Mono, no serif.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              const IntroFx(child: _Branding()),
              const Spacer(flex: 2),
              const IntroFx(
                delay: Duration(milliseconds: 90),
                child: _Slogan(),
              ),
              const Spacer(flex: 3),
              IntroFx(
                delay: const Duration(milliseconds: 180),
                child: _SignInWithAppleButton(
                  label: context.l10n.authWelcomeSignInButton,
                  onPressed: () => context.go('/auth/apple'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _Branding extends StatelessWidget {
  const _Branding();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          context.l10n.authWelcomeEyebrow,
          style: RunBoostText.kicker(),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        const RunBoostWordmark(height: 50),
      ],
    );
  }
}

/// The Anton slogan, centered and leaned. Renders three stacked lines —
/// "TRAIN", "SMARTER," (in the gold hit-block), "NOT HARDER" — sourced from the
/// two headline strings. Line 1 is split into its first word + the rest so the
/// hit-block lands on the right word without hardcoding the copy.
class _Slogan extends StatelessWidget {
  const _Slogan();

  static const double _size = 46;

  @override
  Widget build(BuildContext context) {
    final line1 = context.l10n.authWelcomeHeadlineLine1.trim();
    final line2 = context.l10n.authWelcomeHeadlineLine2.trim();

    final words = line1.split(RegExp(r'\s+'));
    final lead = words.first;
    final accent = words.length > 1 ? words.sublist(1).join(' ') : null;

    return Center(
      child: Transform(
        alignment: Alignment.center,
        transform: kRunBoostLean,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (accent == null)
              _hit(lead)
            else ...[
              _line(lead),
              _hit(accent),
            ],
            _line(line2),
          ],
        ),
      ),
    );
  }

  // Even leading splits the line-box slack equally above/below the glyphs, so
  // the gold block sits centered on the caps instead of hanging low (Anton's
  // default proportional leading + the comma's descender push it down).
  static const TextHeightBehavior _evenLeading = TextHeightBehavior(
    leadingDistribution: TextLeadingDistribution.even,
  );

  Widget _line(String text) => Text(
        text.toUpperCase(),
        textAlign: TextAlign.center,
        textHeightBehavior: _evenLeading,
        style: RunBoostText.display(
          size: _size,
          color: AppColors.rbInk,
          height: 1.0,
        ),
      );

  Widget _hit(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        color: AppColors.rbGold,
        child: Text(
          text.toUpperCase(),
          textAlign: TextAlign.center,
          textHeightBehavior: _evenLeading,
          style: RunBoostText.display(
            size: _size,
            color: AppColors.rbInk,
            height: 1.0,
          ),
        ),
      );
}

class _SignInWithAppleButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _SignInWithAppleButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: onPressed,
      color: AppColors.rbInk,
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 21),
      minimumSize: Size.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.apple, color: AppColors.rbCream, size: 24),
              const SizedBox(width: 14),
              Text(
                label,
                style: RunCoreText.buttonCaps(color: AppColors.rbCream),
              ),
            ],
          ),
          const Icon(Icons.arrow_forward, color: AppColors.rbCream, size: 22),
        ],
      ),
    );
  }
}
