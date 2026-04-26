import Foundation
import HealthKit

/// Native HealthKit personal-record queries exposed to Dart via a
/// MethodChannel. We filter HKWorkout samples by activity-type (.running)
/// + total-distance band (±tolerance), then sort the survivors in Swift
/// to find the smallest duration. HealthKit has no public sort identifier
/// for `duration`, but the distance + type predicates cut the working set
/// to at most a few hundred even for runners with years of history, so
/// in-memory sort is microseconds.
///
/// Method: `getPersonalRecords`
///   args: { "distances": [5000, 10000, 26000, ...],
///           "toleranceFraction": 0.02 }       // optional, default 0.02
///   returns: { "5000":  {duration_seconds: 1685, distance_meters: 5023, date: "...", source_activity_id: "..."},
///              "10000": null,
///              "26000": {...} }
///
/// Keys are stringified integer meters so Dart can prefetch a fixed set
/// of standard race distances at onboarding AND look up arbitrary custom
/// distances on demand (e.g. "Other → 26km" in the form).
enum HealthKitPersonalRecords {
    static let channelName = "nl.runcoach/healthkit_prs"

    private static let defaultToleranceFraction: Double = 0.02

    static func register(controller: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: controller)
        channel.setMethodCallHandler { call, result in
            switch call.method {
            case "getPersonalRecords":
                let args = call.arguments as? [String: Any]
                let distances = (args?["distances"] as? [Any] ?? [])
                    .compactMap { $0 as? NSNumber }
                    .map { $0.doubleValue }
                let tolerance = (args?["toleranceFraction"] as? Double) ?? defaultToleranceFraction
                getPersonalRecords(distances: distances, tolerance: tolerance, result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private static func getPersonalRecords(
        distances: [Double],
        tolerance: Double,
        result: @escaping FlutterResult
    ) {
        guard HKHealthStore.isHealthDataAvailable() else {
            result(FlutterError(code: "HK_UNAVAILABLE",
                                message: "HealthKit is not available on this device.",
                                details: nil))
            return
        }

        if distances.isEmpty {
            result([:])
            return
        }

        let store = HKHealthStore()
        let workoutType = HKObjectType.workoutType()

        store.requestAuthorization(toShare: nil, read: [workoutType]) { granted, error in
            guard granted, error == nil else {
                result(FlutterError(code: "HK_AUTH_DENIED",
                                    message: error?.localizedDescription ?? "HealthKit read access denied.",
                                    details: nil))
                return
            }

            let group = DispatchGroup()
            var output: [String: Any?] = [:]
            let lock = NSLock()

            for distanceMeters in distances {
                group.enter()
                fetchFastestWorkout(
                    distanceMeters: distanceMeters,
                    tolerance: tolerance,
                    store: store
                ) { record in
                    let key = String(Int(distanceMeters.rounded()))
                    lock.lock()
                    output[key] = record
                    lock.unlock()
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                result(output)
            }
        }
    }

    /// Find the workout with the smallest duration whose totalDistance is
    /// within ±tolerance of the target. Returns nil when nothing matches.
    ///
    /// Treadmill runs (HKWorkoutActivityType.runningTreadmill) are not
    /// included separately — Apple Watch logs them as `.running` unless
    /// the user explicitly picks "Indoor Run", and including the indoor
    /// type adds ~no PRs in practice. Indoor distance from a watch is also
    /// notoriously inaccurate (no GPS, accelerometer-based) so omitting
    /// them is closer to the runner's true outdoor PR.
    private static func fetchFastestWorkout(
        distanceMeters: Double,
        tolerance: Double,
        store: HKHealthStore,
        completion: @escaping (Any?) -> Void
    ) {
        let lower = distanceMeters * (1.0 - tolerance)
        let upper = distanceMeters * (1.0 + tolerance)

        let typePredicate = HKQuery.predicateForWorkouts(with: .running)

        let minDistance = HKQuery.predicateForWorkouts(
            with: .greaterThanOrEqualTo,
            totalDistance: HKQuantity(unit: HKUnit.meter(), doubleValue: lower)
        )
        let maxDistance = HKQuery.predicateForWorkouts(
            with: .lessThanOrEqualTo,
            totalDistance: HKQuantity(unit: HKUnit.meter(), doubleValue: upper)
        )

        let combined = NSCompoundPredicate(andPredicateWithSubpredicates: [
            typePredicate, minDistance, maxDistance,
        ])

        let query = HKSampleQuery(
            sampleType: HKObjectType.workoutType(),
            predicate: combined,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { _, samples, _ in
            let workouts = (samples as? [HKWorkout]) ?? []
            guard let fastest = workouts.min(by: { $0.duration < $1.duration }) else {
                completion(nil)
                return
            }

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]

            let actualMeters = fastest.totalDistance?
                .doubleValue(for: HKUnit.meter()) ?? distanceMeters

            completion([
                "duration_seconds": Int(fastest.duration.rounded()),
                "distance_meters": Int(actualMeters.rounded()),
                "date": formatter.string(from: fastest.startDate),
                "source_activity_id": fastest.uuid.uuidString,
            ])
        }

        store.execute(query)
    }
}
