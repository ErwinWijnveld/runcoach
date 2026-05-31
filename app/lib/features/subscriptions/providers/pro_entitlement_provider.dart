import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/features/subscriptions/data/subscriptions_api.dart';
import 'package:app/features/subscriptions/models/sync_response.dart';
import 'package:app/features/subscriptions/services/purchases_service.dart';

part 'pro_entitlement_provider.g.dart';

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
@Riverpod(keepAlive: true)
class ProEntitlement extends _$ProEntitlement {
  @override
  ProEntitlementState build() => const ProEntitlementState();

  /// Reconcile entitlement state with the server.
  ///
  /// [fromPurchase] controls whether we send the client's RevenueCat claim.
  /// Only true right after a real purchase/restore: the server consults the
  /// claim ONLY in local dev (Test Store, where RC REST can't verify) and
  /// ignores it in production. On routine cold-start we send no claim so a
  /// lingering Test Store entitlement can't silently re-grant pro — local
  /// state is then driven purely by the server (and the dev buttons).
  Future<void> syncFromServer({bool fromPurchase = false}) async {
    state = state.copyWith(loading: true);
    try {
      final api = ref.read(subscriptionsApiProvider);
      final body =
          fromPurchase ? await _buildClientClaimBody() : const <String, dynamic>{};
      final response = await api.sync(body);
      _applyResponse(response);
    } catch (e) {
      debugPrint('[pro] sync failed: $e');
      state = state.copyWith(loading: false);
    }
  }

  /// LOCAL-DEV ONLY. Simulate a successful purchase (debug "Simulate payment"
  /// button). Grants the entitlement server-side so the post-paywall app is
  /// usable. The endpoint 404s outside local env.
  Future<void> devActivate() async {
    state = state.copyWith(loading: true);
    try {
      final api = ref.read(subscriptionsApiProvider);
      _applyResponse(await api.devActivate());
    } catch (e) {
      debugPrint('[pro] dev activate failed: $e');
      state = state.copyWith(loading: false);
    }
  }

  /// LOCAL-DEV ONLY. Reset entitlement to free (debug "Reset subscription"
  /// button) so the paywall shows again. The endpoint 404s outside local env.
  Future<void> devDeactivate() async {
    state = state.copyWith(loading: true);
    try {
      final api = ref.read(subscriptionsApiProvider);
      _applyResponse(await api.devDeactivate());
    } catch (e) {
      debugPrint('[pro] dev deactivate failed: $e');
      state = state.copyWith(loading: false);
    }
  }

  void _applyResponse(SyncResponse response) {
    state = ProEntitlementState(
      activeUntil: response.activeUntil,
      productId: response.productId,
      isPro: response.isPro,
      loading: false,
    );
  }

  /// Read the SDK's `CustomerInfo` and shape the active entitlement (if any)
  /// into the `client_entitlement` claim the sync endpoint accepts. Returns
  /// an empty map when the SDK isn't configured or there's no active
  /// entitlement.
  Future<Map<String, dynamic>> _buildClientClaimBody() async {
    try {
      final purchases = ref.read(purchasesServiceProvider);
      final info = await purchases.getCustomerInfo();
      if (info == null) return const {};
      final active = info.entitlements.active;
      final entitlement =
          active['pro'] ?? (active.values.isNotEmpty ? active.values.first : null);
      if (entitlement == null || !entitlement.isActive) return const {};
      return {
        'client_entitlement': {
          'active': true,
          'product_id': entitlement.productIdentifier,
          'expires_at': entitlement.expirationDate,
        },
      };
    } catch (e) {
      debugPrint('[pro] could not build client claim: $e');
      return const {};
    }
  }

  /// Resolve pro-state directly from the RevenueCat SDK's `CustomerInfo`
  /// (client-side), bypassing our backend. Used as a post-purchase fallback so
  /// the UI advances even when the server can't verify the entitlement — e.g.
  /// local dev against RevenueCat's Test Store, where there's no working REST
  /// API or webhook for the backend to consult.
  ///
  /// This only drives NAVIGATION/UX. The real feature gate (coach chat, plan
  /// generation) is still enforced server-side by the `require.pro`
  /// middleware, so a client that lied here would just hit a 402 on the next
  /// API call. In production with a real key the server sync resolves first
  /// and this is never reached.
  Future<void> refreshFromClient() async {
    try {
      final purchases = ref.read(purchasesServiceProvider);
      final info = await purchases.getCustomerInfo(forceRefresh: true);
      if (info == null) return;

      // Prefer the canonical `pro` entitlement, but treat ANY active
      // entitlement as pro — in Test Store the entitlement may be named
      // differently and we only have one tier.
      final active = info.entitlements.active;
      final entitlement =
          active['pro'] ?? (active.values.isNotEmpty ? active.values.first : null);
      if (entitlement == null || !entitlement.isActive) return;

      state = ProEntitlementState(
        activeUntil: entitlement.expirationDate != null
            ? DateTime.tryParse(entitlement.expirationDate!)
            : null,
        productId: entitlement.productIdentifier,
        isPro: true,
        loading: false,
      );
    } catch (e) {
      debugPrint('[pro] client refresh failed: $e');
    }
  }

  /// Used by tests + the boot flow when we want to clear state on logout.
  void reset() {
    state = const ProEntitlementState();
  }
}

@immutable
class ProEntitlementState {
  final DateTime? activeUntil;
  final String? productId;
  final bool isPro;
  final bool loading;

  const ProEntitlementState({
    this.activeUntil,
    this.productId,
    this.isPro = false,
    this.loading = false,
  });

  ProEntitlementState copyWith({
    DateTime? activeUntil,
    String? productId,
    bool? isPro,
    bool? loading,
  }) {
    return ProEntitlementState(
      activeUntil: activeUntil ?? this.activeUntil,
      productId: productId ?? this.productId,
      isPro: isPro ?? this.isPro,
      loading: loading ?? this.loading,
    );
  }

  /// Used by the router to gate post-onboarding routes — `true` when the
  /// runner has bought (or been comped) Pro access.
  bool get hasActiveEntitlement => isPro;
}
