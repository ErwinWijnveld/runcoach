// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(goals)
final goalsProvider = GoalsProvider._();

final class GoalsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Goal>>,
          List<Goal>,
          FutureOr<List<Goal>>
        >
    with $FutureModifier<List<Goal>>, $FutureProvider<List<Goal>> {
  GoalsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'goalsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$goalsHash();

  @$internal
  @override
  $FutureProviderElement<List<Goal>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Goal>> create(Ref ref) {
    return goals(ref);
  }
}

String _$goalsHash() => r'e1bfabdc3a96a9b9147fe4cdd193219fc39d17a3';

@ProviderFor(goalDetail)
final goalDetailProvider = GoalDetailFamily._();

final class GoalDetailProvider
    extends $FunctionalProvider<AsyncValue<Goal>, Goal, FutureOr<Goal>>
    with $FutureModifier<Goal>, $FutureProvider<Goal> {
  GoalDetailProvider._({
    required GoalDetailFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'goalDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$goalDetailHash();

  @override
  String toString() {
    return r'goalDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Goal> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Goal> create(Ref ref) {
    final argument = this.argument as int;
    return goalDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GoalDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$goalDetailHash() => r'0adb6ae582fa752a097262e4d6fa41fb8e02e1ba';

final class GoalDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Goal>, int> {
  GoalDetailFamily._()
    : super(
        retry: null,
        name: r'goalDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GoalDetailProvider call(int id) =>
      GoalDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'goalDetailProvider';
}

@ProviderFor(GoalActions)
final goalActionsProvider = GoalActionsProvider._();

final class GoalActionsProvider
    extends $NotifierProvider<GoalActions, AsyncValue<void>> {
  GoalActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'goalActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$goalActionsHash();

  @$internal
  @override
  GoalActions create() => GoalActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$goalActionsHash() => r'aacef173458d53cfb150228e6e8f7ea5d4b0c40b';

abstract class _$GoalActions extends $Notifier<AsyncValue<void>> {
  AsyncValue<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
