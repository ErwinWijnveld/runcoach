import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:app/core/i18n/build_context_l10n.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/utils/date_formatter.dart';

/// Rendered inside [PlanDetailsSheet] when the proposal payload carries a
/// `diff` array. Shows each edit op as a friendly "what changed" row,
/// grouped by week, so the runner can review a revision at a glance.
class PlanRevisionContent extends StatelessWidget {
  final List<Map<String, dynamic>> ops;

  const PlanRevisionContent({super.key, required this.ops});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final byWeek = <int, List<Map<String, dynamic>>>{};
    final goalOps = <Map<String, dynamic>>[];

    for (final op in ops) {
      if (op['action'] == 'set_goal') {
        goalOps.add(op);
        continue;
      }
      final wk = op['week'];
      if (wk is num) byWeek.putIfAbsent(wk.toInt(), () => []).add(op);
    }
    final sortedWeeks = byWeek.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.coachRevisionChangeCount(ops.length),
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.inkMuted,
          ),
        ),
        const SizedBox(height: 16),
        if (goalOps.isNotEmpty) ...[
          _WeekGroup(label: l10n.coachRevisionGoal, ops: goalOps),
          const SizedBox(height: 10),
        ],
        for (final wk in sortedWeeks) ...[
          _WeekGroup(label: l10n.coachRevisionWeek('$wk'), ops: byWeek[wk]!),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  /// Locale-aware day name. Pulls from intl's DateFormat.EEEE so it
  /// follows the current locale rather than a hardcoded English array.
  static String dayLabel(BuildContext context, int? dow) {
    if (dow == null || dow < 1 || dow > 7) return context.l10n.coachRevisionDayFallback;
    final ref = DateTime(2024, 1, dow); // Jan 1 2024 = Monday
    final locale = Localizations.localeOf(context).toLanguageTag();
    return _intlDayName(locale, ref);
  }

  static String _intlDayName(String locale, DateTime d) {
    // Defer to date_formatter helpers — DateFormat.EEEE(locale).format
    // is the locale-aware full weekday name.
    return _dateFormatEEEE(locale).format(d);
  }
}

// Cached short-circuit to avoid pulling DateFormat into the static method
// signature noise. Returns DateFormat.EEEE(locale).
DateFormat _dateFormatEEEE(String locale) => DateFormat.EEEE(locale);

class _WeekGroup extends StatelessWidget {
  final String label;
  final List<Map<String, dynamic>> ops;

  const _WeekGroup({required this.label, required this.ops});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: 8),
          for (final op in ops) ...[
            _OpRow(op: op),
            if (op != ops.last) ...[
              const SizedBox(height: 6),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 6),
            ],
          ],
        ],
      ),
    );
  }
}

class _OpRow extends StatelessWidget {
  final Map<String, dynamic> op;
  const _OpRow({required this.op});

  @override
  Widget build(BuildContext context) {
    final (icon, tint, headline, detail) = _render(context, op);
    final (beforeLine, afterLine) = _diffLines(context, op);
    final adjustments = (op['adjustments'] is List)
        ? (op['adjustments'] as List).map((e) => e.toString()).where((s) => s.isNotEmpty).toList()
        : const <String>[];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: tint),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryInk,
                    height: 1.25,
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.inkMuted,
                      height: 1.3,
                    ),
                  ),
                ],
                if (beforeLine != null)
                  _DiffLine(
                    label: context.l10n.coachRevisionBeforeChip,
                    text: beforeLine,
                    color: AppColors.danger,
                    background: AppColors.dangerBg,
                  ),
                if (afterLine != null)
                  _DiffLine(
                    label: context.l10n.coachRevisionAfterChip,
                    text: afterLine,
                    color: AppColors.successInk,
                    background: AppColors.successBg,
                  ),
                for (final note in adjustments) ...[
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFF7A5B1F)),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          note,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFF7A5B1F),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color, String, String?) _render(BuildContext context, Map<String, dynamic> op) {
    final l10n = context.l10n;
    // Backend `AdjustPlan` ships ops with `action` (not `op`) and puts the
    // mutable fields at the top level (no `fields` wrapper). Action values:
    // add / remove / shift / replace / adjust / set_goal.
    final name = op['action']?.toString() ?? '';
    switch (name) {
      case 'add':
        final dow = (op['day_of_week'] as num?)?.toInt();
        return (
          Icons.add_rounded,
          AppColors.successInk,
          l10n.coachRevisionAddedOn(PlanRevisionContent.dayLabel(context, dow)),
          null,
        );
      case 'remove':
        final dow = (op['day_of_week'] as num?)?.toInt();
        return (
          Icons.remove_rounded,
          AppColors.danger,
          l10n.coachRevisionRemovedSession(PlanRevisionContent.dayLabel(context, dow)),
          null,
        );
      case 'shift':
        final from = (op['from_day_of_week'] as num?)?.toInt();
        final to = (op['to_day_of_week'] as num?)?.toInt();
        return (
          Icons.swap_horiz_rounded,
          const Color(0xFF7A5B1F),
          l10n.coachRevisionMovedTo(PlanRevisionContent.dayLabel(context, to)),
          l10n.coachRevisionWasOn(PlanRevisionContent.dayLabel(context, from)),
        );
      case 'replace':
      case 'adjust':
        final dow = (op['day_of_week'] as num?)?.toInt();
        return (
          Icons.edit_rounded,
          const Color(0xFF7A5B1F),
          l10n.coachRevisionUpdatedDay(PlanRevisionContent.dayLabel(context, dow)),
          null,
        );
      case 'set_goal':
        return (
          Icons.flag_rounded,
          const Color(0xFF7A5B1F),
          l10n.coachRevisionGoalUpdated,
          _composeGoalDetail(context, op),
        );
      default:
        return (Icons.change_circle_outlined, AppColors.inkMuted, name, null);
    }
  }

  /// The red BEFORE / green AFTER lines for day-level ops. Edits show both
  /// (when the `before` snapshot exists), `add` shows only the new state,
  /// `remove` only the dropped one. Goal/shift ops render no diff lines.
  (String?, String?) _diffLines(BuildContext context, Map<String, dynamic> op) {
    String? before;
    if (op['before'] is Map) {
      final beforeMap = Map<String, dynamic>.from(op['before'] as Map);
      before = _composeDayDetail(context, beforeMap['title']?.toString(), beforeMap);
    }
    final after = _composeDayDetail(context, op['title']?.toString(), op);

    return switch (op['action']?.toString()) {
      // A description-only edit summarizes identically on both sides;
      // showing a matching red line would read as a change that didn't
      // happen, so collapse to the green state.
      'replace' || 'adjust' => before == after ? (null, after) : (before, after),
      'add' => (null, after),
      'remove' => (before, null),
      _ => (null, null),
    };
  }

  String? _composeDayDetail(BuildContext context, String? title, Map<String, dynamic> op) {
    final parts = <String>[];
    if (title != null && title.isNotEmpty) parts.add(title);
    if (op['type'] != null && (title == null || title.isEmpty)) {
      parts.add(_humanType(context, op['type']));
    }
    if (op['target_km'] != null) parts.add('${_num(op['target_km'])} km');
    if (op['target_pace_seconds_per_km'] != null) {
      parts.add(_pace(op['target_pace_seconds_per_km']));
    }
    if (op['target_heart_rate_zone'] != null) {
      parts.add('Z${op['target_heart_rate_zone']}');
    }
    // Stored work-set summary ("4×800m @4:30/km (rec 90s)") shipped by
    // AdjustPlan's diff for interval days (warm-up/cool-down omitted
    // server-side — runners don't review those here).
    if (op['intervals'] is String) {
      parts.add(op['intervals'] as String);
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }

  String? _composeGoalDetail(BuildContext context, Map<String, dynamic> op) {
    final l10n = context.l10n;
    final parts = <String>[];
    if (op['goal_name'] != null) parts.add(l10n.coachRevisionGoalFieldName(op['goal_name'].toString()));
    if (op['distance'] != null) parts.add(l10n.coachRevisionGoalFieldDistance(op['distance'].toString()));
    if (op['target_date'] != null) {
      parts.add(l10n.coachRevisionGoalFieldDate(
        formatDateString(op['target_date']?.toString(), fallback: op['target_date'].toString()),
      ));
    }
    if (op['goal_time_seconds'] != null) {
      parts.add(l10n.coachRevisionGoalFieldGoalTime(_duration(op['goal_time_seconds'])));
    }
    if (op['preferred_weekdays'] is List) {
      final days = (op['preferred_weekdays'] as List)
          .map((d) {
            final label = PlanRevisionContent.dayLabel(context, d is num ? d.toInt() : null);
            return label.length >= 3 ? label.substring(0, 3) : label;
          })
          .join(', ');
      parts.add(l10n.coachRevisionGoalFieldDays(days));
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }

  String _humanType(BuildContext context, dynamic type) {
    if (type == null) return context.l10n.coachRevisionRunFallback;
    final l10n = context.l10n;
    final value = type.toString();
    return switch (value) {
      'easy' => l10n.trainingTypeEasy,
      'tempo' => l10n.trainingTypeTempo,
      'interval' => l10n.trainingTypeInterval,
      'long_run' => l10n.trainingTypeLongRun,
      'threshold' => l10n.trainingTypeThreshold,
      _ => value.replaceAll('_', ' ').split(' ').map((s) {
            if (s.isEmpty) return s;
            return s[0].toUpperCase() + s.substring(1);
          }).join(' '),
    };
  }

  String _num(dynamic n) {
    if (n is num) {
      return n == n.toInt() ? n.toInt().toString() : n.toStringAsFixed(1);
    }
    return n.toString();
  }

  String _pace(dynamic seconds) {
    if (seconds is! num || seconds <= 0) return '-';
    final s = seconds.toInt();
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}/km';
  }

  String _duration(dynamic seconds) {
    if (seconds is! num || seconds <= 0) return '-';
    final s = seconds.toInt();
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    if (h == 0) return '${m}m';
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }
}

/// One side of a day diff: a small VOOR/NA chip + the day summary, both in
/// the same tint (red = old state, green = new state).
class _DiffLine extends StatelessWidget {
  final String label;
  final String text;
  final Color color;
  final Color background;

  const _DiffLine({
    required this.label,
    required this.text,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            // Min-width keeps BEFORE/AFTER (and VOOR/NA) chips equally wide
            // so both summary lines start at the same x.
            constraints: const BoxConstraints(minWidth: 52),
            alignment: Alignment.center,
            margin: const EdgeInsets.only(top: 1),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
