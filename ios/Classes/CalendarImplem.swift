//
//  CalendarImplem.swift
//  eventide
//
//  Created by CHOUPAULT Alexis on 31/12/2024.
//

import Foundation

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
        account: Account?,
        completion: @escaping (Result<Calendar, Error>) -> Void
    ) {
        permissionHandler.checkCalendarAccessThenExecute { [self] in
            guard let uiColor = UIColor(int64: color) else {
                completion(.failure(PigeonError(
                    code: "GENERIC_ERROR",
                    message: "Unable to parse cgColor from hex",
                    details: "hexadecimal number needs to start with # and to be 8 or 6 char long"
                )))
                return
            }
            
            do {
                let createdCalendar = try easyEventStore.createCalendar(title: title, color: uiColor, account: account)
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

    func retrieveCalendars(onlyWritableCalendars: Bool, completion: @escaping (Result<[Calendar], Error>) -> Void) {
        permissionHandler.checkCalendarAccessThenExecute { [self] in
            let calendars = easyEventStore.retrieveCalendars(onlyWritable: onlyWritableCalendars)
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
    
    func deleteCalendar(_ calendarId: String, completion: @escaping (Result<Void, any Error>) -> Void) {
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
                    url: url
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
    
    func deleteEvent(withId eventId: String, completion: @escaping (Result<Void, any Error>) -> Void) {
        permissionHandler.checkCalendarAccessThenExecute { [self] in
            do {
                try easyEventStore.deleteEvent(eventId: eventId)
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
    
    func createReminder(_ reminder: Int64, forEventId eventId: String, completion: @escaping (Result<Event, any Error>) -> Void) {
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
    
    func deleteReminder(_ reminder: Int64, withEventId eventId: String, completion: @escaping (Result<Event, any Error>) -> Void) {
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
}
