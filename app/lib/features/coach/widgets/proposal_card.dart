import 'package:flutter/material.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/coach/models/coach_proposal.dart';
import 'package:google_fonts/google_fonts.dart';

class ProposalCard extends StatelessWidget {
  final CoachProposal proposal;
  final VoidCallback? onAccept;
  final VoidCallback? onViewDetails;

  const ProposalCard({
    super.key,
    required this.proposal,
    this.onAccept,
    this.onViewDetails,
  });

  bool get _isPending => proposal.status == 'pending';

  List<dynamic>? get _diff {
    final raw = proposal.payload['diff'];
    return raw is List && raw.isNotEmpty ? raw : null;
  }

  @override
  Widget build(BuildContext context) {
    final diff = _diff;
    final isRevision = diff != null;
    final weeklyKm = _computeWeeklyKm(proposal.payload);
    final weeklyRuns = _computeWeeklyRuns(proposal.payload);
    final changeCount = diff?.length ?? 0;

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
            if (isRevision) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.goldGlow,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'PLAN REVISION',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: const Color(0xFF785A00),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$changeCount ${changeCount == 1 ? 'change' : 'changes'} to your plan',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryInk,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap below to review what changed before applying.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.inkMuted,
                  height: 1.3,
                ),
              ),
            ] else ...[
              Row(children: [
                Expanded(child: _summaryItem('WEEKLY KM', '${weeklyKm.toStringAsFixed(1)} km')),
                const SizedBox(width: 32),
                Expanded(child: _summaryItem('WEEKLY RUNS', weeklyRuns)),
              ]),
            ],
            const SizedBox(height: 20),
            // Primary CTA — biggest, darkest, full-width. Reviewing the
            // plan is the most useful thing the runner can do before
            // accepting, so it dominates the hierarchy.
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onViewDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isRevision
                          ? Icons.tune_rounded
                          : Icons.visibility_outlined,
                      size: 20,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isRevision ? 'VIEW CHANGES' : 'VIEW DETAILS',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isPending) ...[
              const SizedBox(height: 10),
              // Secondary CTA — gold accent but intentionally slimmer
              // than the primary. Still obvious, just not the default
              // eye-path.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'ACCEPT',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Tertiary — not a button. Points the runner to the chat
              // input below so they can just say what to change.
              Center(
                child: Text(
                  'Tell me what to adjust below',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkMuted,
                    height: 1.3,
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                proposal.status == 'accepted' ? 'Plan accepted.' : 'Rejected.',
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
