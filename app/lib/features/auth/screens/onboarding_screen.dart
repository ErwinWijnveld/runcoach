import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/features/auth/providers/auth_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  String? _coachStyle;
  bool _loading = false;

  Future<void> _complete() async {
    if (_coachStyle == null) return;

    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).completeOnboarding(
            coachStyle: _coachStyle!,
          );
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        await showAppAlert(
          context,
          title: 'Something went wrong',
          message: '$e',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.cream,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              const Text(
                'Choose your\ncoach style',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkBrown,
                  letterSpacing: -0.5,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'We\u2019ll determine your level and capacity from your Strava data.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              _CoachStyleCard(
                icon: CupertinoIcons.flame_fill,
                title: 'Motivational',
                description:
                    'Encouraging and positive. Celebrates your wins and pushes you through tough days.',
                selected: _coachStyle == 'motivational',
                onTap: () => setState(() => _coachStyle = 'motivational'),
              ),
              const SizedBox(height: 12),
              _CoachStyleCard(
                icon: CupertinoIcons.chart_bar_alt_fill,
                title: 'Analytical',
                description:
                    'Data-driven and precise. Focuses on numbers, pace zones, and optimal training load.',
                selected: _coachStyle == 'analytical',
                onTap: () => setState(() => _coachStyle = 'analytical'),
              ),
              const SizedBox(height: 12),
              _CoachStyleCard(
                icon: CupertinoIcons.equal_circle,
                title: 'Balanced',
                description:
                    'Best of both worlds. Mixes encouragement with data insights.',
                selected: _coachStyle == 'balanced',
                onTap: () => setState(() => _coachStyle = 'balanced'),
              ),
              const Spacer(),
              AppFilledButton(
                label: 'Start Training',
                loading: _loading,
                onPressed: _coachStyle != null ? _complete : null,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoachStyleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _CoachStyleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.warmBrown : AppColors.cardBg,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: selected ? AppColors.warmBrown : AppColors.lightTan,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 28,
              color: selected ? CupertinoColors.white : AppColors.warmBrown,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? CupertinoColors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: selected
                          ? CupertinoColors.white.withValues(alpha: 0.85)
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                CupertinoIcons.check_mark_circled_solid,
                color: CupertinoColors.white,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
