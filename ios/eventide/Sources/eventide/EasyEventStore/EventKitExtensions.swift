//
//  EventKitExtensions.swift
//  eventide
//
//  Created by CHOUPAULT Alexis on 07/04/2025.
//

import EventKit

public extension EKRecurrenceRule {
    convenience init?(from rRule: String) {
        let workableRRule: String
        
        if rRule.starts(with: "RRULE:") {
            workableRRule = rRule.replacingOccurrences(of: "RRULE:", with: "")
        } else {
            workableRRule = rRule
        }
        
        
        let components = workableRRule.components(separatedBy: ";")
        var frequency: EKRecurrenceFrequency?       // FREQ
        var interval: Int?                          // INTERVAL
        var daysOfWeek: [EKRecurrenceDayOfWeek]?    // BYDAY
        var daysOfTheMonth: [NSNumber]?             // BYMONTHDAY
        var monthsOfTheYear: [NSNumber]?            // BYMONTH
        var weeksOfTheYear: [NSNumber]?             // BYWEEKNO
        var daysOfTheYear: [NSNumber]?              // BYYEARDAY
        var end: EKRecurrenceEnd?                   // UNTIL

        for component in components {
            let keyValue = component.components(separatedBy: "=")
            guard keyValue.count == 2 else { continue }
            
            let key = keyValue[0]
            let value = keyValue[1]
            
            switch key {
            case "FREQ":
                frequency = Self.parseFrequency(value)
            case "INTERVAL":
                interval = Self.parseInterval(value)
            case "BYDAY":
                daysOfWeek = Self.parseDaysOfWeek(value)
            case "BYMONTHDAY":
                daysOfTheMonth = Self.parseString(value, in: -30...31)
            case "BYMONTH":
                monthsOfTheYear = Self.parseString(value, in: -11...12)
            case "BYWEEKNO":
                weeksOfTheYear = Self.parseString(value, in: -52...53)
            case "BYYEARDAY":
                daysOfTheYear = Self.parseString(value, in: -355...366)
            case "UNTIL":
                end = Self.parseRecurrenceEndDate(value)
            case "COUNT":
                end = Self.parseRecurrenceEndCount(value)
            default:
                break
            }
        }
        
        guard let validFrequency = frequency else { return nil }
        self.init(
            recurrenceWith: validFrequency,
            interval: interval ?? 1,
            daysOfTheWeek: daysOfWeek,
            daysOfTheMonth: daysOfTheMonth,
            monthsOfTheYear: monthsOfTheYear,
            weeksOfTheYear: weeksOfTheYear,
            daysOfTheYear: daysOfTheYear,
            setPositions: nil,
            end: end
        )
    }
    
    static private func parseInterval(_ intervalString: String) -> Int {
        guard let interval = Int(intervalString), interval > 0 else {
            return 1
        }
        
        return interval
    }
    
    static private func parseFrequency(_ freq: String) -> EKRecurrenceFrequency? {
        switch freq.uppercased() {
        case "DAILY": return .daily
        case "WEEKLY": return .weekly
        case "MONTHLY": return .monthly
        case "YEARLY": return .yearly
        default: return nil
        }
    }
    
    static private func parseDaysOfWeek(_ days: String) -> [EKRecurrenceDayOfWeek]? {
        var daysOfWeek: [EKRecurrenceDayOfWeek] = []
        for dayString in days.components(separatedBy: ",") {
            guard let (dayOfWeek, weekNumber) = parseDayOfWeekComponent(component: dayString) else {
                continue
            }
            
            if let weekNumber = weekNumber {
                daysOfWeek.append(EKRecurrenceDayOfWeek(dayOfWeek, weekNumber: weekNumber))
            } else {
                daysOfWeek.append(EKRecurrenceDayOfWeek(dayOfWeek))
            }
        }
        return daysOfWeek
    }
    
    static private func parseDayOfWeekComponent(component: String) -> (dayOfWeek: EKWeekday, weekNumber: Int?)? {
        do {
            let regex = try NSRegularExpression(pattern: "([1-5]|-1)?((MO)|(TU)|(WE)|(TH)|(FR)|(SA)|(SU))")
            let matches = regex.matches(in: component, range: NSRange(component.startIndex..., in: component))
            
            guard let match = matches.first else {
                return nil
            }
            
            let weekNumberRange = match.range(at: 1)
            let dayOfWeekRange = match.range(at: 2)
            
            let weekNumberString = (weekNumberRange.location != NSNotFound) ? String(component[Range(weekNumberRange, in: component)!]) : nil
            let dayOfWeekString = String(component[Range(dayOfWeekRange, in: component)!])
            
            let weekNumber = weekNumberString != nil ? Int(weekNumberString!) : nil
            guard let dayOfWeek = dayOfWeekFromString(dayOfWeekString) else {
                return nil
            }
            
            return (dayOfWeek, weekNumber)
            
        } catch {
            return nil
        }
    }
    
    static private func dayOfWeekFromString(_ day: String) -> EKWeekday? {
        switch day.uppercased() {
        case "SU": return EKWeekday.sunday
        case "MO": return EKWeekday.monday
        case "TU": return EKWeekday.tuesday
        case "WE": return EKWeekday.wednesday
        case "TH": return EKWeekday.thursday
        case "FR": return EKWeekday.friday
        case "SA": return EKWeekday.saturday
        default: return nil
        }
    }
    
    static private func parseString(_ byString: String, in range: ClosedRange<Int>) -> [NSNumber] {
        var values: [NSNumber] = []
        for number in byString.components(separatedBy: ",") {
            guard let int = Int(number), range.contains(int) else {
                continue
            }
            values.append(NSNumber(integerLiteral: int))
        }
        return values
    }
    
    static private func parseRecurrenceEndDate(_ untilString: String) -> EKRecurrenceEnd? {
        guard !untilString.isEmpty else {
            return nil
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        guard let untilDate = dateFormatter.date(from: untilString) else {
            return nil
        }

        return EKRecurrenceEnd(end: untilDate)
    }
    
    static private func parseRecurrenceEndCount(_ countString: String) -> EKRecurrenceEnd? {
        guard !countString.isEmpty else {
            return nil
        }

        guard let count = Int(countString) else {
            return nil
        }

        return EKRecurrenceEnd(occurrenceCount: count)
    }
}
