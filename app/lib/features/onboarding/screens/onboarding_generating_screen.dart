import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/runcore_logo.dart';
import 'package:app/features/auth/providers/auth_provider.dart';
import 'package:app/features/onboarding/data/onboarding_api.dart';
import 'package:app/features/onboarding/models/onboarding_form_data.dart';
import 'package:app/features/onboarding/models/plan_generation.dart';
import 'package:app/features/onboarding/providers/onboarding_form_provider.dart';

const _pollInterval = Duration(seconds: 3);

/// Full-screen loader shown while the backend builds the plan. The agent
/// loop runs in the queue worker (~60-110s); we poll the latest
/// PlanGeneration row every 3s. Progress bar is a local linear animation
/// (no real per-stage signal from the backend) — purely a UX cue.
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
  String _stage = 'Analyzing your Strava history…';
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

  int _estimateSeconds(OnboardingFormData form) {
    int weeks = 6;
    if (form.targetDate != null) {
      final target = DateTime.parse(form.targetDate!);
      final diffDays = target.difference(DateTime.now()).inDays;
      weeks = ((diffDays / 7).ceil()).clamp(3, 26);
    }
    return (weeks * 10).clamp(30, 180);
  }

  void _updateStage() {
    final v = _progress.value;
    final stage = v < 0.3
        ? 'Analyzing your Strava history…'
        : v < 0.6
            ? 'Designing your weekly structure…'
            : v < 0.9
                ? 'Placing training sessions…'
                : 'Finalizing your plan…';
    if (stage != _stage) {
      setState(() => _stage = stage);
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
            "Couldn't reach the server. Check your connection.");
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
            _errorMessage = 'Lost track of the generation. Try again?');
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
            _errorMessage = result.errorMessage ?? 'Generation failed.');
      }
    } catch (_) {
      // Network blip on a poll — keep polling silently. The next tick will
      // try again in 3s; surfacing transient failures would flap.
    }
  }

  Future<void> _navigateToChat(PlanGeneration row) async {
    if (row.conversationId == null) {
      setState(() =>
          _errorMessage = 'Plan ready but conversation id missing.');
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
    context.go('/coach/chat/${row.conversationId}');
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.onboardingGradient),
        child: SafeArea(
          child: _errorMessage != null
              ? _ErrorBody(
                  message: _errorMessage!,
                  onRetry: _enqueue,
                  onBack: () => context.go('/onboarding/form'),
                )
              : _LoadingBody(
                  progress: _progress,
                  stage: _stage,
                  completed: _completed,
                ),
        ),
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  final AnimationController progress;
  final String stage;
  final bool completed;

  const _LoadingBody({
    required this.progress,
    required this.stage,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
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
          Text(
            'Building your plan',
            textAlign: TextAlign.center,
            style: RunCoreText.serifTitle(size: 36).copyWith(height: 1.1),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Text(
              stage,
              key: ValueKey(stage),
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
                ? 'Loading your plan…'
                : "Sit tight. This usually takes under a minute. You can close the app — we'll keep working in the background.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.inkMuted,
              fontStyle: FontStyle.italic,
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
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Plan generation failed',
            textAlign: TextAlign.center,
            style: RunCoreText.serifTitle(size: 28),
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
            child: const Text('Try again'),
          ),
          const SizedBox(height: 8),
          CupertinoButton(
            onPressed: onBack,
            child: Text(
              'Back to form',
              style: GoogleFonts.inter(color: AppColors.inkMuted),
            ),
          ),
        ],
      ),
    );
  }
}
