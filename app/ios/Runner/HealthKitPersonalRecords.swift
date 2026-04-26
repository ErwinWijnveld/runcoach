import Foundation
import HealthKit

/// Native HealthKit personal-record queries exposed to Dart via a
/// MethodChannel. Apple's `HKSampleQuery` with `predicateForWorkouts(
/// operatorType:totalDistance:)` runs server-side in HealthKit's SQLite
/// store with proper indexes — finding the fastest 5k across years of
/// history takes ~milliseconds, vs hundreds of milliseconds (and a lot
/// of memory) when pulling every workout into Dart and sorting there.
///
/// One method: `getPersonalRecords` returns a map keyed by distance code:
///   {
///     "5k":       {"duration_seconds": 1685, "date": "2024-09-12T..."},
///     "10k":      {"duration_seconds": 3620, "date": "2025-03-04T..."},
///     "half":     null,                      // no qualifying workout
///     "marathon": null,
///   }
///
/// Tolerances: ±2% of target distance to allow GPS slop without admitting
/// e.g. a 4.6km run into the 5k bucket. Both `.running` and
/// `.runningTreadmill` count.
enum HealthKitPersonalRecords {
    static let channelName = "nl.runcoach/healthkit_prs"

    private struct Distance {
        let key: String
        let meters: Double
    }

    private static let distances: [Distance] = [
        .init(key: "5k",        meters: 5000),
        .init(key: "10k",       meters: 10000),
        .init(key: "half",      meters: 21097.5),
        .init(key: "marathon",  meters: 42195),
    ]

    private static let toleranceFraction: Double = 0.02

    static func register(controller: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: controller)
        channel.setMethodCallHandler { call, result in
            switch call.method {
            case "getPersonalRecords":
                getPersonalRecords(result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private static func getPersonalRecords(result: @escaping FlutterResult) {
        guard HKHealthStore.isHealthDataAvailable() else {
            result(FlutterError(code: "HK_UNAVAILABLE",
                                message: "HealthKit is not available on this device.",
                                details: nil))
            return
        }

        let store = HKHealthStore()
        let workoutType = HKObjectType.workoutType()

        // Authorization: read-only on workouts. The earlier Dart-side
        // requestAuthorization already prompted; this is a safety net so
        // queries don't silently return empty when called before that path.
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

            for distance in distances {
                group.enter()
                fetchFastestWorkout(at: distance, store: store) { record in
                    lock.lock()
                    output[distance.key] = record
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
    /// within ±toleranceFraction of `distance.meters`. Both `.running` and
    /// `.runningTreadmill` qualify. Returns nil when no workout matches.
    private static func fetchFastestWorkout(
        at distance: Distance,
        store: HKHealthStore,
        completion: @escaping (Any?) -> Void
    ) {
        let lower = distance.meters * (1.0 - toleranceFraction)
        let upper = distance.meters * (1.0 + toleranceFraction)

        let runningPredicate = HKQuery.predicateForWorkouts(with: .running)
        var typePredicates: [NSPredicate] = [runningPredicate]
        if #available(iOS 14.0, *) {
            typePredicates.append(HKQuery.predicateForWorkouts(with: .runningTreadmill))
        }
        let typeOr = NSCompoundPredicate(orPredicateWithSubpredicates: typePredicates)

        let minDistance = HKQuery.predicateForWorkouts(
            operatorType: .greaterThanOrEqualTo,
            totalDistance: HKQuantity(unit: HKUnit.meter(), doubleValue: lower)
        )
        let maxDistance = HKQuery.predicateForWorkouts(
            operatorType: .lessThanOrEqualTo,
            totalDistance: HKQuantity(unit: HKUnit.meter(), doubleValue: upper)
        )

        let combined = NSCompoundPredicate(andPredicateWithSubpredicates: [
            typeOr, minDistance, maxDistance,
        ])

        let sort = NSSortDescriptor(key: HKSampleSortIdentifierDuration, ascending: true)

        let query = HKSampleQuery(
            sampleType: HKObjectType.workoutType(),
            predicate: combined,
            limit: 1,
            sortDescriptors: [sort]
        ) { _, samples, _ in
            guard let workout = samples?.first as? HKWorkout else {
                completion(nil)
                return
            }

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]

            let actualMeters = workout.totalDistance?
                .doubleValue(for: HKUnit.meter()) ?? distance.meters

            completion([
                "duration_seconds": Int(workout.duration.rounded()),
                "distance_meters": Int(actualMeters.rounded()),
                "date": formatter.string(from: workout.startDate),
                "source_activity_id": workout.uuid.uuidString,
            ])
        }

        store.execute(query)
    }
}
