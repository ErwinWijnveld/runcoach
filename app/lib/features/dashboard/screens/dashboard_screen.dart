import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/dashboard/providers/dashboard_provider.dart';
import 'package:app/features/dashboard/models/dashboard_data.dart';
import 'package:app/features/schedule/models/training_day.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: dashboardAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.warmBrown),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                'Could not load dashboard',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(dashboardProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (data) => RefreshIndicator(
          color: AppColors.warmBrown,
          onRefresh: () async => ref.invalidate(dashboardProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (data.weeklySummary != null)
                _WeeklySummaryCard(summary: data.weeklySummary!),
              if (data.nextTraining != null) ...[
                const SizedBox(height: 16),
                _NextTrainingCard(training: data.nextTraining!),
              ],
              if (data.activeRace != null) ...[
                const SizedBox(height: 16),
                _ActiveRaceCard(race: data.activeRace!),
              ],
              if (data.coachInsight != null) ...[
                const SizedBox(height: 16),
                _CoachInsightCard(insight: data.coachInsight!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklySummaryCard extends StatelessWidget {
  final WeeklySummary summary;
  const _WeeklySummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final compliance = summary.complianceAvg;
    final complianceText = compliance != null
        ? '${compliance.round()}%'
        : '--';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, color: AppColors.warmBrown, size: 20),
                const SizedBox(width: 8),
                Text(
                  'This Week',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBrown,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatColumn(
                    label: 'Distance',
                    value: '${summary.totalKmCompleted.toStringAsFixed(1)} km',
                    sub: 'of ${summary.totalKmPlanned.toStringAsFixed(1)} km',
                  ),
                ),
                Expanded(
                  child: _StatColumn(
                    label: 'Sessions',
                    value: '${summary.sessionsCompleted}/${summary.sessionsTotal}',
                    sub: 'completed',
                  ),
                ),
                Expanded(
                  child: _StatColumn(
                    label: 'Compliance',
                    value: complianceText,
                    sub: 'average',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: summary.totalKmPlanned > 0
                    ? (summary.totalKmCompleted / summary.totalKmPlanned).clamp(0.0, 1.0)
                    : 0.0,
                minHeight: 6,
                backgroundColor: AppColors.lightTan,
                valueColor: const AlwaysStoppedAnimation(AppColors.success),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  const _StatColumn({required this.label, required this.value, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.darkBrown,
          ),
        ),
        Text(
          sub,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _NextTrainingCard extends StatelessWidget {
  final TrainingDay training;
  const _NextTrainingCard({required this.training});

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final trainingDate = DateTime(date.year, date.month, date.day);
      final diff = trainingDate.difference(today).inDays;

      if (diff == 0) return 'Today';
      if (diff == 1) return 'Tomorrow';
      return 'In $diff days';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/schedule/day/${training.id}'),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.directions_run, color: AppColors.gold, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Next Training',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBrown,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatDate(training.date),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                training.title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (training.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  training.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (training.targetKm != null)
                    _TrainingChip(
                      icon: Icons.straighten,
                      label: '${training.targetKm!.toStringAsFixed(1)} km',
                    ),
                  if (training.targetKm != null)
                    const SizedBox(width: 8),
                  _TrainingChip(
                    icon: Icons.category_outlined,
                    label: training.type,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrainingChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TrainingChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.lightTan,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.warmBrown),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.warmBrown,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveRaceCard extends StatelessWidget {
  final ActiveRaceSummary race;
  const _ActiveRaceCard({required this.race});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/races/${race.id}'),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.flag, color: AppColors.warmBrown, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Active Race',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBrown,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                race.name,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _TrainingChip(icon: Icons.straighten, label: race.distance),
                  const SizedBox(width: 8),
                  _TrainingChip(
                    icon: Icons.calendar_today,
                    label: race.raceDate,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.warmBrown.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${race.weeksUntilRace} weeks to go',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.warmBrown,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoachInsightCard extends StatelessWidget {
  final String insight;
  const _CoachInsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.gold, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Coach Insight',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBrown,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              insight,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
