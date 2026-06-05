//
//  MockEasyEventStore.swift
//  EventideTests
//
//  Created by CHOUPAULT Alexis on 23/01/2025.
//

import EventKit
import Foundation
import UIKit
@testable import eventide

class MockEasyEventStore: EasyEventStoreProtocol {
    var calendars: [MockCalendar] = []

    func createCalendar(title: String, color: UIColor, account: Account?) throws -> eventide.Calendar {
        let calendar = MockCalendar(
            id: UUID().uuidString,
            title: title,
            color: color,
            isWritable: true,
            account: account ?? Account(id: "local", name: "Local", type: "Local")
        )
        calendars.append(calendar)
        return calendar.toCalendar()
    }

    func retrieveCalendars(
        onlyWritable: Bool,
        from account: Account?
    ) -> [eventide.Calendar] {
        return calendars
            .filter { onlyWritable ? $0.isWritable : true }
            .filter { calendar in
                guard let account = account else { return true }
                return account.id == calendar.account.id && account.type == calendar.account.type
            }
            .map { $0.toCalendar() }
    }

    func retrieveAccounts() -> [Account] {
        return calendars.map { $0.account }
    }

    func deleteCalendar(calendarId: String) throws {
        guard let index = calendars.firstIndex(where: { $0.id == calendarId }) else {
            throw PigeonError(
                code: "NOT_FOUND",
                message: "Calendar not found",
                details: "The provided calendar.id is certainly incorrect"
            )
        }

        guard calendars[index].isWritable else {
            throw PigeonError(
                code: "NOT_EDITABLE",
                message: "Calendar not editable",
                details: "Calendar does not allow content modifications"
            )
        }

        calendars.remove(at: index)
    }

    func updateCalendar(calendarId: String, title: String, color: UIColor) throws -> eventide.Calendar {
        guard let index = calendars.firstIndex(where: { $0.id == calendarId }) else {
            throw PigeonError(
                code: "NOT_FOUND",
                message: "Calendar not found",
                details: "The provided calendar.id is certainly incorrect"
            )
        }

        guard calendars[index].isWritable else {
            throw PigeonError(
                code: "NOT_EDITABLE",
                message: "Calendar not editable",
                details: "Calendar does not allow content modifications"
            )
        }

        calendars[index].title = title
        calendars[index].color = color
        return calendars[index].toCalendar()
    }

    func createEvent(calendarId: String, title: String, startDate: Date, endDate: Date, isAllDay: Bool, description: String?, url: String?, location: String?, timeIntervals: [TimeInterval]?) throws -> Event {
        guard let mockCalendar = calendars.first(where: { $0.id == calendarId }) else {
            throw PigeonError(
                code: "NOT_FOUND",
                message: "Calendar not found",
                details: "The provided calendar.id is certainly incorrect"
            )
        }
        
        let mockEvent = MockEvent(
            id: UUID().uuidString,
            calendarId: calendarId,
            title: title,
            startDate: startDate,
            endDate: endDate,
            isAllDay: isAllDay,
            description: description,
            url: url,
            location: location,
            reminders: timeIntervals ?? []
        )
        
        mockCalendar.events.append(mockEvent)
        return mockEvent.toEvent()
    }

    func updateEvent(eventId: String, calendarId: String, title: String, startDate: Date, endDate: Date, isAllDay: Bool, description: String?, url: String?, location: String?, timeIntervals: [TimeInterval]?) throws -> Event {
        guard let mockEvent = findEvent(eventId: eventId) else {
            throw PigeonError(
                code: "NOT_FOUND",
                message: "Event not found",
                details: "The provided event.id is certainly incorrect"
            )
        }

        // Remove from old calendar if changed
        if mockEvent.calendarId != calendarId {
            guard let oldCalendarIndex = calendars.firstIndex(where: { $0.id == mockEvent.calendarId }) else {
                throw PigeonError(code: "GENERIC_ERROR", message: "Old calendar not found")
            }
            calendars[oldCalendarIndex].events.removeAll { $0.id == eventId }

            guard let newCalendarIndex = calendars.firstIndex(where: { $0.id == calendarId }) else {
                throw PigeonError(code: "NOT_FOUND", message: "New calendar not found")
            }
            calendars[newCalendarIndex].events.append(mockEvent)
        }

        mockEvent.calendarId = calendarId
        mockEvent.title = title
        mockEvent.startDate = startDate
        mockEvent.endDate = endDate
        mockEvent.isAllDay = isAllDay
        mockEvent.description = description
        mockEvent.url = url
        mockEvent.location = location
        if let timeIntervals = timeIntervals {
            mockEvent.reminders = timeIntervals
        }
        return mockEvent.toEvent()
    }

    func createEvent(title: String, startDate: Date, endDate: Date, isAllDay: Bool, description: String?, url: String?, location: String?, timeIntervals: [TimeInterval]?) throws {
        let mockEvent = MockEvent(
            id: UUID().uuidString,
            calendarId: calendars.first!.id,
            title: title,
            startDate: startDate,
            endDate: endDate,
            isAllDay: isAllDay,
            description: description,
            url: url,
            location: location,
            reminders: timeIntervals ?? []
        )
        
        calendars.first!.events.append(mockEvent)
    }
    
    func presentEventCreationViewController(title: String?, startDate: Date?, endDate: Date?, isAllDay: Bool?, description: String?, url: String?, location: String?, timeIntervals: [TimeInterval]?, completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.success(()))
    }
    
    func retrieveEvents(calendarId: String, startDate: Date, endDate: Date) throws -> [Event] {
        guard let mockCalendar = calendars.first(where: { $0.id == calendarId }) else {
            throw PigeonError(
                code: "NOT_FOUND",
                message: "Calendar not found",
                details: "The provided calendar.id is certainly incorrect"
            )
        }
        
        return mockCalendar.events
            .filter { ($0.startDate >= startDate && $0.startDate <= endDate) || ($0.endDate >= startDate && $0.endDate <= endDate) }
            .map { $0.toEvent() }
    }
    
    func deleteEvent(eventId: String) throws {
        guard let mockEvent = findEvent(eventId: eventId) else {
            throw PigeonError(
                code: "NOT_FOUND",
                message: "Event not found",
                details: "The provided event.id is certainly incorrect"
            )
        }
        
        guard let index = calendars.firstIndex(where: { $0.id == mockEvent.calendarId && $0.isWritable }) else {
            throw PigeonError(
                code: "NOT_EDITABLE",
                message: "Calendar not editable",
                details: "The calendar related to this event does not allow content modifications"
            )
        }
        
        calendars[index].events.removeAll { $0.id == eventId }
    }
    
    func createReminder(timeInterval: TimeInterval, eventId: String) throws -> Event {
        guard let mockEvent = findEvent(eventId: eventId) else {
            throw PigeonError(
                code: "NOT_FOUND",
                message: "Event not found",
                details: "The provided event.id is certainly incorrect"
            )
        }
        
        mockEvent.reminders.append(timeInterval)
        return mockEvent.toEvent()
    }
    
    func deleteReminder(timeInterval: TimeInterval, eventId: String) throws -> Event {
        guard let mockEvent = findEvent(eventId: eventId) else {
            throw PigeonError(
                code: "NOT_FOUND",
                message: "Event not found",
                details: "The provided event.id is certainly incorrect"
            )
        }
        
        mockEvent.reminders.removeAll { $0 == timeInterval }
        return mockEvent.toEvent()
    }

    private func findEvent(eventId: String) -> MockEvent? {
        for calendar in calendars {
            if let event = calendar.events.first(where: { $0.id == eventId }) {
                return event
            }
        }
        return nil
    }
}

class MockCalendar {
    let id: String
    var title: String
    var color: UIColor
    let isWritable: Bool
    let account: Account
    var events: [MockEvent] = []

    init(id: String, title: String, color: UIColor, isWritable: Bool, account: Account) {
        self.id = id
        self.title = title
        self.color = color
        self.isWritable = isWritable
        self.account = account
    }

    func toCalendar() -> eventide.Calendar {
        return eventide.Calendar(
            id: id,
            title: title,
            color: color.toInt64(),
            isWritable: isWritable,
            account: account
        )
    }
}

class MockEvent {
    let id: String
    var calendarId: String
    var title: String
    var startDate: Date
    var endDate: Date
    var isAllDay: Bool
    var description: String?
    var url: String?
    var location: String?
    var reminders: [TimeInterval]

    init(id: String, calendarId: String, title: String, startDate: Date, endDate: Date, isAllDay: Bool, description: String?, url: String?, location: String?, reminders: [TimeInterval]) {
        self.id = id
        self.calendarId = calendarId
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.description = description
        self.url = url
        self.location = location
        self.reminders = reminders
    }

    func toEvent() -> Event {
        return Event(
            id: id,
            calendarId: calendarId,
            title: title,
            isAllDay: isAllDay,
            startDate: startDate.millisecondsSince1970,
            endDate: endDate.millisecondsSince1970,
            reminders: reminders.map { Int64($0) },
            attendees: [],
            description: description,
            url: url,
            location: location
        )
    }
}
