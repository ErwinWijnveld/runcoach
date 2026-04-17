import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/coach/models/coach_proposal.dart';

/// Full week-by-week plan overview, rendered directly from the proposal
/// payload (the agent already included a structured `schedule.weeks[]`
/// tree in the CreateSchedule call). Zero AI round-trip — just a compact
/// scrollable summary per week.
class PlanDetailsSheet extends StatelessWidget {
  final CoachProposal proposal;
  final VoidCallback? onAccept;
  final VoidCallback? onAdjust;

  const PlanDetailsSheet({
    super.key,
    required this.proposal,
    this.onAccept,
    this.onAdjust,
  });

  static Future<void> show(
    BuildContext context, {
    required CoachProposal proposal,
    VoidCallback? onAccept,
    VoidCallback? onAdjust,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlanDetailsSheet(
        proposal: proposal,
        onAccept: onAccept,
        onAdjust: onAdjust,
      ),
    );
  }

  bool get _isPending => proposal.status == 'pending';

  @override
  Widget build(BuildContext context) {
    final weeks = _weeks(proposal.payload);
    final avgKm = _averageWeeklyKm(weeks);
    final runsRange = _weeklyRunsRange(weeks);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 3,
                decoration: const BoxDecoration(
                  color: Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(goalName: _goalName()),
                      const SizedBox(height: 16),
                      _TopStats(
                        totalWeeks: weeks.length,
                        avgWeeklyKm: avgKm,
                        weeklyRuns: runsRange,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'WEEKLY BREAKDOWN',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (final w in weeks) ...[
                        _WeekCard(week: w),
                        const SizedBox(height: 8),
                      ],
                      const SizedBox(height: 16),
                      if (_isPending) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _PrimaryButton(
                                label: 'ACCEPT PLAN',
                                background: AppColors.secondary,
                                foreground: AppColors.primary,
                                onPressed: onAccept == null
                                    ? null
                                    : () {
                                        Navigator.of(context).pop();
                                        onAccept!();
                                      },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _PrimaryButton(
                                label: 'ADJUST',
                                background: AppColors.primary,
                                foreground: AppColors.neutral,
                                onPressed: onAdjust == null
                                    ? null
                                    : () {
                                        Navigator.of(context).pop();
                                        onAdjust!();
                                      },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      _CloseButton(onTap: () => Navigator.of(context).pop()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _goalName() {
    final name = proposal.payload['goal_name'];
    if (name is String && name.trim().isNotEmpty) return name;
    return 'Your training plan';
  }

  List<Map<String, dynamic>> _weeks(Map<String, dynamic> payload) {
    final schedule = payload['schedule'];
    if (schedule is! Map) return const [];
    final weeks = schedule['weeks'];
    if (weeks is! List) return const [];
    return weeks
        .whereType<Map>()
        .map((w) => Map<String, dynamic>.from(w))
        .toList(growable: false);
  }

  double _averageWeeklyKm(List<Map<String, dynamic>> weeks) {
    if (weeks.isEmpty) return 0.0;
    final totals =
        weeks.map((w) => w['total_km']).whereType<num>().toList();
    if (totals.isEmpty) return 0.0;
    return totals.fold<double>(0, (a, b) => a + b.toDouble()) / totals.length;
  }

  String _weeklyRunsRange(List<Map<String, dynamic>> weeks) {
    if (weeks.isEmpty) return '0';
    final counts = weeks.map((w) {
      final days = w['days'];
      if (days is! List) return 0;
      return days.whereType<Map>().where((d) => d['type'] != 'rest').length;
    }).toList();
    final min = counts.reduce((a, b) => a < b ? a : b);
    final max = counts.reduce((a, b) => a > b ? a : b);
    return min == max ? '$min' : '$min–$max';
  }
}

class _Header extends StatelessWidget {
  final String goalName;
  const _Header({required this.goalName});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RECOMMENDED PLAN',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: const Color(0xFF785A00),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                goalName,
                style: GoogleFonts.ebGaramond(
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  height: 32 / 28,
                  color: AppColors.primaryInk,
                ),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.directions_run,
          size: 28,
          color: AppColors.eyebrow,
        ),
      ],
    );
  }
}

class _TopStats extends StatelessWidget {
  final int totalWeeks;
  final double avgWeeklyKm;
  final String weeklyRuns;

  const _TopStats({
    required this.totalWeeks,
    required this.avgWeeklyKm,
    required this.weeklyRuns,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatItem(
            label: 'WEEKS',
            value: '$totalWeeks',
          ),
        ),
        Expanded(
          child: _StatItem(
            label: 'AVG KM / WEEK',
            value: avgWeeklyKm.toStringAsFixed(1),
          ),
        ),
        Expanded(
          child: _StatItem(
            label: 'RUNS / WEEK',
            value: weeklyRuns,
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: RunCoreText.statLabel()),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryInk,
          ),
        ),
      ],
    );
  }
}

class _WeekCard extends StatelessWidget {
  final Map<String, dynamic> week;
  const _WeekCard({required this.week});

  static const _dayNames = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  @override
  Widget build(BuildContext context) {
    final weekNumber = week['week_number'] is num
        ? (week['week_number'] as num).toInt()
        : null;
    final focus = (week['focus'] as String?)?.trim();
    final totalKm = week['total_km'] is num
        ? (week['total_km'] as num).toDouble()
        : null;
    final daysRaw = week['days'];
    final days = daysRaw is List
        ? daysRaw.whereType<Map>().map(Map<String, dynamic>.from).toList()
        : <Map<String, dynamic>>[];
    days.sort((a, b) {
      final aDow = a['day_of_week'];
      final bDow = b['day_of_week'];
      return ((aDow is num ? aDow.toInt() : 99) -
          (bDow is num ? bDow.toInt() : 99));
    });

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.neutralHighlight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weekNumber != null ? 'Week $weekNumber' : 'Week',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.primaryInk,
                      ),
                    ),
                    if (focus != null && focus.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        focus,
                        style: GoogleFonts.publicSans(
                          fontSize: 12,
                          color: AppColors.tertiary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (totalKm != null) ...[
                const SizedBox(width: 10),
                Text(
                  '${totalKm.toStringAsFixed(totalKm.truncateToDouble() == totalKm ? 0 : 1)} km',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryInk,
                  ),
                ),
              ],
            ],
          ),
          if (days.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (var i = 0; i < days.length; i++) ...[
              if (i > 0)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.border,
                ),
              _DayRow(day: days[i]),
            ],
          ],
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  final Map<String, dynamic> day;
  const _DayRow({required this.day});

  @override
  Widget build(BuildContext context) {
    final dow = day['day_of_week'] is num
        ? (day['day_of_week'] as num).toInt()
        : null;
    final dayLabel = (dow != null && dow >= 1 && dow <= 7)
        ? _WeekCard._dayNames[dow - 1]
        : '—';
    final title = (day['title'] as String?)?.trim().isNotEmpty == true
        ? day['title'] as String
        : _prettifyType(day['type'] as String?);
    final km = day['target_km'];
    final pace = day['target_pace_seconds_per_km'];

    final metricParts = <String>[];
    if (km is num && km > 0) {
      metricParts.add('${km % 1 == 0 ? km.toInt() : km.toStringAsFixed(1)} km');
    }
    if (pace is num && pace > 0) {
      final secs = pace.toInt();
      metricParts.add('${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')} /km');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 34,
            child: Text(
              dayLabel,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.tertiary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.publicSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryInk,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (metricParts.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              metricParts.join(' · '),
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.tertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _prettifyType(String? type) {
    if (type == null || type.isEmpty) return 'Run';
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .map((p) => p.isEmpty
            ? p
            : p[0].toUpperCase() + p.substring(1).toLowerCase())
        .join(' ');
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback? onPressed;

  const _PrimaryButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.neutralHighlight,
        padding: const EdgeInsets.symmetric(vertical: 10),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Text(
        'CLOSE',
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
