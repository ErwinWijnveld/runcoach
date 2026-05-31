import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/i18n/locale_provider.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/auth/models/user.dart';
import 'package:app/features/auth/providers/auth_provider.dart';
import 'package:app/features/notifications/providers/notifications_provider.dart';
import 'package:app/features/notifications/widgets/notifications_sheet.dart';
import 'package:app/features/push/services/push_service.dart';
import 'package:app/features/share/providers/celebration_provider.dart';
import 'package:app/features/share/widgets/run_celebration_sheet.dart';
import 'package:app/features/subscriptions/providers/pro_entitlement_provider.dart';
import 'package:app/features/subscriptions/services/purchases_service.dart';
import 'package:app/features/wearable/providers/workout_sync_provider.dart';
import 'package:app/features/wearable/widgets/workout_sync_lifecycle.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/router/app_router.dart';

class RunCoachApp extends ConsumerStatefulWidget {
  const RunCoachApp({super.key});

  @override
  ConsumerState<RunCoachApp> createState() => _RunCoachAppState();
}

class _RunCoachAppState extends ConsumerState<RunCoachApp> {
  bool _initialPayloadDrained = false;

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final push = ref.read(pushServiceProvider);

    // Fall back to English while the locale provider is resolving on the
    // first frame — shared_preferences resolves within ~ms so this is
    // rarely visible, but the AsyncValue contract requires us to handle it.
    final locale = ref.watch(appLocaleProvider).value ?? const Locale('en');

    // Tap on a delivered notification — fired by the native bridge.
    push.onTap = (payload) {
      // workout_analyzed pushes carry the freshly written analysis
      // payload; mirror it into local state so the chip flips and the
      // dashboard/schedule providers refresh, even if the user opened
      // the app via the tap rather than the in-app toast.
      _handleWorkoutAnalyzedPayload(ref, payload);
      final path = PushService.routeFromPayload(payload);
      if (path != null) {
        router.go(path);
      }
    };

    // Cold launch from a tap: drain the stashed payload after auth hydrates,
    // so the router redirect doesn't fight us. The notifications boot popup
    // lives in `_BootPopupHost` (mounted inside the router below) — it needs
    // a context with a Navigator ancestor, which only exists IN the router.
    if (!_initialPayloadDrained) {
      _initialPayloadDrained = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _waitForAuth(ref);
        // Drop the deep-link silently when the user isn't authenticated
        // (token expired, signed out between sessions). Without this
        // the router's redirect bounces them to /auth/welcome and the
        // payload is consumed but never honoured — a stale push is
        // worse than no push.
        if (ref.read(authProvider).value == null) {
          await push.consumeInitialPayload();
          return;
        }
        final payload = await push.consumeInitialPayload();
        if (payload == null) return;
        final path = PushService.routeFromPayload(payload);
        if (path != null) {
          router.go(path);
        }
      });
    }

    return CupertinoApp.router(
      title: 'RunCoach',
      theme: AppTheme.cupertino,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        return WorkoutSyncLifecycle(
          child: _SubscriptionBoot(
            child: _BootPopupHost(child: child ?? const SizedBox.shrink()),
          ),
        );
      },
    );
  }

  Future<void> _waitForAuth(WidgetRef ref) async {
    final completer = Completer<void>();
    final sub = ref.listenManual<AsyncValue>(authProvider, (prev, next) {
      if (!next.isLoading && !completer.isCompleted) {
        completer.complete();
      }
    }, fireImmediately: true);
    await completer.future;
    sub.close();
  }

  void _handleWorkoutAnalyzedPayload(
    WidgetRef ref,
    Map<String, dynamic> payload,
  ) {
    if (payload['type'] != 'workout_analyzed') return;
    final activityId = (payload['wearable_activity_id'] as num?)?.toInt();
    if (activityId == null) return;
    ref.read(workoutSyncProvider.notifier).markAnalyzed(
          activityId,
          trainingDayId: (payload['training_day_id'] as num?)?.toInt(),
          trainingResultId: (payload['training_result_id'] as num?)?.toInt(),
          complianceScore: switch (payload['compliance_score']) {
            num n => n.toDouble(),
            String s => double.tryParse(s),
            _ => null,
          },
        );
    // A fresh analysis may have just minted a pace_adjustment notification —
    // refresh the inbox so the bell badge updates without a manual reopen.
    ref.invalidate(notificationsProvider);
  }
}

/// Configure the RevenueCat SDK once auth resolves with a user, then fire a
/// server-side entitlement sync so the router has authoritative pro-state for
/// its redirect logic. Runs once per app launch — Riverpod listeners are
/// idempotent against repeated identical state changes.
///
/// The configure call needs the user's id as `appUserID` so purchases
/// attribute to the right server-side row; the sync call hits our backend
/// which in turn calls RC's REST API (server is the source of truth).
class _SubscriptionBoot extends ConsumerStatefulWidget {
  const _SubscriptionBoot({required this.child});

  final Widget child;

  @override
  ConsumerState<_SubscriptionBoot> createState() => _SubscriptionBootState();
}

class _SubscriptionBootState extends ConsumerState<_SubscriptionBoot> {
  bool _booted = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<User?>>(authProvider, (prev, next) {
      if (_booted) return;
      if (next.isLoading) return;
      final user = next.value;
      if (user == null) return;
      _booted = true;
      _bootOnce(user);
    });
    return widget.child;
  }

  Future<void> _bootOnce(User user) async {
    final purchases = ref.read(purchasesServiceProvider);
    try {
      await purchases.configure(user);
    } catch (e, st) {
      debugPrint('[subscription-boot] configure failed: $e');
      debugPrintStack(stackTrace: st);
    }
    // Even if the SDK couldn't initialize (no key in dev), still sync — the
    // server resolves pro-state independently via its REST call to RC.
    await ref.read(proEntitlementProvider.notifier).syncFromServer();
  }
}

/// Cold-start "Action required" reminder. Mounted INSIDE the router via
/// `CupertinoApp.router(builder: ...)` so the dialog has a Navigator
/// ancestor — which is the requirement for `showCupertinoDialog` to find
/// a route to push onto. Earlier versions called the dialog from the
/// `RunCoachApp` State context (above CupertinoApp.router) and the dialog
/// silently no-op'd because `Navigator.of(...)` couldn't find one.
class _BootPopupHost extends ConsumerStatefulWidget {
  const _BootPopupHost({required this.child});

  final Widget child;

  @override
  ConsumerState<_BootPopupHost> createState() => _BootPopupHostState();
}

class _BootPopupHostState extends ConsumerState<_BootPopupHost> {
  bool _fired = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<User?>>(authProvider, (prev, next) {
      if (_fired) return;
      if (next.isLoading) return;
      if (next.value == null) return;
      _fired = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _showReminder(context);
        if (!mounted) return;
        await _maybeShowCelebration(context);
      });
    });
    return widget.child;
  }

  Future<void> _showReminder(BuildContext ctx) async {
    try {
      final items = await ref.read(notificationsProvider.future);
      if (kDebugMode) {
        debugPrint('[boot-popup] fetched ${items.length} pending notifications');
      }
      if (!mounted || items.isEmpty) return;
      // Pull a context from BELOW the router. The host's own context lives
      // above the navigator (CupertinoApp.router's `builder` wraps the
      // navigator), so showCupertinoDialog can't find a Navigator ancestor
      // from there. The root navigator key, set on the GoRouter, gives us
      // a context that has the navigator as an ancestor.
      final navCtx = rootNavigatorKey.currentContext;
      if (navCtx == null || !navCtx.mounted) return;
      final l10n = AppLocalizations.of(navCtx);
      final view = await showCupertinoDialog<bool>(
        context: navCtx,
        builder: (dialogCtx) => CupertinoAlertDialog(
          title: Text(l10n.bootPopupTitle),
          content: Text(l10n.bootPopupBody(items.length)),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: Text(l10n.bootPopupLater),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: Text(l10n.bootPopupView),
            ),
          ],
        ),
      );
      if (view == true && navCtx.mounted) {
        await showNotificationsSheet(navCtx);
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[boot-popup] error: $e\n$st');
      }
    }
  }

  /// Pop the shareable run-card sheet for the most recent analyzed run
  /// when nothing else is grabbing focus. Runs AFTER the notifications
  /// reminder — actionable items win over delight moments.
  Future<void> _maybeShowCelebration(BuildContext ctx) async {
    try {
      // Skip when notifications popup just took focus (a runner doesn't
      // need two modals stacked on cold start).
      final pending = await ref.read(notificationsProvider.future);
      if (pending.isNotEmpty) return;

      final celebration = ref.read(celebrationProvider.notifier);
      final result = await celebration.findCelebratableRun();
      if (kDebugMode) {
        debugPrint('[boot-popup] celebration result=${result?.id}');
      }
      if (!mounted || result == null) return;
      final activityId = result.wearableActivity?.id;
      if (activityId == null) return;

      final navCtx = rootNavigatorKey.currentContext;
      if (navCtx == null || !navCtx.mounted) return;

      // Mark celebrated FIRST so a hard close mid-sheet doesn't re-fire
      // the popup next boot.
      await celebration.markCelebrated(activityId);

      await RunCelebrationSheet.show(navCtx, result: result);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[boot-popup] celebration error: $e\n$st');
      }
    }
  }
}
