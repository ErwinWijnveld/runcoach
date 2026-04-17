import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, InkWell, Material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/coach_prompt_bar.dart';
import 'package:app/features/coach/widgets/swooshing_star.dart';
import 'package:app/features/schedule/data/training_day_coach_suggestions.dart';
import 'package:app/features/schedule/models/training_day.dart';
import 'package:app/features/schedule/providers/schedule_provider.dart';
import 'package:app/features/schedule/widgets/select_strava_run_sheet.dart';
import 'package:app/features/schedule/widgets/strava_summary_card.dart';
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

    return CupertinoPageScaffold(
      backgroundColor: AppColors.neutral,
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

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BackButton(),
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
                    onSendToWatch: () => _showWatchPlaceholder(context),
                    onSelectStravaRun: () => SelectStravaRunSheet.show(
                      context,
                      dayId: day.id,
                      onMatched: () {
                        // Day detail needs the new result nested in.
                        ref.invalidate(trainingDayDetailProvider(day.id));
                        ref.invalidate(trainingDayResultProvider(day.id));
                        // Weekly schedule list / current-week list render
                        // "completed" badges from TrainingResult too.
                        // Invalidating the family refetches all keyed
                        // instances.
                        ref.invalidate(scheduleProvider);
                        ref.invalidate(currentWeekProvider);
                      },
                    ),
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
                    day.result?.stravaActivity != null) ...[
                  const SizedBox(height: 16),
                  const _SectionTitle('Synced Strava run'),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: StravaSummaryCard(
                      activity: day.result!.stravaActivity!,
                      onOpenDetails: () =>
                          context.push('/schedule/day/${day.id}/result'),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        // Coach prompt bar docked at bottom, like Figma.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: CoachPromptBar.navigateAnimated(
                onTap: () => context.go('/coach'),
                animatedSuggestions: trainingDayCoachSuggestions,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String? _formatDistance(TrainingDay d) {
    final actualKm = d.result?.actualKm;
    final km = actualKm ?? d.targetKm;
    if (km == null) return null;
    return km.toStringAsFixed(km.truncateToDouble() == km ? 0 : 1);
  }

  String? _formatPace(TrainingDay d) {
    final actual = d.result?.actualPaceSecondsPerKm;
    final secs = actual ?? d.targetPaceSecondsPerKm;
    if (secs == null) return null;
    final mm = secs ~/ 60;
    final ss = secs % 60;
    return '$mm:${ss.toString().padLeft(2, '0')}';
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

  Future<void> _showWatchPlaceholder(BuildContext context) {
    return showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Coming soon'),
        content: const Text(
            "'Send to watch' will push this session to your Garmin / Apple Watch once we wire the integration."),
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

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Material(
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

