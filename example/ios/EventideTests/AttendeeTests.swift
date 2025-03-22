//
//  AttendeeTests.swift
//  EventideTests
//
//  Created by CHOUPAULT Alexis on 21/03/2025.
//

import XCTest
@testable import eventide

final class AttendeeTests: XCTestCase {
    private let timeout = TimeInterval(5)
    private var calendarImplem: CalendarImplem!
    
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
                        url: "url",
                        attendees: [
                            MockAttendee(eventId: "1", name: "John Doe", email: "", type: 1, role: 1, status: 1),
                            MockAttendee(eventId: "1", name: "Jane Doe", email: "", type: 1, role: 2, status: 0)
                        ]
                    )
                ]
            )
        ]
    )
    
    func testRetrieveAttendees_permissionGranted() {
        let expectation = expectation(description: "Two attendees have been retrieved")
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionGranted()
        )
        
        calendarImplem.retrieveAttendees(eventId: "1") { retrieveAttendeesResult in
            switch (retrieveAttendeesResult) {
            case .success(let attendees):
                XCTAssert(attendees.count == 2)
                XCTAssert(attendees.first!.name == "John Doe")
                XCTAssert(attendees.first!.type == 1)
                XCTAssert(attendees.first!.role == 1)
                XCTAssert(attendees.first!.status == 1)
                XCTAssert(attendees.last!.name == "Jane Doe")
                XCTAssert(attendees.last!.type == 1)
                XCTAssert(attendees.last!.role == 2)
                XCTAssert(attendees.last!.status == 0)
                expectation.fulfill()
            case .failure:
                XCTFail("Attendees should have been retrieved")
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testRetrieveAttendees_permissionRefused() {
        let expectation = expectation(description: "No attendee has been retrieved")
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionRefused()
        )
        
        calendarImplem.retrieveAttendees(eventId: "1") { retrieveAttendeesResult in
            switch (retrieveAttendeesResult) {
            case .success:
                XCTFail("Attendees should not have been retrieved")
            case .failure(let error):
                guard let error = error as? PigeonError else {
                    XCTFail("error should be of type PigeonError")
                    return
                }
                XCTAssert(error.code == "ACCESS_REFUSED")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testRetrieveAttendees_permissionError() {
        let expectation = expectation(description: "No attendee has been retrieved")
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionError()
        )
        
        calendarImplem.retrieveAttendees(eventId: "1") { retrieveAttendeesResult in
            switch (retrieveAttendeesResult) {
            case .success:
                XCTFail("Attendees should not have been retrieved")
            case .failure(let error):
                guard let _ = error as? PermissionError.PermErr else {
                    XCTFail("error should be of type PermissionError.PermErr")
                    return
                }
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
}
