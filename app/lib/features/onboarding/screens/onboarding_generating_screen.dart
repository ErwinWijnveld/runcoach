import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/runcore_logo.dart';
import 'package:app/features/onboarding/data/onboarding_api.dart';
import 'package:app/features/onboarding/models/generate_plan_response.dart';
import 'package:app/features/onboarding/models/onboarding_form_data.dart';
import 'package:app/features/onboarding/providers/onboarding_form_provider.dart';

/// Full-screen loader shown while the backend builds the plan. Progress is
/// animated linearly to 95% over an estimated duration (6s per scheduled
/// week, floored at 30s); when the API returns we snap to 100% and navigate
/// to the coach chat that was pre-seeded with the proposal.
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
  final CancelToken _cancelToken = CancelToken();
  String _stage = 'Analyzing your Strava history…';
  Object? _error;
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

    WidgetsBinding.instance.addPostFrameCallback((_) => _submit());
  }

  @override
  void dispose() {
    _progress.dispose();
    if (!_cancelToken.isCancelled) {
      _cancelToken.cancel('OnboardingGeneratingScreen disposed');
    }
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

  Future<void> _submit() async {
    try {
      final form = ref.read(onboardingFormProvider.notifier);
      final payload = form.toPayload();
      final generate = ref.read(generatePlanCallProvider);

      final raw = await generate(payload);
      final response = GeneratePlanResponse.fromJson(raw);

      if (!mounted) return;

      _completed = true;
      await _progress.animateTo(1.0, duration: const Duration(milliseconds: 350));
      if (!mounted) return;

      // Small settle so the bar finishes visually.
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;

      // Reset form so returning to /onboarding starts fresh.
      form.reset();

      context.go('/coach/chat/${response.conversationId}');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return;
      if (mounted) setState(() => _error = e);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _retry() {
    setState(() {
      _error = null;
      _completed = false;
    });
    _progress.reset();
    _progress.forward();
    _submit();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.onboardingGradient),
        child: SafeArea(
          child: _error != null
              ? _ErrorBody(
                  error: _error!,
                  onRetry: _retry,
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
                : 'Sit tight. This usually takes under a minute.',
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
  final Object error;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const _ErrorBody({
    required this.error,
    required this.onRetry,
    required this.onBack,
  });

  String _message() {
    if (error is DioException) {
      final e = error as DioException;
      if (e.response?.statusCode == 422) {
        return "Something was off with your choices. Go back and double-check.";
      }
      if (e.response?.statusCode == 500) {
        return "Our coach hit a snag generating the plan. Try again?";
      }
      return "Couldn't reach the server. Check your connection.";
    }
    return error.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Plan generation failed",
            textAlign: TextAlign.center,
            style: RunCoreText.serifTitle(size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            _message(),
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
