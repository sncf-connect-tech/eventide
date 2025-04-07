//
//  EventKitExtensionsTests.swift
//  EventideTests
//
//  Created by CHOUPAULT Alexis on 07/04/2025.
//

import XCTest
import EventKit

final class EventKitExtensionsTests: XCTestCase {
    func test_emptyString() {
        let rrule = "RRULE:"
        
        let recurrenceRule = EKRecurrenceRule(from: rrule)
        
        XCTAssert(recurrenceRule == nil)
    }
    
    func test_invalidFreq() {
        let rrule = "RRULE:FREQ=INVALID"
        
        let recurrenceRule = EKRecurrenceRule(from: rrule)
        
        XCTAssert(recurrenceRule == nil)
    }
    
    func test_invalidInterval() {
        let rrule = "RRULE:FREQ=DAILY;INTERVAL=0"
        
        guard let recurrenceRule = EKRecurrenceRule(from: rrule) else {
            XCTFail("recurrenceRule should be instanciated")
            return
        }
        
        XCTAssert(recurrenceRule.frequency == .daily)
        XCTAssert(recurrenceRule.interval == 1)
    }
    
    func test_invalidWeekday() {
        let rrule = "RRULE:FREQ=WEEKLY;BYDAY=X"
        
        guard let recurrenceRule = EKRecurrenceRule(from: rrule) else {
            XCTFail("recurrenceRule should be instanciated")
            return
        }
        
        XCTAssert(recurrenceRule.frequency == .weekly)
        XCTAssert(recurrenceRule.daysOfTheWeek!.isEmpty)
    }
    
    func test_invalidWeekNo() {
        let rrule = "RRULE:FREQ=MONTHLY;BYWEEKNO=89"
        
        guard let recurrenceRule = EKRecurrenceRule(from: rrule) else {
            XCTFail("recurrenceRule should be instanciated")
            return
        }
        
        XCTAssert(recurrenceRule.frequency == .monthly)
        XCTAssert(recurrenceRule.weeksOfTheYear!.isEmpty)
    }
    
    func test_invalidMonth() {
        let rrule = "RRULE:FREQ=MONTHLY;BYMONTH=13"
        
        guard let recurrenceRule = EKRecurrenceRule(from: rrule) else {
            XCTFail("recurrenceRule should be instanciated")
            return
        }
        
        XCTAssert(recurrenceRule.frequency == .monthly)
        XCTAssert(recurrenceRule.monthsOfTheYear!.isEmpty)
    }
    
    func test_invalidMonthDay() {
        let rrule = "RRULE:FREQ=MONTHLY;BYMONTHDAY=32"
        
        guard let recurrenceRule = EKRecurrenceRule(from: rrule) else {
            XCTFail("recurrenceRule should be instanciated")
            return
        }
        
        XCTAssert(recurrenceRule.frequency == .monthly)
        XCTAssert(recurrenceRule.daysOfTheMonth!.isEmpty)
    }
        
    func test_eachOtherDayUntil() {
        let rrule = "RRULE:FREQ=DAILY;INTERVAL=2;UNTIL=20240101T000000Z"
        
        guard let recurrenceRule = EKRecurrenceRule(from: rrule) else {
            XCTFail("recurrenceRule should be instanciated")
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmssZ"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        let expectedDate = dateFormatter.date(from: "20240101T000000Z")!
        
        XCTAssert(recurrenceRule.frequency == .daily)
        XCTAssert(recurrenceRule.interval == 2)
        XCTAssert(recurrenceRule.recurrenceEnd == EKRecurrenceEnd(end: expectedDate))
    }
    
    func test_eachDayCount() {
        let rrule = "RRULE:FREQ=DAILY;COUNT=15"
        
        guard let recurrenceRule = EKRecurrenceRule(from: rrule) else {
            XCTFail("recurrenceRule should be instanciated")
            return
        }
        
        XCTAssert(recurrenceRule.frequency == .daily)
        XCTAssert(recurrenceRule.recurrenceEnd == EKRecurrenceEnd(occurrenceCount: 15))
    }
    
    func test_eachMondayWednesdayFridayOfTheWeek() {
        let rrule = "RRULE:FREQ=WEEKLY;BYDAY=MO,WE,FR"
        
        guard let recurrenceRule = EKRecurrenceRule(from: rrule) else {
            XCTFail("recurrenceRule should be instanciated")
            return
        }
        
        XCTAssert(recurrenceRule.frequency == .weekly)
        XCTAssert(recurrenceRule.daysOfTheWeek!.contains(EKRecurrenceDayOfWeek(.monday)))
        XCTAssert(recurrenceRule.daysOfTheWeek!.contains(EKRecurrenceDayOfWeek(.wednesday)))
        XCTAssert(recurrenceRule.daysOfTheWeek!.contains(EKRecurrenceDayOfWeek(.friday)))
    }
    
    func test_eachFirstMondaySecondWednesdayAndThirdFridayOfTheMonth() {
        let rrule = "RRULE:FREQ=MONTHLY;BYDAY=1MO,2WE,3FR"
        
        guard let recurrenceRule = EKRecurrenceRule(from: rrule) else {
            XCTFail("recurrenceRule should be instanciated")
            return
        }
        
        XCTAssert(recurrenceRule.frequency == .monthly)
        XCTAssert(recurrenceRule.daysOfTheWeek!.contains(EKRecurrenceDayOfWeek(.monday, weekNumber: 1)))
        XCTAssert(recurrenceRule.daysOfTheWeek!.contains(EKRecurrenceDayOfWeek(.wednesday, weekNumber: 2)))
        XCTAssert(recurrenceRule.daysOfTheWeek!.contains(EKRecurrenceDayOfWeek(.friday, weekNumber: 3)))
    }
    
    func test_eachFirstAndFifteenthDayOfEachOtherMonth() {
        let rrule = "RRULE:FREQ=MONTHLY;BYMONTHDAY=1,15;INTERVAL=2"
        
        guard let recurrenceRule = EKRecurrenceRule(from: rrule) else {
            XCTFail("recurrenceRule should be instanciated")
            return
        }
        
        XCTAssert(recurrenceRule.frequency == .monthly)
        XCTAssert(recurrenceRule.interval == 2)
        XCTAssert(recurrenceRule.daysOfTheMonth!.contains(1))
        XCTAssert(recurrenceRule.daysOfTheMonth!.contains(15))
    }
    
    func test_eachFifteenthOfMarch() {
        let rrule = "RRULE:FREQ=YEARLY;BYMONTH=3;BYMONTHDAY=15"
        
        guard let recurrenceRule = EKRecurrenceRule(from: rrule) else {
            XCTFail("recurrenceRule should be instanciated")
            return
        }
        
        XCTAssert(recurrenceRule.frequency == .yearly)
        XCTAssert(recurrenceRule.monthsOfTheYear!.contains(3))
        XCTAssert(recurrenceRule.daysOfTheMonth!.contains(15))
    }
    
    func test_lastSundayOfEachMonth() {
        let rrule = "RRULE:FREQ=MONTHLY;BYDAY=SU;BYMONTHDAY=-1"
        
        guard let recurrenceRule = EKRecurrenceRule(from: rrule) else {
            XCTFail("recurrenceRule should be instanciated")
            return
        }
        
        XCTAssert(recurrenceRule.frequency == .monthly)
        XCTAssert(recurrenceRule.daysOfTheWeek!.contains(EKRecurrenceDayOfWeek(.sunday)))
        XCTAssert(recurrenceRule.daysOfTheMonth!.contains(-1))
    }
}
