//
//  MockEasyEventStore.swift
//  EventideTests
//
//  Created by CHOUPAULT Alexis on 23/01/2025.
//

import UIKit
import EventKit
@testable import eventide

class MockEasyEventStore: EasyEventStoreProtocol {
    var calendars: [MockCalendar]
    
    init(calendars: [MockCalendar] = []) {
        self.calendars = calendars
    }
    
    func createCalendar(title: String, color: UIColor) throws -> eventide.Calendar {
        let calendar = MockCalendar(
            id: "id",
            title: title,
            color: color,
            isWritable: true,
            sourceName: "iCloud",
            events: []
        )
        
        calendars.append(calendar)
        
        return calendar.toCalendar()
    }
    
    func retrieveCalendars(onlyWritable: Bool) -> [eventide.Calendar] {
        return calendars
            .filter { onlyWritable && $0.isWritable || !onlyWritable }
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
    
    func createEvent(calendarId: String, title: String, startDate: Date, endDate: Date, isAllDay: Bool, description: String?, url: String?) throws -> eventide.Event {
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
            url: url
        )
        
        mockCalendar.events.append(mockEvent)
        
        return mockEvent.toEvent()
    }
    
    func retrieveEvents(calendarId: String, startDate: Date, endDate: Date) throws -> [eventide.Event] {
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
    
    func createReminder(timeInterval: TimeInterval, eventId: String) throws -> eventide.Event {
        guard let mockEvent = findEvent(eventId: eventId) else {
            throw PigeonError(
                code: "NOT_FOUND",
                message: "Event not found",
                details: "The provided event.id is certainly incorrect"
            )
        }
        
        if (mockEvent.reminders == nil) {
            mockEvent.reminders = [EKAlarm(relativeOffset: timeInterval)]
        } else {
            mockEvent.reminders!.append(EKAlarm(relativeOffset: timeInterval))
        }

        return mockEvent.toEvent()
    }
    
    func deleteReminder(timeInterval: TimeInterval, eventId: String) throws -> eventide.Event {
        guard let mockEvent = findEvent(eventId: eventId) else {
            throw PigeonError(
                code: "NOT_FOUND",
                message: "Event not found",
                details: "The provided event.id is certainly incorrect"
            )
        }
        
        guard let index = mockEvent.reminders?.firstIndex(where: { -$0.relativeOffset == timeInterval }) else {
            throw PigeonError(
                code: "NOT_FOUND",
                message: "Reminder not found",
                details: nil
            )
        }
        
        mockEvent.reminders?.remove(at: index)
        return mockEvent.toEvent()
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
    let sourceName: String
    var events: [MockEvent]
    
    init(id: String, title: String, color: UIColor, isWritable: Bool, sourceName: String, events: [MockEvent]) {
        self.id = id
        self.title = title
        self.color = color
        self.isWritable = isWritable
        self.sourceName = sourceName
        self.events = events
    }
    
    fileprivate func toCalendar() -> eventide.Calendar {
        eventide.Calendar(
            id: id,
            title: title,
            color: color.toInt64(),
            isWritable: isWritable,
            sourceName: sourceName
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
    var reminders: [EKAlarm]?
    
    init(id: String, title: String, startDate: Date, endDate: Date, calendarId: String, isAllDay: Bool, description: String?, url: String?, reminders: [TimeInterval]? = nil) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.calendarId = calendarId
        self.isAllDay = isAllDay
        self.description = description
        self.url = url
        self.reminders = reminders?.map({ EKAlarm(relativeOffset: $0) })
    }
    
    fileprivate func toEvent() -> Event {
        Event(
            id: id,
            title: title,
            isAllDay: isAllDay,
            startDate: startDate.millisecondsSince1970,
            endDate: endDate.millisecondsSince1970,
            calendarId: calendarId,
            description: description,
            url: url,
            reminders: reminders?.map({ Int64($0.relativeOffset) })
        )
    }
}
