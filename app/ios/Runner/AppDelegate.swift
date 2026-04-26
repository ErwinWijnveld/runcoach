import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
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
  }
}
