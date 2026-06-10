import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, Material, InkWell;
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/i18n/build_context_l10n.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/schedule/widgets/training_day_status.dart';

/// 2×2 action grid pinned to the bottom of the workout detail screen:
/// move · edit / link · send-to-watch, icon next to label, watch as the
/// filled primary. Replaces the old single CTA + top-right ellipsis menu.
/// Hidden for `completed` days — the run already happened; that state gets
/// the coach analysis + "Share this run" instead.
class TrainingDayActionButtons extends StatelessWidget {
  final TrainingDayStatus status;
  final VoidCallback? onReschedule;
  final VoidCallback? onEdit;
  final VoidCallback? onLink;
  final VoidCallback? onSendToWatch;

  const TrainingDayActionButtons({
    super.key,
    required this.status,
    required this.onReschedule,
    required this.onEdit,
    required this.onLink,
    required this.onSendToWatch,
  });

  @override
  Widget build(BuildContext context) {
    if (status == TrainingDayStatus.completed) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.calendar_month_rounded,
                label: l10n.schedDayActionMove,
                onTap: onReschedule,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                icon: Icons.edit_rounded,
                label: l10n.schedDayActionEdit,
                onTap: onEdit,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.link_rounded,
                label: l10n.schedDayActionLink,
                onTap: onLink,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                icon: Icons.watch_rounded,
                label: l10n.schedDayActionWatch,
                onTap: onSendToWatch,
                primary: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = primary ? CupertinoColors.white : AppColors.primaryInk;
    return Material(
      color: primary ? AppColors.secondary : CupertinoColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: primary ? AppColors.secondary : const Color(0xFFEFE7D2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: primary ? CupertinoColors.white : AppColors.secondary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
