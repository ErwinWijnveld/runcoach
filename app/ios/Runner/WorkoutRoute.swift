import CoreLocation
import Foundation
import HealthKit

/// Native bridge that reads the GPS polyline of a finished HKWorkout via
/// `HKWorkoutRouteQuery`. Used by the share-card flow to draw an
/// abstract gold polyline on the deelbare run-samenvatting.
///
/// Permission: covered by the existing HealthKit read scope (workouts
/// + workout routes share the same authorization).
///
/// Method: `fetchRoute`
///   args: { "workoutUuid": "AB12CD34-..." }  // HKWorkout.uuid as String
///   returns: { "points": [{"lat": 52.3, "lng": 4.9, "t": 1716297600000}, ...] }
///
/// Edge: when the workout has no route data (treadmill, indoor, route
/// recording was off), returns `{ "points": [] }` — never an error, so
/// the share-card flow can gracefully fall back to its no-route variant.
enum WorkoutRoute {
    static let channelName = "nl.runcoach/workout-route"

    static func register(controller: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: controller)
        channel.setMethodCallHandler { call, result in
            switch call.method {
            case "fetchRoute":
                let args = call.arguments as? [String: Any] ?? [:]
                guard let uuidString = args["workoutUuid"] as? String,
                      let uuid = UUID(uuidString: uuidString)
                else {
                    result(FlutterError(code: "WR_BAD_ARGS",
                                        message: "Missing or invalid workoutUuid.",
                                        details: nil))
                    return
                }
                fetchRoute(uuid: uuid, result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private static func fetchRoute(uuid: UUID, result: @escaping FlutterResult) {
        guard HKHealthStore.isHealthDataAvailable() else {
            result(["points": []])
            return
        }

        let store = HKHealthStore()
        let workoutType = HKObjectType.workoutType()
        let routeType = HKSeriesType.workoutRoute()

        store.requestAuthorization(toShare: nil, read: [workoutType, routeType]) { granted, error in
            // Auth flow same as the rest of the HK bridges; bail silently
            // when denied so the share-card flow simply renders the
            // no-route variant.
            guard granted, error == nil else {
                result(["points": []])
                return
            }

            findWorkout(store: store, uuid: uuid) { workout in
                guard let workout = workout else {
                    result(["points": []])
                    return
                }

                findRouteSamples(store: store, workout: workout) { routes in
                    guard !routes.isEmpty else {
                        result(["points": []])
                        return
                    }

                    collectLocations(store: store, routes: routes) { locations in
                        // Flatten + minimise JSON size with short keys; the
                        // share-card painter normalises lat/lng to screen
                        // coords so absolute precision doesn't matter.
                        let points: [[String: Any]] = locations.map { location in
                            [
                                "lat": location.coordinate.latitude,
                                "lng": location.coordinate.longitude,
                                "t": Int(location.timestamp.timeIntervalSince1970 * 1000),
                            ]
                        }
                        result(["points": points])
                    }
                }
            }
        }
    }

    private static func findWorkout(
        store: HKHealthStore,
        uuid: UUID,
        completion: @escaping (HKWorkout?) -> Void
    ) {
        let predicate = HKQuery.predicateForObject(with: uuid)
        let query = HKSampleQuery(
            sampleType: .workoutType(),
            predicate: predicate,
            limit: 1,
            sortDescriptors: nil
        ) { _, samples, _ in
            completion(samples?.first as? HKWorkout)
        }
        store.execute(query)
    }

    private static func findRouteSamples(
        store: HKHealthStore,
        workout: HKWorkout,
        completion: @escaping ([HKWorkoutRoute]) -> Void
    ) {
        let predicate = HKQuery.predicateForObjects(from: workout)
        let query = HKSampleQuery(
            sampleType: HKSeriesType.workoutRoute(),
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { _, samples, _ in
            completion(samples as? [HKWorkoutRoute] ?? [])
        }
        store.execute(query)
    }

    private static func collectLocations(
        store: HKHealthStore,
        routes: [HKWorkoutRoute],
        completion: @escaping ([CLLocation]) -> Void
    ) {
        // `HKWorkoutRouteQuery` streams CLLocations in chunks via its
        // callback, calling once more with `done=true` to signal the
        // route is fully drained. Multiple routes (e.g. mid-run pauses)
        // are processed sequentially via a DispatchGroup so the final
        // array preserves chronological order.
        let group = DispatchGroup()
        var collected: [CLLocation] = []
        let lock = NSLock()

        for route in routes {
            group.enter()
            var routeLocations: [CLLocation] = []
            let routeQuery = HKWorkoutRouteQuery(route: route) { _, locationsBatch, done, _ in
                if let batch = locationsBatch {
                    routeLocations.append(contentsOf: batch)
                }
                if done {
                    lock.lock()
                    collected.append(contentsOf: routeLocations)
                    lock.unlock()
                    group.leave()
                }
            }
            store.execute(routeQuery)
        }

        group.notify(queue: .global(qos: .userInitiated)) {
            // Order by timestamp so multi-segment workouts render as a
            // continuous polyline. Same-timestamp ties are stable.
            collected.sort { $0.timestamp < $1.timestamp }
            completion(collected)
        }
    }
}
