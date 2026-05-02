// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_scheduler_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workoutSchedulerService)
final workoutSchedulerServiceProvider = WorkoutSchedulerServiceProvider._();

final class WorkoutSchedulerServiceProvider
    extends
        $FunctionalProvider<
          WorkoutSchedulerService,
          WorkoutSchedulerService,
          WorkoutSchedulerService
        >
    with $Provider<WorkoutSchedulerService> {
  WorkoutSchedulerServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workoutSchedulerServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workoutSchedulerServiceHash();

  @$internal
  @override
  $ProviderElement<WorkoutSchedulerService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WorkoutSchedulerService create(Ref ref) {
    return workoutSchedulerService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkoutSchedulerService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkoutSchedulerService>(value),
    );
  }
}

String _$workoutSchedulerServiceHash() =>
    r'24b3f34ec34e2a3ea1e60d6d49756545ab91141c';
