import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/i18n/build_context_l10n.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/gradient_scaffold.dart';
import 'package:app/core/widgets/runboost_logo.dart';
import 'package:app/core/widgets/runcore_logo.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/features/auth/providers/auth_provider.dart';
import 'package:app/features/onboarding/data/onboarding_api.dart';
import 'package:app/features/onboarding/models/onboarding_form_data.dart';
import 'package:app/features/onboarding/models/plan_generation.dart';
import 'package:app/features/onboarding/providers/onboarding_form_provider.dart';
import 'package:app/features/subscriptions/providers/pro_entitlement_provider.dart';

const _pollInterval = Duration(seconds: 2);

/// Full-screen loader shown while the backend builds the plan. The
/// deterministic builder takes ~20ms; the OnboardingAgent's friendly
/// reply takes 4-6s; an optional AdjustOnboardingPlan call (when
/// additional_notes warrant injury / preference tweaks) adds another
/// ~8s. We poll the latest PlanGeneration row every 2s. Progress bar
/// is a local linear animation (no real per-stage signal from the
/// backend) — purely a UX cue.
///
/// Resume safety: if the user closes the app mid-generation and reopens
/// later, the router redirect spots `user.pendingPlanGeneration` and routes
/// them back here. On mount we adopt the existing row (no duplicate
/// dispatch) and continue polling. If generation completed while they were
/// gone, the very first poll navigates straight to the chat.
class OnboardingGeneratingScreen extends ConsumerStatefulWidget {
  const OnboardingGeneratingScreen({super.key});

  @override
  ConsumerState<OnboardingGeneratingScreen> createState() =>
      _OnboardingGeneratingScreenState();
}

class _OnboardingGeneratingScreenState
    extends ConsumerState<OnboardingGeneratingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress;
  Timer? _pollTimer;
  // Key into the 4-stage table looked up in [_LoadingBody]. 0..3 maps to
  // analyzing / structuring / placing / finalizing.
  int _stageIndex = 0;
  String? _errorMessage;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    final form = ref.read(onboardingFormProvider);
    final estimated = _estimateSeconds(form);

    _progress = AnimationController(
      vsync: this,
      duration: Duration(seconds: estimated),
      upperBound: 0.95,
    );
    _progress.addListener(_updateStage);
    _progress.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _progress.dispose();
    super.dispose();
  }

  /// Estimated wall-clock for plan generation. Drives the progress bar's
  /// fill speed only — the bar caps at 95% and animates to 100% on
  /// completion regardless of estimate. Slight overestimate is safer
  /// than under (under = bar sits at 95% looking stuck).
  ///
  /// Measured on local-dev queue worker:
  ///   • plain build (no notes)        : 5-6s
  ///   • build + adjust (notes present): 12-14s
  ///
  /// Plan length doesn't materially affect runtime — the deterministic
  /// builder runs in ~20ms regardless of weeks. The variance is the AI
  /// turn (Sonnet inference + optional second tool call).
  int _estimateSeconds(OnboardingFormData form) {
    final hasNotes = (form.additionalNotes ?? form.notes ?? '').trim().isNotEmpty;
    return hasNotes ? 16 : 8;
  }

  void _updateStage() {
    final v = _progress.value;
    final idx = v < 0.3
        ? 0
        : v < 0.6
            ? 1
            : v < 0.9
                ? 2
                : 3;
    if (idx != _stageIndex) {
      setState(() => _stageIndex = idx);
    }
  }

  /// Decide whether to enqueue a new generation or adopt an in-flight one
  /// the server already knows about. Then start polling.
  Future<void> _bootstrap() async {
    final pending = ref.read(authProvider).value?.pendingPlanGeneration;

    if (pending != null && pending.status != PlanGenerationStatus.failed) {
      // Adopting a row the server already has (user reopened mid-flight, or
      // came back after completion to view the proposal). For `completed`
      // the poll loop will navigate immediately on the first tick.
      _startPolling();
      return;
    }

    // No in-flight row (or last attempt failed) — enqueue a fresh one.
    await _enqueue();
  }

  Future<void> _enqueue() async {
    setState(() {
      _errorMessage = null;
      _completed = false;
    });
    _progress.reset();
    _progress.forward();

    try {
      final form = ref.read(onboardingFormProvider.notifier);
      final payload = form.toPayload();
      final generate = ref.read(generatePlanCallProvider);
      final result = await generate(payload);

      if (!mounted) return;

      if (result.status == PlanGenerationStatus.completed) {
        await _navigateToChat(result);
        return;
      }

      _startPolling();
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage =
            context.l10n.onbGeneratingErrorNetwork);
      }
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    // Fire one immediately so a freshly-completed adopt path navigates fast.
    _poll();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  Future<void> _poll() async {
    if (!mounted) return;
    try {
      final poll = ref.read(pollPlanGenerationCallProvider);
      final result = await poll();

      if (!mounted) return;

      if (result == null) {
        // Server says nothing pending — but we're on the loading screen,
        // so something went wrong (row deleted, user hopped accounts, etc).
        setState(() =>
            _errorMessage = context.l10n.onbGeneratingErrorLost);
        _pollTimer?.cancel();
        return;
      }

      if (result.status == PlanGenerationStatus.completed) {
        _pollTimer?.cancel();
        await _navigateToChat(result);
        return;
      }

      if (result.status == PlanGenerationStatus.failed) {
        _pollTimer?.cancel();
        setState(() =>
            _errorMessage = result.errorMessage ?? context.l10n.onbGeneratingErrorGeneric);
      }
    } catch (_) {
      // Network blip on a poll — keep polling silently. The next tick will
      // try again in 3s; surfacing transient failures would flap.
    }
  }

  Future<void> _navigateToChat(PlanGeneration row) async {
    if (row.conversationId == null) {
      setState(() =>
          _errorMessage = context.l10n.onbGeneratingErrorMissingId);
      return;
    }

    setState(() => _completed = true);
    await _progress.animateTo(1.0, duration: const Duration(milliseconds: 350));
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    ref.read(onboardingFormProvider.notifier).reset();
    // Apply the new pending state locally — synchronously — so the router
    // redirect doesn't bounce us back to the loading screen on the next
    // navigation. Avoiding loadProfile() here also dodges the GoRouter
    // rebuild that races with context.go and triggers
    // "Duplicate GlobalKey detected" via reparenting.
    ref.read(authProvider.notifier).patchPendingPlanGeneration(row);

    if (!mounted) return;

    // Hard paywall: non-pro users land on the plan preview first. Pro users
    // (existing TestFlight users via comp + future re-onboardings) skip
    // straight to the coach. The router's redirect mirrors this rule for
    // cold-start resume.
    final isPro = ref.read(proEntitlementProvider).isPro;
    final target = isPro
        ? '/coach/chat/${row.conversationId}'
        : '/onboarding/plan-preview?conversationId=${row.conversationId}';
    context.go(target);
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: SafeArea(
        child: _errorMessage != null
            ? _ErrorBody(
                message: _errorMessage!,
                onRetry: _enqueue,
                onBack: () => context.go('/onboarding/form'),
              )
            : _LoadingBody(
                progress: _progress,
                stageIndex: _stageIndex,
                completed: _completed,
              ),
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  final AnimationController progress;
  final int stageIndex;
  final bool completed;

  const _LoadingBody({
    required this.progress,
    required this.stageIndex,
    required this.completed,
  });

  String _stageLabel(AppLocalizations l10n, int idx) {
    return switch (idx) {
      0 => l10n.onbGeneratingStageAnalyzing,
      1 => l10n.onbGeneratingStageStructuring,
      2 => l10n.onbGeneratingStagePlacing,
      _ => l10n.onbGeneratingStageFinalizing,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stage = _stageLabel(l10n, stageIndex);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
      child: Column(
        children: [
          const SizedBox(
            height: 56,
            child: Center(
              child: RunCoreLogo(starSize: 22, textSize: 22, gap: 8),
            ),
          ),
          const Spacer(),
          RunBoostHeading(
            l10n.onbGeneratingTitle,
            size: 34,
            height: 1.05,
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Text(
              stage,
              key: ValueKey(stageIndex),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.inkMuted,
              ),
            ),
          ),
          const SizedBox(height: 36),
          AnimatedBuilder(
            animation: progress,
            builder: (context, _) => _ProgressBar(value: progress.value),
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: progress,
            builder: (context, _) => Text(
              '${(progress.value * 100).round()}%',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.inkMuted,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const Spacer(),
          Text(
            completed
                ? l10n.onbGeneratingLoadingNext
                : l10n.onbGeneratingFooter,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;
  const _ProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              height: 6,
              width: constraints.maxWidth * value,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const _ErrorBody({
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RunBoostHeading(
            l10n.onbGeneratingErrorTitle,
            size: 26,
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppColors.inkMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          CupertinoButton.filled(
            onPressed: onRetry,
            child: Text(l10n.commonTryAgain),
          ),
          const SizedBox(height: 8),
          CupertinoButton(
            onPressed: onBack,
            child: Text(
              l10n.onbGeneratingBackCta,
              style: GoogleFonts.inter(color: AppColors.inkMuted),
            ),
          ),
        ],
      ),
    );
  }
}
