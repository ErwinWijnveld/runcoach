import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/features/dashboard/providers/dashboard_provider.dart';
import 'package:app/features/schedule/providers/schedule_provider.dart';
import 'package:app/features/schedule/models/training_day.dart';

class WeeklyPlanScreen extends ConsumerWidget {
  const WeeklyPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.cream,
      child: SafeArea(
        child: dashboardAsync.when(
          loading: () => const AppSpinner(),
          error: (err, _) => AppErrorState(title: 'Error: $err'),
          data: (dashboard) {
            final race = dashboard.activeRace;
            if (race == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.calendar,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No active training plan',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: AppFilledButton(
                        label: 'Create one with AI Coach',
                        onPressed: () => context.go('/coach'),
                      ),
                    ),
                  ],
                ),
              );
            }

            final weekAsync = ref.watch(currentWeekProvider(race.id));
            return weekAsync.when(
              loading: () => const AppSpinner(),
              error: (err, _) => AppErrorState(title: 'Error: $err'),
              data: (week) {
                if (week == null) {
                  return const Center(
                    child: Text('No training week found'),
                  );
                }
                final days = week.trainingDays ?? [];

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Week ${week.weekNumber}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const Text(
                                  'Weekly Plan',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${week.totalKm}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.warmBrown,
                                  ),
                                ),
                                const Text(
                                  'KM TOTAL',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverList.builder(
                      itemCount: days.length,
                      itemBuilder: (context, index) => _TrainingDayTile(
                        day: days[index],
                        onTap: () => context.go('/schedule/day/${days[index].id}'),
                      ),
                    ),
                    if (week.coachNotes != null)
                      SliverToBoxAdapter(
                        child: _CoachNotesCard(notes: week.coachNotes!),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                );
              },
            );
          },
        ),
      ),
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
    if (_isCompleted) return CupertinoIcons.check_mark_circled_solid;
    if (_isToday) return CupertinoIcons.bolt_fill;
    return CupertinoIcons.moon;
  }

  Color get _statusColor {
    if (_isCompleted) return AppColors.success;
    if (_isToday) return AppColors.gold;
    return AppColors.textSecondary.withValues(alpha: 0.5);
  }

  @override
  Widget build(BuildContext context) {
    final dayDate = DateTime.tryParse(day.date);
    final dayNames = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: _isToday
              ? BoxDecoration(
                  color: AppColors.lightTan,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
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
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      dayDate != null ? '${dayDate.day}' : '',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warmBrown,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'TODAY',
                              style: TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        Flexible(
                          child: Text(
                            day.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (day.description != null)
                      Text(
                        day.description!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(_statusIcon, color: _statusColor, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoachNotesCard extends StatelessWidget {
  final String notes;
  const _CoachNotesCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkBrown,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(CupertinoIcons.sparkles, color: AppColors.gold, size: 16),
              SizedBox(width: 8),
              Text(
                'COACH INSIGHT',
                style: TextStyle(
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
            style: TextStyle(
              color: CupertinoColors.white.withValues(alpha: 0.9),
              fontStyle: FontStyle.italic,
              height: 1.5,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
