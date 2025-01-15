//
//  PermissionHandler.swift
//  easy_calendar
//
//  Created by CHOUPAULT Alexis on 02/01/2025.
//

import Foundation
import EventKit

class PermissionHandler {
    internal let eventStore: EKEventStore
    
    init(_ eventStore: EKEventStore = EventStoreManager.shared.eventStore) {
        self.eventStore = eventStore
    }
    
    public func checkCalendarAccessThenExecute(
        _ permissionsGrantedCallback: @escaping () -> Void,
        noAccess permissionsRefusedCallback: @escaping () -> Void,
        error errorCallback: @escaping (any Error) -> Void
    ) {
        requestCalendarAccess { result in
            switch (result) {
            case .success(let granted):
                if (granted) {
                    permissionsGrantedCallback()
                } else {
                    permissionsRefusedCallback()
                }
            case .failure(let error):
                errorCallback(error)
            }
        }
    }
    
    private func requestCalendarAccess(completion: @escaping (Result<Bool, any Error>) -> Void) {
        let handler: EKEventStoreRequestAccessCompletionHandler = { isGranted, error in
            guard error == nil else {
                completion(.failure(
                    PigeonError(
                        code: "GENERIC_ERROR",
                        message: "An error occurred during calendar access request.",
                        details: error!.localizedDescription
                    )
                ))
                return
            }
            
            completion(.success(isGranted))
        }
        
        if #available(iOS 17, *) {
            eventStore.requestFullAccessToEvents(completion: handler)
        } else {
            eventStore.requestAccess(to: .event, completion: handler)
        }
    }
}
