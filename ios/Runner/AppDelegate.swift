import Flutter
import CoreMotion
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var stepChannel: FlutterEventChannel?
  private var stepStreamHandler: StepCounterStreamHandler?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterEventChannel(
        name: "com.azaiulv.salud_ulv_app/steps",
        binaryMessenger: controller.binaryMessenger
      )
      let handler = StepCounterStreamHandler()
      stepChannel = channel
      stepStreamHandler = handler
      channel.setStreamHandler(handler)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

private final class StepCounterStreamHandler: NSObject, FlutterStreamHandler {
  private let pedometer = CMPedometer()

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    guard CMPedometer.isStepCountingAvailable() else {
      events(FlutterError(
        code: "STEP_SENSOR_UNAVAILABLE",
        message: "This device has no native step counter",
        details: nil
      ))
      return nil
    }

    events([
      "counterAvailable": true,
      "detectorAvailable": false,
      "confirmedSteps": 0,
      "liveSteps": 0,
    ])

    pedometer.startUpdates(from: Date()) { data, error in
      DispatchQueue.main.async {
        if let error = error {
          events(FlutterError(
            code: "MOTION_PERMISSION_DENIED",
            message: error.localizedDescription,
            details: nil
          ))
          return
        }
        if let steps = data?.numberOfSteps {
          events([
            "counterAvailable": true,
            "detectorAvailable": false,
            "confirmedSteps": steps.intValue,
            "liveSteps": steps.intValue,
          ])
        }
      }
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    pedometer.stopUpdates()
    return nil
  }
}
