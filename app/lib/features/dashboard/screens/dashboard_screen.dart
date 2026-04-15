import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/features/dashboard/providers/dashboard_provider.dart';
import 'package:app/features/dashboard/models/dashboard_data.dart';
import 'package:app/features/schedule/models/training_day.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.cream,
      child: dashboardAsync.when(
        loading: () => const SafeArea(child: AppSpinner()),
        error: (_, _) => SafeArea(
          child: AppErrorState(
            title: 'Could not load dashboard',
            onRetry: () => ref.invalidate(dashboardProvider),
          ),
        ),
        data: (data) => CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            const CupertinoSliverNavigationBar(
              backgroundColor: Color(0xE6FAF8F4),
              border: null,
              largeTitle: Text('Dashboard'),
            ),
            CupertinoSliverRefreshControl(
              onRefresh: () async => ref.invalidate(dashboardProvider),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              sliver: SliverList.list(
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
          ],
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
    final complianceText = compliance != null ? '${compliance.round()}%' : '--';
    final progress = summary.totalKmPlanned > 0
        ? summary.totalKmCompleted / summary.totalKmPlanned
        : 0.0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: CupertinoIcons.chart_bar_alt_fill,
            title: 'This Week',
            iconColor: AppColors.warmBrown,
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
          const SizedBox(height: 16),
          AppLinearBar(value: progress),
        ],
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
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.darkBrown,
          ),
        ),
        Text(
          sub,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
    return AppCard(
      onTap: () => context.go('/schedule/day/${training.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: CupertinoIcons.bolt_fill,
            title: 'Next Training',
            iconColor: AppColors.gold,
            trailing: AppStatusPill(
              label: _formatDate(training.date),
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            training.title,
            style: const TextStyle(
              fontSize: 16,
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
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (training.targetKm != null) ...[
                AppChip(
                  icon: CupertinoIcons.arrow_right_arrow_left,
                  label: '${training.targetKm!.toStringAsFixed(1)} km',
                ),
                const SizedBox(width: 8),
              ],
              AppChip(icon: CupertinoIcons.tag, label: training.type),
            ],
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
    return AppCard(
      onTap: () => context.go('/races/${race.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: CupertinoIcons.flag_fill,
            title: 'Active Race',
            iconColor: AppColors.warmBrown,
          ),
          const SizedBox(height: 12),
          Text(
            race.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              AppChip(
                icon: CupertinoIcons.arrow_right_arrow_left,
                label: race.distance,
              ),
              const SizedBox(width: 8),
              AppChip(icon: CupertinoIcons.calendar, label: race.raceDate),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.warmBrown.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Text(
              '${race.weeksUntilRace} weeks to go',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.warmBrown,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachInsightCard extends StatelessWidget {
  final String insight;
  const _CoachInsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: CupertinoIcons.sparkles,
            title: 'Coach Insight',
            iconColor: AppColors.gold,
          ),
          const SizedBox(height: 12),
          Text(
            insight,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color iconColor;
  final Widget? trailing;
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.darkBrown,
          ),
        ),
        if (trailing != null) ...[
          const Spacer(),
          trailing!,
        ],
      ],
    );
  }
}
