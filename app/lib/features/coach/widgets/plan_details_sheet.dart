import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/i18n/build_context_l10n.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/coach/models/coach_proposal.dart';
import 'package:app/features/coach/widgets/plan_content.dart';

/// Bottom-sheet wrapper around [PlanContent] for the proposal flow
/// (onboarding + coach-chat). Adds the proposal-specific sticky footer
/// (Accept / Adjust / Close) on top of the shared plan rendering. Inactive
/// goals get a different wrapper ([GoalPlanSheet]) without the footer.
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

  bool get _isRevision {
    final raw = proposal.payload['diff'];
    return raw is List && raw.isNotEmpty;
  }

  Map<String, dynamic>? get _ambition {
    final raw = proposal.payload['ambition'];
    if (raw is! Map) return null;
    return Map<String, dynamic>.from(raw);
  }

  @override
  Widget build(BuildContext context) {
    final ambition = _ambition;
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
                  child: PlanContent(payload: proposal.payload),
                ),
              ),
              _StickyFooter(
                isPending: _isPending,
                isRevision: _isRevision,
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
