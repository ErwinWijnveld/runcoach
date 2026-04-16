// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coach_stream_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(coachStreamClient)
final coachStreamClientProvider = CoachStreamClientProvider._();

final class CoachStreamClientProvider
    extends
        $FunctionalProvider<
          CoachStreamClient,
          CoachStreamClient,
          CoachStreamClient
        >
    with $Provider<CoachStreamClient> {
  CoachStreamClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coachStreamClientProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coachStreamClientHash();

  @$internal
  @override
  $ProviderElement<CoachStreamClient> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CoachStreamClient create(Ref ref) {
    return coachStreamClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CoachStreamClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CoachStreamClient>(value),
    );
  }
}

String _$coachStreamClientHash() => r'dc172c4ef83532b87796dfa6fac2e58103278b52';
