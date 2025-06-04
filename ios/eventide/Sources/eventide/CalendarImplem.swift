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
    
    func requestCalendarPermission(completion: @escaping (Result<Bool, any Error>) -> Void) {
        permissionHandler.checkCalendarAccessThenExecute {
            completion(.success(true))
        } onPermissionRefused: {
            completion(.success(false))
        } onPermissionError: { error in
            completion(.failure(error))
        }
    }
    
    func createCalendar(
        title: String,
        color: Int64,
        localAccountName: String,
        completion: @escaping (Result<Calendar, Error>) -> Void
    ) {
        permissionHandler.checkCalendarAccessThenExecute { [self] in            
            do {
                let createdCalendar = try easyEventStore.createCalendar(title: title, color: UIColor(int64: color), localAccountName: localAccountName)
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
        onlyWritableCalendars: Bool,
        fromLocalAccountName accountName: String?,
        completion: @escaping (Result<[Calendar], Error>) -> Void
    ) {
        permissionHandler.checkCalendarAccessThenExecute { [self] in
            let calendars = easyEventStore.retrieveCalendars(onlyWritable: onlyWritableCalendars, from: accountName)
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
    
    func deleteCalendar(calendarId: String, completion: @escaping (Result<Void, any Error>) -> Void) {
        permissionHandler.checkCalendarAccessThenExecute { [self] in
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
        rRule: String?,
        completion: @escaping (Result<Event, Error>
    ) -> Void) {
        permissionHandler.checkCalendarAccessThenExecute { [self] in
            do {
                let createdEvent = try easyEventStore.createEvent(
                    calendarId: calendarId,
                    title: title,
                    startDate: Date(from: startDate),
                    endDate: Date(from: endDate),
                    isAllDay: isAllDay,
                    description: description,
                    url: url,
                    rRule: rRule
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
    
    func retrieveEvents(
        calendarId: String,
        startDate: Int64,
        endDate: Int64,
        completion: @escaping (Result<[Event], any Error>) -> Void
    ) {
        permissionHandler.checkCalendarAccessThenExecute { [self] in
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
    
    func deleteEvent(eventId: String, span: EventSpan, completion: @escaping (Result<Void, any Error>) -> Void) {
        permissionHandler.checkCalendarAccessThenExecute { [self] in
            do {
                try easyEventStore.deleteEvent(eventId: eventId, span: span)
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
    
    func createReminder(reminder: Int64, eventId: String, completion: @escaping (Result<Event, any Error>) -> Void) {
        permissionHandler.checkCalendarAccessThenExecute { [self] in
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
    
    func deleteReminder(reminder: Int64, eventId: String, completion: @escaping (Result<Event, any Error>) -> Void) {
        permissionHandler.checkCalendarAccessThenExecute { [self] in
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
        completion: @escaping (Result<Event, any Error>) -> Void
    ) {
        /// EventKit cannot add participants to an event nor change participant information.
        /// https://developer.apple.com/documentation/eventkit/ekparticipant#overview
        completion(.failure(
            PigeonError(
                code: "INCOMPATIBLE_PLATFORM",
                message: "Platform does not handle this method",
                details: "EventKit API does not support attendee addition"
            )
        ))
    }
    
    func deleteAttendee(
        eventId: String,
        email: String,
        completion: @escaping (Result<Event, any Error>) -> Void
    ) {
        /// EventKit cannot add participants to an event nor change participant information.
        /// https://developer.apple.com/documentation/eventkit/ekparticipant#overview
        completion(.failure(
            PigeonError(
                code: "INCOMPATIBLE_PLATFORM",
                message: "Platform does not handle this method",
                details: "EventKit API does not support attendee deletion"
            )
        ))
    }
}
