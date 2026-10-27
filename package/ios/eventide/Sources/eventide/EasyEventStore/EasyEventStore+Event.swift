//
//  EasyEventStore+Event.swift
//  eventide
//
//  Created by CHOUPAULT Alexis on 29/10/2026.
//

import EventKit
import Foundation

protocol EventProtocol {
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
    ) throws -> Event
    
    func createEvent(
        title: String,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool,
        description: String?,
        url: String?,
        location: String?,
        timeIntervals: [TimeInterval]?,
        recurrenceRule: String?
    ) throws
    
    func presentEventCreationViewController(
        title: String?,
        startDate: Date?,
        endDate: Date?,
        isAllDay: Bool?,
        description: String?,
        url: String?,
        location: String?,
        timeIntervals: [TimeInterval]?,
        recurrenceRule: String?,
        completion: @escaping (Result<Void, Error>) -> Void
    )
    
    func retrieveEvents(calendarId: String, startDate: Date, endDate: Date) throws -> [Event]
    
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
        originalInstanceDate: Date,
        span: Span
    ) throws -> Event
    
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
    ) throws -> Event
    
    func deleteEvent(eventId: String, originalInstanceDate: Date, span: Span) throws -> Void
    func deleteEvent(eventId: String) throws -> Void
}

extension EasyEventStore {
    // MARK: - CalendarApi implementation
    
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
        let ekEvent = EKEvent(eventStore: eventStore)

        guard let ekCalendar = eventStore.calendar(withIdentifier: calendarId) else {
            throw PigeonError(
                code: "NOT_FOUND",
                message: "Calendar not found",
                details: "The provided calendar.id is certainly incorrect"
            )
        }

        ekEvent.calendar = ekCalendar
        ekEvent.title = title
        ekEvent.notes = description
        ekEvent.startDate = startDate
        ekEvent.endDate = endDate
        ekEvent.timeZone = TimeZone(identifier: "UTC")
        ekEvent.isAllDay = isAllDay
        ekEvent.alarms = timeIntervals?.compactMap({ EKAlarm(relativeOffset: $0) })
        ekEvent.location = location

        if let recurrenceRule,
           let ekRule = RRuleParser.parse(recurrenceRule) {
            ekEvent.recurrenceRules = [ekRule]
        }

        if url != nil {
            ekEvent.url = URL(string: url!)
        }

        do {
            try eventStore.save(ekEvent, span: .thisEvent, commit: true)
            return ekEvent.toEvent()

        } catch {
            eventStore.reset()
            throw PigeonError(
                code: "GENERIC_ERROR",
                message: "Event not created",
                details: nil
            )
        }
    }
    
    func createEvent(
        title: String,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool,
        description: String?,
        url: String?,
        location: String?,
        timeIntervals: [TimeInterval]?,
        recurrenceRule: String?
    ) throws {
        let ekEvent = EKEvent(eventStore: eventStore)

        ekEvent.calendar = eventStore.defaultCalendarForNewEvents
        ekEvent.title = title
        ekEvent.notes = description
        ekEvent.startDate = startDate
        ekEvent.endDate = endDate
        ekEvent.timeZone = TimeZone(identifier: "UTC")
        ekEvent.isAllDay = isAllDay
        ekEvent.alarms = timeIntervals?.compactMap({ EKAlarm(relativeOffset: $0) })
        ekEvent.location = location

        if let rrule = recurrenceRule,
           let ekRule = RRuleParser.parse(rrule) {
            ekEvent.recurrenceRules = [ekRule]
        }

        if url != nil {
            ekEvent.url = URL(string: url!)
        }

        do {
            try eventStore.save(ekEvent, span: .thisEvent, commit: true)

        } catch {
            eventStore.reset()
            throw PigeonError(
                code: "GENERIC_ERROR",
                message: "Event not created",
                details: nil
            )
        }
    }
    
    func presentEventCreationViewController(
        title: String?,
        startDate: Date?,
        endDate: Date?,
        isAllDay: Bool?,
        description: String?,
        url: String?,
        location: String?,
        timeIntervals: [TimeInterval]?,
        recurrenceRule: String?,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        eventEditManager.presentEventEditViewController(
            title: title,
            startDate: startDate,
            endDate: endDate,
            isAllDay: isAllDay,
            description: description,
            url: url,
            location: location,
            timeIntervals: timeIntervals,
            recurrenceRule: recurrenceRule,
            completion: completion
        )
    }
    
    func retrieveEvents(calendarId: String, startDate: Date, endDate: Date) throws -> [Event] {
        guard let calendar = eventStore.calendar(withIdentifier: calendarId) else {
            throw PigeonError(
                code: "NOT_FOUND",
                message: "Calendar not found",
                details: "The provided calendar.id is certainly incorrect"
            )
        }
        
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: [calendar]
        )
        
        return eventStore.events(matching: predicate).map { $0.toEvent() }
    }
    
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
        originalInstanceDate: Date,
        span: Span
    ) throws -> Event {
        switch span {
        case .thisEvent:
            return try updateThisEventOccurrence(
                eventId: eventId,
                calendarId: calendarId,
                title: title,
                startDate: startDate,
                endDate: endDate,
                isAllDay: isAllDay,
                description: description,
                url: url,
                location: location,
                timeIntervals: timeIntervals,
                originalInstanceDate: originalInstanceDate
            )
            
        case .thisAndFuture:
            return try updateThisAndFutureEvents(
                eventId: eventId,
                calendarId: calendarId,
                title: title,
                startDate: startDate,
                endDate: endDate,
                isAllDay: isAllDay,
                description: description,
                url: url,
                location: location,
                timeIntervals: timeIntervals,
                recurrenceRule: recurrenceRule,
                originalInstanceDate: originalInstanceDate
            )
        }
    }
    
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
        timeIntervals: [TimeInterval]?
    ) throws -> Event {
        guard let ekEvent = eventStore.event(withIdentifier: eventId) else {
            throw PigeonError(
                code: "NOT_FOUND",
                message: "Event not found",
                details: "The provided event.id is certainly incorrect"
            )
        }
        
        try applyCommonFields(
            to: ekEvent,
            calendarId: calendarId,
            title: title,
            description: description,
            url: url,
            location: location,
            isAllDay: isAllDay,
            timeIntervals: timeIntervals
        )
        
        ekEvent.startDate = startDate
        ekEvent.endDate = endDate
        
        do {
            try eventStore.save(ekEvent, span: .thisEvent, commit: true)
            return ekEvent.toEvent()
        } catch {
            eventStore.reset()
            throw PigeonError(
                code: "GENERIC_ERROR",
                message: "Event not updated",
                details: error.localizedDescription
            )
        }
    }
    
    func deleteEvent(eventId: String, originalInstanceDate: Date, span: Span) throws {
        guard let occurrence = findOccurrence(eventId: eventId, originalInstanceDate: originalInstanceDate) else {
            throw PigeonError(
                code: "NOT_FOUND",
                message: "Event not found",
                details: "The provided eventId or originalInstanceDate is certainly incorrect"
            )
        }
        
        guard occurrence.calendar.allowsContentModifications else {
            throw PigeonError(
                code: "NOT_EDITABLE",
                message: "Calendar not editable",
                details: "The calendar related to this event does not allow content modifications"
            )
        }
        
        do {
            try eventStore.remove(occurrence, span: span.toEKSpan())
        } catch {
            eventStore.reset()
            throw PigeonError(
                code: "GENERIC_ERROR",
                message: "An error occurred",
                details: error.localizedDescription
            )
        }
    }
        
    func deleteEvent(eventId: String) throws {
        guard let event = eventStore.event(withIdentifier: eventId) else {
            throw PigeonError(
                code: "NOT_FOUND",
                message: "Event not found",
                details: "The provided event.id is certainly incorrect"
            )
        }

        guard event.calendar.allowsContentModifications else {
            throw PigeonError(
                code: "NOT_EDITABLE",
                message: "Calendar not editable",
                details: "The calendar related to this event does not allow content modifications"
            )
        }

        do {
            let ekSpan: EKSpan = event.hasRecurrenceRules ? .futureEvents : .thisEvent
            try eventStore.remove(event, span: ekSpan)

        } catch {
            eventStore.reset()
            throw PigeonError(
                code: "GENERIC_ERROR",
                message: "An error occurred",
                details: error.localizedDescription
            )
        }
    }
    
    // MARK: - Private methods
        
    /// Fetches the specific EKEvent occurrence for [eventId] whose occurrenceDate
    /// matches [originalInstanceDateMs] (within a 60-second tolerance).
    private func findOccurrence(eventId: String, originalInstanceDate: Date) -> EKEvent? {
        let predicate = eventStore.predicateForEvents(
            withStart: originalInstanceDate.addingTimeInterval(-86400),
            end: originalInstanceDate.addingTimeInterval(86400),
            calendars: nil
        )
        return eventStore.events(matching: predicate).first {
            ($0.eventIdentifier == eventId || $0.eventIdentifier.starts(with: eventId) || eventId.starts(with: $0.eventIdentifier)) &&
            abs(($0.occurrenceDate ?? $0.startDate).timeIntervalSince(originalInstanceDate)) < 60.0
        }
    }
    
    private func applyCommonFields(
        to ekEvent: EKEvent,
        calendarId: String,
        title: String,
        description: String?,
        url: String?,
        location: String?,
        isAllDay: Bool,
        timeIntervals: [TimeInterval]?
    ) throws {
        guard ekEvent.calendar.allowsContentModifications else {
            throw PigeonError(
                code: "NOT_EDITABLE",
                message: "Event actual calendar is not editable",
                details: "Calendar does not allow content modifications"
            )
        }

        if calendarId != ekEvent.calendar.calendarIdentifier {
            guard let ekCalendar = eventStore.calendar(withIdentifier: calendarId) else {
                throw PigeonError(
                    code: "NOT_FOUND",
                    message: "Calendar not found",
                    details: "The provided calendar.id is certainly incorrect"
                )
            }
            guard ekCalendar.allowsContentModifications else {
                throw PigeonError(
                    code: "NOT_EDITABLE",
                    message: "Event new calendar is not editable",
                    details: "Calendar does not allow content modifications"
                )
            }
            ekEvent.calendar = ekCalendar
        }

        ekEvent.title = title
        ekEvent.notes = description
        ekEvent.timeZone = TimeZone(identifier: "UTC")
        ekEvent.isAllDay = isAllDay
        ekEvent.location = location

        if let url {
            ekEvent.url = URL(string: url)
        } else {
            ekEvent.url = nil
        }

        if let timeIntervals {
            ekEvent.alarms = timeIntervals.map({ EKAlarm(relativeOffset: $0) })
        }
    }

    private func updateThisEventOccurrence(
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
        originalInstanceDate: Date
    ) throws -> Event {
        guard let occurrence = findOccurrence(eventId: eventId, originalInstanceDate: originalInstanceDate) else {
            throw PigeonError(
                code: "NOT_FOUND",
                message: "Event occurrence not found",
                details: "The provided eventId or originalInstanceDate is certainly incorrect"
            )
        }

        try applyCommonFields(
            to: occurrence,
            calendarId: calendarId,
            title: title,
            description: description,
            url: url,
            location: location,
            isAllDay: isAllDay,
            timeIntervals: timeIntervals
        )

        occurrence.startDate = startDate
        occurrence.endDate = endDate

        do {
            try eventStore.save(occurrence, span: .thisEvent, commit: true)
            return occurrence.toEvent()
        } catch {
            eventStore.reset()
            throw PigeonError(
                code: "GENERIC_ERROR",
                message: "Event not updated",
                details: error.localizedDescription
            )
        }
    }

    private func updateThisAndFutureEvents(
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
        originalInstanceDate: Date
    ) throws -> Event {
        guard let occurrence = findOccurrence(eventId: eventId, originalInstanceDate: originalInstanceDate) else {
            throw PigeonError(
                code: "NOT_FOUND",
                message: "Event occurrence not found",
                details: "The provided eventId or originalInstanceDate is certainly incorrect"
            )
        }

        try applyCommonFields(
            to: occurrence,
            calendarId: calendarId,
            title: title,
            description: description,
            url: url,
            location: location,
            isAllDay: isAllDay,
            timeIntervals: timeIntervals
        )

        occurrence.startDate = startDate
        occurrence.endDate = endDate

        if let rrule = recurrenceRule, let ekRule = RRuleParser.parse(rrule) {
            occurrence.recurrenceRules = [ekRule]
        }

        do {
            try eventStore.save(occurrence, span: .futureEvents, commit: true)
            return occurrence.toEvent()
        } catch {
            eventStore.reset()
            throw PigeonError(
                code: "GENERIC_ERROR",
                message: "Event not updated",
                details: error.localizedDescription
            )
        }
    }
}
