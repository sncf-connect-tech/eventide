//
//  EKEventStoreSingleton.swift
//  easy_calendar
//
//  Created by CHOUPAULT Alexis on 23/01/2025.
//

import EventKit

final class EKEventStoreSingleton: ObservableObject {
    static let shared = EKEventStoreSingleton()
    
    let eventStore: EKEventStore
    
    private init() {
        self.eventStore = EKEventStore()
    }
}
