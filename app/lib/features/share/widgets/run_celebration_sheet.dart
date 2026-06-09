import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/i18n/build_context_l10n.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/schedule/models/training_result.dart';
import 'package:app/features/share/services/share_card_exporter.dart';
import 'package:app/features/share/widgets/run_share_card.dart';
import 'package:app/features/wearable/data/wearable_api.dart';
import 'package:app/features/wearable/services/workout_route_service.dart';

/// Full-screen modal that celebrates a completed, AI-analyzed run.
/// Renders the share card with intro animation, then exposes a Share
/// CTA that captures the card to PNG and hands it to the iOS share
/// sheet.
class RunCelebrationSheet {
  /// Show the celebration over the runner's current screen. [result]
  /// must have a `wearableActivity` attached (eager-loaded by the
  /// backend on day/result endpoints) for the route + KPIs.
  static Future<void> show(
    BuildContext context, {
    required TrainingResult result,
  }) {
    return showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => _RunCelebrationOverlay(result: result),
    );
  }
}

class _RunCelebrationOverlay extends ConsumerStatefulWidget {
  final TrainingResult result;

  const _RunCelebrationOverlay({required this.result});

  @override
  ConsumerState<_RunCelebrationOverlay> createState() =>
      _RunCelebrationOverlayState();
}

class _RunCelebrationOverlayState
    extends ConsumerState<_RunCelebrationOverlay> {
  final _boundaryKey = GlobalKey();
  final _shareCtaKey = GlobalKey();

  List<WorkoutRoutePoint>? _route;
  bool _routeLoading = true;
  bool _animationDone = false;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    final activityId = widget.result.wearableActivity?.id;
    if (activityId == null) {
      if (mounted) {
        setState(() {
          _route = const [];
          _routeLoading = false;
        });
      }
      return;
    }

    try {
      final api = ref.read(wearableApiProvider);
      final response = await api.route(activityId);
      final pointsRaw =
          (response as Map<String, dynamic>)['data']?['points'] as List? ??
              const [];
      final points = pointsRaw
          .whereType<Map>()
          .map((m) => WorkoutRoutePoint.fromMap(m))
          .toList(growable: false);
      if (mounted) {
        setState(() {
          _route = points;
          _routeLoading = false;
        });
      }
    } catch (_) {
      // Soft-fail: render the no-route variant.
      if (mounted) {
        setState(() {
          _route = const [];
          _routeLoading = false;
        });
      }
    }
  }

  Future<void> _share() async {
    if (_sharing || _route == null) return;
    setState(() => _sharing = true);
    try {
      await ShareCardExporter.capture(
        boundaryKey: _boundaryKey,
        subject: context.l10n.runShareBarrierLabel,
        origin: _shareCtaOrigin(),
      );
    } catch (e) {
      // Don't crash the sheet on export failure — keep it open so the
      // user can retry.
      debugPrint('[RunCelebrationSheet] share failed: $e');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  /// iOS requires a non-zero `sharePositionOrigin` (anchors the share
  /// sheet/popover on iPad and is rejected outright on iPhone when zero).
  /// Anchor it to the Share CTA's rect; fall back to the full sheet rect.
  Rect _shareCtaOrigin() {
    final box = _shareCtaKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      return box.localToGlobal(Offset.zero) & box.size;
    }
    final fallback = context.findRenderObject() as RenderBox?;
    if (fallback != null && fallback.hasSize) {
      return fallback.localToGlobal(Offset.zero) & fallback.size;
    }
    return Rect.zero;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final result = widget.result;
    final activity = result.wearableActivity;
    final activityDate =
        activity != null ? DateTime.tryParse(activity.startDate) : null;
    final durationSeconds = activity?.durationSeconds ?? 0;
    final paceSecondsPerKm = activity?.averagePaceSecondsPerKm ?? 0;
    final hr = activity?.averageHeartrate;

    final canShare = !_routeLoading && _animationDone && !_sharing;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.cream,
      child: SafeArea(
        child: Column(
          children: [
            _Header(onClose: () => Navigator.of(context).pop()),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.85,
                    child: _routeLoading
                        ? const Center(
                            child: CupertinoActivityIndicator(radius: 14),
                          )
                        : RepaintBoundary(
                            key: _boundaryKey,
                            child: RunShareCard(
                              route: _route ?? const [],
                              activityDate: activityDate ?? DateTime.now(),
                              distanceKm: result.actualKm,
                              durationSeconds: durationSeconds,
                              averagePaceSecondsPerKm: paceSecondsPerKm,
                              averageHeartRate: hr,
                              complianceScore: result.complianceScore,
                              aiFeedback: result.aiFeedback,
                              onIntroComplete: () {
                                if (mounted) {
                                  setState(() => _animationDone = true);
                                }
                              },
                            ),
                          ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ShareCta(
                    key: _shareCtaKey,
                    label: l10n.runShareSheetCta,
                    onPressed: canShare ? _share : null,
                    busy: _sharing,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.runShareSheetSubtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onClose;
  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: Size.zero,
            onPressed: onClose,
            child: Text(
              context.l10n.commonClose,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.inkMuted,
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _ShareCta extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  const _ShareCta({
    super.key,
    required this.label,
    required this.onPressed,
    required this.busy,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: SizedBox(
        width: double.infinity,
        child: CupertinoButton(
          onPressed: onPressed,
          padding: const EdgeInsets.symmetric(vertical: 14),
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(16),
          child: busy
              ? const CupertinoActivityIndicator(color: AppColors.neutral)
              : Text(
                  label.toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.neutral,
                    letterSpacing: 0.8,
                  ),
                ),
        ),
      ),
    );
  }
}
