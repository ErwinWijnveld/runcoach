import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'plan_version_provider.g.dart';

/// Monotonic counter that broadcasts "the plan changed" across the app.
///
/// Plan-derived providers (schedule, current week, dashboard, goals,
/// training day detail/result) `ref.watch` this counter. Mutations that
/// affect plan data (reschedule, match/unlink activity, accept proposal,
/// goal activate/delete) call `bump()` after the API succeeds.
///
/// Bumping marks every watching provider stale; the next `watch` from
/// any screen triggers a fresh fetch — no per-callsite invalidate lists.
///
/// `keepAlive: true` so the counter survives tab/route changes; without
/// it the counter would reset to 0 the moment no widget is watching it,
/// re-flushing every dependent provider on the next read.
@Riverpod(keepAlive: true)
class PlanVersion extends _$PlanVersion {
  @override
  int build() => 0;

  void bump() => state = state + 1;
}
