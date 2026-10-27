//
//  EasyEventStore+Attendees.swift
//  eventide
//
//  Created by CHOUPAULT Alexis on 29/10/2026.
//

import Foundation

protocol AttendeeProtocol {
    func retrieveAttendees(eventId: String) throws -> [Attendee]
}

extension EasyEventStore {
    func retrieveAttendees(eventId: String) throws -> [Attendee] {
        guard let ekEvent = eventStore.event(withIdentifier: eventId) else {
            throw PigeonError(
                code: "NOT_FOUND",
                message: "Event not found",
                details: "The provided event.id is certainly incorrect"
            )
        }
        
        var attendees: [Attendee] = []
        
        ekEvent.attendees?.forEach {
            attendees.append(
                Attendee(
                    name: $0.name ?? "",
                    email: "",
                    type: Int64($0.participantType.rawValue),
                    role: Int64($0.participantRole.rawValue),
                    status: Int64($0.participantStatus.rawValue)
                )
            )
        }
        
        return attendees
    }
}
