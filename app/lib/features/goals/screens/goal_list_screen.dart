import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/features/goals/providers/goal_provider.dart';
import 'package:app/features/goals/models/goal.dart';

class GoalListScreen extends ConsumerWidget {
  const GoalListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.cream,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverNavigationBar(
            backgroundColor: AppColors.cream.withValues(alpha: 0.92),
            border: null,
            largeTitle: const Text('Goals'),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => context.go('/goals/new'),
              child: const Icon(
                CupertinoIcons.add_circled_solid,
                color: AppColors.warmBrown,
              ),
            ),
          ),
          CupertinoSliverRefreshControl(
            onRefresh: () async => ref.invalidate(goalsProvider),
          ),
          goalsAsync.when(
            loading: () => const SliverFillRemaining(child: AppSpinner()),
            error: (_, _) => SliverFillRemaining(
              child: AppErrorState(
                title: 'Could not load goals',
                onRetry: () => ref.invalidate(goalsProvider),
              ),
            ),
            data: (goals) {
              if (goals.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.flag,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No goals yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add your first goal to get a training plan',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final active = goals.where((g) => g.status == 'active').toList();
              final past = goals.where((g) => g.status != 'active').toList();

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverList.list(
                  children: [
                    if (active.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'Active Goals',
                        count: active.length,
                      ),
                      const SizedBox(height: 8),
                      ...active.map(
                        (goal) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _GoalCard(goal: goal),
                        ),
                      ),
                    ],
                    if (past.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _SectionHeader(title: 'Past Goals', count: past.length),
                      const SizedBox(height: 8),
                      ...past.map(
                        (goal) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _GoalCard(goal: goal),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.darkBrown,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.warmBrown.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.warmBrown,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  final Goal goal;
  const _GoalCard({required this.goal});

  Color _statusColor() {
    switch (goal.status) {
      case 'active':
        return AppColors.success;
      case 'completed':
        return AppColors.warmBrown;
      case 'cancelled':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatGoalTime() {
    final seconds = goal.goalTimeSeconds;
    if (seconds == null) return '--';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) {
      return '${h}h ${m.toString().padLeft(2, '0')}m';
    }
    return '${m}m';
  }

  int? _daysUntil() {
    final td = goal.targetDate;
    if (td == null) return null;
    try {
      final date = DateTime.parse(td);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final target = DateTime(date.year, date.month, date.day);
      return target.difference(today).inDays;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysLeft = _daysUntil();

    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: () => context.go('/goals/${goal.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              AppStatusPill(label: goal.status, color: _statusColor()),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (goal.distance != null)
                AppChip(
                  icon: CupertinoIcons.arrow_right_arrow_left,
                  label: goal.distance!,
                ),
              if (goal.targetDate != null)
                AppChip(icon: CupertinoIcons.calendar, label: goal.targetDate!),
              if (goal.goalTimeSeconds != null)
                AppChip(icon: CupertinoIcons.timer, label: _formatGoalTime()),
            ],
          ),
          if (goal.status == 'active' &&
              daysLeft != null &&
              daysLeft >= 0) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warmBrown.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
              child: Text(
                daysLeft == 0 ? 'Race day!' : '$daysLeft days to go',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warmBrown,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
