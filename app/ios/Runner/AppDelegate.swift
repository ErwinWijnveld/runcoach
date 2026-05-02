import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Cold-launch from a push tap: stash the payload so Dart can pull it
    // via `getInitialPayload` after the auth state has hydrated.
    if let remote = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
      var converted: [String: Any] = [:]
      for (k, v) in remote {
        if let key = k as? String { converted[key] = v }
      }
      PushNotifications.shared.setInitialPayload(converted)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    PushNotifications.shared.didRegister(withToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    PushNotifications.shared.didFailToRegister(withError: error)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Native HealthKit helpers exposed to Dart via MethodChannel. The
    // Flutter `health` package handles permissions + workout listing, but
    // doesn't expose efficient personal-record queries — those need
    // `HKQuery.predicateForWorkouts(operatorType:totalDistance:)` with a
    // `limit:1` sort by duration to be fast on years of history.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "HealthKitPRs") {
      HealthKitPersonalRecords.register(controller: registrar.messenger())
    }

    // Native APNs bridge — registration, permission prompt, tap routing.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PushNotifications") {
      PushNotifications.shared.register(controller: registrar.messenger())
    }

    // WorkoutKit bridge — schedules planned runs in the Fitness app so they
    // sync to the paired Apple Watch. iOS 17+; older OSes return
    // status=unavailable.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "WorkoutScheduling") {
      WorkoutScheduling.register(controller: registrar.messenger())
    }
  }
}
