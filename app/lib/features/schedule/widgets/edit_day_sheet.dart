import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/i18n/build_context_l10n.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/primary_cta_button.dart';
import 'package:app/core/widgets/runboost_logo.dart';
import 'package:app/features/onboarding/widgets/pace_wheel_picker.dart';
import 'package:app/features/schedule/models/interval_blueprint.dart';
import 'package:app/features/schedule/models/training_day.dart';
import 'package:app/features/schedule/providers/schedule_provider.dart';
import 'package:app/features/schedule/services/watch_sync_service.dart';
import 'package:app/features/schedule/widgets/interval_blueprint_editor.dart';

/// Minimal in-place editor for a single training day. Tappable rows open
/// Cupertino wheel pickers; Save commits via PATCH /training-days/{id}
/// (no proposal, instant — mirrors reschedule).
///
/// Two modes on `day.type`:
///  - regular days: distance + pace rows;
///  - interval days: the [IntervalBlueprintEditor] block editor. Day-level
///    pace and distance are server-owned there (pace lives per rep, distance
///    is derived from the blueprint by the saving hook), so the sheet sends
///    only the `intervals` structure and renders the derived km live.
class EditDaySheet extends ConsumerStatefulWidget {
  final TrainingDay day;

  const EditDaySheet({super.key, required this.day});

  static Future<void> show(BuildContext context, {required TrainingDay day}) {
    return showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => EditDaySheet(day: day),
    );
  }

  @override
  ConsumerState<EditDaySheet> createState() => _EditDaySheetState();
}

class _EditDaySheetState extends ConsumerState<EditDaySheet> {
  late double _km;
  int? _paceSeconds;
  late IntervalBlueprint _blueprint;
  bool _busy = false;

  bool get _isInterval => widget.day.type == 'interval';

  @override
  void initState() {
    super.initState();
    _km = widget.day.targetKm ?? 5.0;
    _paceSeconds = widget.day.targetPaceSecondsPerKm;
    // Defensive default: an interval day without a blueprint shouldn't exist
    // (server invariant), but seeding the editor keeps the sheet usable and
    // saving it simply stores this canonical skeleton.
    _blueprint = widget.day.intervals ??
        const IntervalBlueprint(
          warmupSeconds: 60,
          steps: [
            IntervalStep(
              type: 'block',
              reps: 4,
              workDistanceM: 400,
              recoverySeconds: 90,
            ),
          ],
          cooldownSeconds: 300,
        );
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(editTrainingDayProvider.notifier).edit(
            dayId: widget.day.id,
            // Interval days: the structure is the edit — km/pace are derived
            // server-side from it.
            targetKm: _isInterval ? null : _km,
            targetPaceSecondsPerKm: _isInterval ? null : _paceSeconds,
            intervals: _isInterval ? _blueprint : null,
          );
      // Content changed → re-ship the upcoming days to the watch.
      await ref.read(watchSyncProvider.notifier).syncUpcoming();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      await showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(context.l10n.editDayErrorTitle),
          content: Text('$e'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(context.l10n.commonOk),
            ),
          ],
        ),
      );
    }
  }

  String _formatPace(int seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.neutral,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    context.l10n.commonCancel,
                    style: GoogleFonts.publicSans(fontSize: 15, color: AppColors.tertiary),
                  ),
                ),
                Expanded(
                  child: RunBoostHeading(
                    context.l10n.editDayTitle,
                    size: 20,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    topPadding: 0,
                  ),
                ),
                const SizedBox(width: 76),
              ],
            ),
            const SizedBox(height: 8),
            if (_isInterval)
              Flexible(
                child: SingleChildScrollView(
                  child: IntervalBlueprintEditor(
                    blueprint: _blueprint,
                    onChanged: (bp) => setState(() => _blueprint = bp),
                  ),
                ),
              )
            else ...[
              _EditRow(
                label: context.l10n.editDayDistanceLabel,
                value: '${_km.toStringAsFixed(1)} km',
                onTap: () async {
                  final picked = await _showDistancePicker(context, _km);
                  if (picked != null) setState(() => _km = picked);
                },
              ),
              const _RowDivider(),
              _EditRow(
                label: context.l10n.editDayPaceLabel,
                value: _paceSeconds == null
                    ? '—'
                    : '${_formatPace(_paceSeconds!)} /km',
                onTap: () async {
                  final picked = await showPaceWheelPicker(
                    context,
                    initialSecondsPerKm: _paceSeconds ?? 300,
                  );
                  if (picked != null) setState(() => _paceSeconds = picked);
                },
              ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: PrimaryCtaButton(
                label: context.l10n.commonSave,
                busy: _busy,
                onPressed: _busy ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _EditRow({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Text(
              label,
              style: GoogleFonts.publicSans(
                fontSize: 16,
                color: AppColors.primaryInk,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: GoogleFonts.publicSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.inkMuted,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(CupertinoIcons.chevron_right, size: 16, color: AppColors.inkMuted),
          ],
        ),
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 1,
      color: AppColors.border,
    );
  }
}

/// Wheel picker for distance in 0.5 km steps, 1–50 km. Returns null on cancel.
Future<double?> _showDistancePicker(BuildContext context, double initial) {
  final values = [for (var i = 2; i <= 100; i++) i / 2]; // 1.0 .. 50.0
  var index = ((initial * 2).round() - 2).clamp(0, values.length - 1);

  return showCupertinoModalPopup<double>(
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
                      context.l10n.editDayDistanceLabel,
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
                      '${v.toStringAsFixed(1)} km',
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
