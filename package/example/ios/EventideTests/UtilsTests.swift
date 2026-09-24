//
//  UtilsTests.swift
//  EventideTests
//
//  Created by CHOUPAULT Alexis on 15/01/2025.
//

import XCTest
import EventKit
@testable import eventide

class UtilsTests: XCTestCase {

    func testMillisecondsSince1970() {
        let date = Date(timeIntervalSince1970: 1672531200) // 01/01/2023 @ 12:00am (UTC)
        XCTAssertEqual(date.millisecondsSince1970, 1672531200000)
    }

    func testDateFromMillisecondsSinceEpoch() {
        let milliseconds: Int64 = 1672531200000
        let date = Date(from: milliseconds)
        XCTAssertEqual(date.timeIntervalSince1970, 1672531200)
    }

    func testUIColorToInt64() {
        let color = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0) // Red color
        XCTAssertEqual(color.toInt64(), 0xFFFF0000)
    }

    func testUIColorToInt64InvalidColor() {
        let color = UIColor()
        XCTAssertEqual(color.toInt64(), 0xFF000000) // Default to black with full alpha
    }

    func testUIColorInitWithInt64() {
        let color = UIColor(int64: 0xFFFF0000) // Red color
        XCTAssertNotNil(color)
        XCTAssertEqual(color.cgColor.alpha, 1.0)
        XCTAssertEqual(color.cgColor.components?[0], 1.0)
        XCTAssertEqual(color.cgColor.components?[1], 0.0)
        XCTAssertEqual(color.cgColor.components?[2], 0.0)
    }
}

final class RRuleParserTests: XCTestCase {

    // MARK: - Parser tests

    func testParseDailyFreq() {
        let rule = RRuleParser.parse("FREQ=DAILY")
        XCTAssertNotNil(rule)
        XCTAssertEqual(rule?.frequency, .daily)
        XCTAssertEqual(rule?.interval, 1)
    }

    func testParseWeeklyWithByday() {
        let rule = RRuleParser.parse("FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE,FR")
        XCTAssertNotNil(rule)
        XCTAssertEqual(rule?.frequency, .weekly)
        XCTAssertEqual(rule?.interval, 2)
        let days = rule?.daysOfTheWeek?.map { $0.dayOfTheWeek } ?? []
        XCTAssertTrue(days.contains(.monday))
        XCTAssertTrue(days.contains(.wednesday))
        XCTAssertTrue(days.contains(.friday))
    }

    func testParseMonthly() {
        let rule = RRuleParser.parse("FREQ=MONTHLY;INTERVAL=1")
        XCTAssertNotNil(rule)
        XCTAssertEqual(rule?.frequency, .monthly)
    }

    func testParseYearly() {
        let rule = RRuleParser.parse("FREQ=YEARLY")
        XCTAssertNotNil(rule)
        XCTAssertEqual(rule?.frequency, .yearly)
    }

    func testParseMonthlyByMonthDay() {
        let rule = RRuleParser.parse("FREQ=MONTHLY;BYMONTHDAY=15,28")
        XCTAssertNotNil(rule)
        let days = rule?.daysOfTheMonth?.map { $0.intValue } ?? []
        XCTAssertTrue(days.contains(15))
        XCTAssertTrue(days.contains(28))
    }

    func testParseYearlyByMonth() {
        let rule = RRuleParser.parse("FREQ=YEARLY;BYMONTH=1,6")
        XCTAssertNotNil(rule)
        let months = rule?.monthsOfTheYear?.map { $0.intValue } ?? []
        XCTAssertTrue(months.contains(1))
        XCTAssertTrue(months.contains(6))
    }

    func testParseCount() {
        let rule = RRuleParser.parse("FREQ=DAILY;COUNT=10")
        XCTAssertNotNil(rule)
        XCTAssertEqual(rule?.recurrenceEnd?.occurrenceCount, 10)
    }

    func testParseUntilDatetime() {
        let rule = RRuleParser.parse("FREQ=DAILY;UNTIL=20261231T235959Z")
        XCTAssertNotNil(rule)
        XCTAssertNotNil(rule?.recurrenceEnd?.endDate)
    }

    func testParseUntilDate() {
        let rule = RRuleParser.parse("FREQ=DAILY;UNTIL=20261231")
        XCTAssertNotNil(rule)
        XCTAssertNotNil(rule?.recurrenceEnd?.endDate)
    }

    func testUnsupportedPropertySilentlyDropped() {
        // BYYEARDAY is unsupported; parser should still return a rule for the supported parts
        let rule = RRuleParser.parse("FREQ=YEARLY;BYYEARDAY=100")
        XCTAssertNotNil(rule)
        XCTAssertEqual(rule?.frequency, .yearly)
    }

    func testUnsupportedPropertiesByWeekNoAndBySetPosSilentlyDropped() {
        let rule = RRuleParser.parse("FREQ=MONTHLY;BYSETPOS=1;BYWEEKNO=5")
        XCTAssertNotNil(rule)
        XCTAssertEqual(rule?.frequency, .monthly)
    }

    func testInvalidFreqReturnsNil() {
        let rule = RRuleParser.parse("FREQ=HOURLY")
        XCTAssertNil(rule)
    }

    func testMissingFreqReturnsNil() {
        let rule = RRuleParser.parse("INTERVAL=2")
        XCTAssertNil(rule)
    }

    // MARK: - Serializer tests

    func testSerializeDaily() {
        let rule = EKRecurrenceRule(
            recurrenceWith: .daily, interval: 1,
            daysOfTheWeek: nil, daysOfTheMonth: nil,
            monthsOfTheYear: nil, weeksOfTheYear: nil,
            daysOfTheYear: nil, setPositions: nil, end: nil
        )
        let rrule = RRuleSerializer.serialize(rule)
        XCTAssertEqual(rrule, "FREQ=DAILY")
    }

    func testSerializeWithIntervalGreaterThanOne() {
        let rule = EKRecurrenceRule(
            recurrenceWith: .weekly, interval: 3,
            daysOfTheWeek: nil, daysOfTheMonth: nil,
            monthsOfTheYear: nil, weeksOfTheYear: nil,
            daysOfTheYear: nil, setPositions: nil, end: nil
        )
        let rrule = RRuleSerializer.serialize(rule)
        XCTAssertTrue(rrule.contains("INTERVAL=3"))
    }

    func testSerializeDoesNotIncludeIntervalWhenOne() {
        let rule = EKRecurrenceRule(
            recurrenceWith: .daily, interval: 1,
            daysOfTheWeek: nil, daysOfTheMonth: nil,
            monthsOfTheYear: nil, weeksOfTheYear: nil,
            daysOfTheYear: nil, setPositions: nil, end: nil
        )
        let rrule = RRuleSerializer.serialize(rule)
        XCTAssertFalse(rrule.contains("INTERVAL"))
    }

    func testSerializeWeeklyWithDays() {
        let rule = EKRecurrenceRule(
            recurrenceWith: .weekly, interval: 1,
            daysOfTheWeek: [
                EKRecurrenceDayOfWeek(.monday),
                EKRecurrenceDayOfWeek(.wednesday),
            ],
            daysOfTheMonth: nil, monthsOfTheYear: nil,
            weeksOfTheYear: nil, daysOfTheYear: nil,
            setPositions: nil, end: nil
        )
        let rrule = RRuleSerializer.serialize(rule)
        XCTAssertTrue(rrule.contains("FREQ=WEEKLY"))
        XCTAssertTrue(rrule.contains("BYDAY="))
        XCTAssertTrue(rrule.contains("MO"))
        XCTAssertTrue(rrule.contains("WE"))
    }

    func testSerializeMonthlyWithByMonthDay() {
        let rule = EKRecurrenceRule(
            recurrenceWith: .monthly, interval: 1,
            daysOfTheWeek: nil, daysOfTheMonth: [15, 28],
            monthsOfTheYear: nil, weeksOfTheYear: nil,
            daysOfTheYear: nil, setPositions: nil, end: nil
        )
        let rrule = RRuleSerializer.serialize(rule)
        XCTAssertTrue(rrule.contains("BYMONTHDAY="))
        XCTAssertTrue(rrule.contains("15"))
        XCTAssertTrue(rrule.contains("28"))
    }

    func testSerializeYearlyWithByMonth() {
        let rule = EKRecurrenceRule(
            recurrenceWith: .yearly, interval: 1,
            daysOfTheWeek: nil, daysOfTheMonth: nil,
            monthsOfTheYear: [1, 6], weeksOfTheYear: nil,
            daysOfTheYear: nil, setPositions: nil, end: nil
        )
        let rrule = RRuleSerializer.serialize(rule)
        XCTAssertTrue(rrule.contains("BYMONTH="))
        XCTAssertTrue(rrule.contains("1"))
        XCTAssertTrue(rrule.contains("6"))
    }

    func testSerializeWithCount() {
        let rule = EKRecurrenceRule(
            recurrenceWith: .daily, interval: 1,
            daysOfTheWeek: nil, daysOfTheMonth: nil,
            monthsOfTheYear: nil, weeksOfTheYear: nil,
            daysOfTheYear: nil, setPositions: nil,
            end: EKRecurrenceEnd(occurrenceCount: 5)
        )
        let rrule = RRuleSerializer.serialize(rule)
        XCTAssertTrue(rrule.contains("COUNT=5"))
        XCTAssertFalse(rrule.contains("UNTIL"))
    }

    func testSerializeWithUntil() {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        let endDate = formatter.date(from: "20261231T235959Z")!
        let rule = EKRecurrenceRule(
            recurrenceWith: .daily, interval: 1,
            daysOfTheWeek: nil, daysOfTheMonth: nil,
            monthsOfTheYear: nil, weeksOfTheYear: nil,
            daysOfTheYear: nil, setPositions: nil,
            end: EKRecurrenceEnd(end: endDate)
        )
        let rrule = RRuleSerializer.serialize(rule)
        XCTAssertTrue(rrule.contains("UNTIL=20261231T235959Z"))
        XCTAssertFalse(rrule.contains("COUNT"))
    }

    // MARK: - Round-trip tests

    func testRoundTripDaily() {
        let original = "FREQ=DAILY"
        guard let rule = RRuleParser.parse(original) else {
            return XCTFail("Parse returned nil")
        }
        let serialized = RRuleSerializer.serialize(rule)
        let reparsed = RRuleParser.parse(serialized)
        XCTAssertEqual(reparsed?.frequency, rule.frequency)
        XCTAssertEqual(reparsed?.interval, rule.interval)
    }

    func testRoundTripWeekly() {
        let original = "FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,FR"
        guard let rule = RRuleParser.parse(original) else {
            return XCTFail("Parse returned nil")
        }
        let serialized = RRuleSerializer.serialize(rule)
        // Re-parse to verify the round-trip is semantically equivalent
        let reparsed = RRuleParser.parse(serialized)
        XCTAssertEqual(reparsed?.frequency, rule.frequency)
        XCTAssertEqual(reparsed?.interval, rule.interval)
        let originalDays = Set(rule.daysOfTheWeek?.map { $0.dayOfTheWeek } ?? [])
        let reparsedDays = Set(reparsed?.daysOfTheWeek?.map { $0.dayOfTheWeek } ?? [])
        XCTAssertEqual(originalDays, reparsedDays)
    }

    func testRoundTripMonthlyWithByMonthDay() {
        let original = "FREQ=MONTHLY;BYMONTHDAY=10"
        guard let rule = RRuleParser.parse(original) else {
            return XCTFail("Parse returned nil")
        }
        let serialized = RRuleSerializer.serialize(rule)
        let reparsed = RRuleParser.parse(serialized)
        XCTAssertEqual(reparsed?.frequency, rule.frequency)
        let days = reparsed?.daysOfTheMonth?.map { $0.intValue } ?? []
        XCTAssertTrue(days.contains(10))
    }

    func testRoundTripYearlyWithByMonth() {
        let original = "FREQ=YEARLY;BYMONTH=12"
        guard let rule = RRuleParser.parse(original) else {
            return XCTFail("Parse returned nil")
        }
        let serialized = RRuleSerializer.serialize(rule)
        let reparsed = RRuleParser.parse(serialized)
        XCTAssertEqual(reparsed?.frequency, rule.frequency)
        let months = reparsed?.monthsOfTheYear?.map { $0.intValue } ?? []
        XCTAssertTrue(months.contains(12))
    }

    func testRoundTripWithCount() {
        let original = "FREQ=DAILY;COUNT=7"
        guard let rule = RRuleParser.parse(original) else {
            return XCTFail("Parse returned nil")
        }
        let serialized = RRuleSerializer.serialize(rule)
        let reparsed = RRuleParser.parse(serialized)
        XCTAssertEqual(reparsed?.recurrenceEnd?.occurrenceCount, 7)
    }
}
