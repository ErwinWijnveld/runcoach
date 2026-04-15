import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/features/races/providers/race_provider.dart';
import 'package:app/features/races/models/race.dart';

class RaceDetailScreen extends ConsumerWidget {
  final int raceId;
  const RaceDetailScreen({super.key, required this.raceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final raceAsync = ref.watch(raceDetailProvider(raceId));

    return CupertinoPageScaffold(
      backgroundColor: AppColors.cream,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.cream.withValues(alpha: 0.92),
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.go('/races'),
          child: const Icon(
            CupertinoIcons.back,
            color: AppColors.warmBrown,
          ),
        ),
        middle: const Text('Race Details'),
      ),
      child: SafeArea(
        child: raceAsync.when(
          loading: () => const AppSpinner(),
          error: (_, _) => AppErrorState(
            title: 'Could not load race details',
            onRetry: () => ref.invalidate(raceDetailProvider(raceId)),
          ),
          data: (race) => _RaceDetailBody(race: race),
        ),
      ),
    );
  }
}

class _RaceDetailBody extends ConsumerWidget {
  final Race race;
  const _RaceDetailBody({required this.race});

  int? _daysUntilRace() {
    try {
      final raceDate = DateTime.parse(race.raceDate);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final target = DateTime(raceDate.year, raceDate.month, raceDate.day);
      return target.difference(today).inDays;
    } catch (_) {
      return null;
    }
  }

  String _formatGoalTime() {
    final seconds = race.goalTimeSeconds;
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
    switch (race.status) {
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
      title: 'Cancel Race',
      message: 'Are you sure you want to delete "${race.name}"?',
      confirmLabel: 'Delete',
      cancelLabel: 'No',
      destructive: true,
    );

    if (confirmed && context.mounted) {
      await ref.read(raceActionsProvider.notifier).deleteRace(race.id);
      if (context.mounted) context.go('/races');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysLeft = _daysUntilRace();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (race.status == 'active' && daysLeft != null && daysLeft >= 0)
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
                      race.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkBrown,
                      ),
                    ),
                  ),
                  AppStatusPill(label: race.status, color: _statusColor()),
                ],
              ),
              const SizedBox(height: 20),
              _DetailRow(
                icon: CupertinoIcons.arrow_right_arrow_left,
                label: 'Distance',
                value: race.distance,
              ),
              const SizedBox(height: 12),
              _DetailRow(
                icon: CupertinoIcons.calendar,
                label: 'Race Date',
                value: race.raceDate,
              ),
              const SizedBox(height: 12),
              _DetailRow(
                icon: CupertinoIcons.timer,
                label: 'Goal Time',
                value: _formatGoalTime(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (race.status == 'active')
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
        if (race.status == 'active')
          AppBorderedButton(
            label: 'Delete Race',
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
