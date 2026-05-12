import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/i18n/build_context_l10n.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/birth_date_picker.dart';
import 'package:app/core/widgets/hr_zone_constants.dart';
import 'package:app/features/auth/models/derived_zones.dart';
import 'package:app/features/auth/models/hr_zone.dart';
import 'package:app/features/auth/providers/auth_provider.dart';
import 'package:app/features/wearable/data/wearable_api.dart';
import 'package:app/router/app_router.dart' show HidesBottomNav;

/// Strava-style HR zone editor:
///   - Max HR field at the top: editing it recomputes all zones via
///     standard 60/70/80/90 percentages.
///   - Each zone's upper boundary is an editable bpm field; the next
///     zone's lower boundary auto-syncs.
///   - Z1 lower is fixed at 0 bpm. Z5 upper is open-ended (`-1`).
Future<void> showHeartRateZonesSheet(BuildContext context) {
  return showCupertinoModalPopup<void>(
    context: context,
    builder: (_) => const HidesBottomNav(child: HeartRateZonesSheet()),
  );
}

class HeartRateZonesSheet extends ConsumerStatefulWidget {
  const HeartRateZonesSheet({super.key});

  @override
  ConsumerState<HeartRateZonesSheet> createState() =>
      _HeartRateZonesSheetState();
}

const _kZonePercentages = [0.60, 0.70, 0.80, 0.90];
const _kFallbackMaxHr = 190;

class _HeartRateZonesSheetState extends ConsumerState<HeartRateZonesSheet> {
  late final TextEditingController _maxHrController;
  // Four interior boundaries (Z1↔Z2 … Z4↔Z5). Z1 lower (0) and Z5 upper
  // (-1) are fixed and not user-editable.
  late final List<TextEditingController> _boundaryControllers;

  bool _saving = false;
  bool _recomputing = false;
  String? _error;
  String? _recomputeNotice;

  @override
  void initState() {
    super.initState();
    final zones = ref.read(authProvider).value?.heartRateZones;
    final initial = _initialBoundaries(zones);
    final maxHr = _maxHrFromBoundaries(initial);

    _maxHrController = TextEditingController(text: '$maxHr');
    _boundaryControllers = [
      for (final b in initial) TextEditingController(text: '$b'),
    ];
  }

  @override
  void dispose() {
    _maxHrController.dispose();
    for (final c in _boundaryControllers) {
      c.dispose();
    }
    super.dispose();
  }

  List<int> _initialBoundaries(List<HrZone>? zones) {
    if (zones == null || zones.length != 5) {
      return _deriveBoundaries(_kFallbackMaxHr);
    }
    return [
      zones[0].max,
      zones[1].max,
      zones[2].max,
      zones[3].max,
    ];
  }

  int _maxHrFromBoundaries(List<int> b) {
    // Z4↔Z5 boundary sits at ~90% of max HR by convention.
    return (b[3] / 0.9).round();
  }

  List<int> _deriveBoundaries(int maxHr) {
    return _kZonePercentages.map((p) => (maxHr * p).round()).toList();
  }

  void _applyMaxHr() {
    final value = int.tryParse(_maxHrController.text.trim());
    if (value == null || value < 100 || value > 250) {
      setState(() => _error = context.l10n.hrZonesErrorMaxHrRange);
      return;
    }
    final derived = _deriveBoundaries(value);
    for (var i = 0; i < derived.length; i++) {
      _boundaryControllers[i].text = '${derived[i]}';
    }
    setState(() => _error = null);
  }

  void _onBoundaryChanged(int index) {
    // PURE refresh — never mutate other boundary controllers from
    // here. Mid-typing values are transiently invalid (e.g. "171"
    // becomes "17" then "1" on backspace as the runner edits Z4↔Z5
    // from 171→175), and the previous cascading-push logic would
    // detect that "1" as ordering violations and overwrite every
    // OTHER boundary with negative numbers, destroying the runner's
    // existing zones in a single keystroke. Validation happens at
    // save time instead — see `_save`.
    final value = int.tryParse(_boundaryControllers[index].text.trim());

    // Keep the Max-HR header in sync when the top boundary moves —
    // safe even with transient values; the field is informational.
    if (value != null && index == _boundaryControllers.length - 1) {
      final inferred = (value / 0.9).round();
      _maxHrController.text = '$inferred';
    }

    // Trigger rebuild so the adjacent zone row's "lower" text reflects
    // the current edit (Z2's lower = boundaries[0], etc).
    setState(() {});
  }

  List<int> _readBoundaries() {
    return _boundaryControllers
        .map((c) => int.tryParse(c.text.trim()) ?? 0)
        .toList();
  }

  /// Pull a fresh derive from the backend (median-of-top-N over the
  /// runner's recent runs, with age + restingHR fallbacks). Overwrites
  /// every editable field in this sheet so the runner can review before
  /// hitting Save.
  ///
  /// Network failures surface inline — never throws up to the caller.
  /// The endpoint always recomputes; it overrides any prior 'manual'
  /// source (this is an explicit user action, so we trust the intent).
  Future<void> _recompute() async {
    if (_recomputing || _saving) return;
    setState(() {
      _recomputing = true;
      _error = null;
      _recomputeNotice = null;
    });

    final hk = ref.read(healthKitServiceProvider);
    DateTime? hkDob;
    int? restingHr;
    try {
      hkDob = await hk.getBirthDate();
      restingHr = await hk.getLatestRestingHeartRate();
    } catch (_) {
      // HealthKit can throw on certain permission states — keep going
      // with whatever we got.
    }

    // Always show the DOB picker so the recompute is deliberate (the
    // runner is overriding their saved zones). Prefill chain: HealthKit
    // DOB → previously stashed `user.dateOfBirth` from a manual pick →
    // null (picker defaults to 30y ago).
    final storedDob = ref.read(authProvider).value?.dateOfBirth;
    final prefill = hkDob ?? storedDob;

    if (!mounted) return;
    final dob = await showBirthDatePickerSheet(context, initial: prefill);
    if (dob == null) {
      // User cancelled — stop the recompute, don't change anything.
      if (!mounted) return;
      setState(() => _recomputing = false);
      return;
    }

    try {
      final result = await ref.read(authProvider.notifier).deriveHeartRateZones(
            dateOfBirth: dob,
            restingHeartRate: restingHr,
          );

      // Mirror the persisted zones into the editable fields so the
      // runner sees what was just saved AND can immediately tweak any
      // boundary. Save → submits whatever's in the fields; flips source
      // back to 'manual' on save (intentional — the values came from
      // the deriver but the runner just signed off on them).
      _applyZonesToFields(result.zones);
      if (!mounted) return;
      setState(() {
        _recomputing = false;
        _recomputeNotice = _noticeFor(result);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _recomputing = false;
        _error = "Couldn't recompute: $e";
      });
    }
  }

  void _applyZonesToFields(List<HrZone> zones) {
    if (zones.length != 5) return;
    _boundaryControllers[0].text = '${zones[0].max}';
    _boundaryControllers[1].text = '${zones[1].max}';
    _boundaryControllers[2].text = '${zones[2].max}';
    _boundaryControllers[3].text = '${zones[3].max}';
    final inferredMaxHr = (zones[3].max / 0.9).round();
    _maxHrController.text = '$inferredMaxHr';
  }

  String _noticeFor(DerivedZones r) {
    final l10n = context.l10n;
    switch (r.source) {
      case 'derived_age':
      case 'derived_empirical':
        final age = r.age;
        final maxHr = r.maxHr;
        if (r.wasCorrected && maxHr != null) {
          return l10n.hrZonesUpdatedCorrected(maxHr);
        }
        if (age != null && maxHr != null) {
          return l10n.hrZonesUpdatedDerivedAge(maxHr, age);
        }
        return l10n.hrZonesUpdatedGenericAge;
      default:
        return l10n.onbZonesSubtitleDefault;
    }
  }

  Future<void> _save() async {
    final b = _readBoundaries();
    for (var i = 0; i < b.length; i++) {
      if (b[i] <= 0 || b[i] >= 250) {
        setState(() => _error = context.l10n.hrZonesErrorInvalidBpm);
        return;
      }
      if (i > 0 && b[i] <= b[i - 1]) {
        setState(() => _error = context.l10n.hrZonesErrorNotAscending);
        return;
      }
    }

    final zones = <HrZone>[
      HrZone(min: 0, max: b[0]),
      HrZone(min: b[0], max: b[1]),
      HrZone(min: b[1], max: b[2]),
      HrZone(min: b[2], max: b[3]),
      HrZone(min: b[3], max: -1),
    ];

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).updateProfile(heartRateZones: zones);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = context.l10n.hrZonesErrorSaveFailed(e.toString());
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.neutral,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.inputBorder,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.hrZonesSheetTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryInk,
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  context.l10n.hrZonesSheetIntro,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppColors.inkMuted, height: 1.4),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _RecomputeRow(
                  busy: _recomputing,
                  enabled: !_saving,
                  notice: _recomputeNotice,
                  onTap: _recompute,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _MaxHrField(
                  controller: _maxHrController,
                  onApply: _applyMaxHr,
                  enabled: !_saving && !_recomputing,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _ZonesList(
                  boundaries: _readBoundaries(),
                  controllers: _boundaryControllers,
                  onChanged: _onBoundaryChanged,
                  enabled: !_saving,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: CupertinoColors.systemRed,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(14),
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Text(
                          context.l10n.commonCancel,
                          style: const TextStyle(
                            color: AppColors.primaryInk,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CupertinoButton.filled(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        borderRadius: BorderRadius.circular(14),
                        // Disable Save while a recompute is in flight so
                        // the user can't persist stale field values that
                        // are about to be overwritten by the deriver.
                        onPressed: (_saving || _recomputing) ? null : _save,
                        child: _saving
                            ? const CupertinoActivityIndicator(
                                color: CupertinoColors.white)
                            : Text(
                                context.l10n.commonSave,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaxHrField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onApply;
  final bool enabled;

  const _MaxHrField({
    required this.controller,
    required this.onApply,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.hrZonesMaxHrLabel,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryInk,
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: CupertinoTextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              enabled: enabled,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.neutral,
                borderRadius: BorderRadius.circular(8),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              onSubmitted: (_) => onApply(),
              onEditingComplete: onApply,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'bpm',
            style: TextStyle(fontSize: 13, color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _ZonesList extends StatelessWidget {
  final List<int> boundaries; // length 4
  final List<TextEditingController> controllers; // length 4
  final ValueChanged<int> onChanged;
  final bool enabled;

  const _ZonesList({
    required this.boundaries,
    required this.controllers,
    required this.onChanged,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < 5; i++) {
      final lower = i == 0 ? 0 : boundaries[i - 1];
      final isLast = i == 4;
      rows.add(_ZoneRow(
        index: i,
        lower: lower,
        upperController: isLast ? null : controllers[i],
        onChanged: () => onChanged(i),
        enabled: enabled,
      ));
      if (i < 4) {
        rows.add(Container(
          margin: const EdgeInsets.only(left: 16),
          height: 0.5,
          color: AppColors.inputBorder,
        ));
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: rows),
    );
  }
}

class _ZoneRow extends StatelessWidget {
  final int index;
  final int lower;
  final TextEditingController? upperController;
  final VoidCallback onChanged;
  final bool enabled;

  const _ZoneRow({
    required this.index,
    required this.lower,
    required this.upperController,
    required this.onChanged,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              'Z${index + 1}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.warmBrown,
              ),
            ),
          ),
          Expanded(
            child: Text(
              hrZoneNames(context.l10n)[index],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryInk,
              ),
            ),
          ),
          Text(
            '$lower',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.inkMuted,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '–',
              style: TextStyle(fontSize: 14, color: AppColors.inkMuted),
            ),
          ),
          if (upperController != null)
            SizedBox(
              width: 56,
              child: CupertinoTextField(
                controller: upperController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                enabled: enabled,
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.neutral,
                  borderRadius: BorderRadius.circular(8),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                onChanged: (_) => onChanged(),
              ),
            )
          else
            const SizedBox(
              width: 56,
              child: Center(
                child: Text(
                  '∞',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.inkMuted,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          const SizedBox(width: 6),
          Text(
            context.l10n.hrZoneBpm,
            style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}

/// Compact row that exposes the "Recompute from your runs" affordance.
/// Sits above the Max HR field — the Max HR + boundary fields are still
/// the canonical edit path; this is a one-tap escape hatch for runners
/// who'd rather have the app figure it out from their own data.
///
/// Shows three states: idle (icon + label), busy (spinner + label), and
/// post-success (subtle notice underneath: "Updated from your last 23 runs (max ~191 bpm)").
class _RecomputeRow extends StatelessWidget {
  final bool busy;
  final bool enabled;
  final String? notice;
  final VoidCallback onTap;

  const _RecomputeRow({
    required this.busy,
    required this.enabled,
    required this.notice,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          minimumSize: const Size(0, 0),
          onPressed: enabled && !busy ? onTap : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                const CupertinoActivityIndicator(radius: 8)
              else
                const Icon(
                  CupertinoIcons.arrow_2_circlepath,
                  size: 16,
                  color: AppColors.warmBrown,
                ),
              const SizedBox(width: 8),
              Text(
                busy ? context.l10n.hrZonesRecomputeBusy : context.l10n.hrZonesRecomputeCta,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryInk,
                ),
              ),
            ],
          ),
        ),
        if (notice != null) ...[
          const SizedBox(height: 6),
          Text(
            notice!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ],
    );
  }
}

