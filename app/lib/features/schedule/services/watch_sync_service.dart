import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/features/goals/providers/goal_provider.dart';
import 'package:app/features/schedule/models/training_day.dart';
import 'package:app/features/schedule/providers/schedule_provider.dart';
import 'package:app/features/schedule/services/workout_scheduler_service.dart';

part 'watch_sync_service.g.dart';

/// Single source of truth for "which TrainingDays should be on the watch
/// right now". Used by:
///   - Proposal accept → [syncUpcoming] (first push of next 7 days)
///   - Reschedule + notification accept → [syncUpcoming] (resync the slice)
///   - App foreground → [syncDeltas] (only re-ship days the coach edited
///     server-side since the last successful sync)
///
/// Per-dayId `lastSyncedAt` timestamps persist in shared_preferences so
/// foreground delta-detection survives cold starts. The native bridge is
/// idempotent under the deterministic UUID (any prior plan for the same
/// dayId is removed and replaced), so over-firing is safe — under-firing
/// would leave the watch stale.
///
/// All public methods are no-ops on non-iOS / web / iOS < 17.4 (the native
/// bridge returns `unavailable`). The manual per-day Send-to-watch button
/// remains the only fallback for those environments.
@Riverpod(keepAlive: true)
class WatchSync extends _$WatchSync {
  static const _prefsKey = 'watch_synced_at_v1';
  static const _defaultLimit = 7;

  @override
  void build() {}

  /// Force-sync the next [limit] eligible training days. Use after the
  /// runner does something that mutated the plan locally (plan accept,
  /// reschedule, notification accept). May trigger the WorkoutKit
  /// permission prompt on first call.
  Future<BatchSyncResult> syncUpcoming({int limit = _defaultLimit}) async {
    if (!ref.read(workoutSchedulerServiceProvider).isSupported) {
      return BatchSyncResult.unavailable;
    }
    final days = await _collectUpcomingDays(limit: limit);
    return _sendDays(days);
  }

  /// Foreground delta sync: re-send only days whose server-side `updated_at`
  /// is newer than the locally-stored last-synced timestamp. No-op when
  /// nothing's changed (the common case after foregrounding).
  Future<BatchSyncResult> syncDeltas({int limit = _defaultLimit}) async {
    if (!ref.read(workoutSchedulerServiceProvider).isSupported) {
      return BatchSyncResult.unavailable;
    }
    final days = await _collectUpcomingDays(limit: limit);
    if (days.isEmpty) return _emptyOk();
    final lastSynced = await _loadLastSynced();
    final stale = days.where((d) {
      final updated = d.updatedAt;
      if (updated == null) return false;
      final synced = lastSynced[d.id];
      return synced == null || updated.isAfter(synced);
    }).toList(growable: false);
    if (stale.isEmpty) return _emptyOk();
    return _sendDays(stale);
  }

  // -------- internals --------

  BatchSyncResult _emptyOk() =>
      const BatchSyncResult(status: BatchSyncStatus.ok, results: []);

  Future<BatchSyncResult> _sendDays(List<TrainingDay> days) async {
    if (days.isEmpty) return _emptyOk();
    final requests = days
        .map(DaySyncRequest.fromTrainingDay)
        .whereType<DaySyncRequest>()
        .toList(growable: false);
    if (requests.isEmpty) return _emptyOk();

    final scheduler = ref.read(workoutSchedulerServiceProvider);
    final result = await scheduler.syncDays(requests);

    if (result.status == BatchSyncStatus.ok) {
      await _persistSyncedAt(result.results);
    }
    return result;
  }

  /// Collects the next [limit] active TrainingDays the watch should know
  /// about. Filters:
  ///   - date >= today (no point scheduling past runs)
  ///   - no result yet (already done)
  ///   - has distance OR intervals (otherwise nothing to send)
  /// Sorted by date ascending.
  Future<List<TrainingDay>> _collectUpcomingDays({required int limit}) async {
    final goals = await ref.read(goalsProvider.future);
    final active = goals
        .where((g) => g.status == 'active')
        .toList(growable: false);
    if (active.isEmpty) return const [];

    // Single-active-goal model in v1; loop anyway in case that ever changes.
    final today = DateTime.now();
    final todayYmd = DateTime(today.year, today.month, today.day);
    final all = <TrainingDay>[];
    for (final goal in active) {
      final weeks = await ref.read(scheduleProvider(goal.id).future);
      for (final week in weeks) {
        final wd = week.trainingDays;
        if (wd == null) continue;
        for (final day in wd) {
          final date = _parseYmd(day.date);
          if (date == null) continue;
          if (date.isBefore(todayYmd)) continue;
          if (day.result != null) continue;
          final hasDistance = (day.targetKm ?? 0) > 0;
          final hasIntervals = day.intervals != null && day.intervals!.isNotEmpty;
          if (!hasDistance && !hasIntervals) continue;
          all.add(day);
        }
      }
    }

    all.sort((a, b) {
      final ad = _parseYmd(a.date)!;
      final bd = _parseYmd(b.date)!;
      return ad.compareTo(bd);
    });
    return all.take(limit).toList(growable: false);
  }

  Future<Map<int, DateTime>> _loadLastSynced() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? const [];
    final map = <int, DateTime>{};
    for (final entry in raw) {
      final parts = entry.split('|');
      if (parts.length != 2) continue;
      final id = int.tryParse(parts[0]);
      final at = DateTime.tryParse(parts[1]);
      if (id == null || at == null) continue;
      map[id] = at;
    }
    return map;
  }

  Future<void> _persistSyncedAt(List<DaySyncResult> results) async {
    final scheduled = results.where((r) => r.status == DaySyncStatus.scheduled);
    if (scheduled.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final current = await _loadLastSynced();
    final now = DateTime.now();
    for (final r in scheduled) {
      current[r.dayId] = now;
    }
    final encoded = current.entries
        .map((e) => '${e.key}|${e.value.toIso8601String()}')
        .toList(growable: false);
    await prefs.setStringList(_prefsKey, encoded);
  }
}

DateTime? _parseYmd(String raw) {
  final parts = raw.split('-');
  if (parts.length != 3) return null;
  try {
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  } catch (_) {
    return null;
  }
}
