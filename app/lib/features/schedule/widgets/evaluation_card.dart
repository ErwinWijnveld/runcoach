import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ElevatedButton;
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/i18n/build_context_l10n.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/utils/date_formatter.dart';
import 'package:app/features/schedule/models/plan_evaluation.dart';

/// Card representing a `PlanEvaluation` row inside the weekly schedule.
///
/// Visually distinct from `TrainingDay` cards — no km/pace/HR tiles,
/// no `TrainingType` colour. Uses the design-system gold accent. Tap on
/// `ready` / `no_change_needed` / `accepted` / `dismissed` routes to the
/// evaluation detail screen.
class EvaluationCard extends StatelessWidget {
  const EvaluationCard({
    super.key,
    required this.evaluation,
    this.weekNumber,
  });

  final PlanEvaluation evaluation;

  /// Week number of the `TrainingWeek` this evaluation sits on, passed in
  /// by the schedule page (the model only carries `trainingWeekId`). Drives
  /// the descriptive "Week N check-in" title; falls back to the generic
  /// check-in title when unknown.
  final int? weekNumber;

  @override
  Widget build(BuildContext context) {
    final isTappable = evaluation.status != 'pending' &&
        evaluation.status != 'processing';
    final formattedDate = formatDateString(evaluation.scheduledFor);
    final title = weekNumber != null
        ? context.l10n.evaluationCardWeekTitle(weekNumber!)
        : context.l10n.evaluationDetailTitle;
    // Status stays in the a11y label (the visible status cue is the glyph).
    final statusWord = _statusTitle(context, evaluation.status);
    final scheduledLine =
        context.l10n.evaluationCardScheduledFor(formattedDate);

    return Semantics(
      button: isTappable,
      enabled: isTappable,
      label: '${context.l10n.evaluationCardEyebrow}: $title — $statusWord. '
          '$scheduledLine',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isTappable
            ? () => context.push('/schedule/evaluation/${evaluation.id}')
            : null,
        child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A37280F),
              blurRadius: 12,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _StatusGlyph(status: evaluation.status),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      context.l10n.evaluationCardEyebrow,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.eyebrow,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: GoogleFonts.ebGaramond(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                      color: AppColors.primaryInk,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    scheduledLine,
                    style: GoogleFonts.publicSans(
                      fontSize: 13,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isTappable)
              ExcludeSemantics(
                child: ElevatedButton(
                  onPressed: () =>
                      context.push('/schedule/evaluation/${evaluation.id}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.neutral,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    context.l10n.evaluationCardCtaView,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.neutral,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

  String _statusTitle(BuildContext context, String status) {
    final l = context.l10n;
    return switch (status) {
      'pending' => l.evaluationCardStatusPending,
      'processing' => l.evaluationCardStatusProcessing,
      'ready' => l.evaluationCardStatusReady,
      'no_change_needed' => l.evaluationCardStatusNoChange,
      'accepted' => l.evaluationCardStatusAccepted,
      'dismissed' => l.evaluationCardStatusDismissed,
      _ => status.replaceAll('_', ' '),
    };
  }
}

class _StatusGlyph extends StatelessWidget {
  const _StatusGlyph({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    // Known statuses (`PlanEvaluationStatus` on backend). Anything else
    // falls through to a neutral calendar glyph so a new status added on
    // the backend before the app is updated renders harmlessly.
    final (icon, fg, bg) = switch (status) {
      'pending' => (CupertinoIcons.calendar, AppColors.tertiary, AppColors.lightTan),
      'processing' => (CupertinoIcons.hourglass, AppColors.tertiary, AppColors.lightTan),
      'ready' => (CupertinoIcons.doc_text_fill, AppColors.secondary, AppColors.goldGlow),
      'no_change_needed' => (CupertinoIcons.check_mark, AppColors.tertiary, AppColors.lightTan),
      'accepted' => (CupertinoIcons.check_mark, AppColors.success, AppColors.lightTan),
      'dismissed' => (CupertinoIcons.xmark, AppColors.inkMuted, AppColors.lightTan),
      _ => (CupertinoIcons.calendar, AppColors.tertiary, AppColors.lightTan),
    };

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 20, color: fg),
    );
  }
}
