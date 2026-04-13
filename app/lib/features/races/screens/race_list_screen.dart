import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/races/providers/race_provider.dart';
import 'package:app/features/races/models/race.dart';

class RaceListScreen extends ConsumerWidget {
  const RaceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final racesAsync = ref.watch(racesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Races'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/races/new'),
        backgroundColor: AppColors.warmBrown,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: racesAsync.when(
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
                'Could not load races',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(racesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (races) {
          if (races.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.flag_outlined, size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    'No races yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first race to get a training plan',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          final active = races.where((r) => r.status == 'active').toList();
          final past = races.where((r) => r.status != 'active').toList();

          return RefreshIndicator(
            color: AppColors.warmBrown,
            onRefresh: () async => ref.invalidate(racesProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (active.isNotEmpty) ...[
                  _SectionHeader(title: 'Active Races', count: active.length),
                  const SizedBox(height: 8),
                  ...active.map((race) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RaceCard(race: race),
                  )),
                ],
                if (past.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _SectionHeader(title: 'Past Races', count: past.length),
                  const SizedBox(height: 8),
                  ...past.map((race) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RaceCard(race: race),
                  )),
                ],
              ],
            ),
          );
        },
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.warmBrown,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _RaceCard extends StatelessWidget {
  final Race race;
  const _RaceCard({required this.race});

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

  String _formatGoalTime() {
    final seconds = race.goalTimeSeconds;
    if (seconds == null) return '--';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) {
      return '${h}h ${m.toString().padLeft(2, '0')}m';
    }
    return '${m}m';
  }

  int? _daysUntilRace() {
    try {
      final raceDate = DateTime.parse(race.raceDate);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final target = DateTime(raceDate.year, raceDate.month, raceDate.day);
      final diff = target.difference(today).inDays;
      return diff;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysLeft = _daysUntilRace();

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/races/${race.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      race.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
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
              const SizedBox(height: 12),
              Row(
                children: [
                  _InfoChip(icon: Icons.straighten, label: race.distance),
                  const SizedBox(width: 8),
                  _InfoChip(icon: Icons.calendar_today, label: race.raceDate),
                  if (race.goalTimeSeconds != null) ...[
                    const SizedBox(width: 8),
                    _InfoChip(icon: Icons.timer, label: _formatGoalTime()),
                  ],
                ],
              ),
              if (race.status == 'active' && daysLeft != null && daysLeft >= 0) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.warmBrown.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    daysLeft == 0 ? 'Race day!' : '$daysLeft days to go',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.warmBrown,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
