import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/i18n/build_context_l10n.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/onboarding/widgets/pace_wheel_picker.dart';
import 'package:app/features/schedule/models/interval_blueprint.dart';

/// Block editor for an interval session — warm-up, work blocks (reps ×
/// distance-or-time @ pace, recovery), cool-down, plus a live derived
/// distance footer. Stateless: the host owns the [blueprint] and receives
/// every change via [onChanged].
///
/// Standalone `rep` / `rest` steps (coach-authored pyramids) render as
/// fixed, non-editable rows in their original position and are passed back
/// unchanged — blocks around them stay editable, the structure is never
/// reshaped client-side. The server normalizes + derives `target_km` on
/// save; the footer uses [IntervalBlueprint.estimateTotalKm] (same
/// constants) so the preview matches what will be stored.
class IntervalBlueprintEditor extends StatelessWidget {
  final IntervalBlueprint blueprint;
  final ValueChanged<IntervalBlueprint> onChanged;

  const IntervalBlueprintEditor({
    super.key,
    required this.blueprint,
    required this.onChanged,
  });

  void _updateStep(int index, IntervalStep step) {
    final steps = [...blueprint.steps];
    steps[index] = step;
    onChanged(blueprint.copyWith(steps: steps));
  }

  void _removeStep(int index) {
    final steps = [...blueprint.steps]..removeAt(index);
    onChanged(blueprint.copyWith(steps: steps));
  }

  void _addBlock() {
    final lastBlock = blueprint.steps.lastWhere(
      (s) => s.type == 'block',
      orElse: () => const IntervalStep(
        type: 'block',
        reps: 4,
        workDistanceM: 400,
        recoverySeconds: 90,
      ),
    );
    onChanged(blueprint.copyWith(steps: [...blueprint.steps, lastBlock]));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final blockCount = blueprint.steps.where((s) => s.type == 'block').length;
    final derivedKm = blueprint.estimateTotalKm();

    var blockNumber = 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Row(
          label: l10n.editDayWarmupLabel,
          value: blueprint.warmupSeconds == null
              ? l10n.editDayWarmupOff
              : '${blueprint.warmupSeconds}s',
          onTap: () async {
            final picked = await _pickSeconds(
              context,
              title: l10n.editDayWarmupLabel,
              values: [for (var s = 0; s <= 120; s += 15) s],
              initial: blueprint.warmupSeconds ?? 0,
              zeroLabel: l10n.editDayWarmupOff,
            );
            if (picked != null) {
              onChanged(blueprint.copyWith(
                warmupSeconds: picked == 0 ? null : picked,
              ));
            }
          },
        ),
        for (var i = 0; i < blueprint.steps.length; i++)
          switch (blueprint.steps[i].type) {
            'block' => _BlockCard(
                index: i,
                number: ++blockNumber,
                step: blueprint.steps[i],
                deletable: blockCount > 1,
                onChanged: (s) => _updateStep(i, s),
                onDelete: () => _removeStep(i),
              ),
            'rep' => _FixedStepRow(
                text:
                    '1× ${_workText(blueprint.steps[i])}${_paceSuffix(blueprint.steps[i])}',
              ),
            _ => _FixedStepRow(
                text:
                    '${l10n.editDayRestStepLabel} · ${blueprint.steps[i].durationSeconds ?? 0}s',
              ),
          },
        CupertinoButton(
          onPressed: _addBlock,
          child: Text(
            '+ ${l10n.editDayAddBlock}',
            style: GoogleFonts.publicSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryInk,
            ),
          ),
        ),
        _Row(
          label: l10n.editDayCooldownLabel,
          value: '${blueprint.cooldownSeconds ?? 300}s',
          onTap: () async {
            final picked = await _pickSeconds(
              context,
              title: l10n.editDayCooldownLabel,
              values: [for (var s = 60; s <= 600; s += 30) s],
              initial: blueprint.cooldownSeconds ?? 300,
            );
            if (picked != null) {
              onChanged(blueprint.copyWith(cooldownSeconds: picked));
            }
          },
        ),
        const _Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Text(
                l10n.editDayDerivedDistanceLabel,
                style: GoogleFonts.publicSans(
                  fontSize: 14,
                  color: AppColors.inkMuted,
                ),
              ),
              const Spacer(),
              Text(
                derivedKm == null ? '—' : '≈ ${derivedKm.toStringAsFixed(1)} km',
                style: GoogleFonts.publicSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _workText(IntervalStep s) => (s.workDistanceM ?? 0) > 0
    ? '${s.workDistanceM}m'
    : '${s.workDurationSeconds ?? 0}s';

String _paceSuffix(IntervalStep s) {
  final pace = s.workPaceSecondsPerKm;
  if (pace == null || pace <= 0) return '';
  return ' @ ${pace ~/ 60}:${(pace % 60).toString().padLeft(2, '0')}';
}

/// One work block: header (number + optional delete) and four tappable rows.
class _BlockCard extends StatelessWidget {
  final int index;
  final int number;
  final IntervalStep step;
  final bool deletable;
  final ValueChanged<IntervalStep> onChanged;
  final VoidCallback onDelete;

  const _BlockCard({
    required this.index,
    required this.number,
    required this.step,
    required this.deletable,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDistance = (step.workDistanceM ?? 0) > 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 6, 0),
            child: Row(
              children: [
                Text(
                  l10n.editDayBlockLabel(number),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.secondary,
                  ),
                ),
                const Spacer(),
                if (deletable)
                  CupertinoButton(
                    key: ValueKey('delete-block-$index'),
                    padding: const EdgeInsets.all(6),
                    minimumSize: Size.zero,
                    onPressed: onDelete,
                    child: const Icon(
                      CupertinoIcons.minus_circle,
                      size: 20,
                      color: AppColors.inkMuted,
                    ),
                  ),
              ],
            ),
          ),
          _Row(
            label: l10n.editDayRepsLabel,
            value: '${step.reps ?? 1}×',
            dense: true,
            onTap: () async {
              // Max mirrors the backend's IntervalBlueprint::REPS_MAX.
              final picked = await _pickFromList<int>(
                context,
                title: l10n.editDayRepsLabel,
                values: [for (var r = 1; r <= 60; r++) r],
                initial: step.reps ?? 1,
                format: (r) => '$r×',
              );
              if (picked != null) onChanged(step.copyWith(reps: picked));
            },
          ),
          if (isDistance)
            _Row(
              label: l10n.editDayRepDistanceLabel,
              value: '${step.workDistanceM}m',
              dense: true,
              onTap: () async {
                // Max mirrors the Filament coach editor's 5000m cap.
                final picked = await _pickFromList<int>(
                  context,
                  title: l10n.editDayRepDistanceLabel,
                  values: [for (var m = 100; m <= 5000; m += 100) m],
                  initial: step.workDistanceM ?? 400,
                  format: (m) => '${m}m',
                );
                if (picked != null) {
                  onChanged(step.copyWith(workDistanceM: picked));
                }
              },
            )
          else
            _Row(
              label: l10n.editDayRepDurationLabel,
              value: '${step.workDurationSeconds ?? 60}s',
              dense: true,
              onTap: () async {
                final picked = await _pickSeconds(
                  context,
                  title: l10n.editDayRepDurationLabel,
                  values: [for (var s = 15; s <= 600; s += 15) s],
                  initial: step.workDurationSeconds ?? 60,
                );
                if (picked != null) {
                  onChanged(step.copyWith(workDurationSeconds: picked));
                }
              },
            ),
          _Row(
            label: l10n.editDayPaceLabel,
            value: step.workPaceSecondsPerKm == null
                ? '—'
                : '${_formatPace(step.workPaceSecondsPerKm!)} /km',
            dense: true,
            onTap: () async {
              // Work paces may go faster than day-level paces (sprint reps);
              // 2:00/km floor instead of the regular 3:00.
              final picked = await showPaceWheelPicker(
                context,
                initialSecondsPerKm: step.workPaceSecondsPerKm ?? 300,
                minMinutes: 2,
              );
              if (picked != null) {
                onChanged(step.copyWith(workPaceSecondsPerKm: picked));
              }
            },
          ),
          _Row(
            label: l10n.editDayRecoveryLabel,
            value: '${step.recoverySeconds ?? 90}s',
            dense: true,
            onTap: () async {
              final picked = await _pickSeconds(
                context,
                title: l10n.editDayRecoveryLabel,
                values: [for (var s = 15; s <= 300; s += 15) s],
                initial: step.recoverySeconds ?? 90,
              );
              if (picked != null) {
                onChanged(step.copyWith(recoverySeconds: picked));
              }
            },
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  static String _formatPace(int seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

/// Tappable label/value row, visually matching EditDaySheet's rows.
class _Row extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool dense;

  const _Row({
    required this.label,
    required this.value,
    required this.onTap,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 16 : 20,
          vertical: dense ? 10 : 16,
        ),
        child: Row(
          children: [
            Text(
              label,
              style: GoogleFonts.publicSans(
                fontSize: dense ? 15 : 16,
                color: AppColors.primaryInk,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: GoogleFonts.publicSans(
                fontSize: dense ? 15 : 16,
                fontWeight: FontWeight.w600,
                color: AppColors.inkMuted,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: AppColors.inkMuted,
            ),
          ],
        ),
      ),
    );
  }
}

/// Non-editable step (standalone rep / rest from the coach editor).
class _FixedStepRow extends StatelessWidget {
  final String text;

  const _FixedStepRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Text(
            text,
            style: GoogleFonts.publicSans(
              fontSize: 15,
              color: AppColors.inkMuted,
            ),
          ),
          const Spacer(),
          const Icon(
            CupertinoIcons.lock,
            size: 14,
            color: AppColors.inkMuted,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 1,
      color: AppColors.border,
    );
  }
}

Future<int?> _pickSeconds(
  BuildContext context, {
  required String title,
  required List<int> values,
  required int initial,
  String? zeroLabel,
}) {
  return _pickFromList<int>(
    context,
    title: title,
    values: values,
    initial: initial,
    format: (s) => s == 0 && zeroLabel != null ? zeroLabel : '${s}s',
  );
}

/// Generic Cupertino wheel over a fixed value list — same shell as the
/// distance picker in EditDaySheet. Returns null on cancel.
Future<T?> _pickFromList<T>(
  BuildContext context, {
  required String title,
  required List<T> values,
  required T initial,
  required String Function(T) format,
}) {
  var index = values.indexOf(initial);
  if (index < 0) index = 0;

  return showCupertinoModalPopup<T>(
    context: context,
    builder: (sheetContext) => Container(
      height: 300,
      decoration: const BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: Text(
                    context.l10n.commonCancel,
                    style: GoogleFonts.inter(fontSize: 16, color: AppColors.inkMuted),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(sheetContext).pop(values[index]),
                  child: Text(
                    context.l10n.paceWheelPickerDone,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryInk,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: CupertinoPicker(
              itemExtent: 36,
              scrollController: FixedExtentScrollController(initialItem: index),
              onSelectedItemChanged: (i) => index = i,
              children: [
                for (final v in values)
                  Center(
                    child: Text(
                      format(v),
                      style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w500),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
