//
//  EasyEventStore.swift
//  eventide
//
//  Created by CHOUPAULT Alexis on 31/12/2024.
//

import EventKit

final class EasyEventStore: EasyEventStoreProtocol {
    private let eventStore: EKEventStore
    
    init(eventStore: EKEventStore) {
        self.eventStore = eventStore
    }
    
    func createCalendar(title: String, color: UIColor, account: Account?) throws -> Calendar {
        guard let source = getSource(account: account) else {
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
    
    func retrieveCalendars(onlyWritable: Bool) -> [Calendar] {
        return eventStore.calendars(for: .event)
            .filter { onlyWritable ? $0.allowsContentModifications : true }
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
    
    func createEvent(calendarId: String, title: String, startDate: Date, endDate: Date, isAllDay: Bool, description: String?, url: String?) throws -> Event {
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
    
    private func getSource(account: Account?) -> EKSource? {
        guard let defaultSource = eventStore.defaultCalendarForNewEvents?.source else {
            // if eventStore.defaultCalendarForNewEvents?.source is nil then eventStore.sources is empty
            return nil
        }
        
        if let account = account, let sourceType = EKSourceType(from: account.type) {
            let wantedSources = eventStore.sources.filter { $0.sourceType == sourceType && $0.sourceIdentifier == account.name }
            if !wantedSources.isEmpty {
                return wantedSources.first
            }
        }
        
        let iCloudSources = eventStore.sources.filter { $0.sourceType == .calDAV && $0.sourceIdentifier == "iCloud" }

        if (!iCloudSources.isEmpty) {
            return iCloudSources.first
        }
        
        let localSources = eventStore.sources.filter { $0.sourceType == .local }

        if (!localSources.isEmpty) {
            return localSources.first
        }

        return defaultSource
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
            title: title,
            isAllDay: isAllDay,
            startDate: startDate.millisecondsSince1970,
            endDate: endDate.millisecondsSince1970,
            calendarId: calendar.calendarIdentifier,
            description: notes,
            url: url?.absoluteString,
            reminders: alarms?.map { Int64($0.relativeOffset) }
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
