// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_sync_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WorkoutSync)
final workoutSyncProvider = WorkoutSyncProvider._();

final class WorkoutSyncProvider
    extends $NotifierProvider<WorkoutSync, WorkoutSyncState> {
  WorkoutSyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workoutSyncProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workoutSyncHash();

  @$internal
  @override
  WorkoutSync create() => WorkoutSync();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkoutSyncState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkoutSyncState>(value),
    );
  }
}

String _$workoutSyncHash() => r'd1bd4ea0b131e06164cbab66693e0200201986f7';

abstract class _$WorkoutSync extends $Notifier<WorkoutSyncState> {
  WorkoutSyncState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<WorkoutSyncState, WorkoutSyncState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<WorkoutSyncState, WorkoutSyncState>,
              WorkoutSyncState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
