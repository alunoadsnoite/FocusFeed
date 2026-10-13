import Flutter
import UIKit
import FamilyControls
import DeviceActivity
import ManagedSettings
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let notices = FocusNoticeDelegate()
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = notices
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "FocusPermissions")!
    SessionBridge.register(messenger: registrar.messenger())
    let channel = FlutterMethodChannel(name: "focusfeed/permissions", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "check":
        if #available(iOS 16.0, *) {
          result(["supported": true, "screenTime": AuthorizationCenter.shared.authorizationStatus == .approved])
        } else {
          result(["supported": false, "screenTime": false])
        }
      case "request":
        let arguments = call.arguments as? [String: Any]
        guard arguments?["permission"] as? String == "screenTime" else {
          result(FlutterError(code: "invalid_permission", message: "Permissão desconhecida", details: nil))
          return
        }
        if #available(iOS 16.0, *) {
          Task { @MainActor in
            do {
              try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
              result(nil)
            } catch {
              result(FlutterError(code: "authorization_failed", message: error.localizedDescription, details: nil))
            }
          }
        } else {
          result(FlutterError(code: "unsupported", message: "Screen Time individual exige iOS 16 ou superior.", details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
