//
//  CalendarImplem.swift
//  easy_calendar
//
//  Created by CHOUPAULT Alexis on 31/12/2024.
//

import Foundation
import EventKit

class CalendarImplem: CalendarApi {
    let eventStore: EKEventStore
    let permissionHandler: PermissionHandler
    
    init(
        _ eventStore: EKEventStore = EventStoreManager.shared.eventStore,
        _ permissionHandler: PermissionHandler = PermissionHandler()
    ) {
        self.eventStore = eventStore
        self.permissionHandler = permissionHandler
    }
    
    func requestCalendarPermission(completion: @escaping (Result<Bool, any Error>) -> Void) {
        permissionHandler.checkCalendarAccessThenExecute {
            completion(.success(true))
        } noAccess: {
            completion(.success(false))
        } error: { error in
            completion(.failure(error))
        }

    }
    
    func createCalendar(
        title: String,
        color: Int64,
        completion: @escaping (Result<Calendar, Error>) -> Void
    ) {
        permissionHandler.checkCalendarAccessThenExecute {
            guard let source = self.getSource() else {
                completion(.failure(PigeonError(
                    code: "NOT_FOUND",
                    message: "Calendar source was not found",
                    details: "No source has been found between local, iCloud nor default sources"
                )))
                return
            }
            
            guard let uiColor = UIColor(int64: color) else {
                completion(.failure(PigeonError(
                    code: "GENERIC_ERROR",
                    message: "Unable to parse cgColor from hex",
                    details: "hexadecimal number needs to start with # and to be 8 or 6 char long"
                )))
                return
            }
            
            let ekCalendar = EKCalendar(for: .event, eventStore: self.eventStore)
            
            ekCalendar.title = title
            ekCalendar.cgColor = uiColor.cgColor
            ekCalendar.source = source
            
            do {
                try self.eventStore.saveCalendar(ekCalendar, commit: true)
                let calendar = Calendar(
                    id: ekCalendar.calendarIdentifier,
                    title: title,
                    color: uiColor.toInt64(),
                    isWritable: true,
                    sourceName: source.sourceIdentifier
                )
                completion(.success(calendar))
                
            } catch {
                self.eventStore.reset()
                completion(.failure(PigeonError(
                    code: "GENERIC_ERROR",
                    message: "Error while saving calendar",
                    details: nil
                )))
            }
            
        } noAccess: {
            completion(.failure(PigeonError(
                code: "ACCESS_REFUSED",
                message: "Calendar access has been refused or has not been given yet",
                details: nil
            )))
        } error: { error in
            completion(.failure(error))
        }

    }

    func retrieveCalendars(onlyWritableCalendars: Bool, completion: @escaping (Result<[Calendar], Error>) -> Void) {
        permissionHandler.checkCalendarAccessThenExecute {
            let calendars = self.eventStore.calendars(for: .event)
                .filter({ calendar in
                    guard onlyWritableCalendars else {
                        return true
                    }
                    return calendar.allowsContentModifications
                })
                .map {
                    Calendar(
                        id: $0.calendarIdentifier,
                        title: $0.title,
                        color: UIColor(cgColor: $0.cgColor).toInt64(),
                        isWritable: $0.allowsContentModifications,
                        sourceName: $0.source.sourceIdentifier
                    )
                }
            
            completion(.success(calendars))
            
        } noAccess: {
            completion(.failure(PigeonError(
                code: "ACCESS_REFUSED",
                message: "Calendar access has been refused or has not been given yet",
                details: nil
            )))
        } error: { error in
            completion(.failure(error))
        }
    }
    
    func deleteCalendar(_ calendarId: String, completion: @escaping (Result<Void, any Error>) -> Void) {
        permissionHandler.checkCalendarAccessThenExecute {
            guard let calendar = self.eventStore.calendar(withIdentifier: calendarId) else {
                completion(.failure(PigeonError(
                    code: "NOT_FOUND",
                    message: "Calendar not found",
                    details: "The provided calendar.id is certainly incorrect"
                )))
                return
            }
            
            guard calendar.allowsContentModifications else {
                completion(.failure(PigeonError(
                    code: "NOT_EDITABLE",
                    message: "Calendar not editable",
                    details: "Calendar does not allow content modifications"
                )))
                return
            }
                
            do {
                try self.eventStore.removeCalendar(calendar, commit: true)
                completion(.success(()))
                
            } catch {
                self.eventStore.reset()
                completion(.failure(PigeonError(
                    code: "GENERIC_ERROR",
                    message: "An error occurred",
                    details: error.localizedDescription
                )))
            }
            
        } noAccess: {
            completion(.failure(PigeonError(
                code: "ACCESS_REFUSED",
                message: "Calendar access has been refused or has not been given yet",
                details: nil
            )))
        } error: { error in
            completion(.failure(error))
        }

    }
    
    func createEvent(
        title: String,
        startDate: Int64,
        endDate: Int64,
        calendarId: String,
        description: String?,
        url: String?,
        completion: @escaping (Result<Event, Error>
    ) -> Void) {
        permissionHandler.checkCalendarAccessThenExecute {
            let ekEvent = EKEvent(eventStore: self.eventStore)
            
            /*
            if event.id == nil {
                ekEvent = EKEvent(eventStore: self.eventStore)
            } else {
                ekEvent = self.eventStore.event(withIdentifier: event.id!)
            }
                         
            guard let ekEvent else {
                completion(.failure(PigeonError(
                    code: "NOT_FOUND",
                    message: "Event not found",
                    details: "The provided event.id is certainly incorrect"
                )))
                return
            }
             */
            
            guard let ekCalendar = self.eventStore.calendar(withIdentifier: calendarId) else {
                completion(.failure(PigeonError(
                    code: "NOT_FOUND",
                    message: "Calendar not found",
                    details: "The provided calendar.id is certainly incorrect"
                )))
                return
            }

            ekEvent.calendar = ekCalendar
            ekEvent.title = title
            ekEvent.notes = description
            ekEvent.startDate = Date(from: startDate)
            ekEvent.endDate = Date(from: endDate)
            ekEvent.timeZone = TimeZone(identifier: "UTC")
            // TODO: location
            
            if url != nil {
                ekEvent.url = URL(string: url!)
            }
            
            do {
                try self.eventStore.save(ekEvent, span: EKSpan.thisEvent, commit: true)
                completion(.success(
                    Event(
                        id: ekEvent.eventIdentifier,
                        title: title,
                        startDate: startDate,
                        endDate: endDate,
                        calendarId: calendarId
                    )
                ))
                
            } catch {
                self.eventStore.reset()
                completion(.failure(PigeonError(
                    code: "GENERIC_ERROR",
                    message: "Event not created",
                    details: nil
                )))
            }
        } noAccess: {
            completion(.failure(PigeonError(
                code: "ACCESS_REFUSED",
                message: "Calendar access has been refused or has not been given yet",
                details: nil
            )))
        } error: { error in
            completion(.failure(error))
        }
    }
    
    func retrieveEvents(
        calendarId: String,
        startDate: Int64,
        endDate: Int64,
        completion: @escaping (Result<[Event], any Error>) -> Void
    ) {
        permissionHandler.checkCalendarAccessThenExecute {
            guard let calendar = self.eventStore.calendar(withIdentifier: calendarId) else {
                completion(.failure(PigeonError(
                    code: "NOT_FOUND",
                    message: "Calendar not found",
                    details: "The provided calendar.id is certainly incorrect"
                )))
                return
            }
            
            let predicate = self.eventStore.predicateForEvents(
                withStart: Date(from: startDate),
                end: Date(from: endDate),
                calendars: [calendar]
            )
            
            let ekEvents = self.eventStore.events(matching: predicate)
            
            completion(.success(ekEvents.map { ekEvent in
                return Event(
                    id: ekEvent.eventIdentifier,
                    title: ekEvent.title,
                    startDate: ekEvent.startDate.millisecondsSince1970,
                    endDate: ekEvent.endDate.millisecondsSince1970,
                    calendarId: ekEvent.calendar.calendarIdentifier,
                    reminders: ekEvent.alarms?.map { Int64($0.relativeOffset) }
                )
            }))
        } noAccess: {
            completion(.failure(PigeonError(
                code: "ACCESS_REFUSED",
                message: "Calendar access has been refused or has not been given yet",
                details: nil
            )))
        } error: { error in
            completion(.failure(error))
        }
    }
    
    func deleteEvent(withId eventId: String, _ calendarId: String, completion: @escaping (Result<Void, any Error>) -> Void) {
        permissionHandler.checkCalendarAccessThenExecute {
            guard let calendar = self.eventStore.calendar(withIdentifier: calendarId) else {
                completion(.failure(PigeonError(
                    code: "NOT_FOUND",
                    message: "Calendar not found",
                    details: "The provided calendar.id is certainly incorrect"
                )))
                return
            }
            
            guard calendar.allowsContentModifications else {
                completion(.failure(PigeonError(
                    code: "NOT_EDITABLE",
                    message: "Calendar not editable",
                    details: "Calendar does not allow content modifications"
                )))
                return
            }
            
            guard let event = self.eventStore.event(withIdentifier: eventId) else {
                completion(.failure(PigeonError(
                    code: "NOT_FOUND",
                    message: "Event not found",
                    details: "The provided event.id is certainly incorrect"
                )))
                return
            }
                
            do {
                try self.eventStore.remove(event, span: .thisEvent)
                // TODO: handle recurrent events
                completion(.success(()))
                
            } catch {
                self.eventStore.reset()
                completion(.failure(PigeonError(
                    code: "GENERIC_ERROR",
                    message: "An error occurred",
                    details: error.localizedDescription
                )))
            }
            
        } noAccess: {
            completion(.failure(PigeonError(
                code: "ACCESS_REFUSED",
                message: "Calendar access has been refused or has not been given yet",
                details: nil
            )))
        } error: { error in
            completion(.failure(error))
        }
    }
    
    func createReminder(_ reminder: Int64, forEventId eventId: String, completion: @escaping (Result<Event, any Error>) -> Void) {
        permissionHandler.checkCalendarAccessThenExecute {
            guard let ekEvent = self.eventStore.event(withIdentifier: eventId) else {
                completion(.failure(PigeonError(
                    code: "NOT_FOUND",
                    message: "Event not found",
                    details: "The provided event.id is certainly incorrect"
                )))
                return
            }
            
            let ekAlarm = EKAlarm(relativeOffset: TimeInterval(-reminder))
            if (ekEvent.alarms == nil) {
                ekEvent.alarms = [ekAlarm]
            } else {
                ekEvent.alarms!.append(ekAlarm)
            }

            do {
                try self.eventStore.save(ekEvent, span: EKSpan.thisEvent, commit: true)
                completion(.success(
                    Event(
                        id: ekEvent.eventIdentifier,
                        title: ekEvent.title,
                        startDate: ekEvent.startDate.millisecondsSince1970,
                        endDate: ekEvent.endDate.millisecondsSince1970,
                        calendarId: ekEvent.calendar.calendarIdentifier,
                        reminders: ekEvent.alarms?.map { Int64($0.relativeOffset) }
                    )
                ))
                
            } catch {
                self.eventStore.reset()
                completion(.failure(PigeonError(
                    code: "GENERIC_ERROR",
                    message: "An error occurred",
                    details: error.localizedDescription
                )))
            }
            
        } noAccess: {
            completion(.failure(PigeonError(
                code: "ACCESS_REFUSED",
                message: "Calendar access has been refused or has not been given yet",
                details: nil
            )))
        } error: { error in
            completion(.failure(error))
        }

    }
    
    func deleteReminder(_ reminder: Int64, withEventId eventId: String, completion: @escaping (Result<Event, any Error>) -> Void) {
        permissionHandler.checkCalendarAccessThenExecute {
            guard let ekEvent = self.eventStore.event(withIdentifier: eventId) else {
                completion(.failure(PigeonError(
                    code: "NOT_FOUND",
                    message: "Event not found",
                    details: "The provided event.id is certainly incorrect"
                )))
                return
            }
            
            let alarmsToDelete = ekEvent.alarms?.filter({ $0.relativeOffset == -TimeInterval(reminder) })
            
            guard let alarmsToDelete = alarmsToDelete, !alarmsToDelete.isEmpty else {
                completion(.failure(PigeonError(
                    code: "NOT_FOUND",
                    message: "Reminder not found",
                    details: "The provided reminder is certainly incorrect"
                )))
                return
            }
            
            alarmsToDelete.forEach { ekEvent.removeAlarm($0) }
            
            do {
                try self.eventStore.save(ekEvent, span: EKSpan.thisEvent, commit: true)
                
                completion(.success(
                    Event(
                        id: ekEvent.eventIdentifier,
                        title: ekEvent.title,
                        startDate: ekEvent.startDate.millisecondsSince1970,
                        endDate: ekEvent.endDate.millisecondsSince1970,
                        calendarId: ekEvent.calendar.calendarIdentifier,
                        reminders: ekEvent.alarms?.map { Int64($0.relativeOffset) }
                    )
                ))
                
            } catch {
                self.eventStore.reset()
                completion(.failure(PigeonError(
                    code: "GENERIC_ERROR",
                    message: "An error occurred",
                    details: error.localizedDescription
                )))
            }
        } noAccess: {
            completion(.failure(PigeonError(
                code: "ACCESS_REFUSED",
                message: "Calendar access has been refused or has not been given yet",
                details: nil
            )))
        } error: { error in
            completion(.failure(error))
        }
    }
    
    private func getSource() -> EKSource? {
        guard let defaultSource = eventStore.defaultCalendarForNewEvents?.source else {
            // if eventStore.defaultCalendarForNewEvents?.source is nil then eventStore.sources is empty
            return nil
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
