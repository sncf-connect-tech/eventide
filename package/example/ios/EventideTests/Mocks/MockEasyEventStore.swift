//
//  MockEasyEventStore.swift
//  EventideTests
//
//  Created by CHOUPAULT Alexis on 23/01/2025.
//

import class UIKit.UIColor
import struct Foundation.UUID
import struct Foundation.Date
import struct Foundation.TimeInterval
@testable import eventide

class MockEasyEventStore: EasyEventStoreProtocol {
    var calendars: [Calendar]
    var events: [Event]
    
    init(calendars: [Calendar] = [], events: [Event] = []) {
        self.calendars = calendars
        self.events = events
    }
    
    func createCalendar(title: String, color: UIColor, account: Account?) throws -> eventide.Calendar {
        // TODO: source / account
        
        let calendar = Calendar(
            id: UUID().uuidString,
            title: title,
            color: color.toInt64(),
            isWritable: true,
            account: account ?? Account(id: "local", name: "local", type: "local")
        )
        
        calendars.append(calendar)
        
        return calendar
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
    }
    
    func retrieveAccounts() -> [Account] {
        return calendars.map { $0.account }
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
        calendars[index].color = color.toInt64()
        
        return calendars[index]
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
        
        let calendarId = calendars[index].id
        calendars.remove(at: index)
        events.removeAll { $0.calendarId == calendarId }
    }
    
    func createEvent(
        calendarId: String,
        title: String,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool,
        description: String?,
        url: String?,
        location: String?,
        timeIntervals: [TimeInterval]?,
        recurrenceRule: String?
    ) throws -> Event {
        guard let mockCalendar = calendars.first(where: { $0.id == calendarId }) else {
            throw PigeonError(
                code: "NOT_FOUND",
                message: "Calendar not found",
                details: "The provided calendar.id is certainly incorrect"
            )
        }
        
        let mockEvent = Event(
            id: UUID().uuidString,
            calendarId: mockCalendar.id,
            title: title,
            isAllDay: isAllDay,
            startDate: startDate.millisecondsSince1970,
            endDate: endDate.millisecondsSince1970,
            reminders: timeIntervals?.map({ Int64($0) }) ?? [],
            attendees: [],
            description: description,
            url: url,
            recurrenceRule: recurrenceRule
        )
        
        events.append(mockEvent)
        
        return mockEvent
    }
    
    func createEvent(title: String, startDate: Date, endDate: Date, isAllDay: Bool, description: String?, url: String?, location: String?, timeIntervals: [TimeInterval]?, recurrenceRule: String?) throws {
        guard let firstCalendar = calendars.first else {
            throw PigeonError(
                code: "NOT_FOUND",
                message: "Default calendar not found",
                details: "No calendar has been found"
            )
        }
        
        let mockEvent = Event(
            id: UUID().uuidString,
            calendarId: firstCalendar.id,
            title: title,
            isAllDay: isAllDay,
            startDate: startDate.millisecondsSince1970,
            endDate: endDate.millisecondsSince1970,
            reminders: timeIntervals?.map({ Int64($0) }) ?? [],
            attendees: [],
            description: description,
            url: url,
            recurrenceRule: recurrenceRule
        )
        
        events.append(mockEvent)
    }
    
    func presentEventCreationViewController(title: String?, startDate: Date?, endDate: Date?, isAllDay: Bool?, description: String?, url: String?, location: String?, timeIntervals: [TimeInterval]?, recurrenceRule: String?, completion: @escaping (Result<Void, any Error>) -> Void) {
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
        
        return events
            .filter { startDate.compare(Date(from: $0.startDate)) == .orderedAscending && Date(from: $0.endDate).compare(endDate) == .orderedAscending }
    }
    
    
    // NOTE: [span] and [originalInstanceTime] are intentionally ignored for behavior
    // purposes in this mock. The mock stores a FLAT `events: [Event]` array with no
    // true master/instance modeling of recurring events, so it cannot meaningfully
    // distinguish "thisEvent" / "thisAndFuture" / "allEvents" — every span behaves
    // like "allEvents" here (operate on the single stored Event matching [eventId]).
    // These tests exercise the CalendarImplem -> EasyEventStoreProtocol parameter
    // forwarding contract only; real span semantics are exercised solely by
    // `EasyEventStore` (real EventKit implementation), which isn't unit-testable
    // in this environment (same limitation noted in Tasks 9-11).
    func updateEvent(
        eventId: String,
        calendarId: String,
        title: String,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool,
        description: String?,
        url: String?,
        location: String?,
        timeIntervals: [TimeInterval]?,
        recurrenceRule: String?,
        span: String,
        originalInstanceTime: Int64?
    ) throws -> eventide.Event {
        guard let eventIndex = events.firstIndex(where: { $0.id == eventId }) else {
            throw PigeonError(
                code: "NOT_FOUND",
                message: "Event not found",
                details: "The provided event.id is certainly incorrect"
            )
        }
        
        guard let oldCalendarIndex = calendars.firstIndex(where: { $0.id == events[eventIndex].calendarId }),
              calendars[oldCalendarIndex].isWritable else {
            throw PigeonError(
                code: "NOT_EDITABLE",
                message: "Event actual calendar is not editable",
                details: "Calendar does not allow content modifications"
            )
        }
        
        if calendarId != events[eventIndex].calendarId {
            guard let calendarIndex = calendars.firstIndex(where: { $0.id == calendarId }) else {
                throw PigeonError(
                    code: "NOT_FOUND",
                    message: "Calendar not found",
                    details: "The provided calendar.id is certainly incorrect"
                )
            }
            
            guard calendars[calendarIndex].isWritable else {
                throw PigeonError(
                    code: "NOT_EDITABLE",
                    message: "Calendar not editable",
                    details: "Calendar does not allow content modifications"
                )
            }
            
            events[eventIndex].calendarId = calendarId
        }
        
        events[eventIndex].title = title
        events[eventIndex].startDate = startDate.millisecondsSince1970
        events[eventIndex].endDate = endDate.millisecondsSince1970
        events[eventIndex].isAllDay = isAllDay
        events[eventIndex].description = description
        events[eventIndex].url = url
        events[eventIndex].location = location
        
        if let timeIntervals = timeIntervals {
            events[eventIndex].reminders = timeIntervals.map({ Int64($0) })
        }
        
        if let recurrenceRule = recurrenceRule {
            events[eventIndex].recurrenceRule = recurrenceRule
        }
        
        return events[eventIndex]
    }
    
    // NOTE: see the comment above `updateEvent` — [span]/[originalInstanceTime] are
    // ignored for behavior purposes; this mock always deletes the single stored
    // Event matching [eventId], regardless of span.
    func deleteEvent(eventId: String, span: String, originalInstanceTime: Int64?) throws {
        guard let eventIndex = events.firstIndex(where: { $0.id == eventId }) else {
            throw PigeonError(
                code: "NOT_FOUND",
                message: "Event not found",
                details: "The provided event.id is certainly incorrect"
            )
        }
        
        guard let calendarIndex = calendars.firstIndex(where: { $0.id == events[eventIndex].calendarId }),
              calendars[calendarIndex].isWritable else {
            throw PigeonError(
                code: "NOT_EDITABLE",
                message: "Calendar not editable",
                details: "The calendar related to this event does not allow content modifications"
            )
        }
        
        events.removeAll { $0.id == eventId }
    }
    
    func createReminder(timeInterval: TimeInterval, eventId: String) throws -> Event {
        guard let eventIndex = events.firstIndex(where: { $0.id == eventId }) else {
            throw PigeonError(
                code: "NOT_FOUND",
                message: "Event not found",
                details: "The provided event.id is certainly incorrect"
            )
        }
        
        events[eventIndex].reminders.append(Int64(timeInterval))

        return events[eventIndex]
    }
    
    func deleteReminder(timeInterval: TimeInterval, eventId: String) throws -> Event {
        guard let eventIndex = events.firstIndex(where: { $0.id == eventId }) else {
            throw PigeonError(
                code: "NOT_FOUND",
                message: "Event not found",
                details: "The provided event.id is certainly incorrect"
            )
        }
        
        guard let reminderIndex = events[eventIndex].reminders.firstIndex(where: { -$0 == Int64(timeInterval) }) else {
            throw PigeonError(
                code: "NOT_FOUND",
                message: "Reminder not found",
                details: nil
            )
        }
        
        events[eventIndex].reminders.remove(at: reminderIndex)
        
        return events[eventIndex]
    }
    
    func retrieveAttendees(eventId: String) throws -> [Attendee] {
        guard let eventIndex = events.firstIndex(where: { $0.id == eventId }) else {
            throw PigeonError(
                code: "NOT_FOUND",
                message: "Event not found",
                details: "The provided event.id is certainly incorrect"
            )
        }
        
        return events[eventIndex].attendees
    }
}

// MARK: - Specialized Mocks for Native Platform Testing

/// Mock that simulates user canceling the native event creation
class MockEasyEventStoreCanceled: MockEasyEventStore {
    override func presentEventCreationViewController(title: String?, startDate: Date?, endDate: Date?, isAllDay: Bool?, description: String?, url: String?, location: String?, timeIntervals: [TimeInterval]?, recurrenceRule: String?, completion: @escaping (Result<Void, any Error>) -> Void) {
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
    override func presentEventCreationViewController(title: String?, startDate: Date?, endDate: Date?, isAllDay: Bool?, description: String?, url: String?, location: String?, timeIntervals: [TimeInterval]?, recurrenceRule: String?, completion: @escaping (Result<Void, any Error>) -> Void) {
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
    override func presentEventCreationViewController(title: String?, startDate: Date?, endDate: Date?, isAllDay: Bool?, description: String?, url: String?, location: String?, timeIntervals: [TimeInterval]?, recurrenceRule: String?, completion: @escaping (Result<Void, any Error>) -> Void) {
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
    override func presentEventCreationViewController(title: String?, startDate: Date?, endDate: Date?, isAllDay: Bool?, description: String?, url: String?, location: String?, timeIntervals: [TimeInterval]?, recurrenceRule: String?, completion: @escaping (Result<Void, any Error>) -> Void) {
        // Simulate unknown action
        completion(.failure(PigeonError(
            code: "GENERIC_ERROR",
            message: "Unknown action from event edit controller",
            details: nil
        )))
    }
}
