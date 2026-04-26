import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/gradient_scaffold.dart';
import 'package:app/core/widgets/runcore_logo.dart';
import 'package:app/features/wearable/data/wearable_api.dart';

/// Asks the user to grant Apple Health read access, then pulls the last
/// 12 months of running workouts and pushes them to the backend before
/// continuing into the onboarding overview screen.
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
  int _synced = 0;

  Future<void> _connectAndSync() async {
    setState(() {
      _stage = _Stage.requestingPermission;
      _error = null;
    });

    try {
      final hk = ref.read(healthKitServiceProvider);
      final granted = await hk.requestPermissions();
      if (!granted) {
        setState(() {
          _stage = _Stage.idle;
          _error = "Apple Health permission was denied. Open Settings → Health → RunCoach to enable read access.";
        });
        return;
      }

      setState(() => _stage = _Stage.syncing);

      // Run the workout pull and the all-time PR query in parallel — they
      // hit independent HealthKit code paths and the PR query is fast
      // (native HKSampleQuery with limit:1 sort by duration). Prefetch the
      // standard race distances so the form has them ready without a
      // device round-trip; custom distances ("Other → 26km") are looked up
      // on demand from the form via personalRecordForDistanceProvider.
      final results = await Future.wait([
        hk.fetchWorkouts(),
        hk.fetchPersonalRecords(distancesMeters: const [5000, 10000, 21097, 42195]),
      ]);
      final workouts = results[0] as List<Map<String, dynamic>>;
      final prs = results[1] as Map<String, Map<String, dynamic>?>;

      // Backend caps each ingest call at 200 activities. Heavy runners
      // (>4 runs/wk for a year) blow past that easily, so chunk client-side.
      const chunkSize = 100;
      final api = ref.read(wearableApiProvider);
      for (var i = 0; i < workouts.length; i += chunkSize) {
        final end =
            (i + chunkSize < workouts.length) ? i + chunkSize : workouts.length;
        final chunk = workouts.sublist(i, end);
        await api.ingest({'activities': chunk});
      }

      // Push PRs in a separate call so they're stored on the user record
      // independently of the activity rows. Drop null entries so the
      // backend doesn't have to defend against them in validation.
      final nonNullPrs = <String, Map<String, dynamic>>{};
      prs.forEach((k, v) {
        if (v != null) nonNullPrs[k] = v;
      });
      if (nonNullPrs.isNotEmpty) {
        await api.ingestPersonalRecords({'records': nonNullPrs});
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.idle;
        _error = e.toString();
      });
    }
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
        return _IntroBody(
          error: _error,
          onConnect: _connectAndSync,
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
  final VoidCallback onConnect;
  const _IntroBody({required this.error, required this.onConnect});

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
        CupertinoButton.filled(
          onPressed: onConnect,
          child: const Text('Connect Apple Health'),
        ),
        const SizedBox(height: 12),
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
