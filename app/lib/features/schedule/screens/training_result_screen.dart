import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show
        AlwaysStoppedAnimation,
        Colors,
        Divider,
        InkWell,
        LinearProgressIndicator,
        Material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/gradient_scaffold.dart';
import 'package:app/features/schedule/models/training_result.dart';
import 'package:app/features/schedule/providers/schedule_provider.dart';

class TrainingResultScreen extends ConsumerWidget {
  final int dayId;
  const TrainingResultScreen({super.key, required this.dayId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(trainingDayResultProvider(dayId));
    final dayAsync = ref.watch(trainingDayDetailProvider(dayId));

    return GradientScaffold(
      child: SafeArea(
        child: resultAsync.when(
          loading: () => const AppSpinner(),
          error: (err, _) => AppErrorState(title: 'Error: $err'),
          data: (result) {
            if (result == null) {
              return Center(
                child: Text(
                  'No result recorded yet.',
                  style: GoogleFonts.publicSans(color: AppColors.tertiary),
                ),
              );
            }

            return SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 24 + MediaQuery.paddingOf(context).bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Header(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: _ComplianceHeader(result: result),
                  ),
                  const SizedBox(height: 16),
                  const _SectionTitle('Score breakdown'),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _ScoreBreakdown(result: result),
                  ),
                  dayAsync.whenOrNull(
                        data: (day) {
                          if (day.targetKm == null &&
                              day.targetPaceSecondsPerKm == null &&
                              day.targetHeartRateZone == null) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _SectionTitle('Target vs actual'),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 8, 16, 0),
                                  child: _VsTargetCard(
                                    targetKm: day.targetKm,
                                    actualKm: result.actualKm,
                                    targetPaceSecondsPerKm:
                                        day.targetPaceSecondsPerKm,
                                    actualPaceSecondsPerKm:
                                        result.actualPaceSecondsPerKm,
                                    targetHeartRateZone:
                                        day.targetHeartRateZone,
                                    actualAvgHeartRate:
                                        result.actualAvgHeartRate,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ) ??
                      const SizedBox.shrink(),
                  if (result.aiFeedback != null &&
                      result.aiFeedback!.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const _SectionTitle('Coach feedback'),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: _CoachFeedbackCard(feedback: result.aiFeedback!),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _UnlinkActivityButton(dayId: dayId),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => context.canPop()
                  ? context.pop()
                  : context.go('/schedule'),
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
          const SizedBox(width: 4),
          Text(
            'Training result',
            style: GoogleFonts.ebGaramond(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              color: AppColors.primaryInk,
            ),
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
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.96,
          color: AppColors.inkMuted,
        ),
      ),
    );
  }
}

class _ComplianceHeader extends StatelessWidget {
  final TrainingResult result;
  const _ComplianceHeader({required this.result});

  @override
  Widget build(BuildContext context) {
    // Scores are stored on a 0-10 scale by ComplianceScoringService; clamp
    // and map into 0-1 for the progress bar and 0-100 for the percentage.
    final score01 = (result.complianceScore / 10).clamp(0.0, 1.0);
    final pct = (score01 * 100).round();
    final color = _scoreColor(score01);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 16)],
      ),
      child: Column(
        children: [
          Text(
            '$pct%',
            style: GoogleFonts.ebGaramond(
              fontSize: 44,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Overall compliance',
            style: GoogleFonts.publicSans(
              fontSize: 14,
              color: AppColors.tertiary,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: score01,
              minHeight: 8,
              backgroundColor: AppColors.neutralHighlight,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBreakdown extends StatelessWidget {
  final TrainingResult result;
  const _ScoreBreakdown({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 16)],
      ),
      child: Column(
        children: [
          _ScoreBar(label: 'Distance', score: result.distanceScore),
          const SizedBox(height: 12),
          _ScoreBar(label: 'Pace', score: result.paceScore),
          if (result.heartRateScore != null) ...[
            const SizedBox(height: 12),
            _ScoreBar(label: 'Heart rate', score: result.heartRateScore!),
          ],
        ],
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final double score; // 0-10
  const _ScoreBar({required this.label, required this.score});

  @override
  Widget build(BuildContext context) {
    // Scores are on a 0-10 scale; clamp then map to 0-1 for the bar.
    final score01 = (score / 10).clamp(0.0, 1.0);
    final pct = (score01 * 100).round();
    final color = _scoreColor(score01);

    return Row(
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: GoogleFonts.publicSans(
              fontSize: 13,
              color: AppColors.tertiary,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: score01,
              minHeight: 8,
              backgroundColor: AppColors.neutralHighlight,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 44,
          child: Text(
            '$pct%',
            textAlign: TextAlign.end,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _VsTargetCard extends StatelessWidget {
  final double? targetKm;
  final double actualKm;
  final int? targetPaceSecondsPerKm;
  final int actualPaceSecondsPerKm;
  final int? targetHeartRateZone;
  final double? actualAvgHeartRate;

  const _VsTargetCard({
    required this.targetKm,
    required this.actualKm,
    required this.targetPaceSecondsPerKm,
    required this.actualPaceSecondsPerKm,
    required this.targetHeartRateZone,
    required this.actualAvgHeartRate,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    if (targetKm != null) {
      rows.add(_ComparisonRow(
        label: 'Distance',
        target: '${targetKm!.toStringAsFixed(1)} km',
        actual: '${actualKm.toStringAsFixed(1)} km',
      ));
    }
    if (targetPaceSecondsPerKm != null) {
      rows.add(_ComparisonRow(
        label: 'Pace',
        target: _formatPace(targetPaceSecondsPerKm!),
        actual: _formatPace(actualPaceSecondsPerKm),
      ));
    }
    if (targetHeartRateZone != null || actualAvgHeartRate != null) {
      rows.add(_ComparisonRow(
        label: 'Heart rate',
        target: targetHeartRateZone != null ? 'Zone $targetHeartRateZone' : '-',
        actual: actualAvgHeartRate != null
            ? '${actualAvgHeartRate!.round()} bpm'
            : '-',
      ));
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 16)],
      ),
      child: Column(
        children: [
          const _ComparisonHeader(),
          const SizedBox(height: 4),
          const Divider(
            height: 12,
            thickness: 1,
            color: AppColors.border,
          ),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            rows[i],
          ],
        ],
      ),
    );
  }

  String _formatPace(int s) {
    if (s <= 0) return '-';
    final mm = s ~/ 60;
    final ss = s % 60;
    return '$mm:${ss.toString().padLeft(2, '0')} /km';
  }

}

class _ComparisonHeader extends StatelessWidget {
  const _ComparisonHeader();

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.spaceGrotesk(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
      color: AppColors.inkMuted,
    );

    return Row(
      children: [
        const Expanded(flex: 2, child: SizedBox()),
        Expanded(
          flex: 3,
          child: Text('TARGET', textAlign: TextAlign.center, style: style),
        ),
        Expanded(
          flex: 3,
          child: Text('ACTUAL', textAlign: TextAlign.end, style: style),
        ),
      ],
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String label;
  final String target;
  final String actual;
  const _ComparisonRow({
    required this.label,
    required this.target,
    required this.actual,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.publicSans(
              fontSize: 13,
              color: AppColors.tertiary,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            target,
            textAlign: TextAlign.center,
            style: GoogleFonts.publicSans(
              fontSize: 14,
              color: AppColors.tertiary,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            actual,
            textAlign: TextAlign.end,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryInk,
            ),
          ),
        ),
      ],
    );
  }
}

class _CoachFeedbackCard extends StatelessWidget {
  final String feedback;
  const _CoachFeedbackCard({required this.feedback});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.sparkles,
                color: AppColors.secondary,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                'COACH FEEDBACK',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GptMarkdown(
            feedback,
            style: GoogleFonts.publicSans(
              fontSize: 14,
              height: 1.5,
              color: CupertinoColors.white.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}

Color _scoreColor(double score01) {
  if (score01 >= 0.8) return const Color(0xFF34C759);
  if (score01 >= 0.5) return AppColors.secondary;
  return AppColors.danger;
}

/// Danger-style button that unlinks the wearable activity from this training
/// day. On success pops the result screen (since there's no longer a result
/// to show) and invalidates the schedule providers.
class _UnlinkActivityButton extends ConsumerStatefulWidget {
  final int dayId;
  const _UnlinkActivityButton({required this.dayId});

  @override
  ConsumerState<_UnlinkActivityButton> createState() =>
      _UnlinkActivityButtonState();
}

class _UnlinkActivityButtonState extends ConsumerState<_UnlinkActivityButton> {
  bool _busy = false;

  Future<void> _confirmAndUnlink() async {
    if (_busy) return;

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Unlink activity?'),
        content: const Text(
            'The run stays in Apple Health; it just stops being matched to this training day.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(manualMatchActivityProvider.notifier)
          .unlink(dayId: widget.dayId);

      if (!mounted) return;
      ref.invalidate(trainingDayDetailProvider(widget.dayId));
      ref.invalidate(trainingDayResultProvider(widget.dayId));
      ref.invalidate(scheduleProvider);
      ref.invalidate(currentWeekProvider);
      ref.invalidate(availableActivitiesProvider(widget.dayId));

      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/schedule');
      }
    } catch (e) {
      if (!mounted) return;
      await showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text("Couldn't unlink"),
          content: Text('$e'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFilledButton(
      label: 'Unlink activity',
      icon: CupertinoIcons.link,
      color: AppColors.danger,
      loading: _busy,
      onPressed: _confirmAndUnlink,
    );
  }
}
