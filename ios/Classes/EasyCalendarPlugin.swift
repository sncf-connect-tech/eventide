import Flutter
import UIKit

public final class EasyCalendarPlugin: NSObject, FlutterPlugin {
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let easyEventStore = EasyEventStore(eventStore: EKEventStoreSingleton.shared.eventStore)
        let permissionHandler = PermissionHandler(eventStore: EKEventStoreSingleton.shared.eventStore)
        
        CalendarApiSetup.setUp(
            binaryMessenger: registrar.messenger(),
            api: CalendarImplem(
                easyEventStore: easyEventStore,
                permissionHandler: permissionHandler
            )
        )
    }
}
