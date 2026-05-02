import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/wearable/models/analyzing_run.dart';
import 'package:app/features/wearable/providers/workout_sync_provider.dart';

/// Persistent chip placed at the top of the dashboard. Single UI surface
/// for the whole foreground-sync → match → AI-analysis pipeline. Shows
/// only when the user has work in flight; collapses to nothing otherwise.
///
/// Visible states (all use the same gold-pulse → green-check transition):
///
///   syncing             →  pulsing dot + "Syncing your runs from Apple Health…"
///                          (visible while isSyncing == true; takes over from
///                          any prior chip immediately)
///   matched / pending   →  pulsing dot + "AI is analyzing your run"
///                          (after sync returns with a matched run, until
///                          push or polling flips status to analyzed)
///   analyzed            →  green check + "Analysis ready · 8.4/10"
///                          (auto-dismisses after a few seconds)
///   unmatched           →  muted dot + "Run logged · no matching training day"
///                          (auto-dismisses)
///
/// Replaces the earlier separate toast + chip: a single persistent indicator
/// is what the user actually wanted ("the spinner keeps running until the
/// run is matched, then AI analysis starts"), and avoids overlay surfaces
/// fighting pumpAndSettle in unit tests.
class AnalyzingRunChip extends ConsumerWidget {
  const AnalyzingRunChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workoutSyncProvider);
    final analyzing = state.analyzing;

    // 1) During the network sync, show the syncing copy regardless of
    //    whether prior analyzing entries exist — they belong to a previous
    //    sync cycle and the new one supersedes them.
    if (state.isSyncing) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: _ChipShell(
          indicator: _PulsingDot(color: AppColors.gold),
          title: 'Syncing your runs',
          subtitle: 'Pulling new runs from Apple Health…',
        ),
      );
    }

    if (analyzing.isEmpty) return const SizedBox.shrink();

    // Show the most recently started run if there are several. The map
    // preserves insertion order in Dart, so .last is the freshest.
    final entry = analyzing.values.last;
    final more = analyzing.length - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: _ChipForRun(run: entry, additionalCount: more),
    );
  }
}

class _ChipForRun extends StatelessWidget {
  final AnalyzingRun run;
  final int additionalCount;
  const _ChipForRun({required this.run, required this.additionalCount});

  @override
  Widget build(BuildContext context) {
    final (title, subtitle, indicator) = switch (run.status) {
      // Pending is rare in the new flow — matching is synchronous in the
      // POST. Kept as a defensive fallback for the polling endpoint which
      // still distinguishes "no result yet".
      AnalyzingRunStatus.pending => (
          'Matching to your training plan',
          'Just a moment…',
          const _PulsingDot(color: AppColors.gold) as Widget,
        ),
      AnalyzingRunStatus.matched => (
          'AI is analyzing your run',
          'Generating personalized feedback…',
          const _PulsingDot(color: AppColors.gold) as Widget,
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
          ) as Widget,
        ),
      AnalyzingRunStatus.unmatched => (
          'Run logged',
          'No matching training day',
          const Icon(
            CupertinoIcons.circle_fill,
            size: 10,
            color: AppColors.textSecondary,
          ) as Widget,
        ),
    };

    final titleSuffix =
        additionalCount > 0 ? ' (${additionalCount + 1} runs)' : '';

    return _ChipShell(
      indicator: indicator,
      title: '$title$titleSuffix',
      subtitle: subtitle,
    );
  }

  String _score(double s) {
    final r = (s * 10).round() / 10;
    if (r == r.toInt()) return r.toInt().toString();
    return r.toString();
  }
}

class _ChipShell extends StatelessWidget {
  final Widget indicator;
  final String title;
  final String subtitle;
  const _ChipShell({
    required this.indicator,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
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
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryInk,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
