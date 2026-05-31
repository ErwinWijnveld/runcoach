// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_sync_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Single source of truth for "which TrainingDays should be on the watch
/// right now". Used by:
///   - Proposal accept → [syncUpcoming] (first push of next 7 days)
///   - Reschedule + notification accept → [syncUpcoming] (resync the slice)
///   - App foreground → [syncDeltas] (only re-ship days the coach edited
///     server-side since the last successful sync)
///
/// Per-dayId `lastSyncedAt` timestamps persist in shared_preferences so
/// foreground delta-detection survives cold starts. The native bridge is
/// idempotent under the deterministic UUID (any prior plan for the same
/// dayId is removed and replaced), so over-firing is safe — under-firing
/// would leave the watch stale.
///
/// All public methods are no-ops on non-iOS / web / iOS < 17.4 (the native
/// bridge returns `unavailable`). The manual per-day Send-to-watch button
/// remains the only fallback for those environments.

@ProviderFor(WatchSync)
final watchSyncProvider = WatchSyncProvider._();

/// Single source of truth for "which TrainingDays should be on the watch
/// right now". Used by:
///   - Proposal accept → [syncUpcoming] (first push of next 7 days)
///   - Reschedule + notification accept → [syncUpcoming] (resync the slice)
///   - App foreground → [syncDeltas] (only re-ship days the coach edited
///     server-side since the last successful sync)
///
/// Per-dayId `lastSyncedAt` timestamps persist in shared_preferences so
/// foreground delta-detection survives cold starts. The native bridge is
/// idempotent under the deterministic UUID (any prior plan for the same
/// dayId is removed and replaced), so over-firing is safe — under-firing
/// would leave the watch stale.
///
/// All public methods are no-ops on non-iOS / web / iOS < 17.4 (the native
/// bridge returns `unavailable`). The manual per-day Send-to-watch button
/// remains the only fallback for those environments.
final class WatchSyncProvider extends $NotifierProvider<WatchSync, void> {
  /// Single source of truth for "which TrainingDays should be on the watch
  /// right now". Used by:
  ///   - Proposal accept → [syncUpcoming] (first push of next 7 days)
  ///   - Reschedule + notification accept → [syncUpcoming] (resync the slice)
  ///   - App foreground → [syncDeltas] (only re-ship days the coach edited
  ///     server-side since the last successful sync)
  ///
  /// Per-dayId `lastSyncedAt` timestamps persist in shared_preferences so
  /// foreground delta-detection survives cold starts. The native bridge is
  /// idempotent under the deterministic UUID (any prior plan for the same
  /// dayId is removed and replaced), so over-firing is safe — under-firing
  /// would leave the watch stale.
  ///
  /// All public methods are no-ops on non-iOS / web / iOS < 17.4 (the native
  /// bridge returns `unavailable`). The manual per-day Send-to-watch button
  /// remains the only fallback for those environments.
  WatchSyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchSyncProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchSyncHash();

  @$internal
  @override
  WatchSync create() => WatchSync();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$watchSyncHash() => r'b21683268b6e8e838f62f5a4f13503c70ac1377f';

/// Single source of truth for "which TrainingDays should be on the watch
/// right now". Used by:
///   - Proposal accept → [syncUpcoming] (first push of next 7 days)
///   - Reschedule + notification accept → [syncUpcoming] (resync the slice)
///   - App foreground → [syncDeltas] (only re-ship days the coach edited
///     server-side since the last successful sync)
///
/// Per-dayId `lastSyncedAt` timestamps persist in shared_preferences so
/// foreground delta-detection survives cold starts. The native bridge is
/// idempotent under the deterministic UUID (any prior plan for the same
/// dayId is removed and replaced), so over-firing is safe — under-firing
/// would leave the watch stale.
///
/// All public methods are no-ops on non-iOS / web / iOS < 17.4 (the native
/// bridge returns `unavailable`). The manual per-day Send-to-watch button
/// remains the only fallback for those environments.

abstract class _$WatchSync extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
