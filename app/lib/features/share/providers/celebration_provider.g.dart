// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'celebration_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Celebration)
final celebrationProvider = CelebrationProvider._();

final class CelebrationProvider
    extends $AsyncNotifierProvider<Celebration, TrainingResult?> {
  CelebrationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'celebrationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$celebrationHash();

  @$internal
  @override
  Celebration create() => Celebration();
}

String _$celebrationHash() => r'cd823588242644333a18e848ffcf26075a11f037';

abstract class _$Celebration extends $AsyncNotifier<TrainingResult?> {
  FutureOr<TrainingResult?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<TrainingResult?>, TrainingResult?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TrainingResult?>, TrainingResult?>,
              AsyncValue<TrainingResult?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
