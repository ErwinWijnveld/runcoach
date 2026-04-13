// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'race_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(races)
final racesProvider = RacesProvider._();

final class RacesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Race>>,
          List<Race>,
          FutureOr<List<Race>>
        >
    with $FutureModifier<List<Race>>, $FutureProvider<List<Race>> {
  RacesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'racesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$racesHash();

  @$internal
  @override
  $FutureProviderElement<List<Race>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Race>> create(Ref ref) {
    return races(ref);
  }
}

String _$racesHash() => r'30be36a17cc47b98300c62e8417810c68479b384';

@ProviderFor(raceDetail)
final raceDetailProvider = RaceDetailFamily._();

final class RaceDetailProvider
    extends $FunctionalProvider<AsyncValue<Race>, Race, FutureOr<Race>>
    with $FutureModifier<Race>, $FutureProvider<Race> {
  RaceDetailProvider._({
    required RaceDetailFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'raceDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$raceDetailHash();

  @override
  String toString() {
    return r'raceDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Race> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Race> create(Ref ref) {
    final argument = this.argument as int;
    return raceDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RaceDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$raceDetailHash() => r'1614c4638cd097ceb1c6e8208e0c10e32c791825';

final class RaceDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Race>, int> {
  RaceDetailFamily._()
    : super(
        retry: null,
        name: r'raceDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RaceDetailProvider call(int id) =>
      RaceDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'raceDetailProvider';
}

@ProviderFor(RaceActions)
final raceActionsProvider = RaceActionsProvider._();

final class RaceActionsProvider
    extends $NotifierProvider<RaceActions, AsyncValue<void>> {
  RaceActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'raceActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$raceActionsHash();

  @$internal
  @override
  RaceActions create() => RaceActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$raceActionsHash() => r'5c7ad53d7deb14eba7d90ef7712f3f1532e2ddde';

abstract class _$RaceActions extends $Notifier<AsyncValue<void>> {
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
