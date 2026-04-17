import 'package:flutter/material.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/coach/models/coach_proposal.dart';
import 'package:google_fonts/google_fonts.dart';

class ProposalCard extends StatelessWidget {
  final CoachProposal proposal;
  final VoidCallback? onAccept;
  final VoidCallback? onAdjust;
  final VoidCallback? onViewDetails;

  const ProposalCard({
    super.key,
    required this.proposal,
    this.onAccept,
    this.onAdjust,
    this.onViewDetails,
  });

  bool get _isPending => proposal.status == 'pending';

  @override
  Widget build(BuildContext context) {
    final weeklyKm = _computeWeeklyKm(proposal.payload);
    final weeklyRuns = _computeWeeklyRuns(proposal.payload);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 296),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 16)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: _summaryItem('WEEKLY KM', '${weeklyKm.toStringAsFixed(1)} km')),
              const SizedBox(width: 32),
              Expanded(child: _summaryItem('WEEKLY RUNS', weeklyRuns)),
            ]),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onViewDetails,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                backgroundColor: AppColors.neutralHighlight,
                side: BorderSide.none,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.visibility_outlined, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'VIEW DETAILS',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            if (_isPending) ...[
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      'ACCEPT',
                      style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAdjust,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      'ADJUST',
                      style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ]),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                proposal.status == 'accepted' ? 'Plan accepted.' : 'Plan rejected.',
                style: const TextStyle(color: AppColors.inkMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.inkMuted,
            letterSpacing: 0.96,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryInk,
          ),
        ),
      ],
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
    return min == max ? '$min' : '$min–$max';
  }
}
