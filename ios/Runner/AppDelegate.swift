import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Không gán delegate thì iOS nuốt thông báo khi app đang mở: tin vẫn tới
    // máy nhưng không vẽ gì, và cú bấm vào thông báo không về được tới Dart.
    // FlutterAppDelegate đã tuân thủ UNUserNotificationCenterDelegate sẵn.
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
