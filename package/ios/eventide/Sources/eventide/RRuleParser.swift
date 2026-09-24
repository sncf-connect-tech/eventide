//
//  RRuleParser.swift
//  eventide
//

import EventKit

struct RRuleParser {
    static func parse(_ rrule: String) -> EKRecurrenceRule? {
        var frequency: EKRecurrenceFrequency?
        var interval = 1
        var daysOfWeek: [EKRecurrenceDayOfWeek]?
        var daysOfMonth: [NSNumber]?
        var monthsOfYear: [NSNumber]?
        var end: EKRecurrenceEnd?

        for component in rrule.components(separatedBy: ";") {
            let parts = component.components(separatedBy: "=")
            guard parts.count == 2 else { continue }
            let key = parts[0].uppercased()
            let value = parts[1]

            switch key {
            case "FREQ":
                frequency = parseFrequency(value)
            case "INTERVAL":
                interval = Int(value) ?? 1
            case "BYDAY":
                daysOfWeek = parseDaysOfWeek(value)
            case "BYMONTHDAY":
                daysOfMonth = value.components(separatedBy: ",")
                    .compactMap { Int($0) as NSNumber? }
            case "BYMONTH":
                monthsOfYear = value.components(separatedBy: ",")
                    .compactMap { Int($0) as NSNumber? }
            case "COUNT":
                if let count = Int(value) {
                    end = EKRecurrenceEnd(occurrenceCount: count)
                }
            case "UNTIL":
                if let date = parseUntilDate(value) {
                    end = EKRecurrenceEnd(end: date)
                }
            default:
                break // unsupported property silently dropped
            }
        }

        guard let freq = frequency else { return nil }

        return EKRecurrenceRule(
            recurrenceWith: freq,
            interval: interval,
            daysOfTheWeek: daysOfWeek,
            daysOfTheMonth: daysOfMonth,
            monthsOfTheYear: monthsOfYear,
            weeksOfTheYear: nil,
            daysOfTheYear: nil,
            setPositions: nil,
            end: end
        )
    }

    private static func parseFrequency(_ value: String) -> EKRecurrenceFrequency? {
        switch value.uppercased() {
        case "DAILY":   return .daily
        case "WEEKLY":  return .weekly
        case "MONTHLY": return .monthly
        case "YEARLY":  return .yearly
        default:        return nil
        }
    }

    private static func parseDaysOfWeek(_ value: String) -> [EKRecurrenceDayOfWeek] {
        let dayMap: [String: EKWeekday] = [
            "SU": .sunday, "MO": .monday, "TU": .tuesday,
            "WE": .wednesday, "TH": .thursday, "FR": .friday, "SA": .saturday,
        ]
        return value.components(separatedBy: ",").compactMap { token in
            guard token.count >= 2 else { return nil }
            let dayKey = String(token.suffix(2)).uppercased()
            let prefix = String(token.dropLast(2))
            let weekNumber = Int(prefix) ?? 0
            guard let weekday = dayMap[dayKey] else { return nil }
            return EKRecurrenceDayOfWeek(weekday, weekNumber: weekNumber)
        }
    }

    private static func parseUntilDate(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        if let date = formatter.date(from: value) { return date }
        formatter.dateFormat = "yyyyMMdd"
        return formatter.date(from: value)
    }
}
