import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/birth_date_picker.dart';
import 'package:app/core/widgets/gradient_scaffold.dart';
import 'package:app/core/widgets/heart_rate_zones_sheet.dart';
import 'package:app/core/widgets/hr_zones_readonly_list.dart';
import 'package:app/core/widgets/runcore_logo.dart';
import 'package:app/features/auth/models/derived_zones.dart';
import 'package:app/features/auth/models/user.dart';
import 'package:app/features/auth/providers/auth_provider.dart';
import 'package:app/features/onboarding/widgets/onboarding_primary_button.dart';
import 'package:app/features/wearable/data/wearable_api.dart';

/// Onboarding step that shows the runner the auto-derived HR zones,
/// explains where the numbers came from, and lets them either continue or
/// open the same edit sheet they'd use later from the menu. Sits between
/// `/onboarding/connect-health` (which both ingests workouts AND fires the
/// initial derive call) and `/onboarding/overview` (4-stat cards + AI
/// narrative).
///
/// The connect-health screen passes the [DerivedZones] result through so
/// we can show source-aware copy ("based on N runs" vs "from your age")
/// without a second API round-trip.
class OnboardingZonesScreen extends ConsumerStatefulWidget {
  /// The derive result that produced the currently-saved zones. May be
  /// null if the runner navigated here via deep link without a fresh
  /// derive — in that case the screen falls back to displaying the user's
  /// stored zones with a generic subtitle.
  final DerivedZones? initialResult;

  const OnboardingZonesScreen({super.key, this.initialResult});

  @override
  ConsumerState<OnboardingZonesScreen> createState() =>
      _OnboardingZonesScreenState();
}

class _OnboardingZonesScreenState
    extends ConsumerState<OnboardingZonesScreen> {
  late DerivedZones? _result = widget.initialResult;
  bool _didPromptOnce = false;

  @override
  void initState() {
    super.initState();
    // If connect-health couldn't pull a DOB out of HealthKit, the
    // initial derive returned `default` and we landed here with empty
    // zones. Prompt the runner once so the screen shows real values
    // instead of the "couldn't compute" copy. Cancel = stay on manual
    // fallback, don't loop the dialog (`_didPromptOnce` flag).
    SchedulerBinding.instance.addPostFrameCallback((_) => _maybePromptForAge());
  }

  @override
  Widget build(BuildContext context) {
    // Cold-launch path: auth may still be loading when initState fires.
    // Re-evaluate the prompt as soon as auth resolves to a non-null user.
    ref.listen<AsyncValue<User?>>(authProvider, (prev, next) {
      if (next.value != null && !_didPromptOnce) {
        SchedulerBinding.instance.addPostFrameCallback(
          (_) => _maybePromptForAge(),
        );
      }
    });
    return _build(context);
  }

  Future<void> _maybePromptForAge() async {
    if (!mounted || _didPromptOnce) return;

    final user = ref.read(authProvider).value;
    // Auth still loading on cold-launch deep-link → don't prompt yet.
    // The screen rebuilds when auth resolves and we can re-evaluate
    // (we keep _didPromptOnce false so the next pass tries again).
    if (user == null) return;
    final source = _result?.source ?? user.heartRateZonesSource ?? 'default';
    // Only prompt when the deriver couldn't produce a value — never
    // when zones already came back from HealthKit DOB or stored
    // user.dateOfBirth.
    if (source != 'default') return;

    _didPromptOnce = true;

    final dob = await showBirthDatePickerSheet(
      context,
      initial: user.dateOfBirth,
    );
    if (dob == null || !mounted) return;

    try {
      // Re-fetch resting HR while we're at it — the connect-health
      // pull may have worked even if DOB didn't (different permission
      // toggles), so it's worth a second try here.
      final hk = ref.read(healthKitServiceProvider);
      final restingHr = await hk.getLatestRestingHeartRate();

      final result = await ref.read(authProvider.notifier).deriveHeartRateZones(
            dateOfBirth: dob,
            restingHeartRate: restingHr,
          );
      if (!mounted) return;
      setState(() => _result = result);
    } catch (_) {
      // Network blip — leave the unavailable body showing. The runner
      // can still tap "Set zones manually" or retry by reopening this
      // screen via the menu sheet.
    }
  }

  Widget _build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    final zones = user?.heartRateZones;
    final source = _result?.source ?? user?.heartRateZonesSource ?? 'default';

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
                child: zones == null
                    ? _UnavailableBody(onContinue: _continue, onEdit: _openEditSheet)
                    : _Body(
                        zones: zones,
                        source: source,
                        result: _result,
                        onContinue: _continue,
                        onEdit: _openEditSheet,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _continue() => context.go('/onboarding/overview');

  Future<void> _openEditSheet() async {
    await showHeartRateZonesSheet(context);
    // After the sheet pops, source may have flipped to 'manual' OR the
    // runner may have hit "Recompute" — either way, our cached result
    // is stale. Drop it so the subtitle reads off the freshly-loaded
    // user.heartRateZonesSource instead of an outdated derive snapshot.
    if (mounted) setState(() => _result = null);
  }
}

class _Body extends StatelessWidget {
  final List zones;
  final String source;
  final DerivedZones? result;
  final VoidCallback onContinue;
  final VoidCallback onEdit;

  const _Body({
    required this.zones,
    required this.source,
    required this.result,
    required this.onContinue,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text('Your heart rate zones', style: RunCoreText.serifTitle(size: 30)),
        const SizedBox(height: 8),
        Text(
          _subtitle(source, result),
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.inkMuted,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 20),
        HrZonesReadonlyList(zones: List.from(zones)),
        const Spacer(),
        OnboardingPrimaryButton(label: 'Looks right', onTap: onContinue),
        const SizedBox(height: 8),
        CupertinoButton(
          onPressed: onEdit,
          child: Text(
            'Edit zones',
            style: GoogleFonts.inter(color: AppColors.inkMuted, fontSize: 14),
          ),
        ),
      ],
    );
  }

  String _subtitle(String source, DerivedZones? r) {
    switch (source) {
      // 'derived_empirical' is legacy — old rows from the v0 deriver. The
      // current deriver always returns 'derived_age' (Tanaka prior, with
      // optional upward correction from real high-effort observations
      // when the runner's pushed past the formula). Treat both the same.
      case 'derived_age':
      case 'derived_empirical':
        final age = r?.age;
        final maxHr = r?.maxHr;
        if ((r?.wasCorrected ?? false) && maxHr != null) {
          return "Based on your age and your hardest recent runs, your max heart rate looks to be around $maxHr bpm. We've split that into 5 training zones.";
        }
        if (age != null && maxHr != null) {
          return "Estimated from your age ($age) — max around $maxHr bpm. After a few hard sessions or a race we'll refine these automatically.";
        }
        return 'Estimated from your age. Tap "Edit zones" if you know your true max HR.';
      case 'manual':
        return "Your previously-saved zones. They'll be used to score every run.";
      default:
        return "We couldn't compute your zones automatically — please set your max HR before continuing.";
    }
  }
}

class _UnavailableBody extends StatelessWidget {
  final VoidCallback onContinue;
  final VoidCallback onEdit;

  const _UnavailableBody({required this.onContinue, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text('Your heart rate zones', style: RunCoreText.serifTitle(size: 30)),
        const SizedBox(height: 8),
        Text(
          "We couldn't compute your zones yet. You can set them manually now or come back to it later from your profile menu.",
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.inkMuted,
            height: 1.45,
          ),
        ),
        const Spacer(),
        OnboardingPrimaryButton(label: 'Set zones manually', onTap: onEdit),
        const SizedBox(height: 8),
        CupertinoButton(
          onPressed: onContinue,
          child: Text(
            'Skip for now',
            style: GoogleFonts.inter(color: AppColors.inkMuted, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
