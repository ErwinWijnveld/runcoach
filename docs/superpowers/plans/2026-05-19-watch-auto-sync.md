# Watch Auto-Sync — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the watch always reflect the current plan without the runner having to remember to press "Send to watch" per day. Auto-sync the next 7 active training days (a) on plan-accept, (b) on every local mutation (reschedule, pace-adjustment notification accept), and (c) on app foreground when the plan has been modified server-side (e.g. coach-driven edit). Manual "Send to watch" button stays as a force-resync per day, but the existing "duplicate" wall is removed so it actually updates after edits.

**Architecture:**
- **Swift bridge** gets one new batch method (`syncDays`) that gates permission once and loops; the existing `scheduleRun`/`scheduleIntervals` switch from "bail on `.duplicate`" to "always replace when our UUID exists at the same date" so re-sends after content edits propagate.
- **Flutter `WatchSyncService`** owns all auto-sync logic (a single source of truth for "which days should be on the watch"). Wire-ins are one-liners at proposal-accept, reschedule, notification-accept, and foreground.
- **Delta detection** uses a per-`dayId` `lastSyncedAt` map in `shared_preferences` compared against the API's `TrainingDay.updated_at` (new field) so foreground sync only re-sends days whose content actually changed.
- iOS 17.0–17.3 fallback: auto-sync disabled (no deterministic UUIDs → can't de-dup); manual button still works.

**Tech stack:** Swift / WorkoutKit. Dart / Riverpod codegen / `shared_preferences`. Laravel 13 (one model change + API resource update).

**No spec — the recommendation in the prior chat turn (cream-card plan accept hybrid) is the spec.**

---

## Task 1: Swift — replace-on-same-date instead of `.duplicate`

**File:** `app/ios/Runner/WorkoutScheduling.swift`

**Why:** Today `ensureNoExistingForDay` returns `.duplicate` when the same `TrainingDay.id` is already scheduled on the same date — even when the workout's content (distance / intervals / pace) has been edited since. This is the "send to watch says already added" bug. After this change, re-sends always replace, so a manual press of Send-to-watch after a coach edit actually updates the watch.

- [ ] **Step 1: Rewrite `ensureNoExistingForDay` to never block same-date**

Find `ensureNoExistingForDay` (around line 326). Replace the `sameDate ? .duplicate : remove+ok` branch with an unconditional remove-then-ok. The `.duplicate` case becomes dead code; remove from the enum too.

```swift
@available(iOS 17.0, *)
private static func removeExistingForDay(dayId: Int?) async {
    guard #available(iOS 17.4, *), let dayId, dayId > 0 else { return }
    let dayUUID = uuidForDay(dayId)
    let scheduler = WorkoutScheduler.shared
    let existing = await scheduler.scheduledWorkouts
    guard let our = existing.first(where: { $0.plan.id == dayUUID }) else { return }
    do {
        try await scheduler.remove(our.plan, at: our.date)
    } catch {
        // Best-effort — if remove fails the schedule call below either
        // succeeds (rare race) or fails and surfaces the error to Dart.
    }
}
```

- [ ] **Step 2: Update both schedule paths to call the new helper**

`scheduleRunIOS17` + `scheduleIntervalsIOS17`: drop the `switch await ensureNoExistingForDay(...)` block, replace with a plain `await removeExistingForDay(dayId: dayId)` after the `ensureAuthorized` gate.

- [ ] **Step 3: Delete `ExistingCheckResult` enum + `duplicateResponse()` helper**

No callers remain after Step 2. Removes the `case duplicate` from `WorkoutScheduleStatus.parse` in Dart later (Task 4 Step 4).

- [ ] **Step 4: Pint-equivalent (no formatter for Swift — ensure manual style matches surrounding code)**

```bash
cd /Users/erwinwijnveld/projects/runcoach/app
flutter analyze  # smoke check — Swift won't be analyzed but Dart side must stay clean
```

Commit:

```bash
git add app/ios/Runner/WorkoutScheduling.swift
git commit -m "fix(watch): always replace existing scheduled workout on same date

The 'duplicate' status was a false positive after the runner edited a
day's distance/intervals — content changed but the dayId UUID matched,
so Send-to-watch refused to update. Now any re-send removes the prior
WorkoutPlan (if any) and schedules fresh. The 'duplicate' status code
is dead and removed from both Swift and Dart parsers."
```

---

## Task 2: Swift — batch `syncDays` method

**File:** `app/ios/Runner/WorkoutScheduling.swift`

**Why:** Auto-sync needs to schedule up to 7 days in one Dart→Native call. Doing 7 individual calls would (a) hit `ensureAuthorized` 7× (each one may show a prompt on first run), (b) re-read `scheduledWorkouts` 7× when one read up front is enough. Batch is faster and avoids prompt-ping-pong on first auto-sync.

- [ ] **Step 1: Add `syncDays` case to the method handler**

In `register(controller:)`, add `case "syncDays": ... syncDays(args: args, result: result)`.

- [ ] **Step 2: Implement the batched flow**

```swift
private static func syncDays(args: [String: Any], result: @escaping FlutterResult) {
    if #available(iOS 17.4, *) {
        Task { @MainActor in
            await syncDaysIOS174(args: args, result: result)
        }
    } else {
        // iOS 17.0-17.3 has no identity tracking — refuse batch (would
        // create duplicate entries on every call). The manual per-day
        // button still works there because it's the runner's choice.
        result(["status": "unavailable", "results": []])
    }
}

@available(iOS 17.4, *)
private static func syncDaysIOS174(args: [String: Any], result: @escaping FlutterResult) async {
    let rawDays = args["days"] as? [[String: Any]] ?? []
    guard !rawDays.isEmpty else {
        result(["status": "ok", "results": []])
        return
    }

    let scheduler = WorkoutScheduler.shared
    var authState = await scheduler.authorizationState
    if authState == .notDetermined {
        authState = await scheduler.requestAuthorization()
    }
    guard authState == .authorized else {
        result(["status": "denied", "results": []])
        return
    }

    // One snapshot of currently-scheduled workouts; reused across all
    // iterations. Avoids N calls to scheduler.scheduledWorkouts.
    let existing = await scheduler.scheduledWorkouts

    var results: [[String: Any]] = []
    for raw in rawDays {
        let dayId = (raw["dayId"] as? NSNumber)?.intValue ?? 0
        let dateString = (raw["date"] as? String) ?? ""
        guard dayId > 0, let components = parseDate(dateString) else {
            results.append(["dayId": dayId, "status": "skipped"])
            continue
        }

        // Remove existing (if any) — fail-soft, errors don't block.
        let dayUUID = uuidForDay(dayId)
        if let our = existing.first(where: { $0.plan.id == dayUUID }) {
            try? await scheduler.remove(our.plan, at: our.date)
        }

        // Build the workout payload — distinguish single-goal vs interval
        // by presence of `steps`. Mirrors scheduleRun/scheduleIntervals.
        let steps = raw["steps"] as? [[String: Any]]
        let plan: WorkoutPlan
        if let steps, !steps.isEmpty {
            guard let workout = buildCustomWorkout(
                displayName: raw["displayName"] as? String,
                warmupSeconds: (raw["warmupSeconds"] as? NSNumber)?.intValue,
                cooldownSeconds: (raw["cooldownSeconds"] as? NSNumber)?.intValue,
                rawSteps: steps
            ) else {
                results.append(["dayId": dayId, "status": "skipped"])
                continue
            }
            plan = WorkoutPlan(.custom(workout), id: dayUUID)
        } else {
            let distanceKm = (raw["distanceKm"] as? NSNumber)?.doubleValue ?? 0
            guard distanceKm > 0 else {
                results.append(["dayId": dayId, "status": "skipped"])
                continue
            }
            let workout = SingleGoalWorkout(
                activity: .running,
                location: .outdoor,
                goal: .distance(distanceKm, UnitLength.kilometers)
            )
            plan = WorkoutPlan(.goal(workout), id: dayUUID)
        }

        do {
            try await scheduler.schedule(plan, at: components)
            results.append(["dayId": dayId, "status": "scheduled"])
        } catch {
            results.append(["dayId": dayId, "status": "failed", "message": error.localizedDescription])
        }
    }

    result(["status": "ok", "results": results])
}

// Extract the existing CustomWorkout-building logic from
// scheduleIntervalsIOS17 into this helper so syncDays can reuse it.
@available(iOS 17.0, *)
private static func buildCustomWorkout(
    displayName: String?,
    warmupSeconds: Int?,
    cooldownSeconds: Int?,
    rawSteps: [[String: Any]]
) -> CustomWorkout? {
    var intervalSteps: [IntervalStep] = []
    for raw in rawSteps {
        let kind = (raw["kind"] as? String) ?? "work"
        let distanceM = (raw["distanceM"] as? NSNumber)?.doubleValue
        let durationSeconds = (raw["durationSeconds"] as? NSNumber)?.intValue
        let purpose: IntervalStep.Purpose = (kind == "recovery") ? .recovery : .work
        guard let goal = buildGoal(distanceM: distanceM, durationSeconds: durationSeconds) else {
            continue
        }
        intervalSteps.append(IntervalStep(purpose, step: WorkoutStep(goal: goal)))
    }
    guard !intervalSteps.isEmpty else { return nil }

    let warmupStep: WorkoutStep? = (warmupSeconds.map { $0 > 0 ? WorkoutStep(goal: .time(Double($0), .seconds)) : nil }) ?? nil
    let cooldownStep: WorkoutStep? = (cooldownSeconds.map { $0 > 0 ? WorkoutStep(goal: .time(Double($0), .seconds)) : nil }) ?? nil

    return CustomWorkout(
        activity: .running,
        location: .outdoor,
        displayName: displayName,
        warmup: warmupStep,
        blocks: [IntervalBlock(steps: intervalSteps, iterations: 1)],
        cooldown: cooldownStep
    )
}
```

Then refactor `scheduleIntervalsIOS17` to call `buildCustomWorkout` instead of inlining the same logic — keeps the two paths in sync.

- [ ] **Step 3: Verify on a real iPhone (Simulator can't run WorkoutKit)**

Manually fire `syncDays` from a debug button (temporary) with 3-4 mixed days and confirm they all land in the iPhone's Fitness app's Scheduled list. Remove the debug button before commit.

Commit:

```bash
git add app/ios/Runner/WorkoutScheduling.swift
git commit -m "feat(watch): add syncDays batch method for auto-sync

Single permission gate + single scheduledWorkouts read for up to N
days in one call. Used by the new WatchSyncService to ship the next
7 days to the watch on plan-accept / foreground / mutation. iOS
17.0-17.3 falls through to status=unavailable since identity
tracking (required for safe replace-on-resend) needs 17.4."
```

---

## Task 3: Backend — expose `TrainingDay.updated_at`

**Files:**
- `api/app/Http/Resources/` (or wherever TrainingDay is serialized — check first)
- `api/app/Models/TrainingDay.php` (already has timestamps, just confirm)

**Why:** Foreground sync needs to know which days have changed since the last sync to avoid re-shipping the same 7 workouts on every app launch. `updated_at` is already on the model; just needs to be in the serialized response.

- [ ] **Step 1: Find the TrainingDay serializer**

```bash
grep -rn "TrainingDay" /Users/erwinwijnveld/projects/runcoach/api/app/Http --include="*.php" | grep -iE "resource|toArray|serialize"
```

Likely it's an `->toArray()` projection inside `TrainingScheduleController` or a `JsonResource` subclass. If it's an array projection, add `'updated_at' => $day->updated_at?->toIso8601String()`. If it's a `JsonResource`, add the key in `toArray()`.

- [ ] **Step 2: Audit every endpoint that returns training days**

```bash
grep -rn "weeks\(\)" /Users/erwinwijnveld/projects/runcoach/api/app/Http --include="*.php"
```

Likely surfaces: `TrainingScheduleController` (weekly + day-detail endpoints), `GoalController` (goal detail includes plan). Make sure every path includes the new field — Flutter parses one model class regardless of which endpoint produced it.

- [ ] **Step 3: Test**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
vendor/bin/pint --dirty --format agent
php artisan test --compact --filter=TrainingSchedule
```

Add a single assertion to the relevant test file checking `updated_at` is present + an ISO string. Failing-first — write the assert, run, then add the field.

Commit:

```bash
git add api/
git commit -m "feat(api): expose training_days.updated_at on schedule + goal endpoints

Watch auto-sync (Flutter side, separate commit) compares this against
a local lastSyncedAt map to ship only days whose content changed
since the last sync — avoids re-shipping all 7 days on every app
foreground."
```

---

## Task 4: Flutter — `TrainingDay.updatedAt` field + `WatchSyncService`

**Files:**
- `app/lib/features/schedule/models/training_day.dart`
- Create: `app/lib/features/schedule/services/watch_sync_service.dart`
- `app/lib/features/schedule/services/workout_scheduler_service.dart` (extend)

- [ ] **Step 1: Add `updatedAt` to `TrainingDay`**

```dart
@JsonKey(name: 'updated_at') DateTime? updatedAt,
```

Run codegen:

```bash
cd /Users/erwinwijnveld/projects/runcoach/app
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 2: Extend `WorkoutSchedulerService` with `syncDays`**

In `workout_scheduler_service.dart`, add:

```dart
/// Batch-schedule N training days in a single native call. Replaces any
/// previously-scheduled workouts for these dayIds (deterministic UUID
/// match). On iOS < 17.4 returns `unavailable` so the caller can fall
/// back to the per-day manual button.
Future<List<DaySyncResult>> syncDays(List<DaySyncRequest> days) async {
  if (!_supportsNativeBridge() || days.isEmpty) {
    return const [];
  }
  try {
    final raw = await _channel.invokeMethod<dynamic>('syncDays', {
      'days': days.map((d) => d.toJson()).toList(growable: false),
    });
    final map = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    if (map['status'] != 'ok') return const [];
    final results = (map['results'] as List?) ?? const [];
    return results
        .whereType<Map>()
        .map((r) => DaySyncResult.fromJson(Map<String, dynamic>.from(r)))
        .toList(growable: false);
  } catch (_) {
    return const [];
  }
}
```

Plus the `DaySyncRequest` + `DaySyncResult` value classes (mirror the JSON shape from Task 2).

- [ ] **Step 3: Create `WatchSyncService`**

```dart
// app/lib/features/schedule/services/watch_sync_service.dart
@Riverpod(keepAlive: true)
class WatchSync extends _$WatchSync {
  static const _prefsKey = 'watch_synced_at_v1';

  @override
  void build() {}

  /// Force-sync the next [limit] active days. Use after plan-accept and
  /// notification-accept (small bursts where the runner did something
  /// that changed the plan).
  Future<void> syncUpcoming({int limit = 7}) async {
    final days = await _collectUpcomingDays(limit: limit);
    if (days.isEmpty) return;
    final requests = days.map(_toRequest).whereType<DaySyncRequest>().toList();
    final results = await ref.read(workoutSchedulerServiceProvider).syncDays(requests);
    await _persistSyncedAt(results, days);
  }

  /// Foreground sync: re-send only days whose `updated_at` is newer than
  /// our locally-stored last-synced timestamp. Idempotent on no-op.
  Future<void> syncDeltas({int limit = 7}) async {
    final days = await _collectUpcomingDays(limit: limit);
    if (days.isEmpty) return;
    final lastSynced = await _loadLastSynced();
    final stale = days.where((d) {
      final updated = d.updatedAt;
      if (updated == null) return false;
      final synced = lastSynced[d.id];
      return synced == null || updated.isAfter(synced);
    }).toList();
    if (stale.isEmpty) return;
    final requests = stale.map(_toRequest).whereType<DaySyncRequest>().toList();
    final results = await ref.read(workoutSchedulerServiceProvider).syncDays(requests);
    await _persistSyncedAt(results, stale);
  }

  Future<List<TrainingDay>> _collectUpcomingDays({required int limit}) async {
    // Read from the existing schedule provider (already fetched + cached).
    // Filter: date >= today, not yet completed, has distance or intervals.
    // Sort by date ascending, take `limit`.
    // … implementation details elided — straightforward provider walk …
  }

  DaySyncRequest? _toRequest(TrainingDay day) {
    // Reuse the existing _buildIntervalPlan logic from
    // training_day_detail_screen.dart — extract it into a top-level
    // helper in workout_scheduler_service.dart so both call sites share.
    // …
  }

  Future<Map<int, DateTime>> _loadLastSynced() async { /* SharedPreferences read */ }
  Future<void> _persistSyncedAt(List<DaySyncResult> results, List<TrainingDay> days) async {
    // For each result where status=='scheduled', store DateTime.now() under dayId.
  }
}
```

**Important refactor**: the `_buildIntervalPlan` helper currently lives inside `training_day_detail_screen.dart` as a private method. Lift it to a top-level function in `workout_scheduler_service.dart` (or a sibling file) so both the manual-button path and the auto-sync path use the exact same payload-shaping logic. No behavior change; just a relocation.

- [ ] **Step 4: Remove `WorkoutScheduleStatus.duplicate` from Dart enum**

After Task 1 Step 3, the native bridge never emits `duplicate`. Drop it from `WorkoutScheduleStatus` and from the switch in `training_day_detail_screen.dart::_sendToWatch`. The success message after a manual press is now always `schedWatchSentTitle` (with body "Workout sent to your Apple Watch via the Fitness app." — no change).

```bash
flutter analyze
flutter test
```

Commit:

```bash
git add app/
git commit -m "feat(watch): WatchSyncService for batched auto-sync

- TrainingDay.updatedAt field (consumes new API timestamp)
- WorkoutSchedulerService.syncDays() batched native call
- WatchSync provider with syncUpcoming() + syncDeltas()
- Last-synced timestamps persisted per dayId in shared_preferences
- WorkoutScheduleStatus.duplicate enum case removed (dead after the
  Swift replace-on-resend change)

No call sites wired yet — that lands in the next commits."
```

---

## Task 5: Wire — proposal accept

**File:** `app/lib/features/coach/providers/coach_proposal_provider.dart` (or wherever the accept call lives — find with `grep -rn "proposals/{id}/accept\|acceptProposal" app/lib`)

- [ ] **Step 1: Add `syncUpcoming()` call after a successful accept**

```dart
Future<void> accept(int proposalId) async {
  final scheduler = ref.read(watchSyncProvider.notifier); // capture before await
  await _api.acceptProposal(proposalId);
  ref.invalidate(scheduleProvider); // existing
  // Fire-and-forget; this is the FIRST time the runner sees the watch
  // permission prompt for this plan. Don't block the navigation.
  unawaited(scheduler.syncUpcoming());
}
```

The capture-before-await pattern matches the project rule in `app/CLAUDE.md` §1b.

- [ ] **Step 2: One-time toast on first successful sync**

Optional but nice: on the first successful `syncUpcoming` (track with a `bool watch_first_sync_shown` in shared_preferences), surface a quiet toast / Cupertino dialog `"Your next 7 workouts are now on your Apple Watch. They'll keep syncing automatically when you change the plan."` — localized via ARB keys `watchAutoSyncToastTitle` / `watchAutoSyncToastBody`.

- [ ] **Step 3: Test**

```bash
flutter test test/features/coach/  # whatever the proposal test path is
```

Commit:

```bash
git add app/
git commit -m "feat(watch): auto-sync next 7 days on plan accept

Replaces the runner-must-remember-per-day Send-to-watch flow with a
one-time batch sync triggered the moment they accept the plan. The
permission prompt now fires in the context of a plan they just chose
to commit to — higher-intent moment than the previous schedule
day-detail screen surface."
```

---

## Task 6: Wire — reschedule day

**File:** `app/lib/features/schedule/widgets/reschedule_day_sheet.dart`

- [ ] **Step 1: Replace the bare `rescheduleIfPresent` with a full re-sync of that day**

Today (`_save`):

```dart
await ref.read(workoutSchedulerServiceProvider).rescheduleIfPresent(
  dayId: widget.day.id,
  newDate: _selected,
);
```

This handles the date-move but if the runner ALSO edited intervals before rescheduling (rare today, common after auto-sync ships), the content on the watch stays stale. Replace with a full re-sync:

```dart
final updatedDay = await ref.read(trainingDayDetailProvider(widget.day.id).future);
await ref.read(watchSyncProvider.notifier).syncUpcoming(limit: 7);
```

`syncUpcoming` already includes the rescheduled day (it sorts by date) and removes-and-replaces under the deterministic UUID — so the old date's entry is wiped and the new date is scheduled with current content. No need for the separate `rescheduleIfPresent` call.

- [ ] **Step 2: Smoke-test on physical device**

1. Schedule a day to watch manually.
2. Reschedule it to a new date.
3. Confirm the Fitness app shows it on the new date, NOT on both.

Commit:

```bash
git add app/
git commit -m "refactor(watch): drop bare rescheduleIfPresent in favour of syncUpcoming

The reschedule sheet's watch-sync was a single-day move via
rescheduleIfPresent. Now it falls under the same batched
syncUpcoming path used by plan-accept + foreground — single code
path for 'make the watch match the current plan'."
```

---

## Task 7: Wire — notification accept (pace adjustment)

**File:** `app/lib/features/notifications/providers/notifications_provider.dart`

- [ ] **Step 1: Add `syncUpcoming` after a successful `accept(id)`**

Pace-adjustment accept applies a pace factor to upcoming days of the matching type — content changes on the server, so the watch needs a re-sync. Pattern matches Task 5.

```dart
Future<void> accept(int id) async {
  final scheduler = ref.read(watchSyncProvider.notifier);
  await _api.accept(id);
  ref.invalidateSelf();
  unawaited(scheduler.syncUpcoming());
}
```

Future notification types that mutate the plan should follow the same pattern. Add a one-liner to the inbox docs in `app/CLAUDE.md` §15 once this ships.

Commit:

```bash
git add app/
git commit -m "feat(watch): auto-sync after pace-adjustment notification accept

Pace adjustments update target pace on multiple upcoming days of the
same type — the watch needs those refreshed too. Hook lives in the
notifications provider so future notification types that mutate the
plan get watch-sync for free if they follow the same pattern."
```

---

## Task 8: Wire — app foreground (delta sync for coach-driven edits)

**File:** `app/lib/features/wearable/widgets/workout_sync_lifecycle.dart`

- [ ] **Step 1: Add a watch-sync trigger to `_maybeSync`**

```dart
void _maybeSync() {
  final auth = ref.read(authProvider);
  final user = auth.value;
  if (user == null) return;
  if (user.hasCompletedOnboarding != true) return;
  unawaited(ref.read(workoutSyncProvider.notifier).sync());
  unawaited(ref.read(permissionsServiceProvider).ensureRequested());
  // NEW: re-sync any days the coach (or anyone with admin access)
  // edited server-side since our last sync. No-op when nothing changed.
  unawaited(ref.read(watchSyncProvider.notifier).syncDeltas());
}
```

- [ ] **Step 2: Make sure `syncDeltas` reads fresh schedule data**

Foreground also invalidates the schedule provider (via `WorkoutSync.sync` above which triggers a new HealthKit pull → server ingest → schedule refresh). Order matters: `syncDeltas` should run AFTER the schedule provider has refreshed, otherwise it'll be reading stale `updated_at`s. Easiest fix: in `WatchSync.syncDeltas()`, kick off with `await ref.read(scheduleProvider.future)` before reading days. Pull-then-decide is cheap and the schedule provider is already cached.

- [ ] **Step 3: Test foreground re-sync**

1. Run dev backend, log in.
2. From Filament admin `/coach`, edit a TrainingDay's distance.
3. Background the app, foreground it.
4. Confirm via Console.app logs that `syncDays` was invoked with that one dayId.
5. Confirm Fitness app shows the new distance.

Commit:

```bash
git add app/
git commit -m "feat(watch): foreground delta sync for coach-driven plan edits

Compares each upcoming day's updated_at vs the locally-stored last-
synced timestamp; re-ships only the days that changed. No-op when
nothing's been edited since the last foreground (the common case).
Closes the gap where a coach modifies a plan while the runner is on
the lock screen and Send-to-watch would otherwise show stale data."
```

---

## Task 9: Tests

**Files:**
- `app/test/features/schedule/services/watch_sync_service_test.dart` (new)
- `api/tests/Feature/Http/TrainingScheduleControllerTest.php` (extend)

- [ ] **Step 1: Backend — `updated_at` round-trip**

Add an assertion to whichever test covers the schedule response shape that `updated_at` is a non-null ISO-8601 string.

- [ ] **Step 2: Flutter — `WatchSync.syncDeltas` only sends stale days**

Mock `WorkoutSchedulerService` with a `verify`-capable stub. Seed three TrainingDays, two with `updatedAt` older than a stored lastSynced, one newer. Call `syncDeltas`, assert the stub was called with exactly the one stale day.

- [ ] **Step 3: Flutter — `WatchSync.syncUpcoming` clamps to limit**

Seed 12 upcoming days. Assert `syncDays` is called with exactly 7 (or whatever default).

- [ ] **Step 4: Run the suite**

```bash
cd /Users/erwinwijnveld/projects/runcoach/app && flutter analyze && flutter test
cd /Users/erwinwijnveld/projects/runcoach/api && php artisan test --compact
```

Commit:

```bash
git add .
git commit -m "test(watch): cover delta + limit logic in WatchSyncService

+ assert TrainingDay JSON carries updated_at server-side."
```

---

## Task 10: Doc updates

**Files:**
- `app/CLAUDE.md` §11 (Send to watch section)
- `CLAUDE.md` (root, "Current state" bullets)

- [ ] **Step 1: Rewrite `app/CLAUDE.md` §11 to describe the auto-sync model**

Replace the per-day-button-centric language with:

```
### 11. Send to watch (WorkoutKit, iOS 17+)

Native MethodChannel bridge nl.runcoach/workout. The watch is kept in
sync automatically — runners no longer have to press a per-day button
before going running.

**Auto-sync triggers (Flutter side, all go through WatchSyncService):**
- Plan accept (coach_proposal_provider) → syncUpcoming(7)
- Reschedule day (reschedule_day_sheet) → syncUpcoming(7)
- Notification accept (notifications_provider) → syncUpcoming(7)
- App foreground (workout_sync_lifecycle) → syncDeltas() — only days
  whose updated_at is newer than the locally-stored lastSyncedAt

**Native methods:**
- syncDays (batch, iOS 17.4+) — used by WatchSyncService
- scheduleRun / scheduleIntervals (per-day, manual button) — kept as
  force-resync; always replaces under deterministic UUID
- rescheduleIfPresent — DEPRECATED, callsites migrated to syncUpcoming

**Permission UX:** the prompt fires inside syncUpcoming the first
time the runner accepts a plan. Earlier surfaces (the manual button)
still trigger it too if they get there first.

**iOS 17.0-17.3 fallback:** identity tracking unavailable — auto-sync
is a no-op (would otherwise create duplicate entries). Manual button
still works.

[…rest of existing section unchanged — interval rules, pbxproj
entries, simulator caveat…]
```

- [ ] **Step 2: Add a one-liner to the root `CLAUDE.md` "Current state" list**

```
- **Watch auto-sync** — accepting a plan ships the next 7 days to the
  Apple Watch in one batch (Swift `syncDays` via deterministic UUID).
  Foreground re-sync only re-ships days the coach edited since the
  last sync. Manual "Send to watch" button kept as force-resync,
  duplicate-prompt removed. Plan:
  `docs/superpowers/plans/2026-05-19-watch-auto-sync.md`.
```

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md app/CLAUDE.md
git commit -m "docs: watch auto-sync model + force-resync button"
```

---

## Out of scope (intentionally deferred)

- **Weekly Sunday-evening "your week is on your watch" push.** Originally floated by the user but redundant once accept-time and foreground sync cover the gaps. If runners report "I forgot my watch had this week's plan" we can add a push pointing at the Fitness app — quick win on top of this foundation.
- **Watch clutter management** (only ship next 3 days instead of 7). Empirically tune after a week of TestFlight feedback; the 7-day default lines up with the schedule UI's weekly view.
- **Background-delivery for HealthKit + foreground-sync coupling.** Already on the deferred-polish list in the root CLAUDE.md; not blocking this.
- **Android.** WatchSyncService gates on `Platform.isIOS` and is a no-op on Android (and web) until HealthConnect's analog ships. Code path stays compile-safe.

---

## Rollout checklist

- [ ] Bump `pubspec.yaml` version (`+N` build number)
- [ ] `bash app/scripts/build-ios.sh`
- [ ] `bash app/scripts/upload-ios.sh` (TestFlight)
- [ ] Smoke-test on a real iPhone with a paired Apple Watch:
  - Accept a fresh plan → check Fitness app's Scheduled list
  - Reschedule a day → confirm move + content correct
  - Coach-edit a day via Filament → background app → foreground → confirm only that day updated
  - Tap manual Send-to-watch on an unchanged day → confirm `scheduled` not `duplicate`
