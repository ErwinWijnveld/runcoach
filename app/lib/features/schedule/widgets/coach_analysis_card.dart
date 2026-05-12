import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/i18n/build_context_l10n.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/ai_glow_card.dart';
import 'package:app/core/widgets/compliance_ring.dart';
import 'package:app/features/coach/widgets/swooshing_star.dart';

/// Coach analysis card on the training day detail screen. Shows a large
/// compliance ring (top-left), a multi-line excerpt of the AI feedback
/// (right, up to 5 lines), and a clear arrow CTA bottom-right that routes
/// to the full result screen. The whole card is tappable too.
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
    final l10n = context.l10n;
    final score01 = (complianceScore10 / 10).clamp(0.0, 1.0);
    final isLoading = aiFeedback == null || aiFeedback!.trim().isEmpty;
    final excerpt = _excerpt(l10n.coachAnalysisAnalysing, aiFeedback);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isLoading ? null : onOpen,
        child: AiGlowCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (isLoading)
                    const SizedBox(
                      width: 84,
                      height: 84,
                      child: Center(child: SwooshingStar(size: 40)),
                    )
                  else
                    ComplianceRing(score01: score01, size: 84, strokeWidth: 7),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.coachAnalysisEyebrow,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.88,
                            color: AppColors.inkMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.coachAnalysisCompliance,
                          style: GoogleFonts.ebGaramond(
                            fontSize: 24,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primaryInk,
                            height: 1.05,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                excerpt,
                style: GoogleFonts.publicSans(
                  fontSize: 14,
                  height: 1.45,
                  color: AppColors.primaryInk,
                ),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
              if (!isLoading) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onOpen,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.coachAnalysisOpenCta,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.96,
                                color: CupertinoColors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              CupertinoIcons.arrow_right,
                              size: 14,
                              color: CupertinoColors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _excerpt(String loadingLabel, String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return loadingLabel;
    }
    return raw
        .replaceAll(RegExp(r'[#*_`>]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
