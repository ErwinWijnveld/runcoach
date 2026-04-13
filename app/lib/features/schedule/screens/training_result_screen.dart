import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/theme/app_theme.dart';
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
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(trainingDayResultProvider(dayId));
    final dayAsync = ref.watch(trainingDayDetailProvider(dayId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/schedule/day/$dayId'),
        ),
        title: const Text('Training Result'),
      ),
      body: resultAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (result) {
          if (result == null) {
            return const Center(child: Text('No result recorded yet'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overall compliance score
                _ComplianceHeader(result: result),
                const SizedBox(height: 24),

                // Actual metrics
                Text(
                  'ACTUAL PERFORMANCE',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ResultMetricCard(
                        label: 'Distance',
                        value: '${result.actualKm} km',
                        icon: Icons.straighten,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ResultMetricCard(
                        label: 'Pace',
                        value: _formatPace(result.actualPaceSecondsPerKm),
                        icon: Icons.speed,
                      ),
                    ),
                  ],
                ),
                if (result.actualAvgHeartRate != null) ...[
                  const SizedBox(height: 12),
                  _ResultMetricCard(
                    label: 'Avg Heart Rate',
                    value: '${result.actualAvgHeartRate!.round()} bpm',
                    icon: Icons.favorite,
                  ),
                ],

                const SizedBox(height: 24),

                // Score breakdown
                Text(
                  'SCORE BREAKDOWN',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    fontSize: 11,
                  ),
                ),
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

                // Target comparison (if day data available)
                dayAsync.whenOrNull(
                  data: (day) {
                    if (day.targetKm == null && day.targetPaceSecondsPerKm == null) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VS TARGET',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                                    target: _formatPace(day.targetPaceSecondsPerKm!),
                                    actual: _formatPace(result.actualPaceSecondsPerKm),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ) ?? const SizedBox.shrink(),

                // AI Feedback
                if (result.aiFeedback != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.darkBrown,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome, color: AppColors.gold, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'COACH FEEDBACK',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
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
            : Colors.redAccent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            '$pct%',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Overall Compliance',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: result.complianceScore,
              backgroundColor: AppColors.lightTan,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.warmBrown, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score,
              backgroundColor: AppColors.lightTan,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 40,
          child: Text(
            '$pct%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              target,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              actual,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
