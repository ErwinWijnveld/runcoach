import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/features/dashboard/providers/dashboard_provider.dart';
import 'package:app/features/schedule/providers/schedule_provider.dart';
import 'package:app/features/wearable/data/wearable_api.dart';
import 'package:app/features/wearable/models/analyzing_run.dart';

part 'workout_sync_provider.freezed.dart';
part 'workout_sync_provider.g.dart';

/// State surfaced by [WorkoutSync] to the UI:
///   - `analyzing` is the queue of runs that the backend is currently
///     scoring and writing AI feedback for. Populated by every successful
///     foreground sync that returned `created_runs`. Entries leave the
///     map when (a) the workout_analyzed push lands, or (b) the polling
///     fallback observes `status == 'analyzed'`/`'unmatched'`, or (c)
///     they hit the safety timeout.
///   - `lastSyncResult` summarizes the most recent foreground sync so
///     the toast/banner can render its "Found N new runs" copy without
///     reaching back into the service.
///   - `lastSyncedAt` debounces the lifecycle observer — we don't sync
///     more than once every [WorkoutSync.minSyncInterval].
@freezed
sealed class WorkoutSyncState with _$WorkoutSyncState {
  const factory WorkoutSyncState({
    @Default(<int, AnalyzingRun>{}) Map<int, AnalyzingRun> analyzing,
    @Default(0) int notifiedNewRunsCount,
    LastSyncResult? lastSyncResult,
    DateTime? lastSyncedAt,
  }) = _WorkoutSyncState;
}

@freezed
sealed class LastSyncResult with _$LastSyncResult {
  const factory LastSyncResult({
    required int created,
    required int updated,
    required List<int> newRunIds,
    required DateTime at,
  }) = _LastSyncResult;
}

/// Poll cadence for the analysis-status fallback. The push notification
/// usually wins this race comfortably (typical activity-feedback job runs
/// in 4-8s on the queue), but on the simulator and when push permission
/// was denied this is the only signal the UI gets.
const _kPollInterval = Duration(seconds: 4);

/// Hard cap on how long we keep showing the "Analyzing…" indicator for a
/// single run. Longer than this and either the queue is wedged or the AI
/// feedback agent is timing out — surface a fallback state so the user
/// isn't stuck staring at a spinner.
const _kAnalyzingTimeout = Duration(minutes: 3);

@Riverpod(keepAlive: true)
class WorkoutSync extends _$WorkoutSync {
  /// Don't pull from HealthKit + POST more often than this. Foreground
  /// resume can fire several times a minute when the user task-switches —
  /// we don't want to thrash the queue or waste battery on duplicate
  /// idempotent posts.
  static const Duration minSyncInterval = Duration(seconds: 90);

  /// 14 days is a reasonable upper bound for "missed runs while the app
  /// was closed". Smaller windows (e.g. 24h) risk dropping a run if the
  /// user opens the app a week after a long trip; larger ones add latency
  /// to every foreground sync without much benefit (idempotent upserts
  /// take ~1ms each on the backend, but the HealthKit read does scale).
  static const Duration syncWindow = Duration(days: 14);

  Timer? _pollTimer;
  final _activePolls = <int>{};

  @override
  WorkoutSyncState build() {
    ref.onDispose(() {
      _pollTimer?.cancel();
    });
    return const WorkoutSyncState();
  }

  /// Foreground sync — pulls last [syncWindow] of HealthKit workouts,
  /// posts to /wearable/activities, and surfaces newly created runs as
  /// "analyzing" in [WorkoutSyncState.analyzing].
  ///
  /// `force=true` skips the [minSyncInterval] debounce; use only for the
  /// explicit "pull to refresh" action, not for lifecycle hooks.
  Future<void> sync({bool force = false}) async {
    final now = DateTime.now();
    final last = state.lastSyncedAt;
    if (!force && last != null && now.difference(last) < minSyncInterval) {
      return;
    }

    // Pre-emptively bump lastSyncedAt so a second concurrent caller bails.
    state = state.copyWith(lastSyncedAt: now);

    try {
      final hk = ref.read(healthKitServiceProvider);
      final api = ref.read(wearableApiProvider);

      // Permission is handled on the connect-health screen. If it's been
      // denied since onboarding, fetchWorkouts returns []; the rest of
      // this method no-ops cleanly.
      final workouts = await hk.fetchWorkouts(window: syncWindow);
      if (workouts.isEmpty) {
        state = state.copyWith(
          lastSyncResult: LastSyncResult(
            created: 0,
            updated: 0,
            newRunIds: const [],
            at: now,
          ),
        );
        return;
      }

      // Backend cap is 200/req. Foreground sync rarely surfaces more
      // than a handful of runs, but chunk anyway to stay correct.
      const chunkSize = 200;
      var created = 0;
      var updated = 0;
      final newRuns = <AnalyzingRun>[];

      for (var i = 0; i < workouts.length; i += chunkSize) {
        final end =
            (i + chunkSize < workouts.length) ? i + chunkSize : workouts.length;
        final chunk = workouts.sublist(i, end);
        final raw = await api.ingest({'activities': chunk});
        final response = (raw is Map) ? Map<String, dynamic>.from(raw) : null;
        if (response == null) continue;

        created += (response['created'] as num?)?.toInt() ?? 0;
        updated += (response['updated'] as num?)?.toInt() ?? 0;

        final createdRuns = response['created_runs'] as List<dynamic>? ?? [];
        for (final entry in createdRuns) {
          final map = Map<String, dynamic>.from(entry as Map);
          final id = (map['id'] as num?)?.toInt();
          final willAnalyze = map['will_analyze'] == true;
          if (id == null || !willAnalyze) continue;
          newRuns.add(AnalyzingRun(
            wearableActivityId: id,
            status: AnalyzingRunStatus.pending,
            startedAt: now,
          ));
        }
      }

      // Merge into state. Existing entries (in case the same run id was
      // surfaced twice across rapid syncs) keep their later progress.
      final merged = Map<int, AnalyzingRun>.from(state.analyzing);
      for (final r in newRuns) {
        merged[r.wearableActivityId] = merged[r.wearableActivityId] ?? r;
      }

      state = state.copyWith(
        analyzing: merged,
        notifiedNewRunsCount: state.notifiedNewRunsCount + newRuns.length,
        lastSyncResult: LastSyncResult(
          created: created,
          updated: updated,
          newRunIds: newRuns.map((r) => r.wearableActivityId).toList(),
          at: now,
        ),
      );

      // Kick the polling fallback. The push handler also clears
      // entries — whichever wins first.
      if (newRuns.isNotEmpty) {
        _ensurePolling();
      }
    } catch (e, st) {
      // Non-fatal: leave lastSyncedAt set so we still respect the
      // debounce, but don't write a misleading lastSyncResult.
      debugPrint('[WorkoutSync] sync failed: $e\n$st');
    }
  }

  /// Mark a run as fully analyzed and refresh dependent providers.
  /// Called from (a) the push handler when a `workout_analyzed` payload
  /// lands, and (b) the polling fallback when status flips to `analyzed`.
  void markAnalyzed(
    int wearableActivityId, {
    int? trainingDayId,
    int? trainingResultId,
    double? complianceScore,
    double? actualKm,
    String? aiFeedback,
  }) {
    final current = state.analyzing[wearableActivityId];
    if (current == null) {
      // Push arrived for a run we never tracked locally (e.g. ingested
      // by a future background-delivery path). Still refresh providers
      // so the schedule picks up the new TrainingResult.
      _refreshDependents();
      return;
    }
    final updated = Map<int, AnalyzingRun>.from(state.analyzing)
      ..[wearableActivityId] = current.copyWith(
        status: AnalyzingRunStatus.analyzed,
        trainingDayId: trainingDayId ?? current.trainingDayId,
        trainingResultId: trainingResultId ?? current.trainingResultId,
        complianceScore: complianceScore ?? current.complianceScore,
        actualKm: actualKm ?? current.actualKm,
        aiFeedback: aiFeedback ?? current.aiFeedback,
      );
    state = state.copyWith(analyzing: updated);
    // Defer the actual removal so the UI can flash a "complete" state
    // before the chip disappears.
    Future.delayed(const Duration(seconds: 4), () {
      final after = Map<int, AnalyzingRun>.from(state.analyzing)
        ..remove(wearableActivityId);
      state = state.copyWith(analyzing: after);
    });
    _refreshDependents();
  }

  /// Drop the toast counter once the UI has shown it.
  void clearNewRunsToast() {
    if (state.notifiedNewRunsCount == 0) return;
    state = state.copyWith(notifiedNewRunsCount: 0);
  }

  void _ensurePolling() {
    if (_pollTimer?.isActive == true) return;
    _pollTimer = Timer.periodic(_kPollInterval, (_) => _pollOnce());
    // Run once immediately so the UI flips status from `pending` to
    // `matched` as soon as ProcessWearableActivity has had time to land.
    unawaited(_pollOnce());
  }

  Future<void> _pollOnce() async {
    final ids = state.analyzing.keys.toList();
    if (ids.isEmpty) {
      _pollTimer?.cancel();
      _pollTimer = null;
      return;
    }

    final api = ref.read(wearableApiProvider);
    for (final id in ids) {
      if (_activePolls.contains(id)) continue;
      _activePolls.add(id);
      unawaited(_pollSingle(api, id).whenComplete(() {
        _activePolls.remove(id);
      }));
    }
  }

  Future<void> _pollSingle(WearableApi api, int id) async {
    try {
      final raw = await api.analysisStatus(id);
      final map =
          (raw is Map) ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
      final statusStr = map['status'] as String?;
      final status = switch (statusStr) {
        'analyzed' => AnalyzingRunStatus.analyzed,
        'matched' => AnalyzingRunStatus.matched,
        'unmatched' => AnalyzingRunStatus.unmatched,
        _ => AnalyzingRunStatus.pending,
      };

      final current = state.analyzing[id];
      if (current == null) return;

      final updated = Map<int, AnalyzingRun>.from(state.analyzing)
        ..[id] = current.copyWith(
          status: status,
          trainingDayId: (map['training_day_id'] as num?)?.toInt() ??
              current.trainingDayId,
          trainingResultId: (map['training_result_id'] as num?)?.toInt() ??
              current.trainingResultId,
          complianceScore: _toDouble(map['compliance_score']) ??
              current.complianceScore,
          actualKm: _toDouble(map['actual_km']) ?? current.actualKm,
          aiFeedback: map['ai_feedback'] as String? ?? current.aiFeedback,
        );

      // Terminal states — drop the entry shortly so the chip animates out.
      if (status == AnalyzingRunStatus.analyzed ||
          status == AnalyzingRunStatus.unmatched) {
        state = state.copyWith(analyzing: updated);
        Future.delayed(const Duration(seconds: 4), () {
          final after = Map<int, AnalyzingRun>.from(state.analyzing)
            ..remove(id);
          state = state.copyWith(analyzing: after);
        });
        _refreshDependents();
        return;
      }

      // Safety timeout — don't spin forever.
      if (DateTime.now().difference(current.startedAt) > _kAnalyzingTimeout) {
        final after = Map<int, AnalyzingRun>.from(state.analyzing)..remove(id);
        state = state.copyWith(analyzing: after);
        return;
      }

      state = state.copyWith(analyzing: updated);
    } catch (e) {
      // Transient — keep polling.
      debugPrint('[WorkoutSync] poll failed for $id: $e');
    }
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  void _refreshDependents() {
    // Fresh result rows mean the dashboard's compliance + the schedule
    // matrix are stale. Invalidate so the next read pulls them.
    ref.invalidate(dashboardProvider);
    // scheduleProvider is family-keyed by goalId — invalidating with no
    // arg busts every entry, which is the correct behavior because we
    // don't track which goal owns the run here.
    ref.invalidate(scheduleProvider);
  }
}
