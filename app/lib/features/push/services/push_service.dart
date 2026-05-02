import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/features/push/data/devices_api.dart';

part 'push_service.g.dart';

/// Bridges the native iOS APNs MethodChannel (see `ios/Runner/PushNotifications.swift`)
/// to Dart and to our backend.
///
/// Lifecycle:
///   1. App cold-start with auth hydrated → `registerIfPermitted()`. If iOS
///      permission was previously granted, we re-register and POST the token
///      to refresh `last_seen_at` server-side.
///   2. End of onboarding form submit → `requestPermissionAndRegister()`.
///      First (and only) time we ask for permission. Apple's rule: ask after
///      the user has experienced enough value to want the prompt.
///   3. Logout → `unregister()` deletes the row server-side so the next
///      signed-in user doesn't inherit the device.
class PushService {
  static const MethodChannel _channel = MethodChannel('nl.runcoach/push');

  final DevicesApi _api;
  void Function(Map<String, dynamic> payload)? onTap;

  String? _lastToken;
  Completer<String?>? _pendingTokenCompleter;

  PushService(this._api, {this.onTap}) {
    _channel.setMethodCallHandler(_onNativeCall);
  }

  /// Convert a push payload (`{type, conversation_id, …}`) to the path the
  /// router should navigate to. Returns null when the payload is unknown.
  static String? routeFromPayload(Map<String, dynamic> payload) {
    final type = payload['type'] as String?;
    return switch (type) {
      'plan_generation_completed' =>
        '/coach/chat/${payload['conversation_id'] as String? ?? ''}',
      'plan_generation_failed' => '/onboarding/generating',
      'training_day_reminder' =>
        '/schedule/day/${payload['training_day_id']?.toString() ?? ''}',
      // Analyzed run with a matched training day → go straight to the
      // result. Without a day id (unmatched runs aren't surfaced via push
      // today, but be defensive) → land on the dashboard.
      'workout_analyzed' => () {
          final dayId = payload['training_day_id']?.toString();
          if (dayId == null || dayId.isEmpty) return '/dashboard';
          return '/schedule/day/$dayId/result';
        }(),
      _ => null,
    };
  }

  bool get _supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Asks iOS for notification permission, registers for remote notifications
  /// on grant, and resolves to the APNs token (or null on denial / failure).
  Future<String?> requestPermissionAndRegister({String? appVersion}) async {
    if (!_supported) return null;
    final granted = await _channel.invokeMethod<bool>('requestPermission') ?? false;
    if (!granted) return null;
    return _awaitTokenAndRegister(appVersion: appVersion);
  }

  /// Cold-start re-register. Calls `requestAuthorization` under the hood —
  /// iOS makes that idempotent: it only shows the system prompt when the
  /// auth status is `notDetermined`, otherwise it returns the cached
  /// answer silently. So this transparently handles three cases:
  ///   - Already granted in a prior session → registers, refreshes
  ///     `last_seen_at` server-side. No prompt.
  ///   - Already denied → returns null silently. No prompt.
  ///   - Never asked (e.g. user onboarded BEFORE push shipped, or fresh
  ///     install where onboarding's explicit prompt hasn't fired yet) →
  ///     shows the prompt.
  Future<String?> registerIfPermitted({String? appVersion}) async {
    if (!_supported) return null;
    return requestPermissionAndRegister(appVersion: appVersion);
  }

  /// Drop the device's row on the server, called from logout.
  Future<void> unregister() async {
    final token = _lastToken;
    if (token == null) return;
    try {
      await _api.unregister({'token': token});
    } catch (_) {
      // best-effort; the listener will prune on the next failed push anyway.
    }
    _lastToken = null;
  }

  /// If the app was cold-launched from a tap, drain that payload now so the
  /// router can deep-link to the right screen.
  Future<Map<String, dynamic>?> consumeInitialPayload() async {
    if (!_supported) return null;
    final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>('getInitialPayload');
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw);
  }

  Future<String?> _awaitTokenAndRegister({
    String? appVersion,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (_lastToken != null) {
      await _registerWithBackend(_lastToken!, appVersion);
      return _lastToken;
    }
    _pendingTokenCompleter ??= Completer<String?>();
    final completer = _pendingTokenCompleter!;
    final token = await completer.future.timeout(timeout, onTimeout: () => null);
    _pendingTokenCompleter = null;
    if (token != null) {
      await _registerWithBackend(token, appVersion);
    }
    return token;
  }

  Future<void> _registerWithBackend(String token, String? appVersion) async {
    try {
      await _api.register({
        'token': token,
        'platform': 'ios',
        'app_version': ?appVersion,
      });
    } catch (_) {
      // Non-fatal; we'll re-attempt on the next cold start.
    }
  }

  Future<dynamic> _onNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'onToken':
        final args = (call.arguments as Map?)?.cast<String, dynamic>();
        final token = args?['token'] as String?;
        if (token != null) {
          _lastToken = token;
          if (_pendingTokenCompleter != null && !_pendingTokenCompleter!.isCompleted) {
            _pendingTokenCompleter!.complete(token);
          }
        }
        return null;
      case 'onTokenError':
        if (_pendingTokenCompleter != null && !_pendingTokenCompleter!.isCompleted) {
          _pendingTokenCompleter!.complete(null);
        }
        return null;
      case 'onPushTapped':
        final args = (call.arguments as Map?)?.cast<String, dynamic>();
        final payload = (args?['payload'] as Map?)?.cast<String, dynamic>();
        if (payload != null) {
          onTap?.call(payload);
        }
        return null;
    }
    return null;
  }
}

@Riverpod(keepAlive: true)
PushService pushService(Ref ref) {
  return PushService(ref.watch(devicesApiProvider));
}
