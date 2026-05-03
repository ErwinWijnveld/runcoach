import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, InkWell, Material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/theme/compliance_colors.dart';
import 'package:app/core/widgets/ai_glow_card.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/compliance_ring.dart';
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
        bottom: false,
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: resultAsync.when(
                loading: () => const AppSpinner(),
                error: (err, _) => AppErrorState(title: 'Error: $err'),
                data: (result) {
                  if (result == null) {
                    return Center(
                      child: Text(
                        'No result recorded yet.',
                        style: GoogleFonts.publicSans(
                          color: AppColors.tertiary,
                        ),
                      ),
                    );
                  }
                  return _ResultBody(
                    dayId: dayId,
                    result: result,
                    dayAsync: dayAsync,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultBody extends StatelessWidget {
  final int dayId;
  final TrainingResult result;
  final AsyncValue dayAsync;

  const _ResultBody({
    required this.dayId,
    required this.result,
    required this.dayAsync,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ComplianceSection(result: result),
                  ...dayAsync.when<List<Widget>>(
                    data: (day) {
                      if (day == null) return const [];
                      if (day.targetKm == null &&
                          day.targetPaceSecondsPerKm == null &&
                          day.targetHeartRateZone == null) {
                        return const [];
                      }
                      return [
                        _TargetVsActualSection(
                          targetKm: day.targetKm,
                          actualKm: result.actualKm,
                          distanceScore10: result.distanceScore,
                          targetPaceSecondsPerKm: day.targetPaceSecondsPerKm,
                          actualPaceSecondsPerKm: result.actualPaceSecondsPerKm,
                          paceScore10: result.paceScore,
                          targetHeartRateZone: day.targetHeartRateZone,
                          actualAvgHeartRate: result.actualAvgHeartRate,
                          heartRateScore10: result.heartRateScore,
                        ),
                      ];
                    },
                    loading: () => const [],
                    error: (_, _) => const [],
                  ),
                  if (result.aiFeedback != null &&
                      result.aiFeedback!.trim().isNotEmpty)
                    _CoachFeedbackSection(feedback: result.aiFeedback!),
                  const Spacer(),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      24,
                      20,
                      16 + bottomInset,
                    ),
                    child: _UnlinkActivityButton(dayId: dayId),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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

class _Eyebrow extends StatelessWidget {
  final String label;
  const _Eyebrow(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
        color: AppColors.inkMuted,
      ),
    );
  }
}

class _ComplianceSection extends StatelessWidget {
  final TrainingResult result;
  const _ComplianceSection({required this.result});

  @override
  Widget build(BuildContext context) {
    final overall01 = (result.complianceScore / 10).clamp(0.0, 1.0);

    final bars = <_BarData>[
      _BarData(
        label: 'DISTANCE',
        score01: (result.distanceScore / 10).clamp(0.0, 1.0),
      ),
      _BarData(
        label: 'PACE',
        score01: (result.paceScore / 10).clamp(0.0, 1.0),
      ),
      if (result.heartRateScore != null)
        _BarData(
          label: 'HEART',
          score01: (result.heartRateScore! / 10).clamp(0.0, 1.0),
        ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('COMPLIANCE'),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: ComplianceRing(
                    score01: overall01,
                    size: 124,
                    strokeWidth: 7,
                    textStyle: GoogleFonts.ebGaramond(
                      fontSize: 34,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                      color: ComplianceColors.forScore01(overall01),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final bar in bars) _ComplianceBar(data: bar),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarData {
  final String label;
  final double score01;
  _BarData({required this.label, required this.score01});
}

class _ComplianceBar extends StatelessWidget {
  final _BarData data;
  const _ComplianceBar({required this.data});

  static const double _maxBarHeight = 96;
  static const double _minBarHeight = 14;

  @override
  Widget build(BuildContext context) {
    final pct = (data.score01 * 100).round();
    final color = ComplianceColors.forScore01(data.score01);
    final fillHeight = (data.score01 * _maxBarHeight).clamp(
      _minBarHeight,
      _maxBarHeight,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _maxBarHeight + 22,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '$pct%',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 30,
                height: fillHeight,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          data.label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: AppColors.inkMuted,
          ),
        ),
      ],
    );
  }
}

class _TargetVsActualSection extends StatelessWidget {
  final double? targetKm;
  final double actualKm;
  final double distanceScore10;
  final int? targetPaceSecondsPerKm;
  final int actualPaceSecondsPerKm;
  final double paceScore10;
  final int? targetHeartRateZone;
  final double? actualAvgHeartRate;
  final double? heartRateScore10;

  const _TargetVsActualSection({
    required this.targetKm,
    required this.actualKm,
    required this.distanceScore10,
    required this.targetPaceSecondsPerKm,
    required this.actualPaceSecondsPerKm,
    required this.paceScore10,
    required this.targetHeartRateZone,
    required this.actualAvgHeartRate,
    required this.heartRateScore10,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <_ComparisonRow>[];
    if (targetKm != null) {
      rows.add(_ComparisonRow(
        label: 'Distance',
        target: '${_trimDouble(targetKm!)} km',
        actual: '${_trimDouble(actualKm)} km',
        actualColor: ComplianceColors.forScore10(distanceScore10),
      ));
    }
    if (targetPaceSecondsPerKm != null) {
      rows.add(_ComparisonRow(
        label: 'Pace',
        target: _formatPace(targetPaceSecondsPerKm!),
        actual: _formatPace(actualPaceSecondsPerKm),
        actualColor: ComplianceColors.forScore10(paceScore10),
      ));
    }
    if (targetHeartRateZone != null || actualAvgHeartRate != null) {
      rows.add(_ComparisonRow(
        label: 'Heart rate',
        target: targetHeartRateZone != null ? 'Zone $targetHeartRateZone' : '—',
        actual: actualAvgHeartRate != null
            ? '${actualAvgHeartRate!.round()} bpm'
            : '—',
        actualColor: ComplianceColors.forScore10(heartRateScore10),
      ));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('TARGET VS ACTUAL'),
          const SizedBox(height: 14),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Color(0x08000000), blurRadius: 16),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _ComparisonHeader(),
                  for (final row in rows) ...[
                    const _RowDivider(),
                    row,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _trimDouble(double v) => v.toStringAsFixed(1);

  static String _formatPace(int s) {
    if (s <= 0) return '—';
    final mm = s ~/ 60;
    final ss = s % 60;
    return "$mm'${ss.toString().padLeft(2, '0')}/km";
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: AppColors.border,
      margin: const EdgeInsets.symmetric(vertical: 14),
    );
  }
}

class _ComparisonHeader extends StatelessWidget {
  const _ComparisonHeader();

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.spaceGrotesk(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.4,
      color: AppColors.tertiary,
    );

    return Row(
      children: [
        const Expanded(flex: 4, child: SizedBox()),
        Expanded(
          flex: 3,
          child: Text('TARGET', textAlign: TextAlign.end, style: style),
        ),
        const SizedBox(width: 16),
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
    required this.actualColor,
  });

  final Color? actualColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: GoogleFonts.publicSans(
              fontSize: 17,
              fontWeight: FontWeight.w400,
              color: AppColors.primaryInk,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            target,
            textAlign: TextAlign.end,
            style: GoogleFonts.ebGaramond(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w400,
              color: AppColors.tertiary,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: Text(
            actual,
            textAlign: TextAlign.end,
            style: GoogleFonts.ebGaramond(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: actualColor ?? AppColors.primaryInk,
            ),
          ),
        ),
      ],
    );
  }
}

class _CoachFeedbackSection extends StatelessWidget {
  final String feedback;
  const _CoachFeedbackSection({required this.feedback});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('COACH FEEDBACK'),
          const SizedBox(height: 14),
          AiGlowCard(
            child: GptMarkdown(
              feedback,
              style: GoogleFonts.publicSans(
                fontSize: 15,
                height: 1.55,
                color: AppColors.primaryInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
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
