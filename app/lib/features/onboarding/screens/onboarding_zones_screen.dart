import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/i18n/build_context_l10n.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/birth_date_picker.dart';
import 'package:app/core/widgets/gradient_scaffold.dart';
import 'package:app/core/widgets/heart_rate_zones_sheet.dart';
import 'package:app/core/widgets/hr_zones_readonly_list.dart';
import 'package:app/core/widgets/runcore_logo.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/features/auth/models/derived_zones.dart';
import 'package:app/features/auth/models/user.dart';
import 'package:app/features/auth/providers/auth_provider.dart';
import 'package:app/features/onboarding/providers/onboarding_derived_zones_provider.dart';
import 'package:app/features/onboarding/widgets/onboarding_primary_button.dart';
import 'package:app/features/wearable/data/wearable_api.dart';

/// Onboarding step that shows the runner the auto-derived HR zones.
/// Renders one of three state bodies based on data shape:
///
///   - **HR-confirmed**: full bpm table + rich subtitle. Triggered when
///     source is `manual`/`derived_empirical` OR `derived_age` with an
///     upward-correction from real high-effort observations.
///   - **DOB-known**: big tappable DOB row + collapsed "Show zones
///     (advanced)" link. Triggered when DOB is set but no HR signal.
///   - **No-DOB**: DOB-picker prompt that auto-opens on first frame.
///     Continue disabled until DOB is picked.
///
/// Reads its initial `DerivedZones` from `onboardingDerivedZonesProvider`
/// (set by connect-health after the initial derive call). Null on
/// deep-link / cold-start — subtitle copy degrades to generic in that case.
class OnboardingZonesScreen extends ConsumerStatefulWidget {
  const OnboardingZonesScreen({super.key});

  @override
  ConsumerState<OnboardingZonesScreen> createState() =>
      _OnboardingZonesScreenState();
}

class _OnboardingZonesScreenState
    extends ConsumerState<OnboardingZonesScreen> {
  DerivedZones? _result;
  bool _didAutoPrompt = false;

  @override
  void initState() {
    super.initState();
    _result = ref.read(onboardingDerivedZonesProvider);
    SchedulerBinding.instance.addPostFrameCallback((_) => _maybeAutoOpenPicker());
  }

  /// State C only: auto-open the DOB picker once on mount so the runner
  /// doesn't have to find the tap target on a screen they've never seen.
  /// Cancel = stay in state C with CTA disabled. No loop (`_didAutoPrompt`).
  Future<void> _maybeAutoOpenPicker() async {
    if (!mounted || _didAutoPrompt) return;
    final user = ref.read(authProvider).value;
    if (user == null) return; // auth still loading; re-eval after listen.
    if (user.dateOfBirth != null) return;
    final source = _result?.source ?? user.heartRateZonesSource ?? 'default';
    if (source != 'default') return;

    _didAutoPrompt = true;
    await _pickDob();
  }

  Future<void> _pickDob() async {
    final user = ref.read(authProvider).value;
    if (user == null || !mounted) return;

    final dob = await showBirthDatePickerSheet(
      context,
      initial: user.dateOfBirth,
    );
    if (dob == null || !mounted) return;

    try {
      // Re-fetch resting HR while we're at it — the connect-health pull may
      // have worked even if DOB didn't, so it's worth a second try here.
      final hk = ref.read(healthKitServiceProvider);
      final restingHr = await hk.getLatestRestingHeartRate();
      final result = await ref.read(authProvider.notifier).deriveHeartRateZones(
            dateOfBirth: dob,
            restingHeartRate: restingHr,
          );
      if (!mounted) return;
      setState(() => _result = result);
    } catch (_) {
      // Network blip — runner can retry by tapping DOB again.
    }
  }

  void _continue() => context.go('/onboarding/form');

  Future<void> _openEditSheet() async {
    await showHeartRateZonesSheet(context);
    // After the sheet pops, source may have flipped to 'manual' — our cached
    // result is stale. Drop it so subtitle reads off the freshly-loaded
    // user.heartRateZonesSource instead.
    if (mounted) setState(() => _result = null);
  }

  @override
  Widget build(BuildContext context) {
    // Re-evaluate auto-prompt when auth resolves on cold-launch.
    ref.listen<AsyncValue<User?>>(authProvider, (prev, next) {
      if (next.value != null && !_didAutoPrompt) {
        SchedulerBinding.instance.addPostFrameCallback(
          (_) => _maybeAutoOpenPicker(),
        );
      }
    });

    final user = ref.watch(authProvider).value;
    final source = _result?.source ?? user?.heartRateZonesSource ?? 'default';
    final dob = user?.dateOfBirth;
    final zones = user?.heartRateZones;

    final hasHrSignal = source == 'manual'
        || source == 'derived_empirical'
        || (source == 'derived_age' && (_result?.wasCorrected ?? false));

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
                child: _selectBody(
                  hasHrSignal: hasHrSignal,
                  zones: zones,
                  dob: dob,
                  source: source,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectBody({
    required bool hasHrSignal,
    required List<dynamic>? zones,
    required DateTime? dob,
    required String source,
  }) {
    if (hasHrSignal && zones != null) {
      return _HrConfirmedBody(
        zones: zones,
        source: source,
        result: _result,
        onContinue: _continue,
        onEdit: _openEditSheet,
      );
    }
    if (dob != null) {
      return _DobKnownBody(
        dob: dob,
        zones: zones,
        onPickDob: _pickDob,
        onContinue: _continue,
        onEdit: _openEditSheet,
      );
    }
    return _NoDobBody(onPickDob: _pickDob);
  }
}

class _HrConfirmedBody extends StatelessWidget {
  final List<dynamic> zones;
  final String source;
  final DerivedZones? result;
  final VoidCallback onContinue;
  final Future<void> Function() onEdit;

  const _HrConfirmedBody({
    required this.zones,
    required this.source,
    required this.result,
    required this.onContinue,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(l10n.onbZonesTitle, style: RunCoreText.serifTitle(size: 30)),
        const SizedBox(height: 8),
        Text(
          _subtitle(l10n, source, result),
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.inkMuted,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 20),
        HrZonesReadonlyList(zones: List.from(zones)),
        const Spacer(),
        OnboardingPrimaryButton(label: l10n.onbZonesConfirmCta, onTap: onContinue),
        const SizedBox(height: 8),
        CupertinoButton(
          onPressed: onEdit,
          child: Text(
            l10n.commonEditZones,
            style: GoogleFonts.inter(color: AppColors.inkMuted, fontSize: 14),
          ),
        ),
      ],
    );
  }

  String _subtitle(AppLocalizations l10n, String source, DerivedZones? r) {
    switch (source) {
      // 'derived_empirical' is legacy — old rows from the v0 deriver. The
      // current deriver always returns 'derived_age' (Tanaka prior, with
      // optional upward correction). Treat both the same.
      case 'derived_age':
      case 'derived_empirical':
        final age = r?.age;
        final maxHr = r?.maxHr;
        if ((r?.wasCorrected ?? false) && maxHr != null) {
          return l10n.onbZonesSubtitleDerivedCorrected(maxHr);
        }
        if (age != null && maxHr != null) {
          return l10n.onbZonesSubtitleDerivedBasic(age, maxHr);
        }
        return l10n.onbZonesSubtitleDerivedGeneric;
      case 'manual':
        return l10n.onbZonesSubtitleManual;
      default:
        return l10n.onbZonesSubtitleDefault;
    }
  }
}

class _DobKnownBody extends StatefulWidget {
  final DateTime dob;
  final List<dynamic>? zones;
  final Future<void> Function() onPickDob;
  final VoidCallback onContinue;
  final Future<void> Function() onEdit;

  const _DobKnownBody({
    required this.dob,
    required this.zones,
    required this.onPickDob,
    required this.onContinue,
    required this.onEdit,
  });

  @override
  State<_DobKnownBody> createState() => _DobKnownBodyState();
}

class _DobKnownBodyState extends State<_DobKnownBody> {
  bool _expanded = false;

  String _formatDob(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(l10n.onbZonesTitle, style: RunCoreText.serifTitle(size: 30)),
        const SizedBox(height: 8),
        Text(
          l10n.onbZonesDobBody,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.inkMuted,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: widget.onPickDob,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.onbZonesDobLabel,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDob(widget.dob),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryInk,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(CupertinoIcons.chevron_right, size: 18, color: AppColors.inkMuted),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Icon(
                _expanded ? CupertinoIcons.chevron_down : CupertinoIcons.chevron_right,
                size: 14,
                color: AppColors.inkMuted,
              ),
              const SizedBox(width: 6),
              Text(
                l10n.onbZonesShowAdvanced,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
        if (_expanded && widget.zones != null) ...[
          const SizedBox(height: 12),
          HrZonesReadonlyList(zones: List.from(widget.zones!)),
          const SizedBox(height: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: widget.onEdit,
            child: Text(
              l10n.commonEditZones,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.inkMuted),
            ),
          ),
        ],
        const Spacer(),
        OnboardingPrimaryButton(label: l10n.commonContinue, onTap: widget.onContinue),
      ],
    );
  }
}

class _NoDobBody extends StatelessWidget {
  final Future<void> Function() onPickDob;

  const _NoDobBody({required this.onPickDob});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(l10n.onbZonesTitle, style: RunCoreText.serifTitle(size: 30)),
        const SizedBox(height: 8),
        Text(
          l10n.onbZonesNoDobBody,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.inkMuted,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: onPickDob,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.onbZonesPickDobCta,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryInk,
                    ),
                  ),
                ),
                const Icon(CupertinoIcons.chevron_right, size: 18, color: AppColors.inkMuted),
              ],
            ),
          ),
        ),
        const Spacer(),
        OnboardingPrimaryButton(label: l10n.commonContinue, onTap: null),
      ],
    );
  }
}
