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

String _$workoutSyncHash() => r'79ca653daec61116467b1810cc8bc2a2bb1c539f';

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
