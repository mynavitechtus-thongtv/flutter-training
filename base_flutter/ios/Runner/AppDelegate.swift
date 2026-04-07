import UIKit
import Flutter
import Firebase
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  lazy var flutterEngine = FlutterEngine(name: "shared_engine")

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Start the Flutter engine
    flutterEngine.run()

    FirebaseApp.configure();
    GeneratedPluginRegistrant.register(with: flutterEngine)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

func didInitializeImplicitFlutterEngine(_ engine: FlutterImplicitEngineBridge) {
  GeneratedPluginRegistrant.register(with: engine.pluginRegistry)
  let notificationChannel = FlutterMethodChannel(
    name: "jp.flutter.app",
    binaryMessenger: engine.applicationRegistrar.messenger()
  )
  notificationChannel.setMethodCallHandler({
    (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
    if call.method == "clearBadgeCount" {
      clearBadgeCount()
      result(nil)
    } else {
      result(FlutterMethodNotImplemented)
    }
  })
}

func clearBadgeCount() {
  // // Clear all pending notifications
  // UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
  
  // // Clear all delivered notifications
  // UNUserNotificationCenter.current().removeAllDeliveredNotifications()
  
  // Reset badge count
  DispatchQueue.main.async {
    UIApplication.shared.applicationIconBadgeNumber = 0
  }
}
