// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'background_sync_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(backgroundSyncService)
final backgroundSyncServiceProvider = BackgroundSyncServiceProvider._();

final class BackgroundSyncServiceProvider
    extends
        $FunctionalProvider<
          BackgroundSyncService,
          BackgroundSyncService,
          BackgroundSyncService
        >
    with $Provider<BackgroundSyncService> {
  BackgroundSyncServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backgroundSyncServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backgroundSyncServiceHash();

  @$internal
  @override
  $ProviderElement<BackgroundSyncService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BackgroundSyncService create(Ref ref) {
    return backgroundSyncService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackgroundSyncService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackgroundSyncService>(value),
    );
  }
}

String _$backgroundSyncServiceHash() =>
    r'392de08ab627ed59ee694f776583fe37c379be15';
