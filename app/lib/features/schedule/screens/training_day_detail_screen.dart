import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, InkWell, Material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/i18n/build_context_l10n.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/theme/compliance_colors.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/gradient_scaffold.dart';
import 'package:app/core/widgets/intro_fx.dart';
import 'package:app/core/widgets/coach_prompt_bar.dart';
import 'package:app/features/schedule/data/training_day_coach_suggestions.dart';
import 'package:app/features/schedule/widgets/workout_chat_sheet.dart';
import 'package:app/features/schedule/models/training_day.dart';
import 'package:app/features/schedule/models/training_day_pace_x.dart';
import 'package:app/features/schedule/providers/schedule_provider.dart';
import 'package:app/features/schedule/services/workout_scheduler_service.dart';
import 'package:app/features/schedule/widgets/coach_analysis_card.dart';
import 'package:app/features/schedule/widgets/reschedule_day_sheet.dart';
import 'package:app/features/schedule/widgets/select_activity_sheet.dart';
import 'package:app/features/schedule/widgets/training_day_action_buttons.dart';
import 'package:app/features/schedule/widgets/training_day_hero_card.dart';
import 'package:app/features/schedule/widgets/training_day_stat_tiles.dart';
import 'package:app/features/schedule/widgets/training_day_status.dart';
import 'package:app/features/schedule/models/training_result.dart';
import 'package:app/features/share/widgets/run_celebration_sheet.dart';
import 'package:app/features/schedule/widgets/training_intervals_table.dart';

class TrainingDayDetailScreen extends ConsumerWidget {
  final int dayId;
  const TrainingDayDetailScreen({super.key, required this.dayId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayAsync = ref.watch(trainingDayDetailProvider(dayId));

    return GradientScaffold(
      child: dayAsync.when(
        loading: () => const SafeArea(child: AppSpinner()),
        error: (err, _) => SafeArea(child: AppErrorState(title: context.l10n.commonErrorWithMessage(err.toString()))),
        data: (day) => _Loaded(day: day, ref: ref),
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  final TrainingDay day;
  final WidgetRef ref;

  const _Loaded({required this.day, required this.ref});

  @override
  Widget build(BuildContext context) {
    final status = TrainingDayStatus.from(day);

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopBar(
            showMore: status.showSelectActivity,
            onMore: () => _showMoreActions(context, day, status),
          ),
          Expanded(
            child: IntroFx(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      child: TrainingDayHeroCard(
                        title: day.title,
                        status: status,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: TrainingDayStatTiles(
                        distance: _distanceTile(day),
                        pace: _paceTile(day),
                        hrZone: _hrZoneTile(day),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: TrainingDayActionButtons(
                        status: status,
                        onSendToWatch: () => _sendToWatch(context, day),
                      ),
                    ),
                    if (status == TrainingDayStatus.completed &&
                        day.result != null) ...[
                      const SizedBox(height: 16),
                      _CoachAnalysisSection(dayId: day.id, day: day),
                      if (day.result!.aiFeedback != null &&
                          day.result!.aiFeedback!.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _ShareThisRunButton(result: day.result!),
                        ),
                      ],
                    ] else
                      ..._buildDetailSection(context, day, status),
                    if (day.intervals != null && day.intervals!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _SectionTitle(context.l10n.schedSectionIntervals),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: TrainingIntervalsTable(intervals: day.intervals!),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: CoachPromptBar.navigateAnimated(
                onTap: () => WorkoutChatSheet.show(context, day.id),
                animatedSuggestions: trainingDayCoachSuggestions(context.l10n),
              ),
            ),
          ),
        ],
      ),
    );
  }

  StatTileData _distanceTile(TrainingDay d) {
    final result = d.result;
    return StatTileData(
      target: _formatKm(d.targetKm),
      actual: result == null ? null : _formatKm(result.actualKm),
      actualColor: result == null
          ? null
          : ComplianceColors.forScore10(result.distanceScore),
    );
  }

  StatTileData _paceTile(TrainingDay d) {
    final result = d.result;
    final isInterval = d.type == 'interval';
    return StatTileData(
      // Use the work-set average for intervals (day-level pace is null
      // there by design — see TrainingDayPaceX).
      target: _formatPaceSecs(d.displayPaceSecondsPerKm),
      // Hide actual pace on interval days: a full-run avg that mixes
      // warmup + work + recovery + cooldown isn't comparable to the
      // work-set target and would mislead the runner. When segment-level
      // ingestion lands we'll surface a real work-pace here.
      actual: result == null || isInterval
          ? null
          : _formatPaceSecs(result.actualPaceSecondsPerKm),
      actualColor: result == null || isInterval
          ? null
          : ComplianceColors.forScore10(result.paceScore),
    );
  }

  StatTileData _hrZoneTile(TrainingDay d) {
    final result = d.result;
    final zone = d.targetHeartRateZone;
    final actualHr = result?.actualAvgHeartRate;
    return StatTileData(
      target: zone == null ? null : 'Z$zone',
      actual: actualHr == null ? null : '${actualHr.round()} bpm',
      actualColor:
          result == null ? null : ComplianceColors.forScore10(result.heartRateScore),
    );
  }

  static String? _formatKm(double? km) {
    if (km == null) return null;
    final value = km.toStringAsFixed(km.truncateToDouble() == km ? 0 : 1);
    return '$value km';
  }

  static String? _formatPaceSecs(int? secs) {
    if (secs == null || secs <= 0) return null;
    final mm = secs ~/ 60;
    final ss = secs % 60;
    return "$mm'${ss.toString().padLeft(2, '0')}\"";
  }

  /// Notes section for upcoming/today/missed days. Completed days route to
  /// `_CoachAnalysisSection` instead — never reaches here.
  List<Widget> _buildDetailSection(BuildContext context, TrainingDay day, TrainingDayStatus status) {
    final description = day.description?.trim();
    if (description == null || description.isEmpty) {
      return const [];
    }
    return [
      const SizedBox(height: 16),
      _SectionTitle(context.l10n.schedSectionNotes),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: _DetailCard(child: Text(description, style: _detailTextStyle)),
      ),
    ];
  }

  static TextStyle get _detailTextStyle => GoogleFonts.publicSans(
        fontSize: 14,
        height: 1.5,
        color: AppColors.primaryInk,
      );

  void _showMoreActions(
    BuildContext context,
    TrainingDay day,
    TrainingDayStatus status,
  ) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetCtx) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(sheetCtx).pop();
              SelectActivitySheet.show(
                context,
                dayId: day.id,
                // The mutation notifier bumps planVersion, which refreshes
                // every plan-derived view automatically — nothing to do here.
                onMatched: () {},
              );
            },
            child: Text(context.l10n.schedDayPickActivity),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(sheetCtx).pop();
              RescheduleDaySheet.show(
                context,
                dayId: day.id,
                initialDate: _parseYmd(day.date) ?? DateTime.now(),
                onRescheduled: () {},
              );
            },
            child: Text(context.l10n.schedDayRescheduleAction),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(sheetCtx).pop(),
          child: Text(context.l10n.commonCancel),
        ),
      ),
    );
  }

  static DateTime? _parseYmd(String input) {
    if (input.length < 10) return null;
    try {
      final parts = input.substring(0, 10).split('-');
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _sendToWatch(BuildContext context, TrainingDay day) async {
    final dateLocal = _parseYmd(day.date);
    if (dateLocal == null) {
      await _showResultDialog(context,
          title: context.l10n.trainingDayWatchCouldNotSend,
          body: context.l10n.schedWatchInvalidDateBody);
      return;
    }

    final hasIntervals = day.intervals != null && day.intervals!.isNotEmpty;
    final km = day.targetKm;

    if (!hasIntervals && (km == null || km <= 0)) {
      await _showResultDialog(context,
          title: context.l10n.schedWatchNothingToSendTitle,
          body: context.l10n.schedWatchNoDistanceBody);
      return;
    }

    // Pre-check: extract the would-be steps so we can surface a friendly
    // error before showing the spinner / hitting the native bridge.
    final intervalPlan = hasIntervals ? buildIntervalPlan(day) : null;
    if (intervalPlan != null && intervalPlan.steps.isEmpty) {
      await _showResultDialog(context,
          title: context.l10n.schedWatchNothingToSendTitle,
          body: context.l10n.schedWatchNoStepsBody);
      return;
    }

    showCupertinoDialog<void>(
      context: context,
      builder: (_) => const _SendingDialog(),
    );

    final service = ref.read(workoutSchedulerServiceProvider);
    final result = intervalPlan != null
        ? await service.scheduleIntervals(
            dayId: day.id,
            date: dateLocal,
            displayName: day.title,
            warmupSeconds: intervalPlan.warmupSeconds,
            cooldownSeconds: intervalPlan.cooldownSeconds,
            steps: intervalPlan.steps,
          )
        : await service.scheduleRun(
            dayId: day.id,
            date: dateLocal,
            distanceKm: km!,
          );

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // close progress

    final l10n = context.l10n;
    final (title, body) = switch (result.status) {
      WorkoutScheduleStatus.scheduled => (
          l10n.schedWatchSentTitle,
          result.message ?? l10n.schedWatchSentBody,
        ),
      WorkoutScheduleStatus.denied => (
          l10n.schedWatchPermissionTitle,
          result.message ?? l10n.schedWatchPermissionBody,
        ),
      WorkoutScheduleStatus.unavailable => (
          l10n.schedWatchUnavailableTitle,
          result.message ?? l10n.schedWatchUnavailableBody,
        ),
      WorkoutScheduleStatus.failed => (
          l10n.schedWatchFailedTitle,
          result.message ?? l10n.schedWatchGenericError,
        ),
    };

    await _showResultDialog(context, title: title, body: body);
  }

  Future<void> _showResultDialog(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    return showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(body),
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

class _SendingDialog extends StatelessWidget {
  const _SendingDialog();

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CupertinoActivityIndicator(radius: 14),
            const SizedBox(height: 12),
            Text(context.l10n.schedDaySendingToWatch),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            CupertinoIcons.chevron_right,
            size: 10,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final bool showMore;
  final VoidCallback onMore;

  const _TopBar({required this.showMore, required this.onMore});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () =>
                  context.canPop() ? context.pop() : context.go('/schedule'),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(
                  CupertinoIcons.back,
                  color: AppColors.primaryInk,
                  size: 22,
                ),
              ),
            ),
          ),
          const Spacer(),
          if (showMore)
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: onMore,
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    CupertinoIcons.ellipsis_circle,
                    color: AppColors.primaryInk,
                    size: 24,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final Widget child;
  const _DetailCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 16),
        ],
      ),
      child: child,
    );
  }
}

/// Combined Coach-analysis + Synced-activity section. Rendered only when
/// the day has a result. Falls back to a placeholder excerpt while the AI
/// feedback is being generated (poll handled by `trainingDayAiFeedbackProvider`).
/// Tapping the card OR the "Open" link routes to the result detail screen.
class _CoachAnalysisSection extends ConsumerWidget {
  final int dayId;
  final TrainingDay day;
  const _CoachAnalysisSection({required this.dayId, required this.day});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = day.result!;
    final initial = result.aiFeedback;
    // Re-poll for AI feedback only when the persisted value is empty —
    // skips an unnecessary HTTP request once the analysis has landed.
    final text = (initial != null && initial.trim().isNotEmpty)
        ? initial
        : ref.watch(trainingDayAiFeedbackProvider(dayId)).value;

    return CoachAnalysisCard(
      complianceScore10: result.complianceScore,
      aiFeedback: text,
      onOpen: () => context.push('/schedule/day/$dayId/result'),
    );
  }
}

/// Inline "Share this run" CTA shown below the Coach Analysis card for
/// completed days that have AI feedback. Lets the runner re-open the
/// share-card sheet on demand (the boot popup is one-shot per run).
class _ShareThisRunButton extends StatelessWidget {
  final TrainingResult result;
  const _ShareThisRunButton({required this.result});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 12),
        color: AppColors.lightTan,
        borderRadius: BorderRadius.circular(14),
        onPressed: () => RunCelebrationSheet.show(context, result: result),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.share,
              size: 16,
              color: AppColors.primaryInk,
            ),
            const SizedBox(width: 8),
            Text(
              context.l10n.runShareInlineCta.toUpperCase(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryInk,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


