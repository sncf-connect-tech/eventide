//
//  EasyEventStore+Calendar.swift
//  eventide
//
//  Created by CHOUPAULT Alexis on 29/10/2026.
//

import EventKit
import UIKit

protocol CalendarProtocol {
    func createCalendar(title: String, color: UIColor, account: Account?) throws -> Calendar
    func retrieveCalendars(onlyWritable: Bool, from account: Account?) -> [Calendar]
    func retrieveAccounts() -> [Account]
    func updateCalendar(calendarId: String, title: String, color: UIColor) throws -> Calendar
    func deleteCalendar(calendarId: String) throws -> Void
}

extension EasyEventStore {
    func createCalendar(title: String, color: UIColor, account: Account?) throws -> Calendar {
        guard let source = getSource(for: account) else {
            throw PigeonError(
                code: "NOT_FOUND",
                message: "Calendar source was not found",
                details: account != nil ? "No source has been found for account: \(account!.name)" : "No suitable calendar source found"
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
        from account: Account?
    ) -> [Calendar] {
        return eventStore.calendars(for: .event)
            .filter { onlyWritable ? $0.allowsContentModifications : true }
            .filter { calendar in
                guard let account = account else { return true }
                return account.id == calendar.source.sourceIdentifier && account.type == calendar.source.sourceType.toString()
            }
            .map { $0.toCalendar() }
    }
    
    func retrieveAccounts() -> [Account] {
        let sources = eventStore.sources
        
        return sources.compactMap { source in
            return Account(
                id: source.sourceIdentifier,
                name: source.title,
                type: source.sourceType.toString()
            )
        }
        // Remove duplicates by converting to Set and back to Array
        .reduce(into: [Account]()) { result, account in
            if !result.contains(where: { $0.name == account.name && $0.type == account.type }) {
                result.append(account)
            }
        }
    }
    
    func updateCalendar(calendarId: String, title: String, color: UIColor) throws -> Calendar {
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
                message: "Calendar not editable",
                details: "Calendar does not allow content modifications"
            )
        }

        ekCalendar.title = title
        ekCalendar.cgColor = color.cgColor

        do {
            try eventStore.saveCalendar(ekCalendar, commit: true)
            return ekCalendar.toCalendar()
            
        } catch {
            eventStore.reset()
            throw PigeonError(
                code: "GENERIC_ERROR",
                message: "Error while updating calendar",
                details: error.localizedDescription
            )
        }
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
    
    private func getSource(for account: Account? = nil) -> EKSource? {
        guard let defaultSource = eventStore.defaultCalendarForNewEvents?.source else {
            // if eventStore.defaultCalendarForNewEvents?.source is nil then eventStore.sources is empty
            return nil
        }
        
        if let account = account {
            if let specificSource = eventStore.sources.first(where: { $0.title == account.name && $0.sourceType.toString() == account.type && $0.sourceIdentifier == account.id }) {
                return specificSource
            }
        }
        
        let localSources = eventStore.sources.filter { $0.sourceType == .local }
        let iCloudSources = eventStore.sources.filter {
            $0.sourceType == .calDAV && $0.title.contains("iCloud")
        }

        return localSources.first ?? iCloudSources.first ?? defaultSource
    }
}
