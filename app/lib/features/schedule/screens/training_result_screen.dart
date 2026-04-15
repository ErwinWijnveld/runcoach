import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/features/schedule/providers/schedule_provider.dart';
import 'package:app/features/schedule/models/training_result.dart';

class TrainingResultScreen extends ConsumerWidget {
  final int dayId;
  const TrainingResultScreen({super.key, required this.dayId});

  String _formatPace(int secondsPerKm) {
    final minutes = secondsPerKm ~/ 60;
    final seconds = secondsPerKm % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')} /km';
  }

  Color _scoreColor(double score) {
    if (score >= 0.8) return AppColors.success;
    if (score >= 0.5) return AppColors.gold;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(trainingDayResultProvider(dayId));
    final dayAsync = ref.watch(trainingDayDetailProvider(dayId));

    return CupertinoPageScaffold(
      backgroundColor: AppColors.cream,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.cream.withValues(alpha: 0.92),
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.go('/schedule/day/$dayId'),
          child: const Icon(
            CupertinoIcons.back,
            color: AppColors.warmBrown,
          ),
        ),
        middle: const Text('Training Result'),
      ),
      child: SafeArea(
        child: resultAsync.when(
          loading: () => const AppSpinner(),
          error: (err, _) => AppErrorState(title: 'Error: $err'),
          data: (result) {
            if (result == null) {
              return const Center(
                child: Text(
                  'No result recorded yet',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ComplianceHeader(result: result),
                  const SizedBox(height: 24),
                  const AppSectionLabel('ACTUAL PERFORMANCE'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ResultMetricCard(
                          label: 'Distance',
                          value: '${result.actualKm} km',
                          icon: CupertinoIcons.arrow_right_arrow_left,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ResultMetricCard(
                          label: 'Pace',
                          value: _formatPace(result.actualPaceSecondsPerKm),
                          icon: CupertinoIcons.speedometer,
                        ),
                      ),
                    ],
                  ),
                  if (result.actualAvgHeartRate != null) ...[
                    const SizedBox(height: 12),
                    _ResultMetricCard(
                      label: 'Avg Heart Rate',
                      value: '${result.actualAvgHeartRate!.round()} bpm',
                      icon: CupertinoIcons.heart_fill,
                    ),
                  ],
                  const SizedBox(height: 24),
                  const AppSectionLabel('SCORE BREAKDOWN'),
                  const SizedBox(height: 12),
                  _ScoreBar(
                    label: 'Distance',
                    score: result.distanceScore,
                    color: _scoreColor(result.distanceScore),
                  ),
                  const SizedBox(height: 8),
                  _ScoreBar(
                    label: 'Pace',
                    score: result.paceScore,
                    color: _scoreColor(result.paceScore),
                  ),
                  if (result.heartRateScore != null) ...[
                    const SizedBox(height: 8),
                    _ScoreBar(
                      label: 'Heart Rate',
                      score: result.heartRateScore!,
                      color: _scoreColor(result.heartRateScore!),
                    ),
                  ],
                  dayAsync.whenOrNull(
                        data: (day) {
                          if (day.targetKm == null &&
                              day.targetPaceSecondsPerKm == null) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const AppSectionLabel('VS TARGET'),
                                const SizedBox(height: 12),
                                AppCard(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      if (day.targetKm != null)
                                        _ComparisonRow(
                                          label: 'Distance',
                                          target: '${day.targetKm} km',
                                          actual: '${result.actualKm} km',
                                        ),
                                      if (day.targetPaceSecondsPerKm != null)
                                        _ComparisonRow(
                                          label: 'Pace',
                                          target: _formatPace(
                                            day.targetPaceSecondsPerKm!,
                                          ),
                                          actual: _formatPace(
                                            result.actualPaceSecondsPerKm,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ) ??
                      const SizedBox.shrink(),
                  if (result.aiFeedback != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.darkBrown,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                CupertinoIcons.sparkles,
                                color: AppColors.gold,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'COACH FEEDBACK',
                                style: TextStyle(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            result.aiFeedback!,
                            style: TextStyle(
                              color:
                                  CupertinoColors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
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
    final pct = (result.complianceScore * 100).round();
    final color = result.complianceScore >= 0.8
        ? AppColors.success
        : result.complianceScore >= 0.5
            ? AppColors.gold
            : AppColors.danger;

    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            '$pct%',
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Overall Compliance',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          AppLinearBar(
            value: result.complianceScore,
            color: color,
            height: 8,
          ),
        ],
      ),
    );
  }
}

class _ResultMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _ResultMetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.warmBrown, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final double score;
  final Color color;
  const _ScoreBar({
    required this.label,
    required this.score,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (score * 100).round();
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: AppLinearBar(value: score, color: color, height: 8),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 40,
          child: Text(
            '$pct%',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            textAlign: TextAlign.end,
          ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              target,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              actual,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
