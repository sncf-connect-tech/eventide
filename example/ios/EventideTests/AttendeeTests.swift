//
//  AttendeeTests.swift
//  EventideTests
//
//  Created by CHOUPAULT Alexis on 02/07/2025.
//

import XCTest
@testable import eventide

final class AttendeeTests: XCTestCase {
    private let timeout = TimeInterval(5)
    private var calendarImplem: CalendarImplem!

    func testCreateAttendee_incompatiblePlatform() {
        let expectation = expectation(description: "Attendee creation should fail with platform incompatibility")
        
        let mockEasyEventStore = MockEasyEventStore(
            calendars: [
                MockCalendar(
                    id: "1",
                    title: "title",
                    color: UIColor.red,
                    isWritable: true,
                    account: Account(name: "local", type: "local"),
                    events: [
                        MockEvent(
                            id: "1",
                            title: "title",
                            startDate: Date(),
                            endDate: Date().addingTimeInterval(TimeInterval(10)),
                            calendarId: "1",
                            isAllDay: false,
                            description: "description",
                            url: "url"
                        )
                    ]
                )
            ]
        )
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionGranted()
        )
        
        calendarImplem.createAttendee(
            eventId: "1",
            name: "John Doe",
            email: "john.doe@example.com",
            role: 1,
            type: 1
        ) { result in
            switch result {
            case .success:
                XCTFail("Attendee creation should fail on iOS platform")
            case .failure(let error):
                if let pigeonError = error as? PigeonError {
                    XCTAssertEqual(pigeonError.code, "NOT_SUPPORTED_BY_PLATFORM")
                    XCTAssertEqual(pigeonError.message, "Platform does not handle this method")
                    XCTAssertEqual(pigeonError.details as? String, "EventKit API does not support attendee addition")
                } else {
                    XCTFail("Expected PigeonError with NOT_SUPPORTED_BY_PLATFORM code")
                }
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testCreateAttendee_permissionRefused() {
        let expectation = expectation(description: "Attendee creation should fail with permission refused")
        
        let mockEasyEventStore = MockEasyEventStore()
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionRefused()
        )
        
        calendarImplem.createAttendee(
            eventId: "1",
            name: "John Doe",
            email: "john.doe@example.com",
            role: 1,
            type: 1
        ) { result in
            switch result {
            case .success:
                XCTFail("Attendee creation should fail due to platform incompatibility")
            case .failure(let error):
                if let pigeonError = error as? PigeonError {
                    XCTAssertEqual(pigeonError.code, "NOT_SUPPORTED_BY_PLATFORM")
                } else {
                    XCTFail("Expected PigeonError")
                }
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: timeout)
    }

    func testDeleteAttendee_incompatiblePlatform() {
        let expectation = expectation(description: "Attendee deletion should fail with platform incompatibility")
        
        let mockEasyEventStore = MockEasyEventStore(
            calendars: [
                MockCalendar(
                    id: "1",
                    title: "title",
                    color: UIColor.red,
                    isWritable: true,
                    account: Account(name: "local", type: "local"),
                    events: [
                        MockEvent(
                            id: "1",
                            title: "title",
                            startDate: Date(),
                            endDate: Date().addingTimeInterval(TimeInterval(10)),
                            calendarId: "1",
                            isAllDay: false,
                            description: "description",
                            url: "url"
                        )
                    ]
                )
            ]
        )
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionGranted()
        )
        
        calendarImplem.deleteAttendee(
            eventId: "1",
            email: "john.doe@example.com"
        ) { result in
            switch result {
            case .success:
                XCTFail("Attendee deletion should fail on iOS platform")
            case .failure(let error):
                if let pigeonError = error as? PigeonError {
                    XCTAssertEqual(pigeonError.code, "NOT_SUPPORTED_BY_PLATFORM")
                    XCTAssertEqual(pigeonError.message, "Platform does not handle this method")
                    XCTAssertEqual(pigeonError.details as? String, "EventKit API does not support attendee deletion")
                } else {
                    XCTFail("Expected PigeonError with NOT_SUPPORTED_BY_PLATFORM code")
                }
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testDeleteAttendee_permissionRefused() {
        let expectation = expectation(description: "Attendee deletion should fail with permission refused")
        
        let mockEasyEventStore = MockEasyEventStore()
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionRefused()
        )
        
        calendarImplem.deleteAttendee(
            eventId: "1",
            email: "john.doe@example.com"
        ) { result in
            switch result {
            case .success:
                XCTFail("Attendee deletion should fail due to platform incompatibility")
            case .failure(let error):
                if let pigeonError = error as? PigeonError {
                    XCTAssertEqual(pigeonError.code, "NOT_SUPPORTED_BY_PLATFORM")
                } else {
                    XCTFail("Expected PigeonError")
                }
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
}
