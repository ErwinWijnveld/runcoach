import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/theme/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              const Icon(
                Icons.directions_run,
                size: 80,
                color: AppColors.warmBrown,
              ),
              const SizedBox(height: 24),
              Text(
                'RunCoach',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBrown,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your AI-powered running coach',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/auth/strava'),
                  icon: const Icon(Icons.link),
                  label: const Text('Connect with Strava'),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We use Strava to read your running data\nand create personalized training plans.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
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
