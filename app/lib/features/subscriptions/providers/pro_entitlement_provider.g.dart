// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pro_entitlement_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide entitlement state. The Flutter side mirrors the server's
/// `users.pro_active_until` — the server is always the source of truth, but
/// we surface the resolved state here so widgets can read `isPro` without
/// making an HTTP call.
///
/// State machine:
///   - `null` initial → empty (treated as not-pro until sync resolves).
///   - `syncFromServer()` POSTs to `/subscriptions/sync` (empty body), which
///     pulls truth from RevenueCat REST. Updates state with the result.
///
/// Wiring:
///   - `app.dart` cold-start fires `syncFromServer()` once after auth resolves
///     so the router has the right state before deciding redirects.
///   - The paywall flow fires it again after every purchase / restore.

@ProviderFor(ProEntitlement)
final proEntitlementProvider = ProEntitlementProvider._();

/// App-wide entitlement state. The Flutter side mirrors the server's
/// `users.pro_active_until` — the server is always the source of truth, but
/// we surface the resolved state here so widgets can read `isPro` without
/// making an HTTP call.
///
/// State machine:
///   - `null` initial → empty (treated as not-pro until sync resolves).
///   - `syncFromServer()` POSTs to `/subscriptions/sync` (empty body), which
///     pulls truth from RevenueCat REST. Updates state with the result.
///
/// Wiring:
///   - `app.dart` cold-start fires `syncFromServer()` once after auth resolves
///     so the router has the right state before deciding redirects.
///   - The paywall flow fires it again after every purchase / restore.
final class ProEntitlementProvider
    extends $NotifierProvider<ProEntitlement, ProEntitlementState> {
  /// App-wide entitlement state. The Flutter side mirrors the server's
  /// `users.pro_active_until` — the server is always the source of truth, but
  /// we surface the resolved state here so widgets can read `isPro` without
  /// making an HTTP call.
  ///
  /// State machine:
  ///   - `null` initial → empty (treated as not-pro until sync resolves).
  ///   - `syncFromServer()` POSTs to `/subscriptions/sync` (empty body), which
  ///     pulls truth from RevenueCat REST. Updates state with the result.
  ///
  /// Wiring:
  ///   - `app.dart` cold-start fires `syncFromServer()` once after auth resolves
  ///     so the router has the right state before deciding redirects.
  ///   - The paywall flow fires it again after every purchase / restore.
  ProEntitlementProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'proEntitlementProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$proEntitlementHash();

  @$internal
  @override
  ProEntitlement create() => ProEntitlement();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProEntitlementState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProEntitlementState>(value),
    );
  }
}

String _$proEntitlementHash() => r'a07f8bfbcf26ad4360e3a0edb270013b6c2a18eb';

/// App-wide entitlement state. The Flutter side mirrors the server's
/// `users.pro_active_until` — the server is always the source of truth, but
/// we surface the resolved state here so widgets can read `isPro` without
/// making an HTTP call.
///
/// State machine:
///   - `null` initial → empty (treated as not-pro until sync resolves).
///   - `syncFromServer()` POSTs to `/subscriptions/sync` (empty body), which
///     pulls truth from RevenueCat REST. Updates state with the result.
///
/// Wiring:
///   - `app.dart` cold-start fires `syncFromServer()` once after auth resolves
///     so the router has the right state before deciding redirects.
///   - The paywall flow fires it again after every purchase / restore.

abstract class _$ProEntitlement extends $Notifier<ProEntitlementState> {
  ProEntitlementState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ProEntitlementState, ProEntitlementState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProEntitlementState, ProEntitlementState>,
              ProEntitlementState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
