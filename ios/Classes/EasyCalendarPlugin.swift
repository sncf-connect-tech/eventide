import Flutter
import UIKit

public class EasyCalendarPlugin: NSObject, FlutterPlugin {
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        CalendarApiSetup.setUp(
            binaryMessenger: registrar.messenger(),
            api: CalendarImplem.init()
        )
    }
}
