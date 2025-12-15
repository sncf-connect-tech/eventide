//
//  MockEasyEventStore.swift
//  EventideTests
//
//  Created by CHOUPAULT Alexis on 23/01/2025.
//

import UIKit
@testable import eventide

class MockEasyEventStore: EasyEventStoreProtocol {
    var calendars: [MockCalendar]
    
    init(calendars: [MockCalendar] = []) {
        self.calendars = calendars
    }
    
    func createCalendar(title: String, color: UIColor, account: Account?) throws -> eventide.Calendar {
        let calendar = MockCalendar(
            id: "id",
            title: title,
            color: color,
            isWritable: true,
            account: account ?? Account(id: "local", name: "local", type: "local"),
            events: []
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
    
    func retrieveAccounts() -> [Account] {
        return calendars.map { $0.account }
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
            id: String(mockCalendar.events.count),
            title: title,
            startDate: startDate,
            endDate: endDate,
            calendarId: mockCalendar.id,
            isAllDay: isAllDay,
            description: description,
            url: url,
            reminders: timeIntervals
        )
        
        mockCalendar.events.append(mockEvent)
        
        return mockEvent.toEvent()
    }
    
    func createEvent(title: String, startDate: Date, endDate: Date, isAllDay: Bool, description: String?, url: String?, location: String?, timeIntervals: [TimeInterval]?) throws {
        let mockEvent = MockEvent(
            id: String(calendars.first!.events.count),
            title: title,
            startDate: startDate,
            endDate: endDate,
            calendarId: calendars.first!.id,
            isAllDay: isAllDay,
            description: description,
            url: url,
            reminders: timeIntervals
        )
        
        calendars.first!.events.append(mockEvent)
    }
    
    func presentEventCreationViewController(title: String?, startDate: Date?, endDate: Date?, isAllDay: Bool?, description: String?, url: String?, location: String?, timeIntervals: [TimeInterval]?, completion: @escaping (Result<Void, any Error>) -> Void) {
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
            .filter { startDate.compare($0.startDate) == .orderedAscending && $0.endDate.compare(endDate) == .orderedAscending }
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
        
        if (mockEvent.reminders == nil) {
            mockEvent.reminders = [timeInterval]
        } else {
            mockEvent.reminders!.append(timeInterval)
        }

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
        
        guard let index = mockEvent.reminders?.firstIndex(where: { -$0 == timeInterval }) else {
            throw PigeonError(
                code: "NOT_FOUND",
                message: "Reminder not found",
                details: nil
            )
        }
        
        mockEvent.reminders?.remove(at: index)
        return mockEvent.toEvent()
    }
    
    func retrieveAttendees(eventId: String) throws -> [Attendee] {
        guard let mockEvent = findEvent(eventId: eventId) else {
            throw PigeonError(
                code: "NOT_FOUND",
                message: "Event not found",
                details: "The provided event.id is certainly incorrect"
            )
        }
        
        return mockEvent.attendees?.map { $0.toAttendee() } ?? []
    }
    
    private func findEvent(eventId: String) -> MockEvent? {
        for calendar in calendars {
            for event in calendar.events {
                if event.id == eventId {
                    return event
                }
            }
        }
        
        return nil
    }
}

class MockCalendar {
    let id: String
    let title: String
    let color: UIColor
    let isWritable: Bool
    let account: Account
    var events: [MockEvent]
    
    init(id: String, title: String, color: UIColor, isWritable: Bool, account: Account, events: [MockEvent]) {
        self.id = id
        self.title = title
        self.color = color
        self.isWritable = isWritable
        self.account = account
        self.events = events
    }
    
    fileprivate func toCalendar() -> eventide.Calendar {
        eventide.Calendar(
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
    let title: String
    let startDate: Date
    let endDate: Date
    let calendarId: String
    let isAllDay: Bool
    let description: String?
    let url: String?
    let location: String?
    var reminders: [TimeInterval]?
    let attendees: [MockAttendee]?

    init(id: String, title: String, startDate: Date, endDate: Date, calendarId: String, isAllDay: Bool, description: String?, url: String?, location: String? = nil, reminders: [TimeInterval]? = nil, attendees: [MockAttendee]? = nil) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.calendarId = calendarId
        self.isAllDay = isAllDay
        self.description = description
        self.url = url
        self.location = location
        self.reminders = reminders?.map({ $0 })
        self.attendees = attendees
    }
    
    fileprivate func toEvent() -> Event {
        Event(
            id: id,
            calendarId: calendarId,
            title: title,
            isAllDay: isAllDay,
            startDate: startDate.millisecondsSince1970,
            endDate: endDate.millisecondsSince1970,
            reminders: reminders?.map({ Int64($0) }) ?? [],
            attendees: attendees?.map { $0.toAttendee() } ?? [],
            description: description,
            url: url
        )
    }
}

class MockAttendee {
    let name: String
    let email: String
    let type: Int64
    let role: Int64
    let status: Int64
    
    init(name: String, email: String, type: Int64, role: Int64, status: Int64) {
        self.name = name
        self.email = email
        self.type = type
        self.role = role
        self.status = status
    }
    
    fileprivate func toAttendee() -> Attendee {
        return Attendee(
            name: name,
            email: email,
            type: type,
            role: role,
            status: status
        )
    }
}

// MARK: - Specialized Mocks for Native Platform Testing

/// Mock that simulates user canceling the native event creation
class MockEasyEventStoreCanceled: MockEasyEventStore {
    override func presentEventCreationViewController(title: String?, startDate: Date?, endDate: Date?, isAllDay: Bool?, description: String?, url: String?, location: String?, timeIntervals: [TimeInterval]?, completion: @escaping (Result<Void, any Error>) -> Void) {
        // Simulate user cancellation
        completion(.failure(PigeonError(
            code: "USER_CANCELED",
            message: "User canceled event creation",
            details: nil
        )))
    }
}

/// Mock that simulates presentation error
class MockEasyEventStorePresentationError: MockEasyEventStore {
    override func presentEventCreationViewController(title: String?, startDate: Date?, endDate: Date?, isAllDay: Bool?, description: String?, url: String?, location: String?, timeIntervals: [TimeInterval]?, completion: @escaping (Result<Void, any Error>) -> Void) {
        // Simulate presentation error
        completion(.failure(PigeonError(
            code: "PRESENTATION_ERROR",
            message: "Unable to present event creation view",
            details: nil
        )))
    }
}

/// Mock that simulates event deletion during creation
class MockEasyEventStoreEventDeleted: MockEasyEventStore {
    override func presentEventCreationViewController(title: String?, startDate: Date?, endDate: Date?, isAllDay: Bool?, description: String?, url: String?, location: String?, timeIntervals: [TimeInterval]?, completion: @escaping (Result<Void, any Error>) -> Void) {
        // Simulate event deletion
        completion(.failure(PigeonError(
            code: "EVENT_DELETED",
            message: "Event was deleted",
            details: nil
        )))
    }
}

/// Mock that simulates unknown action
class MockEasyEventStoreUnknownAction: MockEasyEventStore {
    override func presentEventCreationViewController(title: String?, startDate: Date?, endDate: Date?, isAllDay: Bool?, description: String?, url: String?, location: String?, timeIntervals: [TimeInterval]?, completion: @escaping (Result<Void, any Error>) -> Void) {
        // Simulate unknown action
        completion(.failure(PigeonError(
            code: "GENERIC_ERROR",
            message: "Unknown action from event edit controller",
            details: nil
        )))
    }
}
