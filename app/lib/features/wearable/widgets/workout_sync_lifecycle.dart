import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/auth/providers/auth_provider.dart';
import 'package:app/features/wearable/providers/workout_sync_provider.dart';

/// Wraps the app's router and triggers a foreground sync whenever:
///   - The user is signed in AND has completed onboarding (no point pulling
///     before the connect-health onboarding screen has run — it does its
///     own initial sync there).
///   - The app comes to the foreground (`AppLifecycleState.resumed`).
///   - The auth state flips from null/loading to a logged-in user.
///
/// The actual debounce + idempotency live inside [WorkoutSync.sync] (90s
/// minimum interval). This widget is purely a trigger — it doesn't render
/// any UI itself, only forwards [child] through.
///
/// Mounted once in `app.dart`, OUTSIDE the router's redirect logic, so its
/// lifecycle observers stay alive across route changes.
class WorkoutSyncLifecycle extends ConsumerStatefulWidget {
  final Widget child;
  const WorkoutSyncLifecycle({super.key, required this.child});

  @override
  ConsumerState<WorkoutSyncLifecycle> createState() =>
      _WorkoutSyncLifecycleState();
}

class _WorkoutSyncLifecycleState extends ConsumerState<WorkoutSyncLifecycle>
    with WidgetsBindingObserver {
  bool _initialFireScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _maybeSync();
    }
  }

  void _maybeSync() {
    final auth = ref.read(authProvider);
    final user = auth.value;
    if (user == null) return;
    if (user.hasCompletedOnboarding != true) return;
    // Fire-and-forget — sync() handles its own errors and debouncing.
    unawaited(ref.read(workoutSyncProvider.notifier).sync());
  }

  @override
  Widget build(BuildContext context) {
    // First-load fire: schedule once, after the first frame, so we don't
    // race the auth hydration. Uses ref.listen so we re-fire when the
    // user actually logs in mid-session (not just on cold start).
    if (!_initialFireScheduled) {
      _initialFireScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeSync());
    }

    ref.listen(authProvider, (prev, next) {
      final wasLoggedIn = prev?.value != null;
      final isLoggedIn = next.value != null;
      if (!wasLoggedIn && isLoggedIn) {
        _maybeSync();
      }
    });

    return widget.child;
  }
}
