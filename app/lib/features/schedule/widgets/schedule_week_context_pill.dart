import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:app/core/i18n/build_context_l10n.dart';
import 'package:app/core/theme/app_theme.dart';

/// Neutral, always-visible pill that anchors the Schedule-week chat to
/// the week the runner was viewing when they opened the sheet. Purely
/// informational — not tappable, no dismiss action.
class ScheduleWeekContextPill extends StatelessWidget {
  final int weekNumber;
  final String startsAtIso;

  const ScheduleWeekContextPill({
    super.key,
    required this.weekNumber,
    required this.startsAtIso,
  });

  String _formatRange(BuildContext context) {
    final start = DateTime.tryParse(startsAtIso);
    if (start == null) return '';
    final end = start.add(const Duration(days: 6));
    final locale = Localizations.localeOf(context).toLanguageTag();
    final fmt = DateFormat.MMMd(locale);
    return '${fmt.format(start)} – ${fmt.format(end)}';
  }

  @override
  Widget build(BuildContext context) {
    final range = _formatRange(context);
    final label = context.l10n.scheduleChatViewingWeek(weekNumber, range);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.lightTan,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.inkMuted,
          letterSpacing: 0.2,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
