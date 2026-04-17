// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_explanation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(planExplanation)
final planExplanationProvider = PlanExplanationFamily._();

final class PlanExplanationProvider
    extends
        $FunctionalProvider<
          AsyncValue<PlanExplanation>,
          PlanExplanation,
          FutureOr<PlanExplanation>
        >
    with $FutureModifier<PlanExplanation>, $FutureProvider<PlanExplanation> {
  PlanExplanationProvider._({
    required PlanExplanationFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'planExplanationProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$planExplanationHash();

  @override
  String toString() {
    return r'planExplanationProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PlanExplanation> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PlanExplanation> create(Ref ref) {
    final argument = this.argument as int;
    return planExplanation(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PlanExplanationProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$planExplanationHash() => r'd9892b597adc9c5b964b1f155468acb815487846';

final class PlanExplanationFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PlanExplanation>, int> {
  PlanExplanationFamily._()
    : super(
        retry: null,
        name: r'planExplanationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PlanExplanationProvider call(int proposalId) =>
      PlanExplanationProvider._(argument: proposalId, from: this);

  @override
  String toString() => r'planExplanationProvider';
}
