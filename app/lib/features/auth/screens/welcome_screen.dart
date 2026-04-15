import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_widgets.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.cream,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              const Icon(
                CupertinoIcons.flame_fill,
                size: 80,
                color: AppColors.warmBrown,
              ),
              const SizedBox(height: 24),
              const Text(
                'RunCoach',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkBrown,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your AI-powered running coach',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(flex: 3),
              AppFilledButton(
                label: 'Connect with Strava',
                icon: CupertinoIcons.link,
                onPressed: () => context.go('/auth/strava'),
              ),
              const SizedBox(height: 12),
              const Text(
                'We use Strava to read your running data\nand create personalized training plans.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
