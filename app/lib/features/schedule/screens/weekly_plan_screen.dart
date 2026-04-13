import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/dashboard/providers/dashboard_provider.dart';
import 'package:app/features/schedule/providers/schedule_provider.dart';
import 'package:app/features/schedule/models/training_day.dart';

class WeeklyPlanScreen extends ConsumerWidget {
  const WeeklyPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return dashboardAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        body: Center(child: Text('Error: $err')),
      ),
      data: (dashboard) {
        final race = dashboard.activeRace;
        if (race == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today, size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  const Text('No active training plan'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => context.go('/coach'),
                    child: const Text('Create one with AI Coach'),
                  ),
                ],
              ),
            ),
          );
        }

        final weekAsync = ref.watch(currentWeekProvider(race.id));

        return weekAsync.when(
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => Scaffold(
            body: Center(child: Text('Error: $err')),
          ),
          data: (week) {
            if (week == null) {
              return const Scaffold(
                body: Center(child: Text('No training week found')),
              );
            }

            final days = week.trainingDays ?? [];

            return Scaffold(
              body: SafeArea(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Week ${week.weekNumber}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  'Weekly Plan',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${week.totalKm}',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.warmBrown,
                                  ),
                                ),
                                Text(
                                  'KM TOTAL',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _TrainingDayTile(
                          day: days[index],
                          onTap: () => context.go('/schedule/day/${days[index].id}'),
                        ),
                        childCount: days.length,
                      ),
                    ),
                    if (week.coachNotes != null)
                      SliverToBoxAdapter(
                        child: _CoachInsightCard(notes: week.coachNotes!),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TrainingDayTile extends StatelessWidget {
  final TrainingDay day;
  final VoidCallback onTap;

  const _TrainingDayTile({required this.day, required this.onTap});

  bool get _isToday {
    final now = DateTime.now();
    final dayDate = DateTime.tryParse(day.date);
    return dayDate != null &&
        dayDate.year == now.year &&
        dayDate.month == now.month &&
        dayDate.day == now.day;
  }

  bool get _isCompleted => day.result != null;

  IconData get _statusIcon {
    if (_isCompleted) return Icons.check_circle;
    if (_isToday) return Icons.bolt;
    return Icons.nightlight_round;
  }

  Color get _statusColor {
    if (_isCompleted) return AppColors.success;
    if (_isToday) return AppColors.gold;
    return AppColors.textSecondary.withValues(alpha: 0.4);
  }

  @override
  Widget build(BuildContext context) {
    final dayDate = DateTime.tryParse(day.date);
    final dayNames = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: _isToday
            ? BoxDecoration(
                color: AppColors.lightTan,
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: Column(
                children: [
                  Text(
                    dayDate != null ? dayNames[dayDate.weekday - 1] : '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    dayDate != null ? '${dayDate.day}' : '',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (_isToday)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warmBrown,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'TODAY',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Flexible(
                        child: Text(
                          day.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (day.description != null)
                    Text(
                      day.description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            Icon(_statusIcon, color: _statusColor, size: 24),
          ],
        ),
      ),
    );
  }
}

class _CoachInsightCard extends StatelessWidget {
  final String notes;
  const _CoachInsightCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
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
                'COACH INSIGHT',
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
            '"$notes"',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
