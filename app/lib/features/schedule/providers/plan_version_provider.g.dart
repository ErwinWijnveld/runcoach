// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_version_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(PlanVersion)
final planVersionProvider = PlanVersionProvider._();

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
final class PlanVersionProvider extends $NotifierProvider<PlanVersion, int> {
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
  PlanVersionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planVersionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planVersionHash();

  @$internal
  @override
  PlanVersion create() => PlanVersion();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$planVersionHash() => r'310d3aa7f5bce0a2055e6dfc5916d8a27c2ee4a2';

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

abstract class _$PlanVersion extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
