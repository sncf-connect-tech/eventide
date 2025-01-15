//
//  MockPermissionHandler.swift
//  EasyCalendarTests
//
//  Created by CHOUPAULT Alexis on 16/01/2025.
//

import EventKit
@testable import easy_calendar

final class MockPermissionHandler: PermissionHandler {
    override init(_ eventStore: EKEventStore) {
        super.init(eventStore)
    }
    
    override func checkCalendarAccessThenExecute(
        _ permissionsGrantedCallback: @escaping () -> Void,
        noAccess permissionsRefusedCallback: @escaping () -> Void,
        error errorCallback: @escaping (any Error) -> Void
    ) {
        if (self.eventStore as! MockEventStore).mockRequestAccessResult {
            permissionsGrantedCallback()
        } else {
            permissionsRefusedCallback()
        }
    }
}
