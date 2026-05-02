import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/auth/providers/auth_provider.dart';
import 'package:app/features/push/services/push_service.dart';
import 'package:app/features/wearable/providers/workout_sync_provider.dart';
import 'package:app/features/wearable/widgets/workout_sync_lifecycle.dart';
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
    // so the router redirect doesn't fight us.
    if (!_initialPayloadDrained) {
      _initialPayloadDrained = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Wait until the auth state isn't loading anymore — then route.
        // ref.listen would be cleaner but this is single-shot on cold launch.
        await _waitForAuth(ref);
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
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      builder: (context, child) {
        return WorkoutSyncLifecycle(child: child ?? const SizedBox.shrink());
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
  }
}
