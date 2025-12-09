import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Configure audio session for playback
    do {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(.playback, mode: .default, options: [])
      try audioSession.setActive(true)
    } catch {
      print("Failed to set up audio session: \(error)")
    }

    // Disable automatic keyboard avoidance behavior that conflicts with hardware keyboards
    if let controller = window?.rootViewController as? FlutterViewController {
      controller.additionalSafeAreaInsets = UIEdgeInsets.zero
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Prevent the app from trying to show software keyboard when hardware keyboard is connected
  override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
    super.pressesBegan(presses, with: event)
  }

  override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
    super.pressesEnded(presses, with: event)
  }
}
