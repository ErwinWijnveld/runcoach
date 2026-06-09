import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'background_sync_service.g.dart';

/// Bridges the native iOS HealthKit background-delivery sync
/// (`ios/Runner/HealthKitBackgroundSync.swift`) to Dart.
///
/// The native side owns the `HKObserverQuery` + the `POST /wearable/activities`
/// (the Dart engine isn't running on a background launch). Dart's only job
/// is to hand it the two things it can't see itself: the API base URL and
/// the Sanctum bearer. Call [configure] on login + cold-start, [clear] on
/// logout. iOS-only; a no-op everywhere else.
class BackgroundSyncService {
  static const MethodChannel _channel = MethodChannel('nl.runcoach/bg-sync');

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Store the credentials natively and (re)arm the workout observer.
  Future<void> configure({
    required String baseUrl,
    required String token,
  }) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod('configure', {
        'baseUrl': baseUrl,
        'token': token,
      });
    } catch (_) {
      // Best-effort; the foreground sync remains the guaranteed path.
    }
  }

  /// Wipe the stored token and stop background delivery (logout).
  Future<void> clear() async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod('clear');
    } catch (_) {}
  }
}

@Riverpod(keepAlive: true)
BackgroundSyncService backgroundSyncService(Ref ref) => BackgroundSyncService();
