import Foundation
import HealthKit

/// Background auto-sync of newly-finished runs from Apple Health.
///
/// When a run finishes and the Apple Watch syncs it into the iPhone
/// Health store, iOS wakes the app via an `HKObserverQuery` (background
/// delivery, `.immediate` for workouts). We fetch only the NEW runs via
/// an anchored query and POST them to the existing
/// `POST /wearable/activities` endpoint — in Swift, because the
/// Flutter/Dart engine is not running on a background launch.
///
/// Downstream is unchanged: the backend matches, scores, runs the AI
/// analysis (Pro-gated) and sends the existing `WorkoutAnalyzed` push.
/// The Flutter foreground sync (`WorkoutSyncLifecycle`) remains the
/// guaranteed fallback (e.g. after the user force-quits the app, which
/// suspends background delivery until the next manual launch).
///
/// Config: Dart pushes `{baseUrl, token}` down via the `nl.runcoach/bg-sync`
/// MethodChannel (`configure`) on login/cold-start, and `clear` on logout.
/// `baseUrl` → UserDefaults; `token` → Keychain (readable after first
/// unlock so a locked-device background wake can still authenticate). The
/// observer is (re)armed on every app launch from `AppDelegate`, as the
/// HealthKit background-delivery contract requires — observers don't
/// survive launches.
final class HealthKitBackgroundSync: NSObject {
    static let shared = HealthKitBackgroundSync()
    static let channelName = "nl.runcoach/bg-sync"

    private let store = HKHealthStore()
    private var observerQuery: HKObserverQuery?

    private let kBaseUrl = "bg_sync_base_url"
    private let kAnchor = "bg_sync_workout_anchor_v1"
    private let keychainService = "nl.runcoach.bgsync"
    private let keychainAccount = "sanctum_token"

    private lazy var iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    private override init() { super.init() }

    // MARK: - MethodChannel (nl.runcoach/bg-sync)

    func register(controller: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: controller)
        channel.setMethodCallHandler { [weak self] call, result in
            guard let self else { result(nil); return }
            switch call.method {
            case "configure":
                let args = call.arguments as? [String: Any] ?? [:]
                if let baseUrl = args["baseUrl"] as? String,
                   let token = args["token"] as? String,
                   !baseUrl.isEmpty, !token.isEmpty {
                    UserDefaults.standard.set(baseUrl, forKey: self.kBaseUrl)
                    self.storeToken(token)
                    self.start()
                }
                result(nil)
            case "clear":
                self.deleteToken()
                self.stop()
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    // MARK: - Observer lifecycle

    /// Arms (or re-arms) the workout observer + background delivery. Safe
    /// to call repeatedly: no-op without HealthKit / without configured
    /// credentials, and never stacks duplicate observers.
    func start() {
        guard HKHealthStore.isHealthDataAvailable(), loadToken() != nil else { return }

        let workoutType = HKObjectType.workoutType()
        var readTypes: Set<HKObjectType> = [workoutType]
        if let hr = HKObjectType.quantityType(forIdentifier: .heartRate) {
            readTypes.insert(hr)
        }

        store.requestAuthorization(toShare: nil, read: readTypes) { [weak self] granted, _ in
            guard let self, granted else { return }
            self.armObserver(workoutType: workoutType)
        }
    }

    /// Tears down the observer + background delivery and resets the anchor
    /// so a future login re-primes cleanly. Called on logout.
    func stop() {
        if let existing = observerQuery {
            store.stop(existing)
            observerQuery = nil
        }
        store.disableBackgroundDelivery(for: HKObjectType.workoutType()) { _, _ in }
        UserDefaults.standard.removeObject(forKey: kAnchor)
    }

    private func armObserver(workoutType: HKSampleType) {
        if let existing = observerQuery {
            store.stop(existing)
            observerQuery = nil
        }

        let query = HKObserverQuery(sampleType: workoutType, predicate: nil) {
            [weak self] _, completionHandler, error in
            guard let self, error == nil else { completionHandler(); return }
            self.handleUpdate(completionHandler)
        }
        observerQuery = query
        store.execute(query)
        store.enableBackgroundDelivery(for: workoutType, frequency: .immediate) { _, _ in }
    }

    // MARK: - Sync

    private func handleUpdate(_ completionHandler: @escaping HKObserverQueryCompletionHandler) {
        guard let token = loadToken(),
              let baseUrl = UserDefaults.standard.string(forKey: kBaseUrl),
              !token.isEmpty, !baseUrl.isEmpty else {
            completionHandler()
            return
        }

        // `.running` covers both outdoor and treadmill/indoor runs (indoor
        // runs are `.running` + the indoor-workout metadata flag, not a
        // separate activity type), matching `_normalizeType` on the Dart side.
        let predicate = HKQuery.predicateForWorkouts(with: .running)

        // First run (no anchor): record a baseline so the background path
        // never replays historical runs — the foreground sync owns history.
        guard let anchor = loadAnchor() else {
            primeAnchor(predicate: predicate, completionHandler: completionHandler)
            return
        }

        let query = HKAnchoredObjectQuery(
            type: .workoutType(),
            predicate: predicate,
            anchor: anchor,
            limit: 50
        ) { [weak self] _, samples, _, newAnchor, _ in
            guard let self else { completionHandler(); return }

            let workouts = (samples as? [HKWorkout])?.filter {
                self.workoutDistanceMeters($0) > 0
            } ?? []

            guard !workouts.isEmpty else {
                if let newAnchor { self.saveAnchor(newAnchor) }
                completionHandler()
                return
            }

            self.buildPayloads(workouts) { activities in
                self.post(baseUrl: baseUrl, token: token, activities: activities) { ok in
                    // Only advance the anchor on success, so a failed POST
                    // is retried on the next wake instead of being skipped.
                    if ok, let newAnchor { self.saveAnchor(newAnchor) }
                    completionHandler()
                }
            }
        }
        store.execute(query)
    }

    private func primeAnchor(
        predicate: NSPredicate,
        completionHandler: @escaping HKObserverQueryCompletionHandler
    ) {
        let query = HKAnchoredObjectQuery(
            type: .workoutType(),
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, _, _, newAnchor, _ in
            if let newAnchor { self?.saveAnchor(newAnchor) }
            completionHandler()
        }
        store.execute(query)
    }

    /// Build the POST payload per workout, mirroring the Dart `_shape()` in
    /// `health_kit_service.dart` so the existing backend validation passes
    /// unchanged. HR (avg/max) is workout-scoped via `predicateForObjects`.
    private func buildPayloads(
        _ workouts: [HKWorkout],
        completion: @escaping ([[String: Any]]) -> Void
    ) {
        let group = DispatchGroup()
        let lock = NSLock()
        var result: [[String: Any]] = []

        for workout in workouts {
            group.enter()
            fetchHeartRate(for: workout) { avg, max in
                // Wall-clock elapsed (end − start) to match the Dart shape,
                // which uses the same and not HKWorkout.duration (excludes pauses).
                let seconds = Int(workout.endDate.timeIntervalSince(workout.startDate).rounded())
                var item: [String: Any] = [
                    "source": "apple_health",
                    "source_activity_id": workout.uuid.uuidString,
                    "source_user_id": workout.sourceRevision.source.bundleIdentifier,
                    "type": "Run",
                    "name": NSNull(),
                    "distance_meters": Int(self.workoutDistanceMeters(workout).rounded()),
                    "duration_seconds": seconds,
                    "elapsed_seconds": seconds,
                    "start_date": self.iso8601.string(from: workout.startDate),
                    "end_date": self.iso8601.string(from: workout.endDate),
                    "calories_kcal": Int(self.workoutEnergyKcal(workout).rounded()),
                    "raw_data": [String: Any](),
                ]
                if let avg { item["average_heartrate"] = avg }
                if let max { item["max_heartrate"] = max }

                lock.lock()
                result.append(item)
                lock.unlock()
                group.leave()
            }
        }

        group.notify(queue: .global(qos: .userInitiated)) { completion(result) }
    }

    /// Total distance via `statistics(for:)` (the non-deprecated path that
    /// replaces `HKWorkout.totalDistance`).
    private func workoutDistanceMeters(_ workout: HKWorkout) -> Double {
        guard let type = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            return 0
        }
        return workout.statistics(for: type)?.sumQuantity()?.doubleValue(for: .meter()) ?? 0
    }

    /// Active energy via `statistics(for:)` (replaces `HKWorkout.totalEnergyBurned`).
    private func workoutEnergyKcal(_ workout: HKWorkout) -> Double {
        guard let type = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return 0
        }
        return workout.statistics(for: type)?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
    }

    private func fetchHeartRate(
        for workout: HKWorkout,
        completion: @escaping (Double?, Double?) -> Void
    ) {
        guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            completion(nil, nil)
            return
        }
        let predicate = HKQuery.predicateForObjects(from: workout)
        let query = HKStatisticsQuery(
            quantityType: hrType,
            quantitySamplePredicate: predicate,
            options: [.discreteAverage, .discreteMax]
        ) { _, stats, _ in
            let unit = HKUnit.count().unitDivided(by: .minute())
            // Same 30–250 bpm sanity clamp as _fetchHeartRateForWorkout.
            func clamp(_ v: Double?) -> Double? {
                guard let v, v >= 30, v <= 250 else { return nil }
                return v
            }
            let avg = clamp(stats?.averageQuantity()?.doubleValue(for: unit))
            let max = clamp(stats?.maximumQuantity()?.doubleValue(for: unit))
            completion(avg, max)
        }
        store.execute(query)
    }

    private func post(
        baseUrl: String,
        token: String,
        activities: [[String: Any]],
        completion: @escaping (Bool) -> Void
    ) {
        guard let url = URL(string: baseUrl + "/wearable/activities") else {
            completion(false)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: ["activities": activities])
        } catch {
            completion(false)
            return
        }
        URLSession.shared.dataTask(with: request) { _, response, error in
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            completion(error == nil && (200...299).contains(code))
        }.resume()
    }

    // MARK: - Anchor persistence

    private func loadAnchor() -> HKQueryAnchor? {
        guard let data = UserDefaults.standard.data(forKey: kAnchor) else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data)
    }

    private func saveAnchor(_ anchor: HKQueryAnchor) {
        guard let data = try? NSKeyedArchiver.archivedData(
            withRootObject: anchor, requiringSecureCoding: true
        ) else { return }
        UserDefaults.standard.set(data, forKey: kAnchor)
    }

    // MARK: - Keychain (bearer token)

    private func storeToken(_ token: String) {
        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
        ]
        SecItemDelete(base as CFDictionary)
        var add = base
        add[kSecValueData as String] = Data(token.utf8)
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(add as CFDictionary, nil)
    }

    private func loadToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func deleteToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
