//
//  PermissionHandler.swift
//  flutter_calendar_connect
//
//  Created by CHOUPAULT Alexis on 02/01/2025.
//

import Foundation
import EventKit

final class PermissionHandler {
    private let eventStore: EKEventStore
    
    init() {
        self.eventStore = EventStoreManager.shared.eventStore
    }
    
    public func checkCalendarAccessThenExecute(
        _ permissionsGrantedCallback: @escaping () -> Void,
        noAccess permissionsRefusedCallback: @escaping () -> Void
    ) {
        if hasCalendarAccess() {
            permissionsGrantedCallback()
        } else {
            requestCalendarAccess { granted in
                if (granted) {
                    permissionsGrantedCallback()
                } else {
                    permissionsRefusedCallback()
                }
            }
        }
    }
    
    private func hasCalendarAccess() -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        
        if #available(iOS 17, *) {
            return status == EKAuthorizationStatus.fullAccess
        } else {
            return status == EKAuthorizationStatus.authorized
        }
    }
    
    private func requestCalendarAccess(completion: @escaping (_ isGranted: Bool) -> Void) {
        let handler: EKEventStoreRequestAccessCompletionHandler = { isGranted, error in
            guard error == nil else {
                let pigeonError = PigeonError(code: error!.localizedDescription, message: nil, details: nil)
                completion(isGranted)
                return
            }
            
            completion(isGranted)
        }
        
        if #available(iOS 17, *) {
            eventStore.requestFullAccessToEvents(completion: handler)
        } else {
            eventStore.requestAccess(to: .event, completion: handler)
        }
    }
}
