import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/gradient_scaffold.dart';
import 'package:app/core/widgets/runcore_logo.dart';
import 'package:app/features/wearable/data/wearable_api.dart';

/// Asks the user to grant Apple Health read access, then pulls the last
/// 12 months of running workouts and pushes them to the backend before
/// continuing into the onboarding overview screen.
///
/// Failure-mode policy: the user must NEVER get permanently stuck on this
/// screen. Every error path leaves them with at least one of: retry,
/// open-settings, or skip-to-form (when there's no data to sync).
class OnboardingConnectHealthScreen extends ConsumerStatefulWidget {
  const OnboardingConnectHealthScreen({super.key});

  @override
  ConsumerState<OnboardingConnectHealthScreen> createState() =>
      _OnboardingConnectHealthScreenState();
}

class _OnboardingConnectHealthScreenState
    extends ConsumerState<OnboardingConnectHealthScreen> {
  _Stage _stage = _Stage.idle;
  String? _error;
  bool _permissionDenied = false;
  bool _showEmpty = false;
  int _synced = 0;

  Future<void> _connectAndSync() async {
    // Double-tap / re-entrancy guard. The button is hidden when not idle
    // but a frame-perfect double-tap before setState lands could fire twice.
    if (_stage != _Stage.idle) return;

    setState(() {
      _stage = _Stage.requestingPermission;
      _error = null;
      _permissionDenied = false;
      _showEmpty = false;
    });

    final hk = ref.read(healthKitServiceProvider);

    final bool granted;
    try {
      granted = await hk.requestPermissions();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.idle;
        _error = "Couldn't reach Apple Health. Try again?";
      });
      return;
    }

    if (!granted) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.idle;
        _permissionDenied = true;
        _error = "Apple Health permission was denied. Open Settings → Health → Data Access & Devices → RunCoach to enable read access, then come back.";
      });
      return;
    }

    setState(() => _stage = _Stage.syncing);

    // Pull workouts + PRs in parallel — independent HealthKit code paths.
    final List<Map<String, dynamic>> workouts;
    final Map<String, Map<String, dynamic>?> prs;
    try {
      final results = await Future.wait([
        hk.fetchWorkouts(),
        hk.fetchPersonalRecords(distancesMeters: const [5000, 10000, 21097, 42195]),
      ]);
      workouts = results[0] as List<Map<String, dynamic>>;
      prs = results[1] as Map<String, Map<String, dynamic>?>;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.idle;
        _error = "Couldn't read your runs from Apple Health. Try again?";
      });
      return;
    }

    if (workouts.isEmpty) {
      // New iPhone / no run history. Don't try to ingest nothing — show a
      // dedicated empty state with an explicit "Continue anyway" CTA so
      // the user can complete onboarding manually.
      if (!mounted) return;
      setState(() {
        _stage = _Stage.idle;
        _showEmpty = true;
      });
      return;
    }

    // Push activities. Backend cap is 200/req; chunk at 200 to minimize
    // round-trips. Each chunk gets up to 3 attempts with a small backoff
    // so a single transient blip doesn't bail the whole onboarding.
    final api = ref.read(wearableApiProvider);
    const chunkSize = 200;
    try {
      for (var i = 0; i < workouts.length; i += chunkSize) {
        final end =
            (i + chunkSize < workouts.length) ? i + chunkSize : workouts.length;
        final chunk = workouts.sublist(i, end);
        await _withRetry(() => api.ingest({'activities': chunk}));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.idle;
        _error = "We couldn't sync your runs to the server. Check your connection and try again.";
      });
      return;
    }

    // PRs are best-effort — a failure here doesn't justify discarding the
    // successful activity sync above. The form's `personalRecordForDistance`
    // provider can fetch any specific distance on demand later.
    final nonNullPrs = <String, Map<String, dynamic>>{};
    prs.forEach((k, v) {
      if (v != null) nonNullPrs[k] = v;
    });
    if (nonNullPrs.isNotEmpty) {
      try {
        await _withRetry(() => api.ingestPersonalRecords({'records': nonNullPrs}));
      } catch (_) {
        // ignore: avoid_print
        print('[Onboarding] PR ingest failed — continuing without prefetched PRs');
      }
    }

    if (!mounted) return;
    setState(() {
      _synced = workouts.length;
      _stage = _Stage.done;
    });

    // Brief moment so the user sees "Synced N runs" before we move on.
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    context.go('/onboarding/overview');
  }

  /// Retry [op] up to 3 times with 1s/2s backoff. Surfaces the final error.
  Future<T> _withRetry<T>(Future<T> Function() op) async {
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        return await op();
      } catch (e) {
        lastError = e;
        if (attempt < 2) {
          await Future.delayed(Duration(seconds: attempt + 1));
        }
      }
    }
    throw lastError!;
  }

  Future<void> _openSettings() async {
    try {
      await openAppSettings();
    } catch (_) {
      // Some devices/jailbroken envs disallow settings deep-linking. Best
      // we can do is surface the error; the user can navigate manually.
      if (!mounted) return;
      setState(() {
        _error = "Couldn't open Settings automatically. Go to Settings → Health → Data Access & Devices → RunCoach.";
      });
    }
  }

  void _skipToForm() {
    context.go('/onboarding/form');
  }

  @override
  Widget build(BuildContext context) {
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: _body(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    switch (_stage) {
      case _Stage.idle:
        if (_showEmpty) {
          return _EmptyHistoryBody(onContinue: _skipToForm);
        }
        return _IntroBody(
          error: _error,
          permissionDenied: _permissionDenied,
          onConnect: _connectAndSync,
          onOpenSettings: _openSettings,
          onSkip: _skipToForm,
        );
      case _Stage.requestingPermission:
        return const _StatusBody(
          title: 'Asking Apple Health…',
          subtitle: 'Tap "Allow" on the system prompt.',
        );
      case _Stage.syncing:
        return const _StatusBody(
          title: 'Pulling your runs…',
          subtitle: 'Reading the last 12 months from Apple Health.',
        );
      case _Stage.done:
        return _StatusBody(
          title: 'Synced $_synced runs',
          subtitle: 'Building your profile…',
          done: true,
        );
    }
  }
}

enum _Stage { idle, requestingPermission, syncing, done }

class _IntroBody extends StatelessWidget {
  final String? error;
  final bool permissionDenied;
  final VoidCallback onConnect;
  final VoidCallback onOpenSettings;
  final VoidCallback onSkip;
  const _IntroBody({
    required this.error,
    required this.permissionDenied,
    required this.onConnect,
    required this.onOpenSettings,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(
          'Connect Apple Health',
          style: RunCoreText.serifTitle(size: 32),
        ),
        const SizedBox(height: 6),
        Text(
          'We read your running workouts and heart-rate data so we can score your training and adapt your plan.',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: AppColors.inkMuted,
          ),
        ),
        const SizedBox(height: 24),
        if (error != null)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              error!,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.danger,
              ),
            ),
          ),
        const Spacer(),
        if (permissionDenied) ...[
          CupertinoButton.filled(
            onPressed: onOpenSettings,
            child: const Text('Open Settings'),
          ),
          const SizedBox(height: 8),
          CupertinoButton(
            onPressed: onConnect,
            child: Text(
              'Try again',
              style: GoogleFonts.inter(color: AppColors.inkMuted),
            ),
          ),
        ] else ...[
          CupertinoButton.filled(
            onPressed: onConnect,
            child: const Text('Connect Apple Health'),
          ),
        ],
        const SizedBox(height: 8),
        CupertinoButton(
          onPressed: onSkip,
          child: Text(
            'Continue without syncing',
            style: GoogleFonts.inter(color: AppColors.inkMuted, fontSize: 14),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Garmin, Polar and Strava are coming soon.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.inkMuted,
          ),
        ),
      ],
    );
  }
}

class _EmptyHistoryBody extends StatelessWidget {
  final VoidCallback onContinue;
  const _EmptyHistoryBody({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(
          "We didn't find any runs",
          style: RunCoreText.serifTitle(size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          "Apple Health doesn't show any running workouts in the last 12 months — that's fine, we'll start your plan from scratch.",
          style: GoogleFonts.inter(
            fontSize: 15,
            color: AppColors.inkMuted,
            height: 1.4,
          ),
        ),
        const Spacer(),
        CupertinoButton.filled(
          onPressed: onContinue,
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

class _StatusBody extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool done;
  const _StatusBody({
    required this.title,
    required this.subtitle,
    this.done = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (done)
            const Icon(CupertinoIcons.checkmark_circle_fill,
                size: 44, color: Color(0xFF34C759))
          else
            const AppSpinner(),
          const SizedBox(height: 20),
          Text(title, style: RunCoreText.serifTitle(size: 24)),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}
