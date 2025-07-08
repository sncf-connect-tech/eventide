//
//  EasyEventStore.swift
//  eventide
//
//  Created by CHOUPAULT Alexis on 31/12/2024.
//

import EventKit
import UIKit

final class EasyEventStore: EasyEventStoreProtocol {
    private let eventStore: EKEventStore
    
    init(eventStore: EKEventStore) {
        self.eventStore = eventStore
    }
    
    func createCalendar(title: String, color: UIColor, localAccountName: String) throws -> Calendar {
        guard let source = getSource() else {
            throw PigeonError(
                code: "NOT_FOUND",
                message: "Calendar source was not found",
                details: "No source has been found between local, iCloud nor default sources"
            )
        }
        
        let ekCalendar = EKCalendar(for: .event, eventStore: eventStore)
        
        ekCalendar.title = title
        ekCalendar.cgColor = color.cgColor
        ekCalendar.source = source
        
        do {
            try eventStore.saveCalendar(ekCalendar, commit: true)
            return ekCalendar.toCalendar()
            
        } catch {
            eventStore.reset()
            throw PigeonError(
                code: "GENERIC_ERROR",
                message: "Error while saving calendar",
                details: error.localizedDescription
            )
        }
    }
    
    func retrieveCalendars(
        onlyWritable: Bool,
        from localAccountName: String?
    ) -> [Calendar] {
        return eventStore.calendars(for: .event)
            .filter { onlyWritable ? $0.allowsContentModifications : true }
            .filter { calendar in
                guard let localAccountName = localAccountName else { return true }
                return calendar.source.sourceIdentifier == localAccountName
            }
            .map { $0.toCalendar() }
    }
    
    func deleteCalendar(calendarId: String) throws {
        guard let calendar = eventStore.calendar(withIdentifier: calendarId) else {
            throw PigeonError(
                code: "NOT_FOUND",
                message: "Calendar not found",
                details: "The provided calendar.id is certainly incorrect"
            )
        }
        
        guard calendar.allowsContentModifications else {
            throw PigeonError(
                code: "NOT_EDITABLE",
                message: "Calendar not editable",
                details: "Calendar does not allow content modifications"
            )
        }
            
        do {
            try eventStore.removeCalendar(calendar, commit: true)
            
        } catch {
            eventStore.reset()
            throw PigeonError(
                code: "GENERIC_ERROR",
                message: "An error occurred",
                details: error.localizedDescription
            )
        }
    }
    
    func createEvent(
        calendarId: String,
        title: String,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool,
        description: String?,
        url: String?,
        timeIntervals: [TimeInterval]?
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
        
        if url != nil {
            ekEvent.url = URL(string: url!)
        }
        
        do {
            try eventStore.save(ekEvent, span: EKSpan.thisEvent, commit: true)
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
        timeIntervals: [TimeInterval]?
    ) throws -> Event {
        let ekEvent = EKEvent(eventStore: eventStore)
       
        ekEvent.calendar = eventStore.defaultCalendarForNewEvents
        ekEvent.title = title
        ekEvent.notes = description
        ekEvent.startDate = startDate
        ekEvent.endDate = endDate
        ekEvent.timeZone = TimeZone(identifier: "UTC")
        ekEvent.isAllDay = isAllDay
        ekEvent.alarms = timeIntervals?.compactMap({ EKAlarm(relativeOffset: $0) })
        
        if url != nil {
            ekEvent.url = URL(string: url!)
        }
        
        do {
            try eventStore.save(ekEvent, span: EKSpan.thisEvent, commit: true)
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
            try eventStore.remove(event, span: .thisEvent)
            
        } catch {
            eventStore.reset()
            throw PigeonError(
                code: "GENERIC_ERROR",
                message: "An error occurred",
                details: error.localizedDescription
            )
        }
    }
    
    func createReminder(timeInterval: TimeInterval, eventId: String) throws -> Event {
        guard let ekEvent = eventStore.event(withIdentifier: eventId) else {
            throw PigeonError(
                code: "NOT_FOUND",
                message: "Event not found",
                details: "The provided event.id is certainly incorrect"
            )
        }
        
        let ekAlarm = EKAlarm(relativeOffset: timeInterval)
        if (ekEvent.alarms == nil) {
            ekEvent.alarms = [ekAlarm]
        } else {
            ekEvent.alarms!.append(ekAlarm)
        }

        do {
            try eventStore.save(ekEvent, span: EKSpan.thisEvent, commit: true)
            return ekEvent.toEvent()
            
        } catch {
            eventStore.reset()
            throw PigeonError(
                code: "GENERIC_ERROR",
                message: "An error occurred",
                details: error.localizedDescription
            )
        }
    }
    
    func deleteReminder(timeInterval: TimeInterval, eventId: String) throws -> Event {
        guard let ekEvent = eventStore.event(withIdentifier: eventId) else {
            throw PigeonError(
                code: "NOT_FOUND",
                message: "Event not found",
                details: "The provided event.id is certainly incorrect"
            )
        }
        
        let alarmsToDelete = ekEvent.alarms?.filter({ $0.relativeOffset == timeInterval })
        
        guard let alarmsToDelete = alarmsToDelete, !alarmsToDelete.isEmpty else {
            throw PigeonError(
                code: "NOT_FOUND",
                message: "Reminder not found",
                details: "The provided reminder is certainly incorrect"
            )
        }
        
        alarmsToDelete.forEach { ekEvent.removeAlarm($0) }
        
        do {
            try self.eventStore.save(ekEvent, span: EKSpan.thisEvent, commit: true)
            return ekEvent.toEvent()
            
        } catch {
            self.eventStore.reset()
            throw PigeonError(
                code: "GENERIC_ERROR",
                message: "An error occurred",
                details: error.localizedDescription
            )
        }
    }
    
    func retrieveAttendees(
        eventId: String
    ) throws -> [Attendee] {
        guard let ekEvent = eventStore.event(withIdentifier: eventId) else {
            throw PigeonError(
                code: "NOT_FOUND",
                message: "Event not found",
                details: "The provided event.id is certainly incorrect"
            )
        }
        
        var attendees: [Attendee] = []
        
        ekEvent.attendees?.forEach {
            attendees.append(
                Attendee(
                    name: $0.name ?? "",
                    email: "",
                    type: Int64($0.participantType.rawValue),
                    role: Int64($0.participantRole.rawValue),
                    status: Int64($0.participantStatus.rawValue)
                )
            )
        }
        
        return attendees
    }
    
    private func getSource() -> EKSource? {
        guard let defaultSource = eventStore.defaultCalendarForNewEvents?.source else {
            // if eventStore.defaultCalendarForNewEvents?.source is nil then eventStore.sources is empty
            return nil
        }
        
        let localSources = eventStore.sources.filter { $0.sourceType == .local }
        let iCloudSources = eventStore.sources.filter { $0.sourceType == .calDAV && $0.sourceIdentifier == "iCloud" }

        return localSources.first ?? iCloudSources.first ?? defaultSource
    }
}

fileprivate extension EKCalendar {
    func toCalendar() -> Calendar {
        Calendar(
            id: calendarIdentifier,
            title: title,
            color: UIColor(cgColor: cgColor).toInt64(),
            isWritable: allowsContentModifications,
            account: Account(
                name: source.sourceIdentifier,
                type: source.sourceType.toString()
            )
        )
    }
}

fileprivate extension EKEvent {
    func toEvent() -> Event {
        Event(
            id: eventIdentifier,
            calendarId: calendar.calendarIdentifier,
            title: title,
            isAllDay: isAllDay,
            startDate: startDate.millisecondsSince1970,
            endDate: endDate.millisecondsSince1970,
            reminders: alarms?.map { Int64($0.relativeOffset) } ?? [],
            attendees: attendees?.compactMap {
                Attendee(
                    name: $0.name ?? "",
                    email: "",
                    type: Int64($0.participantType.rawValue),
                    role: Int64($0.participantRole.rawValue),
                    status: Int64($0.participantStatus.rawValue)
                )
            } ?? [],
            description: notes,
            url: url?.absoluteString
        )
    }
}

fileprivate extension EKSource {
    func toAccount() -> Account {
        return Account(
            name: sourceIdentifier,
            type: sourceType.toString()
        )
    }
}

fileprivate extension EKSourceType {
     init?(from string: String) {
        switch string.lowercased() {
        case "local":
            self = .local
        case "caldav":
            self = .calDAV
        case "exchange":
            self = .exchange
        case "subscribed":
            self = .subscribed
        case "mobileme":
            self = .mobileMe
        case "birthdays":
            self = .birthdays
        default:
            return nil
        }
    }

    func toString() -> String {
        switch self {
        case .local:
            return "Local"
        case .calDAV:
            return "CalDAV"
        case .exchange:
            return "Exchange"
        case .subscribed:
            return "Subscribed"
        case .mobileMe:
            return "MobileMe"
        case .birthdays:
            return "Birthdays"
        @unknown default:
            return "Local"
        }
    }
}
