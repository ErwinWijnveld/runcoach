import Foundation
import UIKit
import UserNotifications

/// APNs registration + delivery bridge to Dart.
///
/// MethodChannel: `nl.runcoach/push`
///
/// Methods Dart -> Native:
///   `requestPermission`             → Bool (granted)
///   `registerForRemoteNotifications` → void (triggers iOS APNs registration; token arrives later via `onToken`)
///   `getInitialPayload`             → [String: Any]? (cold-launch payload, consumed once)
///
/// Methods Native -> Dart (invokeMethod):
///   `onToken`        args = { token: "<hex>" }
///   `onTokenError`   args = { error: "<message>" }
///   `onPushTapped`   args = { payload: { type, conversation_id, ... } }
final class PushNotifications: NSObject, UNUserNotificationCenterDelegate {
    static let channelName = "nl.runcoach/push"
    static let shared = PushNotifications()

    private var channel: FlutterMethodChannel?

    /// Payload from a cold-launch tap — set in `didFinishLaunching`,
    /// consumed once by Dart via `getInitialPayload`.
    private var initialPayload: [String: Any]?

    func register(controller: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: controller)
        self.channel = channel
        channel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else { return }
            switch call.method {
            case "requestPermission":
                self.requestPermission(result: result)
            case "registerForRemoteNotifications":
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                    result(nil)
                }
            case "getInitialPayload":
                let payload = self.initialPayload
                self.initialPayload = nil
                result(payload)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        UNUserNotificationCenter.current().delegate = self
    }

    /// Stash a cold-launch payload (called from AppDelegate when the app is
    /// launched FROM a notification tap). Replayed via `getInitialPayload`.
    func setInitialPayload(_ payload: [String: Any]?) {
        guard let payload = payload else { return }
        initialPayload = customPayload(from: payload)
    }

    func didRegister(withToken deviceToken: Data) {
        let hex = deviceToken.map { String(format: "%02x", $0) }.joined()
        channel?.invokeMethod("onToken", arguments: ["token": hex])
    }

    func didFailToRegister(withError error: Error) {
        channel?.invokeMethod("onTokenError", arguments: ["error": error.localizedDescription])
    }

    private func requestPermission(result: @escaping FlutterResult) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                result(granted)
            }
        }
    }

    /// Strip the `aps` envelope and return only the custom keys we put on
    /// the message backend-side (`type`, `conversation_id`, …). Dart only
    /// cares about routing, not the alert text.
    private func customPayload(from userInfo: [AnyHashable: Any]) -> [String: Any] {
        var out: [String: Any] = [:]
        for (k, v) in userInfo {
            guard let key = k as? String, key != "aps" else { continue }
            out[key] = v
        }
        return out
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Foreground delivery: still show the banner + listed in Notification
    /// Center so the user knows.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound, .badge])
    }

    /// Tap on a delivered notification (foreground OR background).
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let payload = customPayload(from: response.notification.request.content.userInfo)
        channel?.invokeMethod("onPushTapped", arguments: ["payload": payload])
        completionHandler()
    }
}
