//
//  EasyEventStoreProtocol.swift
//  eventide
//
//  Created by CHOUPAULT Alexis on 23/01/2025.
//

import Foundation
import UIKit

protocol EasyEventStoreProtocol {
    func createCalendar(title: String, color: UIColor, localAccountName: String) throws -> Calendar
    
    func retrieveDefaultCalendar() -> Calendar?
    
    func retrieveCalendars(onlyWritable: Bool, from localAccountName: String?) -> [Calendar]
    
    func deleteCalendar(calendarId: String) throws -> Void
    
    func createEvent(calendarId: String, title: String, startDate: Date, endDate: Date, isAllDay: Bool, description: String?, url: String?, reminders: [Int64]?) throws
    
    func retrieveEvents(calendarId: String, startDate: Date, endDate: Date) throws -> [Event]
    
    func deleteEvent(eventId: String) throws -> Void
    
    func deleteReminder(timeInterval: TimeInterval, eventId: String) throws -> Event
}
