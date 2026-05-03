import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/auth/models/hr_zone.dart';
import 'package:app/features/auth/providers/auth_provider.dart';
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
  String? _error;

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
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _MaxHrField(
                  controller: _maxHrController,
                  onApply: _applyMaxHr,
                  enabled: !_saving,
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

