import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:app/core/i18n/build_context_l10n.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/runboost_logo.dart';
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
/// The intro is driven by a single internal [AnimationController] so the
/// elements flow in as one coordinated sequence: the polyline draws while
/// a "runner" marker rides its leading edge, and the verdict + KPIs fade
/// in overlapping the tail of that draw (no dead gap). [onIntroComplete]
/// fires once the controller settles — the host gates the Share button
/// on it so the exported PNG never catches a half-drawn frame.
///
/// The card aspects to a fixed 9:16 — callers should provide a sized
/// container (typically via `AspectRatio(aspectRatio: 9/16)`).
class RunShareCard extends StatefulWidget {
  /// Total intro-animation duration. Exposed so the host sheet can stay
  /// in sync without duplicating the number.
  static const Duration introDuration = Duration(milliseconds: 2200);

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

  /// When false (or when Reduce Motion is on) the card renders at its
  /// final state immediately — no intro animation.
  final bool animate;

  /// Fires once the intro animation settles (or immediately when not
  /// animating). Used by the host to enable the Share CTA.
  final VoidCallback? onIntroComplete;

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
    this.animate = true,
    this.onIntroComplete,
  });

  @override
  State<RunShareCard> createState() => _RunShareCardState();
}

class _RunShareCardState extends State<RunShareCard>
    with SingleTickerProviderStateMixin {
  /// Number of KPI tiles that stagger in (3 top + 2 bottom).
  static const _kKpiTileCount = 5;

  late final AnimationController _controller;

  // Pre-built sub-animations so the card layout builds ONCE and only the
  // individual transitions (+ the route painter) tick per frame.
  late final Animation<double> _eyebrowFade;
  late final Animation<double> _routeAnim;
  late final Animation<double> _pillFade;
  late final Animation<double> _verdictFade;
  late final Animation<Offset> _verdictSlide;
  late final List<Animation<double>> _kpiFades;
  late final List<Animation<Offset>> _kpiSlides;

  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: RunShareCard.introDuration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onIntroComplete?.call();
        }
      });

    _eyebrowFade = _fade(0.0, 0.16);
    // The route is the hero — it draws over most of the timeline while a
    // "runner" marker rides its tip. The verdict + KPIs start before it
    // finishes so there's no dead gap.
    _routeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.68, curve: Curves.easeInOutCubic),
    );
    _pillFade = _fade(0.10, 0.30);
    _verdictFade = _fade(0.52, 0.82);
    _verdictSlide = _slide(0.52, 0.82, 0.15);

    _kpiFades = [
      for (var i = 0; i < _kKpiTileCount; i++)
        _fade(0.56 + 0.07 * i, _clamp01(0.78 + 0.07 * i)),
    ];
    _kpiSlides = [
      for (var i = 0; i < _kKpiTileCount; i++)
        _slide(0.56 + 0.07 * i, _clamp01(0.78 + 0.07 * i), 0.2),
    ];
  }

  Animation<double> _fade(double start, double end) => CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );

  Animation<Offset> _slide(double start, double end, double dy) =>
      Tween<Offset>(begin: Offset(0, dy), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );

  static double _clamp01(double v) => v > 1.0 ? 1.0 : v;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!widget.animate || reduceMotion) {
      _controller.value = 1.0;
      // Defer to after this frame so the parent can setState safely.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onIntroComplete?.call();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _hasRoute => widget.route.length >= 2;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final verdict = extractVerdict(widget.aiFeedback);

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
              FadeTransition(
                opacity: _eyebrowFade,
                child: _Eyebrow(date: widget.activityDate),
              ),
              const SizedBox(height: 12),
              Expanded(
                flex: _hasRoute ? 5 : 0,
                child: _hasRoute
                    ? _RoutePanel(
                        route: widget.route,
                        progress: _routeAnim,
                      )
                    : const SizedBox.shrink(),
              ),
              if (!_hasRoute) ...[
                const SizedBox(height: 12),
                FadeTransition(
                  opacity: _pillFade,
                  child: _IndoorPill(label: l10n.runShareIndoorPill),
                ),
              ],
              const SizedBox(height: 18),
              if (verdict != null) ...[
                FadeTransition(
                  opacity: _verdictFade,
                  child: SlideTransition(
                    position: _verdictSlide,
                    child: _Verdict(verdict: verdict),
                  ),
                ),
                const SizedBox(height: 18),
              ],
              _KpiGrid(
                l10n: l10n,
                distanceKm: widget.distanceKm,
                durationSeconds: widget.durationSeconds,
                averagePaceSecondsPerKm: widget.averagePaceSecondsPerKm,
                averageHeartRate: widget.averageHeartRate,
                complianceScore: widget.complianceScore,
                hasRoute: _hasRoute,
                fades: _kpiFades,
                slides: _kpiSlides,
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
  final Animation<double> progress;

  const _RoutePanel({required this.route, required this.progress});

  @override
  Widget build(BuildContext context) {
    // The painter is built ONCE and repaints off [progress]
    // (`super(repaint: progress)`), so the Douglas-Peucker simplification
    // doesn't re-run every frame.
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
    return RunBoostHeading(
      _smartQuote(verdict),
      size: 24,
      maxLines: 3,
      textAlign: TextAlign.left,
      topPadding: 0,
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

  /// Per-tile fade + slide animations, indexed 0..4 (0,1,2 top row;
  /// 3,4 bottom row).
  final List<Animation<double>> fades;
  final List<Animation<Offset>> slides;

  const _KpiGrid({
    required this.l10n,
    required this.distanceKm,
    required this.durationSeconds,
    required this.averagePaceSecondsPerKm,
    required this.averageHeartRate,
    required this.complianceScore,
    required this.hasRoute,
    required this.fades,
    required this.slides,
  });

  @override
  Widget build(BuildContext context) {
    final hasHr = averageHeartRate != null;
    final hasCompliance = complianceScore != null;
    final hasSecondRow = hasHr || hasCompliance;

    Widget tile(int index, Widget child) => FadeTransition(
          opacity: fades[index],
          child: SlideTransition(position: slides[index], child: child),
        );

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: tile(
                0,
                _KpiTile(
                  value: _formatDistance(distanceKm),
                  label: l10n.runShareKpiDistance,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: tile(
                1,
                _KpiTile(
                  value: _formatDuration(durationSeconds),
                  label: l10n.runShareKpiTime,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: tile(
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
                  child: tile(
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
                  child: tile(
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
