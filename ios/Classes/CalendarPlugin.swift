import Flutter
import UIKit
import EventKit

public class CalendarPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        CalendarActionsSetup.setUp(
            binaryMessenger: registrar.messenger(),
            api: CalendarApi()
        )
    }
}

