import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, ElevatedButton, InkWell, Material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:app/core/i18n/build_context_l10n.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/utils/date_formatter.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/gradient_scaffold.dart';
import 'package:app/core/widgets/intro_fx.dart';
import 'package:app/features/coach/widgets/plan_content.dart';
import 'package:app/features/notifications/providers/notifications_provider.dart';
import 'package:app/features/schedule/models/plan_evaluation.dart';
import 'package:app/features/schedule/providers/plan_evaluations_provider.dart';

class EvaluationDetailScreen extends ConsumerWidget {
  const EvaluationDetailScreen({super.key, required this.evaluationId});

  final int evaluationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(planEvaluationProvider(evaluationId));

    return GradientScaffold(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _BackBar(),
            Expanded(
              child: async.when(
                loading: () => const Center(child: AppSpinner()),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    context.l10n.evaluationDetailLoadError(err.toString()),
                    style: GoogleFonts.publicSans(
                      fontSize: 14,
                      color: AppColors.inkMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                data: (eval) => eval == null
                    ? const SizedBox.shrink()
                    : IntroFx(child: _Loaded(evaluation: eval)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Loaded extends ConsumerStatefulWidget {
  const _Loaded({required this.evaluation});

  final PlanEvaluation evaluation;

  @override
  ConsumerState<_Loaded> createState() => _LoadedState();
}

class _LoadedState extends ConsumerState<_Loaded> {
  bool _busy = false;

  Map<String, dynamic>? get _proposalPayload {
    final raw = widget.evaluation.proposal?['payload'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final eval = widget.evaluation;
    final hasProposal = eval.proposalId != null && _proposalPayload != null;
    final isTerminal =
        eval.status == 'accepted' || eval.status == 'dismissed';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Eyebrow(label: context.l10n.evaluationCardEyebrow),
                const SizedBox(height: 8),
                Text(
                  context.l10n.evaluationDetailTitle,
                  style: GoogleFonts.ebGaramond(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                    height: 1.1,
                    color: AppColors.primaryInk,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.evaluationCardScheduledFor(
                    formatDateString(eval.scheduledFor),
                  ),
                  style: GoogleFonts.publicSans(
                    fontSize: 14,
                    color: AppColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 24),
                _SectionHeader(
                  label: context.l10n.evaluationDetailReportHeader,
                ),
                const SizedBox(height: 10),
                _ReportCard(markdown: eval.reportMarkdown),
                if (hasProposal) ...[
                  const SizedBox(height: 24),
                  _SectionHeader(
                    label: context.l10n.evaluationDetailProposalHeader,
                  ),
                  const SizedBox(height: 10),
                  _ProposalCard(payload: _proposalPayload!),
                ],
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: isTerminal
                ? _PrimaryButton(
                    label: context.l10n.evaluationDetailClose,
                    busy: false,
                    onPressed: () => Navigator.of(context).maybePop(),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _SecondaryButton(
                          label: context.l10n.evaluationDetailDismiss,
                          onPressed: _busy ? null : _dismiss,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: _PrimaryButton(
                          label: hasProposal
                              ? context.l10n.evaluationDetailApply
                              : context.l10n.evaluationDetailClose,
                          busy: _busy,
                          onPressed: _busy
                              ? null
                              : (hasProposal ? _accept : () => Navigator.of(context).maybePop()),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _accept() async {
    final notifId = widget.evaluation.notificationId;
    if (notifId == null) return;
    setState(() => _busy = true);
    // `NotificationsProvider.accept` invalidates planEvaluationsProvider +
    // scheduleProvider already; we only need to drop the single-evaluation
    // cache so the next visit to this id refetches and shows accepted state.
    final notifications = ref.read(notificationsProvider.notifier);
    try {
      await notifications.accept(notifId);
      ref.invalidate(planEvaluationProvider(widget.evaluation.id));
      if (mounted) Navigator.of(context).maybePop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _dismiss() async {
    final notifId = widget.evaluation.notificationId;
    if (notifId == null) return;
    setState(() => _busy = true);
    final notifications = ref.read(notificationsProvider.notifier);
    try {
      await notifications.dismiss(notifId);
      ref.invalidate(planEvaluationProvider(widget.evaluation.id));
      if (mounted) Navigator.of(context).maybePop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _BackBar extends StatelessWidget {
  const _BackBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () =>
                  context.canPop() ? context.pop() : context.go('/schedule'),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(
                  CupertinoIcons.back,
                  color: AppColors.primaryInk,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.goldGlow,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: AppColors.eyebrow,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.96,
        color: AppColors.inkMuted,
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.markdown});

  final String? markdown;

  @override
  Widget build(BuildContext context) {
    final body = markdown?.trim();
    return Container(
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
      padding: const EdgeInsets.all(18),
      child: body == null || body.isEmpty
          ? Text(
              context.l10n.evaluationDetailNoReport,
              style: GoogleFonts.publicSans(
                fontSize: 14,
                color: AppColors.inkMuted,
              ),
            )
          : GptMarkdown(
              body,
              style: GoogleFonts.publicSans(
                fontSize: 15,
                height: 1.55,
                color: AppColors.primaryInk,
              ),
            ),
    );
  }
}

class _ProposalCard extends StatelessWidget {
  const _ProposalCard({required this.payload});

  final Map<String, dynamic> payload;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      padding: const EdgeInsets.all(18),
      child: PlanContent(payload: payload),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.neutral,
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CupertinoActivityIndicator(
                color: CupertinoColors.white,
              ),
            )
          : Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.neutral,
              ),
            ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.lightTan,
        foregroundColor: AppColors.primaryInk,
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
          letterSpacing: 0.8,
          color: AppColors.primaryInk,
        ),
      ),
    );
  }
}
