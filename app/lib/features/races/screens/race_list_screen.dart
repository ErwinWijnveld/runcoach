import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/features/races/providers/race_provider.dart';
import 'package:app/features/races/models/race.dart';

class RaceListScreen extends ConsumerWidget {
  const RaceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final racesAsync = ref.watch(racesProvider);

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
            largeTitle: const Text('Races'),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => context.go('/races/new'),
              child: const Icon(
                CupertinoIcons.add_circled_solid,
                color: AppColors.warmBrown,
              ),
            ),
          ),
          CupertinoSliverRefreshControl(
            onRefresh: () async => ref.invalidate(racesProvider),
          ),
          racesAsync.when(
            loading: () => const SliverFillRemaining(child: AppSpinner()),
            error: (_, _) => SliverFillRemaining(
              child: AppErrorState(
                title: 'Could not load races',
                onRetry: () => ref.invalidate(racesProvider),
              ),
            ),
            data: (races) {
              if (races.isEmpty) {
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
                          'No races yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add your first race to get a training plan',
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

              final active = races.where((r) => r.status == 'active').toList();
              final past = races.where((r) => r.status != 'active').toList();

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverList.list(
                  children: [
                    if (active.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'Active Races',
                        count: active.length,
                      ),
                      const SizedBox(height: 8),
                      ...active.map(
                        (race) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _RaceCard(race: race),
                        ),
                      ),
                    ],
                    if (past.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _SectionHeader(title: 'Past Races', count: past.length),
                      const SizedBox(height: 8),
                      ...past.map(
                        (race) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _RaceCard(race: race),
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
      return target.difference(today).inDays;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysLeft = _daysUntilRace();

    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: () => context.go('/races/${race.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  race.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              AppStatusPill(label: race.status, color: _statusColor()),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppChip(
                icon: CupertinoIcons.arrow_right_arrow_left,
                label: race.distance,
              ),
              AppChip(icon: CupertinoIcons.calendar, label: race.raceDate),
              if (race.goalTimeSeconds != null)
                AppChip(icon: CupertinoIcons.timer, label: _formatGoalTime()),
            ],
          ),
          if (race.status == 'active' &&
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
