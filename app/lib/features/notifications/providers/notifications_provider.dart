import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/features/notifications/data/notifications_api.dart';
import 'package:app/features/notifications/models/user_notification.dart';

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
    // mid-request), capturing the api handle before await keeps the call-
    // site uniform with the rest of the codebase's mutator pattern. See
    // `app/CLAUDE.md` section 1b.
    final api = ref.read(notificationsApiProvider);
    await api.accept(id);
    ref.invalidateSelf();
  }

  Future<void> dismiss(int id) async {
    final api = ref.read(notificationsApiProvider);
    await api.dismiss(id);
    ref.invalidateSelf();
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
