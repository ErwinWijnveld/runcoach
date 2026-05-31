import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/features/goals/models/goal.dart';
import 'package:app/features/goals/providers/goal_provider.dart';
import 'package:app/features/schedule/models/training_day.dart';
import 'package:app/features/schedule/models/training_week.dart';
import 'package:app/features/schedule/providers/schedule_provider.dart';
import 'package:app/features/schedule/services/watch_sync_service.dart';
import 'package:app/features/schedule/services/workout_scheduler_service.dart';

/// Captures syncDays invocations so the tests can assert on exactly which
/// days the WatchSync service decided to push. Returns a status mirroring
/// the `BatchSyncStatus.ok` outcome with every input marked `scheduled`.
class _RecordingScheduler extends WorkoutSchedulerService {
  final List<List<DaySyncRequest>> calls = [];

  @override
  bool get isSupported => true;

  @override
  Future<BatchSyncResult> syncDays(List<DaySyncRequest> days) async {
    calls.add(List.unmodifiable(days));
    return BatchSyncResult(
      status: BatchSyncStatus.ok,
      results: days
          .map((d) => DaySyncResult(
                dayId: d.dayId,
                status: DaySyncStatus.scheduled,
              ))
          .toList(growable: false),
    );
  }
}

TrainingDay _day({
  required int id,
  required DateTime date,
  double? targetKm = 6.0,
  DateTime? updatedAt,
}) {
  String ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  return TrainingDay(
    id: id,
    date: ymd(date),
    type: 'easy',
    title: 'Easy run',
    order: 1,
    targetKm: targetKm,
    updatedAt: updatedAt,
  );
}

TrainingWeek _week(List<TrainingDay> days) => TrainingWeek(
      id: 1,
      goalId: 42,
      weekNumber: 1,
      startsAt: '2026-05-19',
      totalKm: 30.0,
      focus: 'base',
      trainingDays: days,
    );

ProviderContainer _makeContainer({
  required _RecordingScheduler scheduler,
  required List<TrainingDay> upcoming,
}) {
  return ProviderContainer(
    overrides: [
      workoutSchedulerServiceProvider.overrideWith((ref) => scheduler),
      goalsProvider.overrideWith((ref) async => [
            const Goal(
              id: 42,
              type: 'race',
              name: 'Test goal',
              status: 'active',
            ),
          ]),
      scheduleProvider(42).overrideWith((ref) async => [_week(upcoming)]),
    ],
  );
}

void main() {
  setUp(() {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  test('syncUpcoming clamps to limit and skips past-dated days', () async {
    final scheduler = _RecordingScheduler();
    final today = DateTime.now();
    final upcoming = [
      // 1 past day — should be skipped
      _day(id: 1, date: today.subtract(const Duration(days: 1))),
      // 12 future days — should be clamped to 7
      for (int i = 0; i < 12; i++)
        _day(id: 100 + i, date: today.add(Duration(days: i))),
    ];
    final container = _makeContainer(scheduler: scheduler, upcoming: upcoming);
    addTearDown(container.dispose);

    final result = await container.read(watchSyncProvider.notifier).syncUpcoming();

    expect(result.status, BatchSyncStatus.ok);
    expect(scheduler.calls, hasLength(1));
    expect(scheduler.calls.first.length, 7);
    // Days should be the 7 earliest future ones, in ascending date order.
    final ids = scheduler.calls.first.map((r) => r.dayId).toList();
    expect(ids, [100, 101, 102, 103, 104, 105, 106]);
  });

  test('syncDeltas re-sends only days with updatedAt newer than lastSynced',
      () async {
    final scheduler = _RecordingScheduler();
    final today = DateTime.now();

    // Seed lastSyncedAt for day 1 + day 2 at `cutoff`.
    final cutoff = DateTime.now().subtract(const Duration(hours: 2));
    SharedPreferences.setMockInitialValues({
      'watch_synced_at_v1': [
        '1|${cutoff.toIso8601String()}',
        '2|${cutoff.toIso8601String()}',
      ],
    });

    final upcoming = [
      // Day 1: untouched since last sync — should be skipped
      _day(
        id: 1,
        date: today.add(const Duration(days: 1)),
        updatedAt: cutoff.subtract(const Duration(hours: 1)),
      ),
      // Day 2: edited after the cutoff — should be re-sent
      _day(
        id: 2,
        date: today.add(const Duration(days: 2)),
        updatedAt: cutoff.add(const Duration(minutes: 30)),
      ),
      // Day 3: never synced before but updatedAt is set — should be re-sent
      _day(
        id: 3,
        date: today.add(const Duration(days: 3)),
        updatedAt: today,
      ),
      // Day 4: no updatedAt at all — service can't reason about it, skip
      _day(
        id: 4,
        date: today.add(const Duration(days: 4)),
        updatedAt: null,
      ),
    ];

    final container = _makeContainer(scheduler: scheduler, upcoming: upcoming);
    addTearDown(container.dispose);

    final result = await container.read(watchSyncProvider.notifier).syncDeltas();

    expect(result.status, BatchSyncStatus.ok);
    expect(scheduler.calls, hasLength(1));
    final ids = scheduler.calls.first.map((r) => r.dayId).toSet();
    expect(ids, {2, 3});
  });

  test('syncDeltas is a no-op when nothing has changed', () async {
    final scheduler = _RecordingScheduler();
    final today = DateTime.now();
    final cutoff = DateTime.now();
    SharedPreferences.setMockInitialValues({
      'watch_synced_at_v1': [
        '1|${cutoff.toIso8601String()}',
      ],
    });

    final upcoming = [
      _day(
        id: 1,
        date: today.add(const Duration(days: 1)),
        updatedAt: cutoff.subtract(const Duration(seconds: 1)),
      ),
    ];

    final container = _makeContainer(scheduler: scheduler, upcoming: upcoming);
    addTearDown(container.dispose);

    final result = await container.read(watchSyncProvider.notifier).syncDeltas();

    expect(result.status, BatchSyncStatus.ok);
    // No native call should fire when every day is fresh.
    expect(scheduler.calls, isEmpty);
  });
}
