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
      // Background is the global cream → gold gradient set in
      // RunCoachApp.builder; CupertinoTheme.scaffoldBackgroundColor is
      // transparent so it shows through.
      backgroundColor: CupertinoColors.transparent,
      child: SafeArea(
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
              _SignInWithAppleButton(
                onPressed: () => context.go('/auth/apple'),
              ),
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

class _SignInWithAppleButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SignInWithAppleButton({required this.onPressed});

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
                Icons.apple,
                color: AppColors.neutral,
                size: 24,
              ),
              const SizedBox(width: 16),
              Text('SIGN IN WITH APPLE', style: RunCoreText.buttonCaps()),
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
