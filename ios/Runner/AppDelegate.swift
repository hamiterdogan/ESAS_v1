import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Firebase is not available on iOS (GoogleService-Info.plist not in Xcode project)
    // Firebase initialization is handled in Dart code only for Android/Web
    
    // Push notification delegate
    UNUserNotificationCenter.current().delegate = self
    
    // Register for remote notifications (for manual notification handling)
    application.registerForRemoteNotifications()
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
