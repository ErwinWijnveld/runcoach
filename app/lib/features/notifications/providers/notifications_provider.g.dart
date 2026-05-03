// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notifications_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Notifications)
final notificationsProvider = NotificationsProvider._();

final class NotificationsProvider
    extends $AsyncNotifierProvider<Notifications, List<UserNotification>> {
  NotificationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationsHash();

  @$internal
  @override
  Notifications create() => Notifications();
}

String _$notificationsHash() => r'c5af19eeea13d9aa89843627a6f34959eebfd894';

abstract class _$Notifications extends $AsyncNotifier<List<UserNotification>> {
  FutureOr<List<UserNotification>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<UserNotification>>, List<UserNotification>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<UserNotification>>,
                List<UserNotification>
              >,
              AsyncValue<List<UserNotification>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Convenience: count of pending items, defaulting to 0 while loading or
/// on error so the header bell doesn't flicker between numbers.

@ProviderFor(pendingNotificationCount)
final pendingNotificationCountProvider = PendingNotificationCountProvider._();

/// Convenience: count of pending items, defaulting to 0 while loading or
/// on error so the header bell doesn't flicker between numbers.

final class PendingNotificationCountProvider
    extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Convenience: count of pending items, defaulting to 0 while loading or
  /// on error so the header bell doesn't flicker between numbers.
  PendingNotificationCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingNotificationCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingNotificationCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return pendingNotificationCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$pendingNotificationCountHash() =>
    r'e73497d9eac09ba0e0b417a74bb7665dcf956d70';
