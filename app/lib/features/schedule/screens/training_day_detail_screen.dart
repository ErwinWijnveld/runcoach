import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, InkWell, Material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/gradient_scaffold.dart';
import 'package:app/core/widgets/coach_prompt_bar.dart';
import 'package:app/features/coach/providers/coach_provider.dart';
import 'package:app/features/coach/widgets/swooshing_star.dart';
import 'package:app/features/schedule/data/training_day_coach_suggestions.dart';
import 'package:app/features/schedule/models/training_day.dart';
import 'package:app/features/schedule/providers/schedule_provider.dart';
import 'package:app/features/schedule/services/workout_scheduler_service.dart';
import 'package:app/features/schedule/widgets/reschedule_day_sheet.dart';
import 'package:app/features/schedule/widgets/select_activity_sheet.dart';
import 'package:app/features/schedule/widgets/wearable_summary_card.dart';
import 'package:app/features/schedule/widgets/training_day_action_buttons.dart';
import 'package:app/features/schedule/widgets/training_day_hero_card.dart';
import 'package:app/features/schedule/widgets/training_day_stat_tiles.dart';
import 'package:app/features/schedule/widgets/training_day_status.dart';
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
        error: (err, _) => SafeArea(child: AppErrorState(title: 'Error: $err')),
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
                      distance: _formatDistance(day),
                      pace: _formatPace(day),
                      hrZone: _formatHrZone(day),
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
                  if (day.intervals != null && day.intervals!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const _SectionTitle('Intervals'),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: TrainingIntervalsTable(intervals: day.intervals!),
                    ),
                  ],
                  ..._buildDetailSection(day, status),
                  if (status == TrainingDayStatus.completed &&
                      day.result?.wearableActivity != null) ...[
                    const SizedBox(height: 16),
                    const _SectionTitle('Synced activity'),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: WearableSummaryCard(
                        activity: day.result!.wearableActivity!,
                        onOpenDetails: () =>
                            context.push('/schedule/day/${day.id}/result'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: CoachPromptBar.navigateAnimated(
                onTap: () => startNewCoachChat(context, ref),
                animatedSuggestions: trainingDayCoachSuggestions,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _formatDistance(TrainingDay d) {
    final actualKm = d.result?.actualKm;
    final km = actualKm ?? d.targetKm;
    if (km == null) return null;
    final value = km.toStringAsFixed(km.truncateToDouble() == km ? 0 : 1);
    return '$value km';
  }

  String? _formatPace(TrainingDay d) {
    final actual = d.result?.actualPaceSecondsPerKm;
    final secs = actual ?? d.targetPaceSecondsPerKm;
    if (secs == null) return null;
    final mm = secs ~/ 60;
    final ss = secs % 60;
    return "$mm'${ss.toString().padLeft(2, '0')}\"";
  }

  String? _formatHrZone(TrainingDay d) {
    final zone = d.targetHeartRateZone;
    if (zone == null) return null;
    return '$zone';
  }

  List<Widget> _buildDetailSection(TrainingDay day, TrainingDayStatus status) {
    final completed = status == TrainingDayStatus.completed;
    final description = day.description?.trim();

    if (!completed && (description == null || description.isEmpty)) {
      return const [];
    }

    final Widget body = completed
        ? _AnalysisBody(dayId: day.id, initial: day.result?.aiFeedback)
        : Text(description!, style: _detailTextStyle);

    return [
      const SizedBox(height: 16),
      _SectionTitle(completed ? 'Coach analysis' : 'Notes'),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: _DetailCard(child: body),
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
                onMatched: () {
                  ref.invalidate(trainingDayDetailProvider(day.id));
                  ref.invalidate(trainingDayResultProvider(day.id));
                  ref.invalidate(scheduleProvider);
                  ref.invalidate(currentWeekProvider);
                },
              );
            },
            child: const Text('Pick activity'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(sheetCtx).pop();
              RescheduleDaySheet.show(
                context,
                dayId: day.id,
                initialDate: _parseYmd(day.date) ?? DateTime.now(),
                onRescheduled: () {
                  ref.invalidate(trainingDayDetailProvider(day.id));
                  ref.invalidate(scheduleProvider);
                  ref.invalidate(currentWeekProvider);
                },
              );
            },
            child: const Text('Reschedule'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(sheetCtx).pop(),
          child: const Text('Cancel'),
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
          title: "Couldn't send",
          body:
              "This training day has an invalid date — try refreshing the schedule.");
      return;
    }

    final hasIntervals = day.intervals != null && day.intervals!.isNotEmpty;
    final km = day.targetKm;

    if (!hasIntervals && (km == null || km <= 0)) {
      await _showResultDialog(context,
          title: "Nothing to send",
          body:
              'This workout has no distance set, so it can\'t be scheduled on the watch.');
      return;
    }

    // Pre-check: extract the would-be steps so we can surface a friendly
    // error before showing the spinner / hitting the native bridge.
    final intervalPlan = hasIntervals ? _buildIntervalPlan(day) : null;
    if (intervalPlan != null && intervalPlan.steps.isEmpty) {
      await _showResultDialog(context,
          title: "Nothing to send",
          body:
              'This interval session has no work reps to send to the watch.');
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

    final (title, body) = switch (result.status) {
      WorkoutScheduleStatus.scheduled => (
          'Sent to your watch',
          result.message ??
              'Open the Fitness app on your iPhone or Apple Watch to start it.'
        ),
      WorkoutScheduleStatus.duplicate => (
          'Already scheduled',
          result.message ??
              'You already have a workout planned for this day in the Fitness app.'
        ),
      WorkoutScheduleStatus.denied => (
          'Permission needed',
          result.message ??
              'Allow workout scheduling in Settings → RunCoach to send this run to your watch.'
        ),
      WorkoutScheduleStatus.unavailable => (
          'Not available',
          result.message ??
              'Sending workouts to the Apple Watch needs iOS 17 or newer.'
        ),
      WorkoutScheduleStatus.failed => (
          "Couldn't send",
          result.message ?? 'Something went wrong. Try again.'
        ),
    };

    await _showResultDialog(context, title: title, body: body);
  }

  /// Build the WorkoutKit payload from a TrainingDay's intervals list. Old
  /// rows can still contain distance-based recoveries / cooldowns — we
  /// normalize them here so the watch always gets the canonical shape:
  ///   - warmup hoisted to its own slot, time-based, capped at 120s
  ///   - work + recovery flow into the IntervalBlock as steps
  ///   - cooldown hoisted to its own slot, time-based, clamped to [60s, 600s];
  ///     synthesized at 300s if the segment list lacks one (defensive)
  ///
  /// Pure helper — does NOT call the native bridge. The screen invokes the
  /// service with the returned [_IntervalPlan]. This split lets us pre-check
  /// `steps.isEmpty` and show a friendly error before the spinner appears.
  _IntervalPlan _buildIntervalPlan(TrainingDay day) {
    int? warmupSeconds;
    int? cooldownSeconds;
    final steps = <WorkoutIntervalStep>[];

    for (final segment in day.intervals!) {
      switch (segment.kind) {
        case 'warmup':
          // Take only the first warmup encountered; rest are ignored.
          if (warmupSeconds != null) break;
          warmupSeconds = (segment.durationSeconds ?? 60).clamp(15, 120);
          break;
        case 'recovery':
          int? duration = segment.durationSeconds;
          if ((duration == null || duration <= 0) &&
              segment.distanceM != null &&
              segment.distanceM! > 0) {
            // Fall back: convert distance to time using a 6:00/km recovery
            // pace (360 sec/km). Conservative — better too long than too short.
            duration = ((segment.distanceM! / 1000) * 360).round();
          }
          duration ??= 90;
          steps.add(WorkoutIntervalStep(
            kind: 'recovery',
            durationSeconds: duration.clamp(15, 600),
          ));
          break;
        case 'cooldown':
          int? duration = segment.durationSeconds;
          if ((duration == null || duration <= 0) &&
              segment.distanceM != null &&
              segment.distanceM! > 0) {
            duration = ((segment.distanceM! / 1000) * 360).round();
          }
          duration ??= 300;
          cooldownSeconds = duration.clamp(60, 600);
          break;
        case 'work':
        default:
          // Default branch handles unexpected `kind` values defensively as
          // work segments rather than dropping them silently.
          if (segment.distanceM != null && segment.distanceM! > 0) {
            steps.add(WorkoutIntervalStep(
              kind: 'work',
              distanceM: segment.distanceM,
            ));
          } else if (segment.durationSeconds != null &&
              segment.durationSeconds! > 0) {
            steps.add(WorkoutIntervalStep(
              kind: 'work',
              durationSeconds: segment.durationSeconds,
            ));
          }
          break;
      }
    }

    // Cooldown is mandatory in our schema. If the day's payload somehow
    // arrived without one, synthesize the default so the watch session
    // still ends with one.
    cooldownSeconds ??= 300;

    return _IntervalPlan(
      warmupSeconds: warmupSeconds,
      cooldownSeconds: cooldownSeconds,
      steps: steps,
    );
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
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Pure value object: the normalized payload ready to send to the native
/// WorkoutKit bridge. Built by `_buildIntervalPlan` so the screen can
/// pre-check shape (e.g. empty steps) before calling the bridge.
class _IntervalPlan {
  final int? warmupSeconds;
  final int? cooldownSeconds;
  final List<WorkoutIntervalStep> steps;

  const _IntervalPlan({
    required this.warmupSeconds,
    required this.cooldownSeconds,
    required this.steps,
  });
}

class _SendingDialog extends StatelessWidget {
  const _SendingDialog();

  @override
  Widget build(BuildContext context) {
    return const CupertinoAlertDialog(
      content: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoActivityIndicator(radius: 14),
            SizedBox(height: 12),
            Text('Sending to your watch…'),
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

class _AnalysisBody extends ConsumerWidget {
  final int dayId;
  final String? initial;
  const _AnalysisBody({required this.dayId, required this.initial});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = (initial != null && initial!.trim().isNotEmpty)
        ? initial
        : ref.watch(trainingDayAiFeedbackProvider(dayId)).value;

    if (text == null || text.trim().isEmpty) {
      return Row(
        children: [
          const SwooshingStar(size: 18),
          const SizedBox(width: 12),
          Text('Analysing your run…', style: _Loaded._detailTextStyle),
        ],
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).push(
        CupertinoPageRoute(builder: (_) => _AnalysisFullScreen(text: text)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 110,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topLeft,
                maxHeight: double.infinity,
                child: GptMarkdown(text, style: _Loaded._detailTextStyle),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Read more →',
            style: GoogleFonts.publicSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisFullScreen extends StatelessWidget {
  final String text;
  const _AnalysisFullScreen({required this.text});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.neutral,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.neutral.withValues(alpha: 0.92),
        border: null,
        middle: Text(
          'Coach analysis',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryInk,
          ),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: GptMarkdown(text, style: _Loaded._detailTextStyle),
        ),
      ),
    );
  }
}

