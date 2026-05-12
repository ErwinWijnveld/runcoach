import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:app/core/i18n/build_context_l10n.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/coach/models/coach_proposal.dart';
import 'package:app/features/coach/widgets/plan_revision_content.dart';

/// Full week-by-week plan overview, rendered directly from the proposal
/// payload (the agent already included a structured `schedule.weeks[]`
/// tree in the CreateSchedule call). Zero AI round-trip — just a compact
/// scrollable summary per week.
class PlanDetailsSheet extends StatelessWidget {
  final CoachProposal proposal;
  final Future<void> Function()? onAccept;
  final Future<void> Function({String? prefill})? onAdjust;

  const PlanDetailsSheet({
    super.key,
    required this.proposal,
    this.onAccept,
    this.onAdjust,
  });

  static Future<void> show(
    BuildContext context, {
    required CoachProposal proposal,
    Future<void> Function()? onAccept,
    Future<void> Function({String? prefill})? onAdjust,
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

  List<Map<String, dynamic>>? get _diffOps {
    final raw = proposal.payload['diff'];
    if (raw is! List || raw.isEmpty) return null;
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Map<String, dynamic>? _ambition(Map<String, dynamic> payload) {
    final raw = payload['ambition'];
    if (raw is! Map) return null;
    return Map<String, dynamic>.from(raw);
  }

  @override
  Widget build(BuildContext context) {
    final ops = _diffOps;
    final weeks = _weeks(proposal.payload);
    final avgKm = _averageWeeklyKm(weeks);
    final runsRange = _weeklyRunsRange(weeks);
    final ambition = _ambition(proposal.payload);
    final warnUnrealistic =
        ambition != null && ambition['verdict_zone'] == 'unrealistic';
    final adjustPrefill = warnUnrealistic
        ? ambition['adjust_prefill'] as String?
        : null;

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
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(
                        goalName: _goalName(context),
                        isRevision: ops != null,
                      ),
                      const SizedBox(height: 16),
                      if (ops != null) ...[
                        PlanRevisionContent(ops: ops),
                      ] else ...[
                        if (ambition != null) ...[
                          _FeasibilityZoneBar(ambition: ambition),
                          const SizedBox(height: 20),
                        ],
                        _TopStats(
                          totalWeeks: weeks.length,
                          avgWeeklyKm: avgKm,
                          weeklyRuns: runsRange,
                        ),
                        const SizedBox(height: 20),
                        _WeeklyVolumeChart(
                          weeks: weeks,
                          raceWeekNumber: _raceWeekNumber(weeks),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          context.l10n.planDetailsBreakdownLabel,
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
                          const SizedBox(height: 14),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              _StickyFooter(
                isPending: _isPending,
                isRevision: ops != null,
                warnUnrealistic: warnUnrealistic,
                adjustPrefill: adjustPrefill,
                onAccept: onAccept,
                onAdjust: onAdjust,
              ),
            ],
          ),
        );
      },
    );
  }

  String _goalName(BuildContext context) {
    final name = proposal.payload['goal_name'];
    if (name is String && name.trim().isNotEmpty) return name;
    return context.l10n.planDetailsGoalFallback;
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

  /// Find the week that contains the race day (computed from `target_date`
  /// the same way the backend optimizer does — plan starts at this week's
  /// Monday and weeks advance by 7 days). Returns null when there's no
  /// race day (open-ended general-fitness plans). The chart strips this
  /// week so a taper-week dip / single race-day entry doesn't dominate
  /// the volume curve.
  int? _raceWeekNumber(List<Map<String, dynamic>> weeks) {
    final target = proposal.payload['target_date'];
    if (target is! String || target.isEmpty) return null;
    final raceDate = DateTime.tryParse(target);
    if (raceDate == null) return null;

    final now = DateTime.now();
    final planStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: (now.weekday - 1)));

    for (final w in weeks) {
      final wn = w['week_number'];
      if (wn is! num) continue;
      final weekStart = planStart.add(Duration(days: (wn.toInt() - 1) * 7));
      final weekEnd = weekStart.add(const Duration(days: 7));
      if (!raceDate.isBefore(weekStart) && raceDate.isBefore(weekEnd)) {
        return wn.toInt();
      }
    }
    return null;
  }
}

class _Header extends StatelessWidget {
  final String goalName;
  final bool isRevision;
  const _Header({required this.goalName, this.isRevision = false});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isRevision ? l10n.planDetailsEyebrowRevision : l10n.planDetailsEyebrowRecommended,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: const Color(0xFF785A00),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isRevision ? l10n.planDetailsRevisionTitle : goalName,
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
        Icon(
          isRevision ? Icons.tune_rounded : Icons.directions_run,
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
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: _StatItem(
            label: l10n.planDetailsStatWeeks,
            value: '$totalWeeks',
          ),
        ),
        Expanded(
          child: _StatItem(
            label: l10n.planDetailsStatAvgKm,
            value: avgWeeklyKm.toStringAsFixed(1),
          ),
        ),
        Expanded(
          child: _StatItem(
            label: l10n.planDetailsStatRunsPerWeek,
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

  static String _dayName(BuildContext context, int weekday) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final ref = DateTime(2024, 1, weekday); // Jan 1 2024 = Monday
    return DateFormat.E(locale).format(ref).toUpperCase();
  }

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

    final hasFocus = focus != null && focus.isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      decoration: BoxDecoration(
        color: AppColors.neutralHighlight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasFocus) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.goldGlow,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          focus.toUpperCase(),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: const Color(0xFF785A00),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      weekNumber != null
                          ? context.l10n.planDetailsWeekLabel(weekNumber)
                          : context.l10n.planDetailsWeekFallback,
                      style: GoogleFonts.ebGaramond(
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                        color: AppColors.primaryInk,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              if (totalKm != null) _KmTotal(km: totalKm),
            ],
          ),
          if (days.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.border,
            ),
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

class _KmTotal extends StatelessWidget {
  final double km;
  const _KmTotal({required this.km});

  @override
  Widget build(BuildContext context) {
    final label = km == km.roundToDouble()
        ? km.toStringAsFixed(0)
        : km.toStringAsFixed(1);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.secondary,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          context.l10n.planDetailsKmTotal,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.inkMuted,
          ),
        ),
      ],
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
        ? _WeekCard._dayName(context, dow)
        : '-';
    final title = (day['title'] as String?)?.trim().isNotEmpty == true
        ? day['title'] as String
        : _prettifyType(context, day['type'] as String?);
    final km = day['target_km'];
    // Mirror TrainingDayPaceX.displayPaceSecondsPerKm: day-level pace is
    // always null on intervals (per the optimizer's hard invariant), so
    // fall through to the unweighted mean of every `kind=work` segment's
    // target pace. Keeps interval rows from showing a blank metric and
    // matches what weekly_plan_screen / training_day_detail render.
    final paceSecs = _displayPaceSeconds(day);

    final metricParts = <String>[];
    if (km is num && km > 0) {
      metricParts.add('${km % 1 == 0 ? km.toInt() : km.toStringAsFixed(1)} km');
    }
    if (paceSecs != null && paceSecs > 0) {
      metricParts.add('${paceSecs ~/ 60}:${(paceSecs % 60).toString().padLeft(2, '0')} /km');
    }

    final kmLabel = km is num && km > 0
        ? (km % 1 == 0 ? km.toInt().toString() : km.toStringAsFixed(1))
        : null;
    final paceLabel = paceSecs != null && paceSecs > 0
        ? '${paceSecs ~/ 60}:${(paceSecs % 60).toString().padLeft(2, '0')}'
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.goldGlow,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              dayLabel,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: const Color(0xFF785A00),
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.publicSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryInk,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (kmLabel != null) ...[
            const SizedBox(width: 8),
            _DayMetric(value: kmLabel, suffix: 'km'),
          ],
          if (paceLabel != null) ...[
            const SizedBox(width: 10),
            _DayMetric(value: paceLabel, suffix: '/km', muted: true),
          ],
        ],
      ),
    );
  }

  String _prettifyType(BuildContext context, String? type) {
    if (type == null || type.isEmpty) return context.l10n.planDetailsDayRun;
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .map((p) => p.isEmpty
            ? p
            : p[0].toUpperCase() + p.substring(1).toLowerCase())
        .join(' ');
  }

  /// Raw-map equivalent of `TrainingDayPaceX.displayPaceSecondsPerKm`. For
  /// non-interval days returns `target_pace_seconds_per_km` directly; for
  /// intervals returns the unweighted mean across `kind=work` segments.
  int? _displayPaceSeconds(Map<String, dynamic> day) {
    final type = day['type'] as String?;
    if (type != 'interval') {
      final raw = day['target_pace_seconds_per_km'];
      return raw is num ? raw.toInt() : null;
    }
    final segments = day['intervals'];
    if (segments is! List || segments.isEmpty) return null;
    final paces = <int>[];
    for (final s in segments) {
      if (s is! Map) continue;
      if (s['kind'] != 'work') continue;
      final p = s['target_pace_seconds_per_km'];
      if (p is num && p > 0) paces.add(p.toInt());
    }
    if (paces.isEmpty) return null;
    return (paces.reduce((a, b) => a + b) / paces.length).round();
  }
}

/// Numeric metric with a small unit suffix — used for "4 km" and "4:25 /km"
/// in the day rows. `muted` is the secondary tone (pace), normal is the
/// primary tone (km). Keeps the values eye-pulling without making the row
/// shout.
class _DayMetric extends StatelessWidget {
  final String value;
  final String suffix;
  final bool muted;

  const _DayMetric({
    required this.value,
    required this.suffix,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final valueColor = muted ? AppColors.tertiary : AppColors.primaryInk;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: valueColor,
            height: 1.0,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          suffix,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            color: AppColors.inkMuted,
          ),
        ),
      ],
    );
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

/// Pinned action bar at the bottom of the sheet — stays visible regardless
/// of scroll position so the runner can always accept or adjust without
/// scrolling to the end of a long plan.
class _StickyFooter extends StatelessWidget {
  final bool isPending;
  final bool isRevision;
  final bool warnUnrealistic;
  final String? adjustPrefill;
  final Future<void> Function()? onAccept;
  final Future<void> Function({String? prefill})? onAdjust;

  const _StickyFooter({
    required this.isPending,
    required this.isRevision,
    required this.warnUnrealistic,
    required this.adjustPrefill,
    required this.onAccept,
    required this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final Widget body;
    if (!isPending) {
      body = _PrimaryButton(
        label: l10n.planDetailsFooterClose,
        background: AppColors.lightTan,
        foreground: AppColors.primary,
        onPressed: () => Navigator.of(context).pop(),
      );
    } else if (warnUnrealistic) {
      body = _UnrealisticFooter(
        adjustPrefill: adjustPrefill,
        onAccept: onAccept,
        onAdjust: onAdjust,
      );
    } else {
      body = Row(
        children: [
          Expanded(
            child: _PrimaryButton(
              label: l10n.planDetailsFooterAdjust,
              background: AppColors.lightTan,
              foreground: AppColors.primary,
              onPressed: onAdjust == null
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      onAdjust!();
                    },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: _PrimaryButton(
              label: isRevision ? l10n.planDetailsFooterApplyChanges : l10n.planDetailsFooterAcceptPlan,
              background: AppColors.secondary,
              foreground: AppColors.primary,
              onPressed: onAccept == null
                  ? null
                  : () async {
                      await onAccept!();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
            ),
          ),
        ],
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: body,
        ),
      ),
    );
  }
}

class _UnrealisticFooter extends StatelessWidget {
  final String? adjustPrefill;
  final Future<void> Function()? onAccept;
  final Future<void> Function({String? prefill})? onAdjust;

  const _UnrealisticFooter({
    required this.adjustPrefill,
    required this.onAccept,
    required this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PrimaryButton(
          label: l10n.planDetailsFooterAdjustGoal,
          background: AppColors.danger,
          foreground: Colors.white,
          onPressed: onAdjust == null
              ? null
              : () {
                  Navigator.of(context).pop();
                  onAdjust!(prefill: adjustPrefill);
                },
        ),
        const SizedBox(height: 8),
        _PrimaryButton(
          label: l10n.planDetailsFooterAcceptAnyway,
          background: AppColors.lightTan,
          foreground: AppColors.primary,
          onPressed: onAccept == null
              ? null
              : () async {
                  await onAccept!();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
        ),
      ],
    );
  }
}

/// Weekly km line chart. Fixed-height + CustomPainter so it lays out
/// immediately on open with no jitter. Renders nothing when the plan has
/// fewer than 2 weeks of data (a single point isn't a trend). The race
/// week is stripped — its single-day entry would tank the line and
/// distort the build-up curve runners actually care about.
class _WeeklyVolumeChart extends StatelessWidget {
  final List<Map<String, dynamic>> weeks;
  final int? raceWeekNumber;
  const _WeeklyVolumeChart({required this.weeks, this.raceWeekNumber});

  @override
  Widget build(BuildContext context) {
    final points = weeks
        .map((w) {
          final wn = w['week_number'];
          final km = w['total_km'];
          return (
            week: wn is num ? wn.toInt() : 0,
            km: km is num ? km.toDouble() : 0.0,
          );
        })
        .where((p) => p.week > 0 && p.week != raceWeekNumber)
        .toList();
    if (points.length < 2) return const SizedBox.shrink();

    final maxKm = points.map((p) => p.km).reduce((a, b) => a > b ? a : b);
    final minKm = points.map((p) => p.km).reduce((a, b) => a < b ? a : b);
    final peakWeek = points.reduce((a, b) => a.km > b.km ? a : b);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.neutralHighlight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.planDetailsVolumeEyebrow,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.inkMuted,
                ),
              ),
              Text(
                context.l10n.planDetailsVolumePeak(peakWeek.km.toStringAsFixed(0), peakWeek.week),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 110,
            width: double.infinity,
            child: CustomPaint(
              painter: _VolumePainter(
                points: points,
                maxKm: maxKm,
                minKm: minKm,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'W${points.first.week}',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.tertiary,
                ),
              ),
              Text(
                'W${points.last.week}',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.tertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VolumePainter extends CustomPainter {
  final List<({int week, double km})> points;
  final double maxKm;
  final double minKm;

  _VolumePainter({
    required this.points,
    required this.maxKm,
    required this.minKm,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // Scale to the actual data range, not [0, max]. A build-up plan
    // typically climbs from ~15 km to ~26 km — anchoring to zero leaves
    // the line sitting at half-height and hides the trend. With this
    // mapping the lowest week sits near the bottom and the peak near
    // the top, using the full vertical canvas.
    const topPad = 6.0;
    const bottomPad = 6.0;
    final usable = size.height - topPad - bottomPad;
    final span = maxKm - minKm;
    // If every week is identical (span = 0), render a flat line at mid
    // height instead of dividing by zero.
    final normalizer = span == 0 ? 1.0 : span;

    final stepX = points.length == 1 ? 0.0 : size.width / (points.length - 1);
    final coords = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final x = stepX * i;
      final t = span == 0 ? 0.5 : (points[i].km - minKm) / normalizer;
      final y = topPad + (1 - t) * usable;
      coords.add(Offset(x, y));
    }

    final fillPath = Path()..moveTo(coords.first.dx, size.height);
    for (final p in coords) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(coords.last.dx, size.height);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x55D4A84B), Color(0x00D4A84B)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    final linePath = Path()..moveTo(coords.first.dx, coords.first.dy);
    for (final p in coords.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = const Color(0xFFC09437)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    final dotPaint = Paint()..color = const Color(0xFFC09437);
    final dotCorePaint = Paint()..color = Colors.white;
    for (final p in coords) {
      canvas.drawCircle(p, 3.5, dotPaint);
      canvas.drawCircle(p, 1.5, dotCorePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _VolumePainter old) =>
      old.points.length != points.length ||
      old.maxKm != maxKm ||
      old.minKm != minKm;
}

/// Feasibility verdict + horizontal zone-bar. Reads `proposal.payload['ambition']`
/// — a map produced by `AmbitionAssessment::toFeasibilityPayload()` on the
/// backend. Renders nothing when the key is absent (no measurable goal).
class _FeasibilityZoneBar extends StatelessWidget {
  final Map<String, dynamic> ambition;
  const _FeasibilityZoneBar({required this.ambition});

  @override
  Widget build(BuildContext context) {
    final pct = (ambition['feasibility_pct'] as num?)?.toInt() ?? 0;
    final zone = ambition['verdict_zone'] as String? ?? 'ok';
    final label = ambition['verdict_label'] as String? ?? '';
    final detail = ambition['detail'] as String? ?? '';

    final isUnrealistic = zone == 'unrealistic';
    final bgColor = isUnrealistic ? AppColors.dangerBg : AppColors.lightTan;
    final pctColor = switch (zone) {
      'ok' => AppColors.success,
      'stretch' => AppColors.secondary,
      'unrealistic' => AppColors.danger,
      _ => AppColors.primaryInk,
    };

    final clampedPct = pct.clamp(0, 100);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.ebGaramond(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                    color: isUnrealistic ? AppColors.danger : AppColors.primaryInk,
                    height: 1.15,
                  ),
                ),
              ),
              Text(
                '$clampedPct%',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: pctColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final markerLeft =
                  (width * clampedPct / 100).clamp(0.0, width - 4);
              return SizedBox(
                height: 22,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: 4,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 14,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFC24A2C),
                              Color(0xFFC24A2C),
                              Color(0xFFE0B044),
                              Color(0xFFE0B044),
                              Color(0xFF6FAA59),
                              Color(0xFF6FAA59),
                            ],
                            stops: [0.0, 0.35, 0.35, 0.70, 0.70, 1.0],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: markerLeft,
                      child: Container(
                        width: 4,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppColors.primaryInk,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.white,
                              blurRadius: 0,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _axisLabel(context.l10n.planDetailsFeasibilityUnrealistic),
              _axisLabel(context.l10n.planDetailsFeasibilityStretch),
              _axisLabel(context.l10n.planDetailsFeasibilityOk),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            detail,
            style: GoogleFonts.publicSans(
              fontSize: 12.5,
              height: 1.45,
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _axisLabel(String text) => Text(
        text,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: AppColors.inkMuted,
        ),
      );
}
