import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var faceTecBridge: FaceTecBridge?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let viewController = window?.rootViewController as? FlutterViewController {
      let faceTecBridge = FaceTecBridge()
      faceTecBridge.register(
        messenger: viewController.binaryMessenger,
        presentingViewController: viewController
      )
      self.faceTecBridge = faceTecBridge
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
