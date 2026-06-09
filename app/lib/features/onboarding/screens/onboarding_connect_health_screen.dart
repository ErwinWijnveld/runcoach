import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app/core/i18n/build_context_l10n.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/gradient_scaffold.dart';
import 'package:app/core/widgets/runboost_logo.dart';
import 'package:app/core/widgets/runcore_logo.dart';
import 'package:app/features/auth/models/derived_zones.dart';
import 'package:app/features/auth/providers/auth_provider.dart';
import 'package:app/features/onboarding/providers/onboarding_derived_zones_provider.dart';
import 'package:app/features/onboarding/widgets/onboarding_primary_button.dart';
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
  bool _showEmpty = false;
  int _synced = 0;

  /// Live progress for the chunked upload, surfaced as "X / Y" while syncing
  /// so a large history doesn't look stuck. 0 total = not yet known.
  int _syncProgress = 0;
  int _syncTotal = 0;

  Future<void> _connectAndSync() async {
    // Double-tap / re-entrancy guard. The button is hidden when not idle
    // but a frame-perfect double-tap before setState lands could fire twice.
    if (_stage != _Stage.idle) return;

    setState(() {
      _stage = _Stage.requestingPermission;
      _error = null;
      _showEmpty = false;
    });

    final hk = ref.read(healthKitServiceProvider);

    // The boolean from requestPermissions is unreliable on iOS — it returns
    // false even when the user grants workouts but denies HR (per the
    // docstring on requestPermissions). We fire it to surface the system
    // prompt the first time and ignore the result. The genuine "user
    // denied workouts" case shows up downstream as `workouts.isEmpty` and
    // is handled by the empty-history state.
    try {
      await hk.requestPermissions();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.idle;
        _error = context.l10n.onbConnectHealthErrorPermission;
      });
      return;
    }

    setState(() => _stage = _Stage.syncing);

    // Pull workouts + PRs in parallel — independent HealthKit code paths.
    final List<Map<String, dynamic>> workouts;
    final Map<String, Map<String, dynamic>?> prs;
    try {
      final results = await Future.wait([
        // Onboarding only needs run metrics for the fitness profile — NOT GPS
        // routes (those feed the shareable run-card and are backfilled lazily
        // afterwards). Stripping routes keeps each activity ~500 bytes so even
        // a thousand-run history syncs in a handful of small batches without
        // tripping the server's body-size limit.
        hk.fetchWorkouts(includeRoutes: false),
        hk.fetchPersonalRecords(distancesMeters: const [5000, 10000, 21097, 42195]),
      ]);
      workouts = results[0] as List<Map<String, dynamic>>;
      prs = results[1] as Map<String, Map<String, dynamic>?>;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.idle;
        _error = context.l10n.onbConnectHealthErrorRead;
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

    // Push activities in route-free batches. Each row is ~500 bytes so the
    // backend's 200/req cap is the only limit that matters — a thousand-run
    // history is just a few round-trips. Each chunk gets up to 3 attempts with
    // a small backoff so a single transient blip doesn't bail the whole
    // onboarding. Progress is surfaced live via `_syncProgress / _syncTotal`.
    final api = ref.read(wearableApiProvider);
    const chunkSize = kWearableIngestChunkSize;
    if (mounted) {
      setState(() {
        _syncTotal = workouts.length;
        _syncProgress = 0;
      });
    }
    try {
      for (var i = 0; i < workouts.length; i += chunkSize) {
        final end =
            (i + chunkSize < workouts.length) ? i + chunkSize : workouts.length;
        final chunk = workouts.sublist(i, end);
        await _withRetry(() => api.ingest({'activities': chunk}));
        if (mounted) {
          setState(() => _syncProgress = end);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.idle;
        _error = context.l10n.onbConnectHealthErrorSync;
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

    // Derive HR zones from the freshly-ingested data. Best-effort:
    // age + restingHR may both be null (denied permission, not set in
    // Health) — backend handles all combinations gracefully. Failures
    // here MUST NOT block the rest of onboarding; we route to /zones
    // either way. The /zones screen handles the "no age available"
    // case by prompting the user on mount.
    DerivedZones? derivedZones;
    try {
      final dob = await hk.getBirthDate();
      final restingHr = await hk.getLatestRestingHeartRate();
      derivedZones = await ref.read(authProvider.notifier).deriveHeartRateZones(
            dateOfBirth: dob,
            restingHeartRate: restingHr,
          );
    } catch (e) {
      // ignore: avoid_print
      print('[Onboarding] HR-zone derive failed (non-blocking): $e');
    }

    // Brief moment so the user sees "Synced N runs" before we move on.
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    // Stash the derive result so the zones screen (now two steps away)
    // can still source-aware its subtitle without a re-fetch.
    ref.read(onboardingDerivedZonesProvider.notifier).set(derivedZones);
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
        _error = context.l10n.onbConnectHealthErrorSettings;
      });
    }
  }

  void _skipToOverview() {
    context.go('/onboarding/overview');
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
          return _EmptyHistoryBody(
            onContinue: _skipToOverview,
            onOpenSettings: _openSettings,
            onTryAgain: _connectAndSync,
          );
        }
        return _IntroBody(
          error: _error,
          onConnect: _connectAndSync,
          onSkip: _skipToOverview,
        );
      case _Stage.requestingPermission:
        return _StatusBody(
          title: context.l10n.onbConnectHealthStageRequesting,
          subtitle: context.l10n.onbConnectHealthStageRequestingSub,
        );
      case _Stage.syncing:
        return _StatusBody(
          title: context.l10n.onbConnectHealthStageSyncing,
          subtitle: _syncTotal > 0
              ? context.l10n.onbConnectHealthStageSyncingProgress(
                  _syncProgress,
                  _syncTotal,
                )
              : context.l10n.onbConnectHealthStageSyncingSub,
        );
      case _Stage.done:
        return _StatusBody(
          title: context.l10n.onbConnectHealthStageDone(_synced),
          subtitle: context.l10n.onbConnectHealthStageDoneSub,
          done: true,
        );
    }
  }
}

enum _Stage { idle, requestingPermission, syncing, done }

class _IntroBody extends StatelessWidget {
  final String? error;
  final VoidCallback onConnect;
  final VoidCallback onSkip;
  const _IntroBody({
    required this.error,
    required this.onConnect,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        RunBoostHeading(l10n.onbConnectHealthIntroTitle, size: 30, maxLines: 2),
        const SizedBox(height: 6),
        Text(
          l10n.onbConnectHealthIntroBody,
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
        OnboardingPrimaryButton(
          label: l10n.onbConnectHealthConnectCta,
          onTap: onConnect,
        ),
        const SizedBox(height: 8),
        CupertinoButton(
          onPressed: onSkip,
          child: Text(
            l10n.onbConnectHealthSkipCta,
            style: GoogleFonts.inter(color: AppColors.inkMuted, fontSize: 14),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.onbConnectHealthFooter,
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
  final VoidCallback onOpenSettings;
  final VoidCallback onTryAgain;
  const _EmptyHistoryBody({
    required this.onContinue,
    required this.onOpenSettings,
    required this.onTryAgain,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        RunBoostHeading(l10n.onbConnectHealthEmptyTitle, size: 26, maxLines: 2),
        const SizedBox(height: 8),
        Text(
          l10n.onbConnectHealthEmptyBody,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: AppColors.inkMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.onbConnectHealthEmptyHint,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.inkMuted,
            height: 1.4,
          ),
        ),
        const Spacer(),
        OnboardingPrimaryButton(
          label: l10n.commonOpenSettings,
          onTap: onOpenSettings,
        ),
        const SizedBox(height: 8),
        CupertinoButton(
          onPressed: onTryAgain,
          child: Text(
            l10n.commonTryAgain,
            style: GoogleFonts.inter(color: AppColors.inkMuted),
          ),
        ),
        const SizedBox(height: 4),
        CupertinoButton(
          onPressed: onContinue,
          child: Text(
            l10n.onbConnectHealthSkipCta,
            style: GoogleFonts.inter(color: AppColors.inkMuted, fontSize: 14),
          ),
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
          RunBoostHeading(
            title,
            size: 22,
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
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
