//
//  UtilsTests.swift
//  EasyCalendarTests
//
//  Created by CHOUPAULT Alexis on 15/01/2025.
//

import XCTest
import EventKit
@testable import easy_calendar

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
        XCTAssertEqual(color?.cgColor.alpha, 1.0)
        XCTAssertEqual(color?.cgColor.components?[0], 1.0)
        XCTAssertEqual(color?.cgColor.components?[1], 0.0)
        XCTAssertEqual(color?.cgColor.components?[2], 0.0)
    }

    func testEKSourceSourceName() {
        let localSource = EKSource()
        localSource.setValue(EKSourceType.local.rawValue, forKey: "sourceType")
        XCTAssertNil(localSource.sourceName)

        let exchangeSource = EKSource()
        exchangeSource.setValue(EKSourceType.exchange.rawValue, forKey: "sourceType")
        exchangeSource.setValue("Exchange", forKey: "title")
        XCTAssertEqual(exchangeSource.sourceName, "Exchange")
    }
}
