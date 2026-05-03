import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/features/push/services/push_service.dart';
import 'package:app/features/wearable/data/wearable_api.dart';

part 'permissions_service.g.dart';

/// Re-asks for the three permissions RunCoach needs (HealthKit workouts +
/// heart-rate, push notifications) on every foreground.
///
/// Both underlying iOS calls (`HKHealthStore.requestAuthorization` and
/// `UNUserNotificationCenter.requestAuthorization`) are idempotent: the
/// system prompt is shown ONLY when the user hasn't decided yet
/// (`notDetermined`). Already-granted or already-denied returns the
/// cached answer silently. So this is safe to fire on every cold-start
/// and resume — iOS handles the actual UX.
class PermissionsService {
  PermissionsService(this._ref);

  final Ref _ref;

  Future<void> ensureRequested() async {
    try {
      await _ref.read(healthKitServiceProvider).requestPermissions();
    } catch (e) {
      debugPrint('[Permissions] HealthKit request failed: $e');
    }
    unawaited(_ref.read(pushServiceProvider).registerIfPermitted());
  }
}

@Riverpod(keepAlive: true)
PermissionsService permissionsService(Ref ref) => PermissionsService(ref);
