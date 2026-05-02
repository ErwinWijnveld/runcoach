import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/wearable/providers/workout_sync_provider.dart';

/// Floating toast that slides in from the top whenever a foreground sync
/// produced new run rows. Auto-dismisses after [_visibleFor] and clears
/// the [WorkoutSync.notifiedNewRunsCount] counter so it only appears once
/// per sync.
///
/// Lives at the root of the router shell so it overlays whatever screen
/// is on top — same surface the analyzing chip uses.
class NewRunsToastHost extends ConsumerStatefulWidget {
  final Widget child;
  const NewRunsToastHost({super.key, required this.child});

  @override
  ConsumerState<NewRunsToastHost> createState() => _NewRunsToastHostState();
}

class _NewRunsToastHostState extends ConsumerState<NewRunsToastHost> {
  static const _visibleFor = Duration(seconds: 3);
  static const _slideDuration = Duration(milliseconds: 300);

  Timer? _hideTimer;
  int? _activeBatchSize;
  bool _visible = false;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _show(int newRuns) {
    _hideTimer?.cancel();
    setState(() {
      _activeBatchSize = newRuns;
      _visible = true;
    });
    _hideTimer = Timer(_visibleFor, () {
      if (!mounted) return;
      setState(() => _visible = false);
    });
    // Drop the counter immediately so we don't re-trigger on rebuilds.
    ref.read(workoutSyncProvider.notifier).clearNewRunsToast();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(workoutSyncProvider, (prev, next) {
      // Fire only on the rising edge of notifiedNewRunsCount and only
      // when the latest sync actually produced new runs.
      final prevCount = prev?.notifiedNewRunsCount ?? 0;
      final newCount = next.notifiedNewRunsCount;
      if (newCount > prevCount) {
        _show(newCount - prevCount);
      }
    });

    final topPadding = MediaQuery.paddingOf(context).top;

    return Stack(
      children: [
        Positioned.fill(child: widget.child),
        Positioned(
          left: 16,
          right: 16,
          top: topPadding + 8,
          child: IgnorePointer(
            ignoring: !_visible,
            child: AnimatedSlide(
              offset: _visible ? Offset.zero : const Offset(0, -1.5),
              duration: _slideDuration,
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: _visible ? 1 : 0,
                duration: _slideDuration,
                child: _ToastBody(count: _activeBatchSize ?? 0),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ToastBody extends StatelessWidget {
  final int count;
  const _ToastBody({required this.count});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final label = count == 1
        ? 'Found 1 new run — analyzing…'
        : 'Found $count new runs — analyzing…';
    return Material(
      color: AppColors.primaryInk,
      borderRadius: BorderRadius.circular(14),
      elevation: 4,
      shadowColor: AppColors.primaryInk.withValues(alpha: 0.25),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            const _Spinner(),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 18,
      height: 18,
      child: CupertinoActivityIndicator(color: AppColors.gold, radius: 8),
    );
  }
}

