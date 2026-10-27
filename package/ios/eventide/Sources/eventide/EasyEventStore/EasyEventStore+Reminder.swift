//
//  EasyEventStore+Reminders.swift
//  eventide
//
//  Created by CHOUPAULT Alexis on 29/10/2026.
//

import EventKit
import Foundation

protocol ReminderProtocol {
    func createReminder(timeInterval: TimeInterval, eventId: String) throws -> Event
    func deleteReminder(timeInterval: TimeInterval, eventId: String) throws -> Event
}

extension EasyEventStore {
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
}
