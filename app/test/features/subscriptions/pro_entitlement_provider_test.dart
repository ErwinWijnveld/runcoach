import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/subscriptions/data/subscriptions_api.dart';
import 'package:app/features/subscriptions/models/sync_response.dart';
import 'package:app/features/subscriptions/providers/pro_entitlement_provider.dart';

/// Fake API that lets each test choose the response shape. Used in lieu of
/// hitting the real Dio client.
class _FakeSubscriptionsApi implements SubscriptionsApi {
  SyncResponse Function()? _next;
  Future<SyncResponse> Function()? _nextAsync;

  void willReturn(SyncResponse response) {
    _next = () => response;
    _nextAsync = null;
  }

  void willThrow(Object e) {
    _next = null;
    _nextAsync = () => Future.error(e);
  }

  @override
  Future<SyncResponse> sync(Map<String, dynamic> body) {
    final asyncOverride = _nextAsync;
    if (asyncOverride != null) return asyncOverride();
    final synchronous = _next;
    if (synchronous != null) return Future.value(synchronous());
    throw StateError('no response configured');
  }

  @override
  Future<SyncResponse> devActivate() =>
      Future.value(const SyncResponse(isPro: true, productId: 'runcoach_pro_yearly'));

  @override
  Future<SyncResponse> devDeactivate() =>
      Future.value(const SyncResponse(isPro: false));
}

void main() {
  test('initial state is not-pro, not-loading', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = container.read(proEntitlementProvider);
    expect(state.isPro, isFalse);
    expect(state.activeUntil, isNull);
    expect(state.productId, isNull);
    expect(state.loading, isFalse);
  });

  test('successful sync populates pro state', () async {
    final api = _FakeSubscriptionsApi()
      ..willReturn(SyncResponse(
        activeUntil: DateTime.utc(2026, 12, 1),
        productId: 'runcoach_pro_yearly',
        isPro: true,
      ));

    final container = ProviderContainer(overrides: [
      subscriptionsApiProvider.overrideWithValue(api),
    ]);
    addTearDown(container.dispose);

    await container
        .read(proEntitlementProvider.notifier)
        .syncFromServer();

    final state = container.read(proEntitlementProvider);
    expect(state.isPro, isTrue);
    expect(state.productId, 'runcoach_pro_yearly');
    expect(state.activeUntil, DateTime.utc(2026, 12, 1));
    expect(state.loading, isFalse);
  });

  test('failed sync leaves state unchanged + clears loading flag', () async {
    final api = _FakeSubscriptionsApi()..willThrow(StateError('boom'));

    final container = ProviderContainer(overrides: [
      subscriptionsApiProvider.overrideWithValue(api),
    ]);
    addTearDown(container.dispose);

    await container
        .read(proEntitlementProvider.notifier)
        .syncFromServer();

    final state = container.read(proEntitlementProvider);
    expect(state.isPro, isFalse);
    expect(state.activeUntil, isNull);
    expect(state.loading, isFalse);
  });

  test('reset clears state back to defaults', () async {
    final api = _FakeSubscriptionsApi()
      ..willReturn(SyncResponse(
        activeUntil: DateTime.utc(2026, 12, 1),
        productId: 'runcoach_pro_yearly',
        isPro: true,
      ));

    final container = ProviderContainer(overrides: [
      subscriptionsApiProvider.overrideWithValue(api),
    ]);
    addTearDown(container.dispose);

    await container
        .read(proEntitlementProvider.notifier)
        .syncFromServer();
    expect(container.read(proEntitlementProvider).isPro, isTrue);

    container.read(proEntitlementProvider.notifier).reset();
    final state = container.read(proEntitlementProvider);
    expect(state.isPro, isFalse);
    expect(state.activeUntil, isNull);
    expect(state.productId, isNull);
  });

  test('sync response decodes from JSON with snake_case keys', () {
    final json = {
      'active_until': '2026-12-01T00:00:00Z',
      'product_id': 'runcoach_pro_yearly',
      'is_pro': true,
    };
    final parsed = SyncResponse.fromJson(json);
    expect(parsed.isPro, isTrue);
    expect(parsed.productId, 'runcoach_pro_yearly');
    expect(parsed.activeUntil, DateTime.utc(2026, 12, 1));
  });
}
