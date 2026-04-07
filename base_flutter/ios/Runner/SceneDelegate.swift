import Flutter
import UIKit

@available(iOS 13.0, *)
@objc class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene else { return }

    // Get the shared FlutterEngine from AppDelegate
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
      fatalError("AppDelegate not found")
    }
    let flutterEngine = appDelegate.flutterEngine

    self.window = UIWindow(windowScene: windowScene)
    let flutterViewController = FlutterViewController(
      engine: flutterEngine,
      nibName: nil,
      bundle: nil
    )
    self.window?.rootViewController = flutterViewController
    self.window?.makeKeyAndVisible()
  }

  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
          let url = URLContexts.first?.url else {
      return
    }
    _ = appDelegate.application(
      UIApplication.shared,
      open: url,
      options: [:]
    )
  }

  func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
      return
    }
    _ = appDelegate.application(
      UIApplication.shared,
      continue: userActivity,
      restorationHandler: { _ in }
    )
  }
}
