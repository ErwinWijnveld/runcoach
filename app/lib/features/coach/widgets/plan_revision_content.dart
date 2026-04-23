import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/utils/date_formatter.dart';

/// Rendered inside [PlanDetailsSheet] when the proposal payload carries a
/// `diff` array. Shows each edit op as a friendly "what changed" row,
/// grouped by week, so the runner can review a revision at a glance.
class PlanRevisionContent extends StatelessWidget {
  final List<Map<String, dynamic>> ops;

  const PlanRevisionContent({super.key, required this.ops});

  static const _dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    final byWeek = <int, List<Map<String, dynamic>>>{};
    final goalOps = <Map<String, dynamic>>[];

    for (final op in ops) {
      if (op['op'] == 'set_goal') {
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
          '${ops.length} ${ops.length == 1 ? 'change' : 'changes'} to your plan',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.inkMuted,
          ),
        ),
        const SizedBox(height: 16),
        if (goalOps.isNotEmpty) ...[
          _WeekGroup(label: 'GOAL', ops: goalOps),
          const SizedBox(height: 10),
        ],
        for (final wk in sortedWeeks) ...[
          _WeekGroup(label: 'WEEK $wk', ops: byWeek[wk]!),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  static String dayLabel(int? dow) {
    if (dow == null || dow < 1 || dow > 7) return 'Day';
    return _dayNames[dow - 1];
  }
}

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
    final (icon, tint, headline, detail) = _render(op);
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color, String, String?) _render(Map<String, dynamic> op) {
    final name = op['op']?.toString() ?? '';
    switch (name) {
      case 'add_day':
        final dow = (op['day_of_week'] as num?)?.toInt();
        final fields = (op['fields'] as Map?)?.cast<String, dynamic>() ?? {};
        final title = fields['title']?.toString() ?? _humanType(fields['type']);
        return (
          Icons.add_rounded,
          const Color(0xFF2F8F4E),
          'Added on ${PlanRevisionContent.dayLabel(dow)}',
          _composeDayDetail(title, fields),
        );
      case 'remove_day':
        final dow = (op['day_of_week'] as num?)?.toInt();
        return (
          Icons.remove_rounded,
          const Color(0xFF8F3A3A),
          'Removed ${PlanRevisionContent.dayLabel(dow)} session',
          null,
        );
      case 'shift_day':
        final from = (op['from_day_of_week'] as num?)?.toInt();
        final to = (op['to_day_of_week'] as num?)?.toInt();
        return (
          Icons.swap_horiz_rounded,
          const Color(0xFF7A5B1F),
          'Moved to ${PlanRevisionContent.dayLabel(to)}',
          'Was on ${PlanRevisionContent.dayLabel(from)}',
        );
      case 'set_day':
        final dow = (op['day_of_week'] as num?)?.toInt();
        final fields = (op['fields'] as Map?)?.cast<String, dynamic>() ?? {};
        return (
          Icons.edit_rounded,
          const Color(0xFF7A5B1F),
          'Updated ${PlanRevisionContent.dayLabel(dow)}',
          _composeDayDetail(null, fields),
        );
      case 'set_goal':
        final fields = (op['fields'] as Map?)?.cast<String, dynamic>() ?? {};
        return (
          Icons.flag_rounded,
          const Color(0xFF7A5B1F),
          'Goal details updated',
          _composeGoalDetail(fields),
        );
      default:
        return (Icons.change_circle_outlined, AppColors.inkMuted, name, null);
    }
  }

  String? _composeDayDetail(String? title, Map<String, dynamic> fields) {
    final parts = <String>[];
    if (title != null && title.isNotEmpty) parts.add(title);
    if (fields['type'] != null && (title == null || title.isEmpty)) {
      parts.add(_humanType(fields['type']));
    }
    if (fields['target_km'] != null) parts.add('${_num(fields['target_km'])} km');
    if (fields['target_pace_seconds_per_km'] != null) {
      parts.add(_pace(fields['target_pace_seconds_per_km']));
    }
    if (fields['target_heart_rate_zone'] != null) {
      parts.add('Z${fields['target_heart_rate_zone']}');
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }

  String? _composeGoalDetail(Map<String, dynamic> fields) {
    final parts = <String>[];
    if (fields['goal_name'] != null) parts.add('Name: ${fields['goal_name']}');
    if (fields['distance'] != null) parts.add('Distance: ${fields['distance']}');
    if (fields['target_date'] != null) {
      parts.add('Date: ${formatDateString(fields['target_date']?.toString(), fallback: fields['target_date'].toString())}');
    }
    if (fields['goal_time_seconds'] != null) {
      parts.add('Goal time: ${_duration(fields['goal_time_seconds'])}');
    }
    if (fields['preferred_weekdays'] != null) {
      final days = (fields['preferred_weekdays'] as List)
          .map((d) => PlanRevisionContent.dayLabel(d is num ? d.toInt() : null).substring(0, 3))
          .join(', ');
      parts.add('Days: $days');
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }

  String _humanType(dynamic type) {
    if (type == null) return 'Run';
    return type.toString().replaceAll('_', ' ').split(' ').map((s) {
      if (s.isEmpty) return s;
      return s[0].toUpperCase() + s.substring(1);
    }).join(' ');
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
