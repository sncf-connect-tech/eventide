//
//  Mocks.swift
//  EasyCalendarTests
//
//  Created by CHOUPAULT Alexis on 15/01/2025.
//

import EventKit

final class MockEventStore: EKEventStore {
    let mockRequestAccessResult: Bool
    let mockRequestAccessError: Error?
    var noSource: Bool = false
    
    override var defaultCalendarForNewEvents: EKCalendar? {
        if (noSource) {
            return nil
        } else {
            return super.defaultCalendarForNewEvents
        }
    }
    
    init(
        requestAccessResult: Bool,
        requestAccessError: Error? = nil
    ) {
        self.mockRequestAccessResult = requestAccessResult
        self.mockRequestAccessError = requestAccessError
        super.init()
    }
    
    override func requestAccess(to entityType: EKEntityType, completion: @escaping EKEventStoreRequestAccessCompletionHandler) {
        completion(mockRequestAccessResult, mockRequestAccessError)
    }
    
    @available(iOS 17, *)
    override func requestFullAccessToEvents(completion: @escaping EKEventStoreRequestAccessCompletionHandler) {
        completion(mockRequestAccessResult, mockRequestAccessError)
    }
}
