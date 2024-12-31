import Flutter
import UIKit
import EventKit

public class CalendarPlugin: NSObject, FlutterPlugin {
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        CalendarApiSetup.setUp(
            binaryMessenger: registrar.messenger(),
            api: CalendarImplem.init()
        )
    }
}
