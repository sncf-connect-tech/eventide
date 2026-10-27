//
//  EasyEventStore+Extensions.swift
//  eventide
//
//  Created by CHOUPAULT Alexis on 29/10/2026.
//

import EventKit
import UIKit

extension EKCalendar {
    func toCalendar() -> Calendar {
        Calendar(
            id: calendarIdentifier,
            title: title,
            color: UIColor(cgColor: cgColor).toInt64(),
            isWritable: allowsContentModifications,
            account: Account(
                id: source.sourceIdentifier,
                name: source.title,
                type: source.sourceType.toString()
            )
        )
    }
}

extension EKEvent {
    func toEvent() -> Event {
        Event(
            id: eventIdentifier,
            calendarId: calendar.calendarIdentifier,
            title: title,
            isAllDay: isAllDay,
            startDate: startDate.millisecondsSince1970,
            endDate: endDate.millisecondsSince1970,
            reminders: alarms?.map { Int64($0.relativeOffset) } ?? [],
            attendees: attendees?.compactMap {
                Attendee(
                    name: $0.name ?? "",
                    email: "",
                    type: Int64($0.participantType.rawValue),
                    role: Int64($0.participantRole.rawValue),
                    status: Int64($0.participantStatus.rawValue)
                )
            } ?? [],
            description: notes,
            url: url?.absoluteString,
            location: location,
            recurrenceRule: recurrenceRules?.first.map { RRuleSerializer.serialize($0) },
            originalInstanceDate: (recurrenceRules?.isEmpty == false) ? occurrenceDate.millisecondsSince1970 : nil
        )
    }
}

extension EKSource {
    func toAccount() -> Account {
        return Account(
            id: sourceIdentifier,
            name: title,
            type: sourceType.toString()
        )
    }
}

extension EKSourceType {
     init?(from string: String) {
        switch string.lowercased() {
        case "local":
            self = .local
        case "caldav":
            self = .calDAV
        case "exchange":
            self = .exchange
        case "subscribed":
            self = .subscribed
        case "mobileme":
            self = .mobileMe
        case "birthdays":
            self = .birthdays
        default:
            return nil
        }
    }

    func toString() -> String {
        switch self {
        case .local:
            return "Local"
        case .calDAV:
            return "CalDAV"
        case .exchange:
            return "Exchange"
        case .subscribed:
            return "Subscribed"
        case .mobileMe:
            return "MobileMe"
        case .birthdays:
            return "Birthdays"
        @unknown default:
            return "Local"
        }
    }
}

extension Span {
    func toEKSpan() -> EKSpan {
        switch self {
        case .thisEvent:
            return .thisEvent
        case .thisAndFuture:
            return .futureEvents
        }
    }
}
