//
//  CalendarImplem.swift
//  eventide
//
//  Created by CHOUPAULT Alexis on 31/12/2024.
//

import Foundation
import UIKit

class CalendarImplem: CalendarApi {
    private let easyEventStore: EasyEventStoreProtocol
    private let permissionHandler: PermissionHandlerProtocol
    
    init(easyEventStore: EasyEventStoreProtocol, permissionHandler: PermissionHandlerProtocol) {
        self.easyEventStore = easyEventStore
        self.permissionHandler = permissionHandler
    }

    func createCalendar(
        title: String,
        color: Int64,
        in account: Account?,
        completion: @escaping (Result<Calendar, Error>) -> Void
    ) {
        permissionHandler.checkCalendarAccessThenExecute(.fullAccess) { [self] in
            do {
                let createdCalendar = try easyEventStore.createCalendar(title: title, color: UIColor(int64: color), account: account)
                completion(.success(createdCalendar))
                
            } catch {
                completion(.failure(error))
            }
            
        } onPermissionRefused: {
            completion(.failure(PigeonError(
                code: "ACCESS_REFUSED",
                message: "Calendar access has been refused or has not been given yet",
                details: nil
            )))
        } onPermissionError: { error in
            completion(.failure(error))
        }
    }
    
    func retrieveCalendars(
        onlyWritable onlyWritableCalendars: Bool,
        from account: Account?,
        completion: @escaping (Result<[Calendar], Error>) -> Void
    ) {
        permissionHandler.checkCalendarAccessThenExecute(.fullAccess) { [self] in
            let calendars = easyEventStore.retrieveCalendars(onlyWritable: onlyWritableCalendars, from: account)
            completion(.success(calendars))
            
        } onPermissionRefused: {
            completion(.failure(PigeonError(
                code: "ACCESS_REFUSED",
                message: "Calendar access has been refused or has not been given yet",
                details: nil
            )))
        } onPermissionError: { error in
            completion(.failure(error))
        }
    }
    
    func retrieveAccounts(completion: @escaping (Result<[Account], Error>) -> Void) {
        permissionHandler.checkCalendarAccessThenExecute(.fullAccess) { [self] in
            let accounts = easyEventStore.retrieveAccounts()
            completion(.success(accounts))
            
        } onPermissionRefused: {
            completion(.failure(PigeonError(
                code: "ACCESS_REFUSED",
                message: "Calendar access has been refused or has not been given yet",
                details: nil
            )))
        } onPermissionError: { error in
            completion(.failure(error))
        }
    }
    
    func updateCalendar(withId calendarId: String, title: String, color: Int64, completion: @escaping (Result<Calendar, Error>) -> Void) {
        permissionHandler.checkCalendarAccessThenExecute(.fullAccess) { [self] in
            do {
                let calendar = try easyEventStore.updateCalendar(calendarId: calendarId, title: title, color: UIColor(int64: color))
                completion(.success(calendar))
                
            } catch {
                completion(.failure(error))
            }
            
        } onPermissionRefused: {
            completion(.failure(PigeonError(
                code: "ACCESS_REFUSED",
                message: "Calendar access has been refused or has not been given yet",
                details: nil
            )))
        } onPermissionError: { error in
            completion(.failure(error))
        }
    }
    
    func deleteCalendar(_ calendarId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        permissionHandler.checkCalendarAccessThenExecute(.fullAccess) { [self] in
            do {
                try easyEventStore.deleteCalendar(calendarId: calendarId)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
            
        } onPermissionRefused: {
            completion(.failure(PigeonError(
                code: "ACCESS_REFUSED",
                message: "Calendar access has been refused or has not been given yet",
                details: nil
            )))
        } onPermissionError: { error in
            completion(.failure(error))
        }

    }
    
    func createEvent(
        calendarId: String,
        title: String,
        startDate: Int64,
        endDate: Int64,
        isAllDay: Bool,
        description: String?,
        url: String?,
        location: String?,
        reminders: [Int64]?,
        recurrenceRule: String? = nil,
        completion: @escaping (Result<Event, Error>) -> Void) {
        permissionHandler.checkCalendarAccessThenExecute(.writeOnly) { [self] in
            do {
                let createdEvent = try easyEventStore.createEvent(
                    calendarId: calendarId,
                    title: title,
                    startDate: Date(from: startDate),
                    endDate: Date(from: endDate),
                    isAllDay: isAllDay,
                    description: description,
                    url: url,
                    location: location,
                    timeIntervals: reminders?.compactMap { TimeInterval(-$0) },
                    recurrenceRule: recurrenceRule
                )
                completion(.success(createdEvent))

            } catch {
                completion(.failure(error))
            }

        } onPermissionRefused: {
            completion(.failure(PigeonError(
                code: "ACCESS_REFUSED",
                message: "Calendar access has been refused or has not been given yet",
                details: nil
            )))
        } onPermissionError: { error in
            completion(.failure(error))
        }
    }
    
    func createEventInDefaultCalendar(
        title: String,
        startDate: Int64,
        endDate: Int64,
        isAllDay: Bool,
        description: String?,
        url: String?,
        location: String?,
        reminders: [Int64]?,
        recurrenceRule: String? = nil,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        permissionHandler.checkCalendarAccessThenExecute(.writeOnly) { [self] in
            do {
                let createdEvent = try easyEventStore.createEvent(
                    title: title,
                    startDate: Date(from: startDate),
                    endDate: Date(from: endDate),
                    isAllDay: isAllDay,
                    description: description,
                    url: url,
                    location: location,
                    timeIntervals: reminders?.compactMap { TimeInterval(-$0) },
                    recurrenceRule: recurrenceRule
                )
                completion(.success(()))

            } catch {
                completion(.failure(error))
            }

        } onPermissionRefused: {
            completion(.failure(PigeonError(
                code: "ACCESS_REFUSED",
                message: "Calendar access has been refused or has not been given yet",
                details: nil
            )))
        } onPermissionError: { error in
            completion(.failure(error))
        }

    }
    
    func createEventThroughNativePlatform(
        title: String?,
        startDate: Int64?,
        endDate: Int64?,
        isAllDay: Bool?,
        description: String?,
        url: String?,
        location: String?,
        reminders: [Int64]?,
        recurrenceRule: String? = nil,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        easyEventStore.presentEventCreationViewController(
            title: title,
            startDate: startDate != nil ? Date(from: startDate!) : nil,
            endDate: endDate != nil ? Date(from: endDate!) : nil,
            isAllDay: isAllDay,
            description: description,
            url: url,
            location: location,
            timeIntervals: reminders?.compactMap { TimeInterval(-$0) },
            recurrenceRule: recurrenceRule
        ) { result in
            completion(result)
        }
    }
    
    func retrieveEvents(
        calendarId: String,
        startDate: Int64,
        endDate: Int64,
        completion: @escaping (Result<[Event], Error>) -> Void
    ) {
        permissionHandler.checkCalendarAccessThenExecute(.fullAccess) { [self] in
            do {
                let events = try easyEventStore.retrieveEvents(
                    calendarId: calendarId,
                    startDate: Date(from: startDate),
                    endDate: Date(from: endDate)
                )
                completion(.success(events))
                
            } catch {
                completion(.failure(error))
            }
            
        } onPermissionRefused: {
            completion(.failure(PigeonError(
                code: "ACCESS_REFUSED",
                message: "Calendar access has been refused or has not been given yet",
                details: nil
            )))
        } onPermissionError: { error in
            completion(.failure(error))
        }
    }
    
    func updateEvent(
        withId eventId: String,
        calendarId: String,
        title: String,
        startDate: Int64,
        endDate: Int64,
        isAllDay: Bool,
        description: String?,
        url: String?,
        location: String?,
        reminders: [Int64]?,
        recurrenceRule: String? = nil,
        span: String = "allEvents",
        originalInstanceTime: Int64? = nil,
        completion: @escaping (Result<Event, Error>) -> Void
    ) {
        permissionHandler.checkCalendarAccessThenExecute(.fullAccess) { [self] in
            do {
                let event = try easyEventStore.updateEvent(
                    eventId: eventId,
                    calendarId: calendarId,
                    title: title,
                    startDate: Date(from: startDate),
                    endDate: Date(from: endDate),
                    isAllDay: isAllDay,
                    description: description,
                    url: url,
                    location: location,
                    timeIntervals: reminders?.compactMap { TimeInterval(-$0) },
                    recurrenceRule: recurrenceRule,
                    span: span,
                    originalInstanceTime: originalInstanceTime
                )
                completion(.success(event))
                
            } catch {
                completion(.failure(error))
            }
            
        } onPermissionRefused: {
            completion(.failure(PigeonError(
                code: "ACCESS_REFUSED",
                message: "Calendar access has been refused or has not been given yet",
                details: nil
            )))
        } onPermissionError: { error in
            completion(.failure(error))
        }
    }
    
    func deleteEvent(withId eventId: String, span: String = "allEvents", originalInstanceTime: Int64? = nil, completion: @escaping (Result<Void, Error>) -> Void) {
        permissionHandler.checkCalendarAccessThenExecute(.fullAccess) { [self] in
            do {
                try easyEventStore.deleteEvent(eventId: eventId, span: span, originalInstanceTime: originalInstanceTime)
                completion(.success(()))
                
            } catch {
                completion(.failure(error))
            }
            
        } onPermissionRefused: {
            completion(.failure(PigeonError(
                code: "ACCESS_REFUSED",
                message: "Calendar access has been refused or has not been given yet",
                details: nil
            )))
        } onPermissionError: { error in
            completion(.failure(error))
        }
    }
    
    func createReminder(_ reminder: Int64, forEventId eventId: String, completion: @escaping (Result<Event, Error>) -> Void) {
        permissionHandler.checkCalendarAccessThenExecute(.fullAccess) { [self] in
            do {
                let modifiedEvent = try easyEventStore.createReminder(timeInterval: TimeInterval(-reminder), eventId: eventId)
                completion(.success(modifiedEvent))
                
            } catch {
                completion(.failure(error))
            }
            
        } onPermissionRefused: {
            completion(.failure(PigeonError(
                code: "ACCESS_REFUSED",
                message: "Calendar access has been refused or has not been given yet",
                details: nil
            )))
        } onPermissionError: { error in
            completion(.failure(error))
        }

    }
    
    func deleteReminder(_ reminder: Int64, withEventId eventId: String, completion: @escaping (Result<Event, Error>) -> Void) {
        permissionHandler.checkCalendarAccessThenExecute(.fullAccess) { [self] in
            do {
                let modifiedEvent = try easyEventStore.deleteReminder(timeInterval: TimeInterval(-reminder), eventId: eventId)
                completion(.success(modifiedEvent))
                
            } catch {
                completion(.failure(error))
            }
            
        } onPermissionRefused: {
            completion(.failure(PigeonError(
                code: "ACCESS_REFUSED",
                message: "Calendar access has been refused or has not been given yet",
                details: nil
            )))
        } onPermissionError: { error in
            completion(.failure(error))
        }
    }
    
    func createAttendee(
        eventId: String,
        name: String,
        email: String,
        role: Int64,
        type: Int64,
        completion: @escaping (Result<Event, Error>) -> Void
    ) {
        /// EventKit cannot add participants to an event nor change participant information.
        /// https://developer.apple.com/documentation/eventkit/ekparticipant#overview
        completion(.failure(
            PigeonError(
                code: "NOT_SUPPORTED_BY_PLATFORM",
                message: "Platform does not handle this method",
                details: "EventKit API does not support attendee addition"
            )
        ))
    }
    
    func deleteAttendee(
        eventId: String,
        email: String,
        completion: @escaping (Result<Event, Error>) -> Void
    ) {
        /// EventKit cannot add participants to an event nor change participant information.
        /// https://developer.apple.com/documentation/eventkit/ekparticipant#overview
        completion(.failure(
            PigeonError(
                code: "NOT_SUPPORTED_BY_PLATFORM",
                message: "Platform does not handle this method",
                details: "EventKit API does not support attendee deletion"
            )
        ))
    }
}
