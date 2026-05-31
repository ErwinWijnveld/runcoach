// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_route_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workoutRouteService)
final workoutRouteServiceProvider = WorkoutRouteServiceProvider._();

final class WorkoutRouteServiceProvider
    extends
        $FunctionalProvider<
          WorkoutRouteService,
          WorkoutRouteService,
          WorkoutRouteService
        >
    with $Provider<WorkoutRouteService> {
  WorkoutRouteServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workoutRouteServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workoutRouteServiceHash();

  @$internal
  @override
  $ProviderElement<WorkoutRouteService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WorkoutRouteService create(Ref ref) {
    return workoutRouteService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkoutRouteService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkoutRouteService>(value),
    );
  }
}

String _$workoutRouteServiceHash() =>
    r'6e91d89cc0843a0d2fd6ed35d89aeb994b08f8bf';
