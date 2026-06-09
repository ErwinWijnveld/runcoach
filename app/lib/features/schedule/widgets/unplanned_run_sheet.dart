import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, InkWell, Material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:app/core/i18n/build_context_l10n.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/schedule/models/training_day.dart';
import 'package:app/features/schedule/models/training_day_pace_x.dart';
import 'package:app/features/schedule/models/training_week.dart';
import 'package:app/features/schedule/models/wearable_activity_summary.dart';
import 'package:app/features/schedule/providers/schedule_provider.dart';

/// Detail + "link to a training" sheet for an off-plan ("buiten schema") run.
/// Two states inside one modal: the run's stats with a single big "Koppel aan
/// training" CTA, then a picker of nearby uncompleted sessions. Picking one
/// relocates that session onto the run's real date and scores it (the run then
/// stops surfacing as off-plan).
Future<void> showUnplannedRunSheet(
  BuildContext context, {
  required WearableActivitySummary run,
  required int goalId,
}) {
  return showCupertinoModalPopup<void>(
    context: context,
    builder: (_) => _UnplannedRunSheet(run: run, goalId: goalId),
  );
}

class _UnplannedRunSheet extends ConsumerStatefulWidget {
  final WearableActivitySummary run;
  final int goalId;
  const _UnplannedRunSheet({required this.run, required this.goalId});

  @override
  ConsumerState<_UnplannedRunSheet> createState() => _UnplannedRunSheetState();
}

class _UnplannedRunSheetState extends ConsumerState<_UnplannedRunSheet> {
  bool _picking = false;
  bool _busy = false;

  Future<void> _link(int dayId) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(linkUnplannedRunProvider.notifier).link(
            activityId: widget.run.id,
            trainingDayId: dayId,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      await showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(context.l10n.schedOffPlanLinkErrorTitle),
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
            _picking
                ? _PickerView(
                    run: widget.run,
                    goalId: widget.goalId,
                    busy: _busy,
                    onBack: () => setState(() => _picking = false),
                    onPick: _link,
                  )
                : _DetailsView(
                    run: widget.run,
                    onCancel: () => Navigator.of(context).pop(),
                    onLink: () => setState(() => _picking = true),
                  ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Details — run stats + the big "Koppel aan training" CTA
// ---------------------------------------------------------------------------

class _DetailsView extends StatelessWidget {
  final WearableActivitySummary run;
  final VoidCallback onCancel;
  final VoidCallback onLink;
  const _DetailsView({
    required this.run,
    required this.onCancel,
    required this.onLink,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(run.startDate);
    final title = date == null
        ? context.l10n.schedOffPlanRunTitle
        : _capitalize(DateFormat('EEEE d MMMM',
                Localizations.localeOf(context).toLanguageTag())
            .format(date));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.offPlanGlow,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  context.l10n.schedOffPlanBadge,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.offPlan,
                  ),
                ),
              ),
              const Spacer(),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onCancel,
                child: Text(
                  context.l10n.commonClose,
                  style: GoogleFonts.publicSans(
                    fontSize: 15,
                    color: AppColors.tertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.ebGaramond(
              fontSize: 26,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              color: AppColors.primaryInk,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MiniStat(
                label: context.l10n.schedDayDistance,
                value: _km(run.distanceMeters),
              ),
              _MiniStat(
                label: context.l10n.schedDayPace,
                value: _pace(run.averagePaceSecondsPerKm),
              ),
              _MiniStat(
                label: context.l10n.schedDayDuration,
                value: _duration(run.durationSeconds),
              ),
              if (run.averageHeartrate != null)
                _MiniStat(
                  label: context.l10n.schedDayHr,
                  value: '${run.averageHeartrate!.round()}',
                ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: AppColors.offPlan,
              borderRadius: BorderRadius.circular(14),
              onPressed: onLink,
              child: Text(
                context.l10n.schedOffPlanLinkCta,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: CupertinoColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Picker — nearby uncompleted sessions (±7 days), nearest first
// ---------------------------------------------------------------------------

class _PickerView extends ConsumerWidget {
  final WearableActivitySummary run;
  final int goalId;
  final bool busy;
  final VoidCallback onBack;
  final ValueChanged<int> onPick;
  const _PickerView({
    required this.run,
    required this.goalId,
    required this.busy,
    required this.onBack,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(scheduleProvider(goalId));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: Row(
            children: [
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                onPressed: busy ? null : onBack,
                child: Text(
                  context.l10n.commonBack,
                  style: GoogleFonts.publicSans(
                    fontSize: 15,
                    color: AppColors.tertiary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  context.l10n.schedOffPlanPickTitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ebGaramond(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryInk,
                  ),
                ),
              ),
              const SizedBox(width: 76),
            ],
          ),
        ),
        const SizedBox(height: 4),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.5,
          ),
          child: scheduleAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: CupertinoActivityIndicator(),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                context.l10n.commonErrorWithMessage('$e'),
                textAlign: TextAlign.center,
                style: GoogleFonts.publicSans(
                  fontSize: 14,
                  color: AppColors.inkMuted,
                ),
              ),
            ),
            data: (weeks) {
              final candidates = _candidates(weeks, run);
              if (candidates.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                  child: Text(
                    context.l10n.schedOffPlanPickEmpty,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.publicSans(
                      fontSize: 14,
                      color: AppColors.inkMuted,
                    ),
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                itemCount: candidates.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _CandidateRow(
                  day: candidates[i],
                  disabled: busy,
                  onTap: () => onPick(candidates[i].id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Uncompleted, non-race sessions within ±7 days of the run, nearest first.
  /// The race day (the plan's last-dated session) is excluded — it has to stay
  /// on the goal date, and the backend rejects linking to it anyway.
  static List<TrainingDay> _candidates(
    List<TrainingWeek> weeks,
    WearableActivitySummary run,
  ) {
    final runDt = DateTime.tryParse(run.startDate);
    if (runDt == null) return const [];
    final rd = DateTime(runDt.year, runDt.month, runDt.day);

    final all = <TrainingDay>[
      for (final w in weeks) ...?w.trainingDays,
    ];

    DateTime? raceDate;
    for (final d in all) {
      final dt = DateTime.tryParse(d.date);
      if (dt == null) continue;
      final day = DateTime(dt.year, dt.month, dt.day);
      if (raceDate == null || day.isAfter(raceDate)) raceDate = day;
    }

    final out = <TrainingDay>[];
    for (final d in all) {
      if (d.result != null) continue;
      final dt = DateTime.tryParse(d.date);
      if (dt == null) continue;
      final day = DateTime(dt.year, dt.month, dt.day);
      if (raceDate != null && day == raceDate) continue;
      if (day.difference(rd).inDays.abs() > 7) continue;
      out.add(d);
    }

    out.sort((a, b) {
      final da = DateTime.parse(a.date);
      final db = DateTime.parse(b.date);
      final na = DateTime(da.year, da.month, da.day);
      final nb = DateTime(db.year, db.month, db.day);
      final c =
          na.difference(rd).inDays.abs().compareTo(nb.difference(rd).inDays.abs());
      return c != 0 ? c : na.compareTo(nb);
    });
    return out;
  }
}

class _CandidateRow extends StatelessWidget {
  final TrainingDay day;
  final bool disabled;
  final VoidCallback onTap;
  const _CandidateRow({
    required this.day,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(day.date);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateLabel = date == null
        ? ''
        : _capitalize(DateFormat('EEE d MMM', locale).format(date));

    final pace = day.displayPaceSecondsPerKm;
    final meta = <String>[
      if (day.targetKm != null && day.targetKm! > 0) _km(day.targetKm! * 1000),
      if (pace != null && pace > 0) _pace(pace),
    ].join(' · ');

    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Material(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateLabel,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        day.title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryInk,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (meta.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          meta,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.offPlan,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.add_link_rounded,
                  color: AppColors.offPlan,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bits
// ---------------------------------------------------------------------------

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.inkMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryInk,
            ),
          ),
        ],
      ),
    );
  }
}

String _capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

String _km(num meters) {
  final km = meters / 1000;
  final label = km == km.truncate()
      ? km.toInt().toString()
      : km.toStringAsFixed(1);
  return '$label km';
}

String _pace(int secondsPerKm) {
  if (secondsPerKm <= 0) return '—';
  final m = secondsPerKm ~/ 60;
  final s = (secondsPerKm % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

String _duration(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  if (h > 0) {
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '$m:${s.toString().padLeft(2, '0')}';
}
