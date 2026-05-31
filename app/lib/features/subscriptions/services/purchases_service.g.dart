// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchases_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(purchasesService)
final purchasesServiceProvider = PurchasesServiceProvider._();

final class PurchasesServiceProvider
    extends
        $FunctionalProvider<
          PurchasesService,
          PurchasesService,
          PurchasesService
        >
    with $Provider<PurchasesService> {
  PurchasesServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'purchasesServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$purchasesServiceHash();

  @$internal
  @override
  $ProviderElement<PurchasesService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PurchasesService create(Ref ref) {
    return purchasesService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PurchasesService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PurchasesService>(value),
    );
  }
}

String _$purchasesServiceHash() => r'34e6922d4c69bd394292e7808a960668d33c1ea8';
