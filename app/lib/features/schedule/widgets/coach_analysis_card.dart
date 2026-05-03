import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/ai_glow_card.dart';
import 'package:app/core/widgets/compliance_ring.dart';
import 'package:app/features/coach/widgets/swooshing_star.dart';

/// Combined card that replaces the separate "Coach analysis" + "Synced
/// activity" sections on the training day detail screen. Shows:
///   - top eyebrow "COACH ANALYSIS" + "Open ›" link (right-aligned),
///   - circular ring with the compliance percentage on the left,
///   - "COMPLIANCE" eyebrow + a one-line excerpt of the AI feedback,
///   - dark arrow button on the right.
///
/// The whole card AND the "Open" link AND the arrow all route to the same
/// place — the training result screen — to give the user multiple obvious
/// entry points.
class CoachAnalysisCard extends StatelessWidget {
  final double complianceScore10;
  final String? aiFeedback;
  final VoidCallback onOpen;

  const CoachAnalysisCard({
    super.key,
    required this.complianceScore10,
    required this.aiFeedback,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final score01 = (complianceScore10 / 10).clamp(0.0, 1.0);
    final isLoading = aiFeedback == null || aiFeedback!.trim().isEmpty;
    final excerpt = _excerpt(aiFeedback);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
          child: Row(
            children: [
              Text(
                'COACH ANALYSIS',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.96,
                  color: AppColors.inkMuted,
                ),
              ),
              const Spacer(),
              if (!isLoading)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onOpen,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          'Open',
                          style: GoogleFonts.publicSans(
                            fontSize: 14,
                            color: AppColors.primaryInk,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          CupertinoIcons.chevron_right,
                          size: 12,
                          color: AppColors.primaryInk,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: isLoading ? null : onOpen,
            child: AiGlowCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (isLoading)
                    const SizedBox(
                      width: 56,
                      height: 56,
                      child: Center(child: SwooshingStar(size: 28)),
                    )
                  else
                    ComplianceRing(score01: score01),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'COMPLIANCE',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.88,
                            color: AppColors.inkMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          excerpt,
                          style: GoogleFonts.publicSans(
                            fontSize: 14,
                            height: 1.4,
                            color: AppColors.primaryInk,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (!isLoading) ...[
                    const SizedBox(width: 12),
                    const _ArrowButton(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Strip basic markdown markers and collapse whitespace so the text fits
  /// cleanly in the 2-line clamp. The Text widget handles truncation; we
  /// don't manually slice characters (was producing odd cut-offs mid-word).
  /// Returns a placeholder only when feedback genuinely hasn't landed yet.
  static String _excerpt(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 'Analysing your run…';
    }
    return raw
        .replaceAll(RegExp(r'[#*_`>]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Icon(
        CupertinoIcons.arrow_right,
        size: 16,
        color: CupertinoColors.white,
      ),
    );
  }
}
