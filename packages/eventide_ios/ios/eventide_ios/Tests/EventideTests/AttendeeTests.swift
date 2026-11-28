//
//  AttendeeTests.swift
//  EventideTests
//
//  Created by CHOUPAULT Alexis on 02/07/2025.
//

import XCTest
@testable import eventide_ios

final class AttendeeTests: XCTestCase {
    private let timeout = TimeInterval(5)
    private var calendarImplem: CalendarImplem!

    func testRetrieveEvents_includesAttendees() {
        let expectation = expectation(description: "Retrieved event should contain its attendees")

        let now = Date()
        let attendee = Attendee(
            name: "John Doe",
            email: "",
            type: 1,
            role: 1,
            status: 2
        )

        let mockEasyEventStore = MockEasyEventStore(
            calendars: [
                Calendar(
                    id: "1",
                    title: "title",
                    color: UIColor.red.toInt64(),
                    isWritable: true,
                    account: Account(id: "local", name: "local", type: "local")
                )
            ],
            events: [
                Event(
                    id: "1",
                    calendarId: "1",
                    title: "title",
                    isAllDay: false,
                    startDate: now.addingTimeInterval(60).millisecondsSince1970,
                    endDate: now.addingTimeInterval(120).millisecondsSince1970,
                    reminders: [],
                    attendees: [attendee],
                    description: "description",
                    url: "url"
                )
            ]
        )

        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionGranted()
        )

        calendarImplem.retrieveEvents(
            calendarId: "1",
            startDate: now.millisecondsSince1970,
            endDate: now.addingTimeInterval(3600).millisecondsSince1970
        ) { result in
            switch result {
            case .success(let events):
                XCTAssertEqual(events.count, 1)
                XCTAssertEqual(events.first?.attendees.count, 1)
                XCTAssertEqual(events.first?.attendees.first?.name, "John Doe")
                XCTAssertEqual(events.first?.attendees.first?.type, 1)
                XCTAssertEqual(events.first?.attendees.first?.role, 1)
                XCTAssertEqual(events.first?.attendees.first?.status, 2)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Expected events with attendees, got error: \(error)")
            }
        }

        waitForExpectations(timeout: timeout)
    }
}
