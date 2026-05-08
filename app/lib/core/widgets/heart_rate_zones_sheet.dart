import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme/app_theme.dart';
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

const _kZoneNames = ['Endurance', 'Moderate', 'Tempo', 'Threshold', 'Anaerobic'];
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
      setState(() => _error = 'Max HR must be between 100 and 250 bpm.');
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
    int? hkAge;
    int? restingHr;
    try {
      hkAge = await hk.getAge();
      restingHr = await hk.getLatestRestingHeartRate();
    } catch (_) {
      // HealthKit can throw on certain permission states — keep going
      // with whatever we got.
    }

    // Always prompt the runner to confirm/edit their age before
    // recomputing — even when we have a value from HealthKit or stored
    // birth_year. The prefill avoids retyping; the prompt makes the
    // recompute deliberate (the user is overriding their saved zones).
    final storedBirthYear = ref.read(authProvider).value?.birthYear;
    final storedAge = storedBirthYear != null
        ? DateTime.now().year - storedBirthYear
        : null;
    final prefill = hkAge ?? storedAge;

    if (!mounted) return;
    final age = await _promptForAge(initialAge: prefill);
    if (age == null) {
      // User cancelled — stop the recompute, don't change anything.
      if (!mounted) return;
      setState(() => _recomputing = false);
      return;
    }

    try {
      final result = await ref.read(authProvider.notifier).deriveHeartRateZones(
            age: age,
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

  /// Cupertino dialog asking the runner to confirm/edit their age before
  /// recomputing zones. [initialAge] prefills the field when we already
  /// have a value (from HealthKit or stored birth_year) — runner can
  /// just hit Compute, OR overwrite if the prefill is wrong. Returns
  /// null on cancel.
  Future<int?> _promptForAge({int? initialAge}) async {
    final controller = TextEditingController(
      text: initialAge != null ? '$initialAge' : '',
    );
    final age = await showCupertinoDialog<int>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Your age'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            children: [
              const Text(
                'We use your age to compute heart rate zones. Confirm or edit before continuing.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                placeholder: 'Age',
                autofocus: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              final v = int.tryParse(controller.text.trim());
              if (v == null || v < 5 || v > 120) {
                Navigator.of(ctx).pop();
                return;
              }
              Navigator.of(ctx).pop(v);
            },
            child: const Text('Compute'),
          ),
        ],
      ),
    );
    controller.dispose();
    return age;
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
    switch (r.source) {
      case 'derived_age':
      case 'derived_empirical':
        final age = r.age;
        final maxHr = r.maxHr;
        final corrected = r.sampleCount >= 3;
        if (corrected && maxHr != null) {
          return 'Updated — max ~$maxHr bpm (age + your hardest recent runs).';
        }
        if (age != null && maxHr != null) {
          return 'Updated — max ~$maxHr bpm (estimated from age $age).';
        }
        return 'Updated from your age.';
      default:
        return "Couldn't compute zones — please set your max HR manually.";
    }
  }

  Future<void> _save() async {
    final b = _readBoundaries();
    for (var i = 0; i < b.length; i++) {
      if (b[i] <= 0 || b[i] >= 250) {
        setState(() => _error = 'Enter valid bpm values (0-250).');
        return;
      }
      if (i > 0 && b[i] <= b[i - 1]) {
        setState(() => _error = 'Zones must be in ascending order.');
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
          _error = 'Could not save: $e';
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
              const Text(
                'HR Zones',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryInk,
                ),
              ),
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Edit Max HR to recompute every zone, or change a boundary to update the adjacent zone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.inkMuted, height: 1.4),
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
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
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
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const CupertinoActivityIndicator(
                                color: CupertinoColors.white)
                            : const Text(
                                'Save',
                                style: TextStyle(
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
          const Expanded(
            child: Text(
              'Max HR',
              style: TextStyle(
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
              _kZoneNames[index],
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
          const Text(
            'bpm',
            style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
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
                busy ? 'Recomputing…' : 'Recompute from your runs',
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

