import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:app/core/i18n/build_context_l10n.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/runcore_logo.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/features/share/painters/route_polyline_painter.dart';
import 'package:app/features/share/utils/feedback_verdict_extractor.dart';
import 'package:app/features/wearable/services/workout_route_service.dart';

/// 9:16 portrait share card for a completed, AI-analyzed run.
///
/// Composes the brand eyebrow, an animated gold route polyline, the
/// italic-Garamond verdict sentence (first bold span from AI feedback),
/// and 5 KPIs in two rows (distance + time + pace top, HR + compliance
/// bottom). Designed to be wrapped in a `RepaintBoundary` by the host
/// sheet so it can be exported to PNG for the iOS share sheet.
///
/// The card aspects to a fixed 9:16 — callers should provide a sized
/// container (typically via `AspectRatio(aspectRatio: 9/16)`).
class RunShareCard extends StatelessWidget {
  /// GPS polyline. Pass an empty list for treadmill / no-GPS runs;
  /// the card falls back to a route-less layout with bigger KPI tiles.
  final List<WorkoutRoutePoint> route;

  /// Activity start (used for the "Wed 22 May 2026" date stamp).
  final DateTime activityDate;

  /// Distance in km. Renders as "10.2 KM" / "10 KM".
  final double distanceKm;

  /// Total duration in seconds. Renders as "52:18" / "1:23:45".
  final int durationSeconds;

  /// Average pace in seconds per km. Renders as "5:08/KM".
  final int averagePaceSecondsPerKm;

  /// Average HR in bpm. Null → HR tile hidden.
  final double? averageHeartRate;

  /// 0–10 compliance score from `TrainingResult`. Null → tile hidden.
  final double? complianceScore;

  /// Raw AI feedback string; we extract the first **bold** sentence.
  final String? aiFeedback;

  /// 0.0 → 1.0 — drives the polyline stroke-draw + marker pop-in.
  /// Pass `1.0` for the static final state (e.g. golden tests / when
  /// rendering after the animation finished).
  final double routeProgress;

  const RunShareCard({
    super.key,
    required this.route,
    required this.activityDate,
    required this.distanceKm,
    required this.durationSeconds,
    required this.averagePaceSecondsPerKm,
    this.averageHeartRate,
    this.complianceScore,
    this.aiFeedback,
    this.routeProgress = 1.0,
  });

  bool get _hasRoute => route.length >= 2;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final verdict = extractVerdict(aiFeedback);

    return AspectRatio(
      aspectRatio: 9 / 16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.cream,
          gradient: RadialGradient(
            center: const Alignment(0.85, -0.9),
            radius: 1.1,
            colors: [
              AppColors.secondary.withValues(alpha: 0.18),
              AppColors.cream,
            ],
            stops: const [0.0, 0.7],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Eyebrow(date: activityDate)
                  .animate()
                  .fadeIn(duration: 300.ms, curve: Curves.easeOut),
              const SizedBox(height: 12),
              Expanded(
                flex: _hasRoute ? 5 : 0,
                child: _hasRoute
                    ? _RoutePanel(
                        route: route,
                        progress: routeProgress,
                      )
                    : const SizedBox.shrink(),
              ),
              if (!_hasRoute) ...[
                const SizedBox(height: 12),
                _IndoorPill(label: l10n.runShareIndoorPill)
                    .animate()
                    .fadeIn(duration: 300.ms, curve: Curves.easeOut),
              ],
              const SizedBox(height: 18),
              if (verdict != null) ...[
                _Verdict(verdict: verdict)
                    .animate()
                    .fadeIn(
                      delay: 1500.ms,
                      duration: 400.ms,
                      curve: Curves.easeOutCubic,
                    )
                    .slideY(
                      begin: 0.15,
                      end: 0,
                      duration: 400.ms,
                      curve: Curves.easeOutCubic,
                    ),
                const SizedBox(height: 18),
              ],
              _KpiGrid(
                l10n: l10n,
                distanceKm: distanceKm,
                durationSeconds: durationSeconds,
                averagePaceSecondsPerKm: averagePaceSecondsPerKm,
                averageHeartRate: averageHeartRate,
                complianceScore: complianceScore,
                hasRoute: _hasRoute,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Brand wordmark (left) + date stamp (right) — top eyebrow row.
class _Eyebrow extends StatelessWidget {
  final DateTime date;
  const _Eyebrow({required this.date});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final formatted = DateFormat.yMMMd(locale).format(date).toUpperCase();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const RunCoreLogo(
          starSize: 18,
          textSize: 18,
          gap: 8,
          textColor: AppColors.primaryInk,
          starColor: AppColors.primaryInk,
        ),
        const Spacer(),
        Text(
          formatted,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.eyebrow,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _RoutePanel extends StatelessWidget {
  final List<WorkoutRoutePoint> route;
  final double progress;

  const _RoutePanel({required this.route, required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(
        painter: RoutePolylinePainter(
          progress: progress,
          points: route,
        ),
      ),
    );
  }
}

class _IndoorPill extends StatelessWidget {
  final String label;
  const _IndoorPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.goldGlow,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.eyebrow,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

class _Verdict extends StatelessWidget {
  final String verdict;
  const _Verdict({required this.verdict});

  @override
  Widget build(BuildContext context) {
    return Text(
      _smartQuote(verdict),
      textAlign: TextAlign.left,
      style: GoogleFonts.ebGaramond(
        fontSize: 26,
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.italic,
        color: AppColors.primaryInk,
        height: 1.1,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _smartQuote(String s) {
    // Strip trailing period (it floats awkwardly in italic Garamond
    // when set in a card).
    final trimmed = s.trim().replaceFirst(RegExp(r'[.]+$'), '');
    return '"$trimmed."';
  }
}

class _KpiGrid extends StatelessWidget {
  final AppLocalizations l10n;
  final double distanceKm;
  final int durationSeconds;
  final int averagePaceSecondsPerKm;
  final double? averageHeartRate;
  final double? complianceScore;
  final bool hasRoute;

  const _KpiGrid({
    required this.l10n,
    required this.distanceKm,
    required this.durationSeconds,
    required this.averagePaceSecondsPerKm,
    required this.averageHeartRate,
    required this.complianceScore,
    required this.hasRoute,
  });

  @override
  Widget build(BuildContext context) {
    final hasHr = averageHeartRate != null;
    final hasCompliance = complianceScore != null;
    final hasSecondRow = hasHr || hasCompliance;

    // Stagger params per spec — KPI tiles fade-slide in starting at 1700ms.
    Widget stagger(int index, Widget child) => child
        .animate()
        .fadeIn(
          delay: (1700 + 80 * index).ms,
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        )
        .slideY(
          begin: 0.2,
          end: 0,
          delay: (1700 + 80 * index).ms,
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        );

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: stagger(
                0,
                _KpiTile(
                  value: _formatDistance(distanceKm),
                  label: l10n.runShareKpiDistance,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: stagger(
                1,
                _KpiTile(
                  value: _formatDuration(durationSeconds),
                  label: l10n.runShareKpiTime,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: stagger(
                2,
                _KpiTile(
                  value: _formatPace(averagePaceSecondsPerKm),
                  label: l10n.runShareKpiAvgPace,
                ),
              ),
            ),
          ],
        ),
        if (hasSecondRow) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              if (hasHr)
                Expanded(
                  flex: hasCompliance ? 1 : 2,
                  child: stagger(
                    3,
                    _KpiTile(
                      value: averageHeartRate!.round().toString(),
                      label: l10n.runShareKpiAvgHr,
                    ),
                  ),
                ),
              if (hasHr && hasCompliance) const SizedBox(width: 10),
              if (hasCompliance)
                Expanded(
                  flex: hasHr ? 1 : 2,
                  child: stagger(
                    4,
                    _KpiTile(
                      value: '${(complianceScore! * 10).round()}%',
                      label: l10n.runShareKpiCompliance,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  String _formatDistance(double km) {
    if (km == 0) return '—';
    final rounded = km.toStringAsFixed(km < 100 ? 1 : 0);
    return '$rounded km';
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '—';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String _formatPace(int secondsPerKm) {
    if (secondsPerKm <= 0) return '—';
    final m = secondsPerKm ~/ 60;
    final s = secondsPerKm % 60;
    return '$m:${s.toString().padLeft(2, '0')}/km';
  }
}

class _KpiTile extends StatelessWidget {
  final String value;
  final String label;

  const _KpiTile({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A37280F),
            blurRadius: 8,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryInk,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.inkMuted,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
