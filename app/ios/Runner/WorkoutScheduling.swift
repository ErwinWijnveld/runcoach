import Foundation
import HealthKit
#if canImport(WorkoutKit)
import WorkoutKit
#endif

/// Native bridge that schedules a planned outdoor running workout in the
/// Fitness app. The workout shows up on the user's iPhone Fitness app for
/// that day and syncs to the paired Apple Watch automatically.
///
/// Identity tracking (iOS 17.4+):
/// Every TrainingDay has a deterministic UUID derived from its DB id. We
/// pass this UUID as `WorkoutPlan.id`, which lets the bridge:
///   - de-dup ONLY against itself (multiple non-RunCoach workouts on the
///     same day are allowed; sending the same TrainingDay twice on the same
///     date is the only "duplicate"),
///   - find and replace its own scheduled workout when a TrainingDay's date
///     changes (`rescheduleIfPresent`).
///
/// On iOS 17.0–17.3 (no custom IDs available), we fall back to "always
/// schedule, no de-dup" — multiple sends per day end up as multiple watch
/// entries until the user prunes them in the Fitness app.
///
/// Methods:
///
///   `scheduleRun`  — single-goal distance run (no intervals).
///     args: { "date": "YYYY-MM-DD", "distanceKm": 6.0, "dayId": 48 }
///
///   `scheduleIntervals` — interval session (CustomWorkout).
///     args: {
///       "date": "YYYY-MM-DD",
///       "dayId": 48,
///       "displayName": "6×800m",
///       "warmupSeconds": 60,         // optional, null = no warmup
///       "cooldownSeconds": 300,      // optional, null = no cooldown
///       "steps": [
///         { "kind": "work", "distanceM": 800, "durationSeconds": null },
///         { "kind": "recovery", "distanceM": null, "durationSeconds": 90 },
///         …
///       ]
///     }
///
///   `rescheduleIfPresent` — fire-and-forget; moves an already-scheduled
///   watch workout to a new date if (and only if) we previously scheduled
///   it. Silent no-op when nothing was scheduled.
///     args: { "date": "YYYY-MM-DD", "dayId": 48 }
///
/// All methods return: { "status": "scheduled" | "duplicate" | "denied" |
///                                 "unavailable" | "failed" | "moved" |
///                                 "skipped",
///                       "message": String? }
///
/// Requires iOS 17.0+ for scheduling, iOS 17.4+ for identity tracking +
/// reschedule. Falls back to `status=unavailable` on older OSes.
enum WorkoutScheduling {
    static let channelName = "nl.runcoach/workout"

    static func register(controller: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: controller)
        channel.setMethodCallHandler { call, result in
            switch call.method {
            case "scheduleRun":
                let args = call.arguments as? [String: Any] ?? [:]
                scheduleRun(args: args, result: result)
            case "scheduleIntervals":
                let args = call.arguments as? [String: Any] ?? [:]
                scheduleIntervals(args: args, result: result)
            case "rescheduleIfPresent":
                let args = call.arguments as? [String: Any] ?? [:]
                rescheduleIfPresent(args: args, result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    // MARK: - Single goal (basic run)

    private static func scheduleRun(args: [String: Any], result: @escaping FlutterResult) {
        if #available(iOS 17.0, *) {
            Task { @MainActor in
                await scheduleRunIOS17(args: args, result: result)
            }
        } else {
            result(unavailableResponse())
        }
    }

    @available(iOS 17.0, *)
    private static func scheduleRunIOS17(args: [String: Any], result: @escaping FlutterResult) async {
        let dateString = (args["date"] as? String) ?? ""
        let distanceKm = (args["distanceKm"] as? NSNumber)?.doubleValue ?? 0.0
        let dayId = (args["dayId"] as? NSNumber)?.intValue

        guard let components = parseDate(dateString) else {
            result(failedResponse("Invalid date format (expected YYYY-MM-DD)."))
            return
        }
        guard distanceKm > 0 else {
            result(failedResponse("This workout has no distance set, so it can't be sent to the watch."))
            return
        }

        guard await ensureAuthorized(result: result) else { return }

        // Identity dedup: if our specific TrainingDay is already scheduled
        // somewhere, replace it (or no-op if same date).
        switch await ensureNoExistingForDay(dayId: dayId, at: components) {
        case .duplicate:
            result(duplicateResponse())
            return
        case .conflict:
            // We can't reach here today (replaceExistingForDay never returns
            // .conflict) but kept exhaustive for future tweaks.
            return
        case .ok:
            break
        }

        let goal = WorkoutGoal.distance(distanceKm, UnitLength.kilometers)
        let workout = SingleGoalWorkout(
            activity: .running,
            location: .outdoor,
            goal: goal
        )
        let plan = buildPlan(.goal(workout), dayId: dayId)
        await commitSchedule(plan: plan, at: components, result: result)
    }

    // MARK: - Custom workout (intervals)

    private static func scheduleIntervals(args: [String: Any], result: @escaping FlutterResult) {
        if #available(iOS 17.0, *) {
            Task { @MainActor in
                await scheduleIntervalsIOS17(args: args, result: result)
            }
        } else {
            result(unavailableResponse())
        }
    }

    @available(iOS 17.0, *)
    private static func scheduleIntervalsIOS17(args: [String: Any], result: @escaping FlutterResult) async {
        let dateString = (args["date"] as? String) ?? ""
        let dayId = (args["dayId"] as? NSNumber)?.intValue

        guard let components = parseDate(dateString) else {
            result(failedResponse("Invalid date format (expected YYYY-MM-DD)."))
            return
        }

        let displayName = args["displayName"] as? String
        let warmupSeconds = (args["warmupSeconds"] as? NSNumber)?.intValue
        let cooldownSeconds = (args["cooldownSeconds"] as? NSNumber)?.intValue
        let rawSteps = args["steps"] as? [[String: Any]] ?? []

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

        guard !intervalSteps.isEmpty else {
            result(failedResponse("This interval session has no reps to send."))
            return
        }

        guard await ensureAuthorized(result: result) else { return }

        switch await ensureNoExistingForDay(dayId: dayId, at: components) {
        case .duplicate:
            result(duplicateResponse())
            return
        case .conflict:
            return
        case .ok:
            break
        }

        let warmupStep: WorkoutStep? = {
            guard let secs = warmupSeconds, secs > 0 else { return nil }
            return WorkoutStep(goal: .time(Double(secs), .seconds))
        }()

        let cooldownStep: WorkoutStep? = {
            guard let secs = cooldownSeconds, secs > 0 else { return nil }
            return WorkoutStep(goal: .time(Double(secs), .seconds))
        }()

        let block = IntervalBlock(steps: intervalSteps, iterations: 1)

        let workout = CustomWorkout(
            activity: .running,
            location: .outdoor,
            displayName: displayName,
            warmup: warmupStep,
            blocks: [block],
            cooldown: cooldownStep
        )
        let plan = buildPlan(.custom(workout), dayId: dayId)
        await commitSchedule(plan: plan, at: components, result: result)
    }

    // MARK: - Reschedule helper

    /// Fire-and-forget watch sync. If we previously scheduled this dayId on
    /// the watch, move it to the new date. Otherwise no-op. Never fails the
    /// caller — the watch state is best-effort, the source of truth is the
    /// app DB.
    private static func rescheduleIfPresent(args: [String: Any], result: @escaping FlutterResult) {
        guard #available(iOS 17.4, *) else {
            // Identity tracking unavailable on iOS 17.0–17.3; nothing to do.
            result(["status": "skipped"])
            return
        }
        Task { @MainActor in
            await rescheduleIfPresentIOS174(args: args, result: result)
        }
    }

    @available(iOS 17.4, *)
    private static func rescheduleIfPresentIOS174(args: [String: Any], result: @escaping FlutterResult) async {
        let dateString = (args["date"] as? String) ?? ""
        let dayId = (args["dayId"] as? NSNumber)?.intValue ?? 0

        guard dayId > 0, let components = parseDate(dateString) else {
            result(["status": "skipped"])
            return
        }

        let scheduler = WorkoutScheduler.shared
        // We deliberately DON'T request authorization here — this runs after
        // a successful reschedule and we don't want to surprise the user with
        // a permission prompt for a watch sync they didn't initiate.
        let authState = await scheduler.authorizationState
        guard authState == .authorized else {
            result(["status": "skipped"])
            return
        }

        let dayUUID = uuidForDay(dayId)
        let existing = await scheduler.scheduledWorkouts
        guard let our = existing.first(where: { $0.plan.id == dayUUID }) else {
            // Wasn't on the watch — nothing to move.
            result(["status": "skipped"])
            return
        }

        // Already on the right date? No-op.
        if our.date.year == components.year &&
            our.date.month == components.month &&
            our.date.day == components.day {
            result(["status": "skipped"])
            return
        }

        // Two-step move with rollback. If schedule-at-new-date fails after
        // remove succeeded, attempt to restore at the original date so the
        // watch isn't left empty. Any rollback error is swallowed — at that
        // point we've exhausted reasonable options and the user can manually
        // re-send via Send-to-watch.
        do {
            try await scheduler.remove(our.plan, at: our.date)
        } catch {
            result([
                "status": "failed",
                "message": "Couldn't move the watch workout: \(error.localizedDescription)"
            ])
            return
        }

        do {
            try await scheduler.schedule(our.plan, at: components)
            result(["status": "moved"])
        } catch {
            try? await scheduler.schedule(our.plan, at: our.date)
            result([
                "status": "failed",
                "message": "Couldn't move the watch workout: \(error.localizedDescription)"
            ])
        }
    }

    // MARK: - Identity helpers (iOS 17.4+)

    /// Deterministic UUID derived from the TrainingDay primary key. Format:
    /// `00000000-0000-0000-0000-{dayId as 12-char hex}`. Stable across app
    /// launches as long as the DB id doesn't change. The dayId is masked to
    /// 48 bits so the hex always fits exactly 12 chars — without the mask a
    /// large `Int` would expand `%llx` past 12 chars and the UUID parse
    /// would fail (silently falling back to a random UUID, defeating
    /// identity tracking).
    @available(iOS 17.4, *)
    private static func uuidForDay(_ dayId: Int) -> UUID {
        let masked = UInt64(max(0, dayId)) & 0x0000_FFFF_FFFF_FFFF
        let hex = String(format: "%012llx", masked)
        return UUID(uuidString: "00000000-0000-0000-0000-\(hex)") ?? UUID()
    }

    @available(iOS 17.0, *)
    private static func buildPlan(_ workout: WorkoutPlan.Workout, dayId: Int?) -> WorkoutPlan {
        if #available(iOS 17.4, *), let dayId, dayId > 0 {
            return WorkoutPlan(workout, id: uuidForDay(dayId))
        }
        return WorkoutPlan(workout)
    }

    private enum ExistingCheckResult {
        case ok           // proceed with scheduling
        case duplicate    // our workout already at this date — return duplicate
        case conflict     // reserved for future use
    }

    /// Identity-aware pre-flight: if our TrainingDay is already scheduled at
    /// a DIFFERENT date, remove it (caller will then schedule fresh at the
    /// new date). If it's at the SAME date, return `.duplicate` so the
    /// caller bails. On iOS < 17.4 (no IDs), always returns `.ok` —
    /// scheduling is unrestricted.
    @available(iOS 17.0, *)
    private static func ensureNoExistingForDay(
        dayId: Int?,
        at components: DateComponents
    ) async -> ExistingCheckResult {
        guard #available(iOS 17.4, *), let dayId, dayId > 0 else {
            return .ok
        }
        let dayUUID = uuidForDay(dayId)
        let scheduler = WorkoutScheduler.shared
        let existing = await scheduler.scheduledWorkouts
        guard let our = existing.first(where: { $0.plan.id == dayUUID }) else {
            return .ok
        }
        let sameDate = our.date.year == components.year &&
            our.date.month == components.month &&
            our.date.day == components.day
        if sameDate {
            return .duplicate
        }
        // Different date — remove the stale entry so we can schedule fresh.
        do {
            try await scheduler.remove(our.plan, at: our.date)
        } catch {
            // If remove fails we could end up with two entries; keep going.
            // The verify-after-schedule pass will at least confirm one exists.
        }
        return .ok
    }

    // MARK: - Shared helpers

    @available(iOS 17.0, *)
    private static func ensureAuthorized(result: @escaping FlutterResult) async -> Bool {
        let scheduler = WorkoutScheduler.shared
        var authState = await scheduler.authorizationState
        if authState == .notDetermined {
            authState = await scheduler.requestAuthorization()
        }
        guard authState == .authorized else {
            result([
                "status": "denied",
                "message": "RunCoach needs permission to schedule workouts. Enable it in Settings → RunCoach."
            ])
            return false
        }
        return true
    }

    @available(iOS 17.0, *)
    private static func commitSchedule(
        plan: WorkoutPlan,
        at components: DateComponents,
        result: @escaping FlutterResult
    ) async {
        let scheduler = WorkoutScheduler.shared

        // `schedule(_:at:)` is non-throwing on iOS 17 but `async throws` on
        // iOS 18+. Wrap in do/try/catch so the build works against any SDK
        // ≥ iOS 17 and any thrown error becomes a friendly failed response.
        do {
            try await scheduler.schedule(plan, at: components)
        } catch {
            result(failedResponse("Couldn't schedule the workout: \(error.localizedDescription)"))
            return
        }

        // schedule() doesn't return a status; verify by re-reading
        // scheduledWorkouts and confirming OUR specific plan landed at the
        // requested date. Identity check (`plan.id`) prevents a false
        // positive when an unrelated workout from another app already sat
        // on the same calendar day. `WorkoutPlan.id` is read-accessible from
        // iOS 17.0 (only the custom-id init was added in 17.4), so this
        // works on every supported version.
        let after = await scheduler.scheduledWorkouts
        let scheduledId = plan.id
        let landed = after.contains { entry in
            entry.plan.id == scheduledId &&
            entry.date.year == components.year &&
            entry.date.month == components.month &&
            entry.date.day == components.day
        }
        if landed {
            result([
                "status": "scheduled",
                "message": "Workout sent to your Apple Watch via the Fitness app."
            ])
        } else {
            result(failedResponse("The workout was rejected by the Fitness app. Try again from a real device."))
        }
    }

    @available(iOS 17.0, *)
    private static func buildGoal(distanceM: Double?, durationSeconds: Int?) -> WorkoutGoal? {
        if let m = distanceM, m > 0 {
            return .distance(m, UnitLength.meters)
        }
        if let s = durationSeconds, s > 0 {
            return .time(Double(s), .seconds)
        }
        return nil
    }

    private static func parseDate(_ dateString: String) -> DateComponents? {
        let parts = dateString.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        var components = DateComponents()
        components.year = parts[0]
        components.month = parts[1]
        components.day = parts[2]
        components.hour = 7
        components.minute = 0
        return components
    }

    private static func unavailableResponse() -> [String: String] {
        return [
            "status": "unavailable",
            "message": "Sending workouts to your watch needs iOS 17 or newer."
        ]
    }

    private static func duplicateResponse() -> [String: String] {
        return [
            "status": "duplicate",
            "message": "This workout is already on your watch for this day."
        ]
    }

    private static func failedResponse(_ message: String) -> [String: String] {
        return ["status": "failed", "message": message]
    }
}
