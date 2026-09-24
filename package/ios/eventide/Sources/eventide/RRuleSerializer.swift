//
//  RRuleSerializer.swift
//  eventide
//

import EventKit

struct RRuleSerializer {
    static func serialize(_ rule: EKRecurrenceRule) -> String {
        var parts: [String] = ["FREQ=\(serializeFrequency(rule.frequency))"]

        if rule.interval > 1 {
            parts.append("INTERVAL=\(rule.interval)")
        }

        if let days = rule.daysOfTheWeek, !days.isEmpty {
            let dayStrings = days.map { day -> String in
                let abbr = serializeWeekday(day.dayOfTheWeek)
                return day.weekNumber != 0 ? "\(day.weekNumber)\(abbr)" : abbr
            }.sorted() // deterministic output
            parts.append("BYDAY=\(dayStrings.joined(separator: ","))")
        }

        if let days = rule.daysOfTheMonth, !days.isEmpty {
            parts.append("BYMONTHDAY=\(days.map { "\($0)" }.joined(separator: ","))")
        }

        if let months = rule.monthsOfTheYear, !months.isEmpty {
            parts.append("BYMONTH=\(months.map { "\($0)" }.joined(separator: ","))")
        }

        if let recEnd = rule.recurrenceEnd {
            if recEnd.occurrenceCount > 0 {
                parts.append("COUNT=\(recEnd.occurrenceCount)")
            } else if let endDate = recEnd.endDate {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(identifier: "UTC")
                formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
                parts.append("UNTIL=\(formatter.string(from: endDate))")
            }
        }

        return parts.joined(separator: ";")
    }

    private static func serializeFrequency(_ freq: EKRecurrenceFrequency) -> String {
        switch freq {
        case .daily:   return "DAILY"
        case .weekly:  return "WEEKLY"
        case .monthly: return "MONTHLY"
        case .yearly:  return "YEARLY"
        @unknown default: return "DAILY"
        }
    }

    private static func serializeWeekday(_ weekday: EKWeekday) -> String {
        switch weekday {
        case .sunday:    return "SU"
        case .monday:    return "MO"
        case .tuesday:   return "TU"
        case .wednesday: return "WE"
        case .thursday:  return "TH"
        case .friday:    return "FR"
        case .saturday:  return "SA"
        @unknown default: return "MO"
        }
    }
}
