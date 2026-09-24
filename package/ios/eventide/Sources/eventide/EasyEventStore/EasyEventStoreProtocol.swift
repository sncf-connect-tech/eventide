//
//  EasyEventStoreProtocol.swift
//  eventide
//
//  Created by CHOUPAULT Alexis on 23/01/2025.
//

import Foundation
import UIKit

protocol EasyEventStoreProtocol {
    func createCalendar(title: String, color: UIColor, account: Account?) throws -> Calendar
    
    func retrieveCalendars(onlyWritable: Bool, from account: Account?) -> [Calendar]
    
    func retrieveAccounts() -> [Account]
    
    func updateCalendar(calendarId: String, title: String, color: UIColor) throws -> Calendar
    
    func deleteCalendar(calendarId: String) throws -> Void

    func createEvent(calendarId: String, title: String, startDate: Date, endDate: Date, isAllDay: Bool, description: String?, url: String?, location: String?, timeIntervals: [TimeInterval]?, recurrenceRule: String?) throws -> Event

    func createEvent(title: String, startDate: Date, endDate: Date, isAllDay: Bool, description: String?, url: String?, location: String?, timeIntervals: [TimeInterval]?, recurrenceRule: String?) throws

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
    
    func updateEvent(eventId: String, calendarId: String, title: String, startDate: Date, endDate: Date, isAllDay: Bool, description: String?, url: String?, location: String?, timeIntervals: [TimeInterval]?, recurrenceRule: String?, span: String, originalInstanceTime: Int64?) throws -> Event

    func deleteEvent(eventId: String, span: String, originalInstanceTime: Int64?) throws -> Void

    func createReminder(timeInterval: TimeInterval, eventId: String) throws -> Event

    func deleteReminder(timeInterval: TimeInterval, eventId: String) throws -> Event
}
