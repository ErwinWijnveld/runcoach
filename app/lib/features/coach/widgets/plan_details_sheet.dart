import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/coach/models/coach_proposal.dart';
import 'package:app/features/coach/providers/plan_explanation_provider.dart';
import 'package:app/features/coach/widgets/swooshing_star.dart';

class PlanDetailsSheet extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(planExplanationProvider(proposal.id));
    final weeklyKm = _computeWeeklyKm(proposal.payload);
    final weeklyRuns = _computeWeeklyRuns(proposal.payload);

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
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(async),
                      const SizedBox(height: 12),
                      _body(async),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: _statItem(
                              'WEEKLY KM',
                              '${weeklyKm.toStringAsFixed(1)} km',
                            ),
                          ),
                          const SizedBox(width: 32),
                          Expanded(child: _statItem('WEEKLY RUNS', weeklyRuns)),
                        ],
                      ),
                      const SizedBox(height: 32),
                      if (_isPending) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _primaryButton(
                                'ACCEPT PLAN',
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
                              child: _primaryButton(
                                'ADJUST',
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
                      _closeButton(context),
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

  Widget _header(AsyncValue<PlanExplanation> async) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recommended Plan',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF785A00),
                ),
              ),
              const SizedBox(height: 4),
              async.when(
                data: (e) => Text(
                  e.name,
                  style: GoogleFonts.ebGaramond(
                    fontSize: 30,
                    fontWeight: FontWeight.w400,
                    height: 34 / 30,
                    color: AppColors.primaryInk,
                  ),
                ),
                loading: () => Container(
                  height: 30,
                  width: 200,
                  decoration: BoxDecoration(
                    color: AppColors.neutralHighlight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                error: (_, _) => Text(
                  'Your training plan',
                  style: GoogleFonts.ebGaramond(
                    fontSize: 30,
                    fontWeight: FontWeight.w400,
                    height: 34 / 30,
                    color: AppColors.primaryInk,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.directions_run,
          size: 30,
          color: AppColors.eyebrow,
        ),
      ],
    );
  }

  Widget _body(AsyncValue<PlanExplanation> async) {
    return async.when(
      data: (e) => Text(
        e.explanation,
        style: GoogleFonts.publicSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.4,
          color: AppColors.primaryInk,
        ),
      ),
      loading: () => const _PlanExplanationLoading(),
      error: (err, _) => Row(
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_circle,
            size: 16,
            color: AppColors.danger,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Couldn't load the explanation.",
              style: GoogleFonts.publicSans(
                fontSize: 14,
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: RunCoreText.statLabel()),
        const SizedBox(height: 4),
        Text(value, style: RunCoreText.statValue()),
      ],
    );
  }

  Widget _primaryButton(
    String label, {
    required Color background,
    required Color foreground,
    VoidCallback? onPressed,
  }) {
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

  Widget _closeButton(BuildContext context) {
    return OutlinedButton(
      onPressed: () => Navigator.of(context).pop(),
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

  double _computeWeeklyKm(Map<String, dynamic> payload) {
    final schedule = payload['schedule'] as Map<String, dynamic>?;
    final weeks = schedule?['weeks'] as List?;
    if (weeks == null || weeks.isEmpty) return 0.0;
    final totals = weeks
        .map((w) => (w as Map)['total_km'])
        .whereType<num>()
        .toList();
    if (totals.isEmpty) return 0.0;
    return totals.reduce((a, b) => a + b) / totals.length;
  }

  String _computeWeeklyRuns(Map<String, dynamic> payload) {
    final schedule = payload['schedule'] as Map<String, dynamic>?;
    final weeks = schedule?['weeks'] as List?;
    if (weeks == null || weeks.isEmpty) return '0';
    final counts = weeks.map((w) {
      final days = ((w as Map)['days'] as List?)
              ?.where((d) => (d as Map)['type'] != 'rest')
              .length ??
          0;
      return days;
    }).toList();
    final min = counts.reduce((a, b) => a < b ? a : b);
    final max = counts.reduce((a, b) => a > b ? a : b);
    return min == max ? '$min' : '$min to $max';
  }
}

class _PlanExplanationLoading extends StatelessWidget {
  const _PlanExplanationLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.neutralHighlight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SwooshingStar(size: 28),
          const SizedBox(height: 16),
          Text(
            'Writing your plan summary',
            style: GoogleFonts.ebGaramond(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              color: AppColors.primaryInk,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'This takes a few seconds — your coach is reviewing the weekly structure.',
            style: GoogleFonts.publicSans(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.4,
              color: AppColors.tertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
