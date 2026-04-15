import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/features/schedule/providers/schedule_provider.dart';

class TrainingDayDetailScreen extends ConsumerWidget {
  final int dayId;
  const TrainingDayDetailScreen({super.key, required this.dayId});

  String _formatPace(int secondsPerKm) {
    final minutes = secondsPerKm ~/ 60;
    final seconds = secondsPerKm % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')} /km';
  }

  String _hrZoneLabel(int zone) {
    const labels = {
      1: 'Zone 1 - Recovery',
      2: 'Zone 2 - Easy',
      3: 'Zone 3 - Tempo',
      4: 'Zone 4 - Threshold',
      5: 'Zone 5 - Max',
    };
    return labels[zone] ?? 'Zone $zone';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayAsync = ref.watch(trainingDayDetailProvider(dayId));

    return dayAsync.when(
      loading: () => const CupertinoPageScaffold(
        backgroundColor: AppColors.cream,
        child: SafeArea(child: AppSpinner()),
      ),
      error: (err, _) => CupertinoPageScaffold(
        backgroundColor: AppColors.cream,
        navigationBar: CupertinoNavigationBar(
          backgroundColor: AppColors.cream.withValues(alpha: 0.92),
          border: null,
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => context.go('/schedule'),
            child: const Icon(
              CupertinoIcons.back,
              color: AppColors.warmBrown,
            ),
          ),
        ),
        child: SafeArea(
          child: AppErrorState(title: 'Error: $err'),
        ),
      ),
      data: (day) {
        final hasResult = day.result != null;

        return CupertinoPageScaffold(
          backgroundColor: AppColors.cream,
          navigationBar: CupertinoNavigationBar(
            backgroundColor: AppColors.cream.withValues(alpha: 0.92),
            border: null,
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => context.go('/schedule'),
              child: const Icon(
                CupertinoIcons.back,
                color: AppColors.warmBrown,
              ),
            ),
            middle: Text(day.title),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warmBrown.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          day.type.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.warmBrown,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        day.date,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (day.description != null) ...[
                    Text(
                      day.description!,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  const AppSectionLabel('TARGETS'),
                  const SizedBox(height: 12),
                  _MetricsGrid(
                    children: [
                      if (day.targetKm != null)
                        _MetricCard(
                          icon: CupertinoIcons.arrow_right_arrow_left,
                          label: 'Distance',
                          value: '${day.targetKm} km',
                        ),
                      if (day.targetPaceSecondsPerKm != null)
                        _MetricCard(
                          icon: CupertinoIcons.speedometer,
                          label: 'Pace',
                          value: _formatPace(day.targetPaceSecondsPerKm!),
                        ),
                      if (day.targetHeartRateZone != null)
                        _MetricCard(
                          icon: CupertinoIcons.heart_fill,
                          label: 'HR Zone',
                          value: _hrZoneLabel(day.targetHeartRateZone!),
                        ),
                    ],
                  ),
                  if (day.intervalsJson != null &&
                      day.intervalsJson!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const AppSectionLabel('INTERVALS'),
                    const SizedBox(height: 12),
                    _IntervalsCard(intervals: day.intervalsJson!),
                  ],
                  const SizedBox(height: 32),
                  if (hasResult)
                    AppFilledButton(
                      label: 'View Result',
                      icon: CupertinoIcons.check_mark_circled,
                      color: AppColors.success,
                      onPressed: () =>
                          context.go('/schedule/day/$dayId/result'),
                    )
                  else
                    const AppBorderedButton(
                      label: 'Awaiting Strava sync',
                      icon: CupertinoIcons.hourglass,
                      color: AppColors.textSecondary,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final List<Widget> children;
  const _MetricsGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 12, runSpacing: 12, children: children);
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.of(context).size.width - 52) / 2,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.warmBrown, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _IntervalsCard extends StatelessWidget {
  final Map<String, dynamic> intervals;
  const _IntervalsCard({required this.intervals});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: intervals.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${entry.value}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
