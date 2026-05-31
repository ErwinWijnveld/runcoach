import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/features/notifications/data/notifications_api.dart';
import 'package:app/features/notifications/models/user_notification.dart';
import 'package:app/features/schedule/providers/plan_evaluations_provider.dart';
import 'package:app/features/schedule/providers/schedule_provider.dart';
import 'package:app/features/schedule/services/watch_sync_service.dart';

part 'notifications_provider.g.dart';

@Riverpod(keepAlive: true)
class Notifications extends _$Notifications {
  @override
  Future<List<UserNotification>> build() async {
    final api = ref.watch(notificationsApiProvider);
    final data = await api.list();
    final list = (data['data'] as List).cast<Map<String, dynamic>>();
    return list.map(UserNotification.fromJson).toList();
  }

  Future<void> accept(int id) async {
    // Even though this provider is keepAlive (so `ref` doesn't auto-dispose
    // mid-request), capturing handles before the await keeps the call-site
    // uniform with the rest of the codebase's mutator pattern. See
    // `app/CLAUDE.md` section 1b.
    final api = ref.read(notificationsApiProvider);
    final watchSync = ref.read(watchSyncProvider.notifier);
    await api.accept(id);
    ref.invalidateSelf();
    // Plan-evaluation accepts apply an EditActivePlan proposal server-side,
    // which mutates upcoming training days. Refresh the surfaces that
    // render those days so the runner sees the result wherever they came
    // from (inbox OR schedule view OR detail screen). Watch sync ships
    // the next 7 days to the wearable. Fire-and-forget.
    ref.invalidate(planEvaluationsProvider);
    ref.invalidate(scheduleProvider);
    unawaited(watchSync.syncUpcoming());
  }

  Future<void> dismiss(int id) async {
    final api = ref.read(notificationsApiProvider);
    await api.dismiss(id);
    ref.invalidateSelf();
    // Server-side dismiss also flips the linked PlanEvaluation to dismissed —
    // refresh the schedule's evaluation cards so the runner sees the new
    // state on their next visit.
    ref.invalidate(planEvaluationsProvider);
  }
}

/// Convenience: count of pending items, defaulting to 0 while loading or
/// on error so the header bell doesn't flicker between numbers.
@riverpod
int pendingNotificationCount(Ref ref) {
  return ref.watch(notificationsProvider).maybeWhen(
        data: (list) => list.length,
        orElse: () => 0,
      );
}
