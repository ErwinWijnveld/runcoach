import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/i18n/build_context_l10n.dart';
import 'package:app/core/widgets/runboost_logo.dart';
import 'package:app/features/schedule/widgets/training_day_status.dart';

/// Brandkit hero: the cream→gold gradient slab with the RunBoost spark as an
/// oversized watermark bleeding out of the top-right corner. Status pill +
/// title + status line sit bottom-left. No image assets — pure code, so it
/// renders identically on every platform and in every status (only the pill
/// and dot change color).
///
/// Design: option B of docs/design/2026-06-10-workout-hero-restyle.html.
class TrainingDayHeroCard extends StatelessWidget {
  final String title;
  final TrainingDayStatus status;

  const TrainingDayHeroCard({
    super.key,
    required this.title,
    required this.status,
  });

  /// Same vertical gradient as the brandkit tile (and the dashboard's
  /// recent-runs icon): #FDF9ED → #FCEFC8 @ 70% (flattened) → #F8E4AE.
  static const _gradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFDF9ED), Color(0xFFFCF2D3), Color(0xFFF8E4AE)],
    stops: [0.0, 0.5, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    final pillColor = status.pillColor;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: _gradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEFE7D2)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -26,
            top: -30,
            child: Transform.rotate(
              angle: 12 * 3.1415926535 / 180,
              child: const Opacity(
                opacity: 0.3,
                child: RunBoostSpark(size: 170),
              ),
            ),
          ),
          // Bottom-left anchored content; the breathing room falls at the
          // top of the slab (mockup B: justify-content flex-end).
          Container(
            constraints: const BoxConstraints(minHeight: 170),
            alignment: Alignment.bottomLeft,
            padding: const EdgeInsets.fromLTRB(18, 40, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: pillColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status.pillLabel(context.l10n),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                RunBoostHeading(
                  title,
                  size: 32,
                  height: 1.02,
                  maxLines: 2,
                  topPadding: 0,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: pillColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      status.subtitle(context.l10n),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: pillColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
