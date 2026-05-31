import 'dart:async';

import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app/features/auth/models/user.dart';

part 'purchases_service.g.dart';

/// Thin wrapper around the RevenueCat `purchases_flutter` SDK so the rest of
/// the app doesn't depend on the SDK directly. Single instance per app
/// lifetime — `configure()` is idempotent.
///
/// The RevenueCat public iOS SDK key is read from `--dart-define` at build
/// time so it ships with the binary. If the key is empty (dev runs without
/// the env var set), the service silently no-ops — paywall calls will fail
/// closed, but unrelated screens keep working.
class PurchasesService {
  static const String _publicSdkKey = String.fromEnvironment(
    'REVENUECAT_PUBLIC_SDK_KEY',
    defaultValue: '',
  );

  static bool _configured = false;

  /// True when the bundled SDK key is non-empty. Tests + dev builds without
  /// the key set should branch on this to avoid invoking the SDK.
  static bool get isAvailable => _publicSdkKey.isNotEmpty;

  /// Initialize the RevenueCat SDK with the runner's id as `appUserID` so
  /// purchases attribute to the right server-side user. Idempotent — safe to
  /// call again on auth-state changes.
  Future<void> configure(User user) async {
    if (!isAvailable) return;

    if (_configured) {
      // Identity may have changed (re-login as a different user). RC's logIn
      // returns a "did purchase" flag we don't need here; we just rebind.
      await Purchases.logIn(user.id.toString());
      return;
    }

    await Purchases.setLogLevel(LogLevel.warn);
    final config = PurchasesConfiguration(_publicSdkKey)
      ..appUserID = user.id.toString();
    await Purchases.configure(config);
    _configured = true;
  }

  /// Force a fresh `CustomerInfo` read from RC's backend. Returns null if the
  /// SDK isn't configured (no key in dev).
  Future<CustomerInfo?> getCustomerInfo({bool forceRefresh = false}) async {
    if (!_configured) return null;
    if (forceRefresh) {
      await Purchases.invalidateCustomerInfoCache();
    }
    return Purchases.getCustomerInfo();
  }

  /// Open the iOS "Manage subscription" deep link (Settings → user's active
  /// subs). Apple owns this UI; we just open the URL RC computed for us.
  /// Returns true when a URL was opened, false otherwise.
  Future<bool> openManageSubscriptions() async {
    if (!_configured) return false;
    final info = await Purchases.getCustomerInfo();
    final url = info.managementURL;
    if (url == null) return false;
    return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  /// Trigger `Purchases.restorePurchases()`. Returns the resulting
  /// `CustomerInfo` so the caller can re-sync the server.
  Future<CustomerInfo?> restorePurchases() async {
    if (!_configured) return null;
    return Purchases.restorePurchases();
  }
}

@Riverpod(keepAlive: true)
PurchasesService purchasesService(Ref ref) => PurchasesService();
