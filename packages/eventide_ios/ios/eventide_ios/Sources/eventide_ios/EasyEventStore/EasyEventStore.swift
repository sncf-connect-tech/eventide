//
//  EasyEventStore.swift
//  eventide
//
//  Created by CHOUPAULT Alexis on 31/12/2024.
//

import EventKit
import UIKit

protocol EasyEventStoreProtocol: CalendarProtocol, EventProtocol, AttendeeProtocol, ReminderProtocol {}

final class EasyEventStore: EasyEventStoreProtocol {
    let eventStore: EKEventStore
    let eventEditManager: EventEditViewControllerManager
    
    init(eventStore: EKEventStore) {
        self.eventStore = eventStore
        self.eventEditManager = EventEditViewControllerManager(eventStore: eventStore)
    }
}
