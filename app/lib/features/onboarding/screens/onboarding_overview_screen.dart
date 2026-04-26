import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/gradient_scaffold.dart';
import 'package:app/core/widgets/runcore_logo.dart';
import 'package:app/features/coach/widgets/stats_card_bubble.dart';
import 'package:app/features/onboarding/models/onboarding_profile.dart';
import 'package:app/features/onboarding/providers/onboarding_profile_provider.dart';

/// Step 1 of the form-based onboarding: shows the user their last 12 months
/// of running data as 4 stat cards + a one-line AI narrative, then gates
/// progress to the multi-step form via a Continue CTA.
class OnboardingOverviewScreen extends ConsumerWidget {
  const OnboardingOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(onboardingProfileControllerProvider);

    return GradientScaffold(
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(
              height: 56,
              child: Center(
                child: RunCoreLogo(starSize: 22, textSize: 22, gap: 8),
              ),
            ),
            Expanded(
              child: profileAsync.when(
                data: (profile) => _OverviewBody(profile: profile),
                loading: () => const _SyncingState(),
                error: (e, _) => _ErrorState(
                  message: e.toString(),
                  onRetry: () => ref
                      .read(onboardingProfileControllerProvider.notifier)
                      .refresh(),
                  onSkip: () => context.go('/onboarding/form'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewBody extends StatelessWidget {
  final OnboardingProfile profile;
  const _OverviewBody({required this.profile});

  @override
  Widget build(BuildContext context) {
    final metricsMap = profile.metrics == null
        ? const <String, dynamic>{}
        : <String, dynamic>{
            'weekly_avg_km': profile.metrics!.weeklyAvgKm ?? 0,
            'weekly_avg_runs': profile.metrics!.weeklyAvgRuns ?? 0,
            'avg_pace_seconds_per_km': profile.metrics!.avgPaceSecondsPerKm ?? 0,
            'session_avg_duration_seconds': profile.metrics!.sessionAvgDurationSeconds ?? 0,
          };

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    "Here's your last 12 months",
                    style: RunCoreText.serifTitle(size: 32),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "A quick snapshot from your synced runs",
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 20),
                  StatsCardBubble(
                    metrics: metricsMap,
                    tileColor: Colors.white,
                    tileAspectRatio: 16 / 9,
                  ),
                  if ((profile.narrativeSummary ?? '').isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _NarrativeQuote(text: profile.narrativeSummary!),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ContinueButton(
            onTap: () => context.push('/onboarding/form'),
          ),
        ],
      ),
    );
  }
}

class _NarrativeQuote extends StatelessWidget {
  final String text;
  const _NarrativeQuote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: RunCoreText.italicSmall(size: 15).copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ContinueButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primaryInk,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'CONTINUE',
            style: RunCoreText.buttonCaps(color: AppColors.neutral).copyWith(
              letterSpacing: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _SyncingState extends StatelessWidget {
  const _SyncingState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CupertinoActivityIndicator(radius: 16),
          const SizedBox(height: 20),
          Text(
            'Syncing your runs…',
            textAlign: TextAlign.center,
            style: RunCoreText.serifTitle(size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            'This usually takes a few seconds.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onSkip;
  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Couldn't load your profile",
            textAlign: TextAlign.center,
            style: RunCoreText.serifTitle(size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: 20),
          CupertinoButton.filled(
            onPressed: onRetry,
            child: const Text('Try again'),
          ),
          const SizedBox(height: 8),
          CupertinoButton(
            onPressed: onSkip,
            child: Text(
              'Skip for now',
              style: GoogleFonts.inter(color: AppColors.inkMuted),
            ),
          ),
        ],
      ),
    );
  }
}
