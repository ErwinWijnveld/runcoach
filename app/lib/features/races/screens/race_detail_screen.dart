import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/races/providers/race_provider.dart';
import 'package:app/features/races/models/race.dart';

class RaceDetailScreen extends ConsumerWidget {
  final int raceId;
  const RaceDetailScreen({super.key, required this.raceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final raceAsync = ref.watch(raceDetailProvider(raceId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Race Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/races'),
        ),
      ),
      body: raceAsync.when(
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
                'Could not load race details',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(raceDetailProvider(raceId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (race) => _RaceDetailBody(race: race),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Race'),
        content: Text('Are you sure you want to delete "${race.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(raceActionsProvider.notifier).deleteRace(race.id);
      if (context.mounted) {
        context.go('/races');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysLeft = _daysUntilRace();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Countdown banner
        if (race.status == 'active' && daysLeft != null && daysLeft >= 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.warmBrown,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  daysLeft == 0 ? 'Race Day!' : '$daysLeft',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (daysLeft > 0)
                  Text(
                    'days to go',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // Race info card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        race.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkBrown,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor().withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        race.status,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _statusColor(),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _DetailRow(
                  icon: Icons.straighten,
                  label: 'Distance',
                  value: race.distance,
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.calendar_today,
                  label: 'Race Date',
                  value: race.raceDate,
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.timer,
                  label: 'Goal Time',
                  value: _formatGoalTime(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // View schedule link
        if (race.status == 'active')
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.go('/schedule'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_month,
                        color: AppColors.gold,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Training Schedule',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'View your weekly training plan',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 24),

        // Action buttons
        if (race.status == 'active')
          OutlinedButton.icon(
            onPressed: () => _confirmDelete(context, ref),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: const Text('Delete Race'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.warmBrown),
        const SizedBox(width: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
