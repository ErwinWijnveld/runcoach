import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/features/goals/providers/goal_provider.dart';
import 'package:app/features/goals/models/goal.dart';

class GoalDetailScreen extends ConsumerWidget {
  final int goalId;
  const GoalDetailScreen({super.key, required this.goalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalAsync = ref.watch(goalDetailProvider(goalId));

    return CupertinoPageScaffold(
      backgroundColor: AppColors.cream,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.cream.withValues(alpha: 0.92),
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.go('/goals'),
          child: const Icon(
            CupertinoIcons.back,
            color: AppColors.warmBrown,
          ),
        ),
        middle: const Text('Goal Details'),
      ),
      child: SafeArea(
        child: goalAsync.when(
          loading: () => const AppSpinner(),
          error: (_, _) => AppErrorState(
            title: 'Could not load goal details',
            onRetry: () => ref.invalidate(goalDetailProvider(goalId)),
          ),
          data: (goal) => _GoalDetailBody(goal: goal),
        ),
      ),
    );
  }
}

class _GoalDetailBody extends ConsumerWidget {
  final Goal goal;
  const _GoalDetailBody({required this.goal});

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

  String _formatGoalTime() {
    final seconds = goal.goalTimeSeconds;
    if (seconds == null) return 'Not set';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h}h ${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
    }
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

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

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAppConfirm(
      context,
      title: 'Delete Goal',
      message: 'Are you sure you want to delete "${goal.name}"?',
      confirmLabel: 'Delete',
      cancelLabel: 'No',
      destructive: true,
    );

    if (confirmed && context.mounted) {
      await ref.read(goalActionsProvider.notifier).deleteGoal(goal.id);
      if (context.mounted) context.go('/goals');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysLeft = _daysUntil();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (goal.status == 'active' && daysLeft != null && daysLeft >= 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.warmBrown,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Column(
              children: [
                Text(
                  daysLeft == 0 ? 'Race Day!' : '$daysLeft',
                  style: const TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w700,
                    color: CupertinoColors.white,
                    letterSpacing: -1,
                  ),
                ),
                if (daysLeft > 0)
                  Text(
                    'days to go',
                    style: TextStyle(
                      fontSize: 16,
                      color: CupertinoColors.white.withValues(alpha: 0.85),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      goal.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkBrown,
                      ),
                    ),
                  ),
                  AppStatusPill(label: goal.status, color: _statusColor()),
                ],
              ),
              const SizedBox(height: 20),
              if (goal.distance != null) ...[
                _DetailRow(
                  icon: CupertinoIcons.arrow_right_arrow_left,
                  label: 'Distance',
                  value: goal.distance!,
                ),
                const SizedBox(height: 12),
              ],
              if (goal.targetDate != null) ...[
                _DetailRow(
                  icon: CupertinoIcons.calendar,
                  label: 'Target Date',
                  value: goal.targetDate!,
                ),
                const SizedBox(height: 12),
              ],
              _DetailRow(
                icon: CupertinoIcons.timer,
                label: 'Goal Time',
                value: _formatGoalTime(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (goal.status == 'active')
          AppCard(
            padding: const EdgeInsets.all(16),
            onTap: () => context.go('/schedule'),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  child: const Icon(
                    CupertinoIcons.calendar,
                    color: AppColors.gold,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Training Schedule',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'View your weekly training plan',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  CupertinoIcons.chevron_right,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        if (goal.status == 'active')
          AppBorderedButton(
            label: 'Delete Goal',
            icon: CupertinoIcons.delete,
            color: AppColors.danger,
            onPressed: () => _confirmDelete(context, ref),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.warmBrown),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
