import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/wearable/models/analyzing_run.dart';
import 'package:app/features/wearable/providers/workout_sync_provider.dart';

/// Persistent chip placed at the top of the dashboard while a run is
/// being analyzed. Three visual states keyed off [AnalyzingRunStatus]:
///
///   pending / matched   →  pulsing gold dot + "Analyzing your run…"
///   analyzed            →  solid green check + "Analysis ready"
///                          (auto-dismisses after a few seconds)
///   unmatched           →  muted dot + "Run logged"
///
/// Hidden entirely when the analyzing map is empty.
class AnalyzingRunChip extends ConsumerWidget {
  const AnalyzingRunChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workoutSyncProvider);
    final analyzing = state.analyzing;
    if (analyzing.isEmpty) return const SizedBox.shrink();

    // Show the most recently started run if there are several. The map
    // preserves insertion order in Dart.
    final entry = analyzing.values.last;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: _ChipBody(run: entry, total: analyzing.length),
    );
  }
}

class _ChipBody extends StatelessWidget {
  final AnalyzingRun run;
  final int total;
  const _ChipBody({required this.run, required this.total});

  @override
  Widget build(BuildContext context) {
    final (label, sublabel, indicator) = switch (run.status) {
      AnalyzingRunStatus.pending => (
          'Analyzing your run',
          'Matching with your training plan…',
          const _PulsingDot(color: AppColors.gold),
        ),
      AnalyzingRunStatus.matched => (
          'Coach is reviewing it',
          'Generating feedback…',
          const _PulsingDot(color: AppColors.gold),
        ),
      AnalyzingRunStatus.analyzed => (
          'Analysis ready',
          run.complianceScore != null
              ? 'Compliance ${_score(run.complianceScore!)}/10'
              : 'Tap to view',
          const Icon(
            CupertinoIcons.checkmark_circle_fill,
            size: 16,
            color: AppColors.success,
          ),
        ),
      AnalyzingRunStatus.unmatched => (
          'Run logged',
          'No matching training day',
          const Icon(
            CupertinoIcons.circle_fill,
            size: 10,
            color: AppColors.textSecondary,
          ),
        ),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryInk.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(width: 18, height: 18, child: Center(child: indicator)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  total > 1 ? '$label (${total - 1} more queued)' : label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryInk,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sublabel,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _score(double s) {
    final r = (s * 10).round() / 10;
    if (r == r.toInt()) return r.toInt().toString();
    return r.toString();
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final scale = 0.7 + 0.5 * _ctrl.value;
        final opacity = 0.45 + 0.55 * (1 - _ctrl.value);
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 14 * scale,
              height: 14 * scale,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: opacity * 0.3),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
          ],
        );
      },
    );
  }
}
