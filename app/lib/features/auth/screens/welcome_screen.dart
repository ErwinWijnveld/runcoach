import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:go_router/go_router.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/runcore_logo.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.neutral,
      child: Stack(
        children: [
          const _BackgroundGlow(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 48,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Branding(),
                  const SizedBox(height: 72),
                  const _Headline(),
                  const SizedBox(height: 72),
                  _ConnectStravaButton(
                    onPressed: () => context.go('/auth/strava'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundGlow extends StatelessWidget {
  const _BackgroundGlow();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Stack(
        children: [
          _GlowBlob(
            left: -60,
            top: -80,
            size: 340,
            alpha: 0.55,
          ),
          _GlowBlob(
            right: -120,
            top: 220,
            size: 360,
            alpha: 0.4,
          ),
          _GlowBlob(
            right: -90,
            bottom: -120,
            size: 420,
            alpha: 0.5,
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final double size;
  final double alpha;

  const _GlowBlob({
    this.left,
    this.top,
    this.right,
    this.bottom,
    required this.size,
    required this.alpha,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              AppColors.goldGlow.withValues(alpha: alpha),
              AppColors.goldGlow.withValues(alpha: 0.0),
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
          'YOUR AI RUNCOACH',
          style: RunCoreText.eyebrow(),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        const RunCoreLogo(),
      ],
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Train Smarter,',
          style: RunCoreText.serifDisplay(size: 55, height: 56 / 55),
          textAlign: TextAlign.center,
        ),
        Text(
          'Not Harder',
          style: RunCoreText.serifDisplay(
            size: 55,
            style: FontStyle.italic,
            height: 56 / 55,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ConnectStravaButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ConnectStravaButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: onPressed,
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
      minimumSize: Size.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.directions_run,
                color: AppColors.neutral,
                size: 24,
              ),
              const SizedBox(width: 16),
              Text('CONNECT TO STRAVA', style: RunCoreText.buttonCaps()),
            ],
          ),
          const Icon(
            Icons.arrow_forward,
            color: AppColors.neutral,
            size: 24,
          ),
        ],
      ),
    );
  }
}
