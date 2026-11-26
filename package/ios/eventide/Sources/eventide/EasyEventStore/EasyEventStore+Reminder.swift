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
    func createReminder(timeInterval: TimeInterval, eventId: String, originalInstanceDate: Date, span: Span) throws -> Event
    func deleteReminder(timeInterval: TimeInterval, eventId: String) throws -> Event
    func deleteReminder(timeInterval: TimeInterval, eventId: String, originalInstanceDate: Date, span: Span) throws -> Event
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
        
        return try saveReminder(timeInterval: timeInterval, on: ekEvent, span: .thisEvent)
    }

    func createReminder(timeInterval: TimeInterval, eventId: String, originalInstanceDate: Date, span: Span) throws -> Event {
        guard let occurrence = findOccurrence(eventId: eventId, originalInstanceDate: originalInstanceDate) else {
            throw PigeonError(
                code: "NOT_FOUND",
                message: "Event occurrence not found",
                details: "The provided eventId or originalInstanceDate is certainly incorrect"
            )
        }

        return try saveReminder(timeInterval: timeInterval, on: occurrence, span: span.toEKSpan())
    }
    
    func deleteReminder(timeInterval: TimeInterval, eventId: String) throws -> Event {
        guard let ekEvent = eventStore.event(withIdentifier: eventId) else {
            throw PigeonError(
                code: "NOT_FOUND",
                message: "Event not found",
                details: "The provided event.id is certainly incorrect"
            )
        }
        
        return try removeReminder(timeInterval: timeInterval, on: ekEvent, span: .thisEvent)
    }

    func deleteReminder(timeInterval: TimeInterval, eventId: String, originalInstanceDate: Date, span: Span) throws -> Event {
        guard let occurrence = findOccurrence(eventId: eventId, originalInstanceDate: originalInstanceDate) else {
            throw PigeonError(
                code: "NOT_FOUND",
                message: "Event occurrence not found",
                details: "The provided eventId or originalInstanceDate is certainly incorrect"
            )
        }

        return try removeReminder(timeInterval: timeInterval, on: occurrence, span: span.toEKSpan())
    }

    // MARK: - Private methods

    private func saveReminder(timeInterval: TimeInterval, on ekEvent: EKEvent, span: EKSpan) throws -> Event {
        let ekAlarm = EKAlarm(relativeOffset: timeInterval)
        if ekEvent.alarms == nil {
            ekEvent.alarms = [ekAlarm]
        } else {
            ekEvent.alarms!.append(ekAlarm)
        }

        do {
            try eventStore.save(ekEvent, span: span, commit: true)
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

    private func removeReminder(timeInterval: TimeInterval, on ekEvent: EKEvent, span: EKSpan) throws -> Event {
        let alarmsToDelete = ekEvent.alarms?.filter({ $0.relativeOffset == timeInterval })

        guard let alarmsToDelete, !alarmsToDelete.isEmpty else {
            throw PigeonError(
                code: "NOT_FOUND",
                message: "Reminder not found",
                details: "The provided reminder is certainly incorrect"
            )
        }

        alarmsToDelete.forEach { ekEvent.removeAlarm($0) }

        do {
            try eventStore.save(ekEvent, span: span, commit: true)
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
}
