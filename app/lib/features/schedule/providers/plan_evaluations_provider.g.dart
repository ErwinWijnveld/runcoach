// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_evaluations_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// All `PlanEvaluation`s attached to the runner's currently active goal.
/// The schedule UI interleaves these as cards inside the week grid.

@ProviderFor(PlanEvaluations)
final planEvaluationsProvider = PlanEvaluationsProvider._();

/// All `PlanEvaluation`s attached to the runner's currently active goal.
/// The schedule UI interleaves these as cards inside the week grid.
final class PlanEvaluationsProvider
    extends $AsyncNotifierProvider<PlanEvaluations, List<PlanEvaluation>> {
  /// All `PlanEvaluation`s attached to the runner's currently active goal.
  /// The schedule UI interleaves these as cards inside the week grid.
  PlanEvaluationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planEvaluationsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planEvaluationsHash();

  @$internal
  @override
  PlanEvaluations create() => PlanEvaluations();
}

String _$planEvaluationsHash() => r'eaeaad6782220833b8bdb80dfe103372a91edf0b';

/// All `PlanEvaluation`s attached to the runner's currently active goal.
/// The schedule UI interleaves these as cards inside the week grid.

abstract class _$PlanEvaluations extends $AsyncNotifier<List<PlanEvaluation>> {
  FutureOr<List<PlanEvaluation>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<PlanEvaluation>>, List<PlanEvaluation>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<PlanEvaluation>>,
                List<PlanEvaluation>
              >,
              AsyncValue<List<PlanEvaluation>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Single-evaluation lookup for the detail screen. `keepAlive: true` so a
/// brief detail-screen pop + re-push doesn't refetch and re-flash the
/// loading state. The accept/dismiss flow explicitly invalidates this
/// provider when it needs to refresh.

@ProviderFor(planEvaluation)
final planEvaluationProvider = PlanEvaluationFamily._();

/// Single-evaluation lookup for the detail screen. `keepAlive: true` so a
/// brief detail-screen pop + re-push doesn't refetch and re-flash the
/// loading state. The accept/dismiss flow explicitly invalidates this
/// provider when it needs to refresh.

final class PlanEvaluationProvider
    extends
        $FunctionalProvider<
          AsyncValue<PlanEvaluation?>,
          PlanEvaluation?,
          FutureOr<PlanEvaluation?>
        >
    with $FutureModifier<PlanEvaluation?>, $FutureProvider<PlanEvaluation?> {
  /// Single-evaluation lookup for the detail screen. `keepAlive: true` so a
  /// brief detail-screen pop + re-push doesn't refetch and re-flash the
  /// loading state. The accept/dismiss flow explicitly invalidates this
  /// provider when it needs to refresh.
  PlanEvaluationProvider._({
    required PlanEvaluationFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'planEvaluationProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$planEvaluationHash();

  @override
  String toString() {
    return r'planEvaluationProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PlanEvaluation?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PlanEvaluation?> create(Ref ref) {
    final argument = this.argument as int;
    return planEvaluation(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PlanEvaluationProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$planEvaluationHash() => r'7ea04794759a37a3aafab8076449bb35a77d110e';

/// Single-evaluation lookup for the detail screen. `keepAlive: true` so a
/// brief detail-screen pop + re-push doesn't refetch and re-flash the
/// loading state. The accept/dismiss flow explicitly invalidates this
/// provider when it needs to refresh.

final class PlanEvaluationFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PlanEvaluation?>, int> {
  PlanEvaluationFamily._()
    : super(
        retry: null,
        name: r'planEvaluationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Single-evaluation lookup for the detail screen. `keepAlive: true` so a
  /// brief detail-screen pop + re-push doesn't refetch and re-flash the
  /// loading state. The accept/dismiss flow explicitly invalidates this
  /// provider when it needs to refresh.

  PlanEvaluationProvider call(int id) =>
      PlanEvaluationProvider._(argument: id, from: this);

  @override
  String toString() => r'planEvaluationProvider';
}
