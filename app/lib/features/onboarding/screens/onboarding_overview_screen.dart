import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/gradient_scaffold.dart';
import 'package:app/core/widgets/runcore_logo.dart';
import 'package:app/features/onboarding/data/onboarding_api.dart';
import 'package:app/features/onboarding/models/onboarding_profile.dart';
import 'package:app/features/onboarding/providers/onboarding_profile_provider.dart';
import 'package:app/features/onboarding/widgets/locked_stat_field.dart';
import 'package:app/features/onboarding/widgets/onboarding_primary_button.dart';
import 'package:app/features/onboarding/widgets/pace_wheel_picker.dart';

/// Editable baseline-stats screen. Works for users with AND without
/// wearable data: prefills + locks fields when cascade data is available,
/// otherwise asks the user to fill them in.
///
/// Spec: `docs/superpowers/specs/2026-05-11-onboarding-self-reported-stats-design.md`
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
                data: (profile) => _BaselineForm(profile: profile),
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

class _BaselineForm extends ConsumerStatefulWidget {
  final OnboardingProfile profile;
  const _BaselineForm({required this.profile});

  @override
  ConsumerState<_BaselineForm> createState() => _BaselineFormState();
}

class _BaselineFormState extends ConsumerState<_BaselineForm> {
  final _kmController = TextEditingController();

  bool _kmLocked = false;
  bool _paceLocked = false;

  double? _wearableKm;
  int? _wearablePace;

  double? _km;
  int? _paceSeconds;

  bool _kmTouched = false;
  bool _paceTouched = false;

  bool _submitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    final baseline = widget.profile.baseline;

    if (baseline?.weeklyKm != null) {
      _km = baseline!.weeklyKm;
      _wearableKm = baseline.weeklyKm;
      _kmController.text = baseline.weeklyKm!
          .toStringAsFixed(1)
          .replaceAll(RegExp(r'\.0$'), '');
      _kmLocked = baseline.weeklyKmSource == 'apple_health';
      _kmTouched = baseline.weeklyKmSource == 'self_reported';
    }

    if (baseline?.easyPaceSecondsPerKm != null && baseline?.easyPaceSource != null) {
      _paceSeconds = baseline!.easyPaceSecondsPerKm;
      _wearablePace = baseline.easyPaceSecondsPerKm;
      _paceLocked = baseline.easyPaceSource == 'apple_health';
      _paceTouched = baseline.easyPaceSource == 'self_reported';
    }
  }

  @override
  void dispose() {
    _kmController.dispose();
    super.dispose();
  }

  bool get _canContinue {
    final kmReady = _kmLocked || (_km != null && _km! >= 1);
    final paceReady = _paceLocked || _paceTouched;
    return kmReady && paceReady && !_submitting;
  }

  Future<void> _openPaceWheel() async {
    final picked = await showPaceWheelPicker(
      context,
      initialSecondsPerKm: _paceSeconds ?? 360,
    );
    if (picked != null && mounted) {
      setState(() {
        _paceSeconds = picked;
        _paceTouched = true;
      });
    }
  }

  void _unlockKm() {
    setState(() {
      _kmLocked = false;
      _kmTouched = false;
    });
  }

  void _unlockPace() {
    setState(() {
      _paceLocked = false;
      _paceTouched = false;
    });
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _submitError = null;
    });

    final save = ref.read(saveSelfReportedStatsCallProvider);
    final weeklyKm = _kmLocked ? null : (_kmTouched ? _km : null);
    final easyPace = _paceLocked ? null : (_paceTouched ? _paceSeconds : null);

    try {
      await save(weeklyKm: weeklyKm, easyPaceSecondsPerKm: easyPace);
      if (!mounted) return;
      context.push('/onboarding/form');
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitError = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String get _paceText {
    if (_paceSeconds == null) return 'Tap to choose';
    final m = _paceSeconds! ~/ 60;
    final s = (_paceSeconds! % 60).toString().padLeft(2, '0');
    return '$m:$s /km';
  }

  @override
  Widget build(BuildContext context) {
    final hasAnyPrefill = _wearableKm != null || _wearablePace != null;
    final title = hasAnyPrefill ? 'Your running baseline' : 'Tell us about your running';
    final subtitle = hasAnyPrefill
        ? 'We use these to calibrate your training plan.'
        : 'We need two numbers to build an accurate plan.';

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
                  Text(title, style: RunCoreText.serifTitle(size: 30)),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 28),

                  _kmLocked
                      ? LockedStatField(
                          label: 'Average weekly km (last 4 weeks)',
                          valueText: _km == null
                              ? '—'
                              : '${_km!.toStringAsFixed(1).replaceAll(RegExp(r"\.0$"), "")} km',
                          sourceLabel: 'Apple Health',
                          locked: true,
                          onUnlock: _unlockKm,
                          onTapWhenUnlocked: () {},
                        )
                      : _KmEditField(
                          controller: _kmController,
                          sourceLabel: _wearableKm != null ? 'Apple Health' : null,
                          touched: _kmTouched,
                          onChanged: (text) {
                            final parsed = double.tryParse(text.replaceAll(',', '.'));
                            setState(() {
                              _km = parsed;
                              _kmTouched = parsed != null && parsed >= 1;
                            });
                          },
                        ),

                  const SizedBox(height: 24),

                  LockedStatField(
                    label: 'Easy run pace',
                    valueText: _paceLocked
                        ? _paceText
                        : (_paceTouched ? _paceText : 'Tap to choose'),
                    sourceLabel: _wearablePace != null ? 'Apple Health' : null,
                    locked: _paceLocked,
                    onUnlock: _unlockPace,
                    onTapWhenUnlocked: _openPaceWheel,
                  ),

                  if (_submitError != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _submitError!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: CupertinoColors.systemRed,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          OnboardingPrimaryButton(
            label: _submitting ? 'Saving…' : 'Continue',
            onTap: _canContinue ? _submit : null,
          ),
        ],
      ),
    );
  }
}

class _KmEditField extends StatelessWidget {
  final TextEditingController controller;
  final String? sourceLabel;
  final bool touched;
  final ValueChanged<String> onChanged;

  const _KmEditField({
    required this.controller,
    required this.sourceLabel,
    required this.touched,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Average weekly km (last 4 weeks)',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.inkMuted,
          ),
        ),
        const SizedBox(height: 6),
        CupertinoTextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: onChanged,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryInk,
          ),
          placeholder: '0',
          placeholderStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.inkMuted.withValues(alpha: 0.5),
          ),
          suffix: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              'km',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.inkMuted,
              ),
            ),
          ),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.inputBorder),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          sourceLabel != null
              ? (touched ? 'Edited by you' : 'From $sourceLabel')
              : 'Required',
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted),
        ),
      ],
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
            'Loading your baseline…',
            textAlign: TextAlign.center,
            style: RunCoreText.serifTitle(size: 24),
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
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "We couldn't load your data.",
            style: RunCoreText.serifTitle(size: 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.inkMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OnboardingPrimaryButton(label: 'Retry', onTap: onRetry),
          const SizedBox(height: 8),
          CupertinoButton(
            onPressed: onSkip,
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }
}
