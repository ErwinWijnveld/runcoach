import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/schedule/widgets/training_day_status.dart';

/// Figma-faithful hero card: full-bleed illustration background with a
/// frosted-glass slab layered over the bottom third showing the status pill,
/// italic serif title, and status line.
///
/// Illustration swaps per [TrainingDayStatus] — currently every state uses
/// `assets/images/finisher.png` as a single placeholder. Drop additional
/// per-state PNGs into `assets/images/` (e.g. `missed.png`, `upcoming.png`)
/// and extend [_backgroundFor] to pick them.
class TrainingDayHeroCard extends StatelessWidget {
  final String title;
  final TrainingDayStatus status;

  const TrainingDayHeroCard({
    super.key,
    required this.title,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final pillColor = status.pillColor;

    return SizedBox(
      height: 200,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background illustration. Use a direct Image.asset (NOT a
          // Container with DecorationImage + a fallback color) so transparent
          // edges in the PNG don't reveal a colored ring at the rounded
          // corners. Default antiAlias clip keeps the corners looking as
          // round as the original — antiAliasWithSaveLayer renders them
          // slightly crisper which optically reads as "less rounded".
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Image.asset(
                _backgroundFor(status),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                alignment: Alignment.center,
              ),
            ),
          ),

          // Frosted-glass overlay slab — anchored to the bottom of the hero
          // so it always sits neatly regardless of the chosen illustration.
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status pill
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
                          status.pillLabel,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: CupertinoColors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Italic serif title
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.ebGaramond(
                          fontSize: 32,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                          color: AppColors.primaryInk,
                          height: 1.05,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
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
                            status.subtitle,
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Per-status background asset. Single placeholder today; add
  /// `missed.png`, `today.png`, `upcoming.png` when the designs land.
  String _backgroundFor(TrainingDayStatus status) {
    return switch (status) {
      TrainingDayStatus.completed => 'assets/images/finisher.png',
      TrainingDayStatus.missed => 'assets/images/finisher.png',
      TrainingDayStatus.today => 'assets/images/finisher.png',
      TrainingDayStatus.upcoming => 'assets/images/finisher.png',
    };
  }
}
