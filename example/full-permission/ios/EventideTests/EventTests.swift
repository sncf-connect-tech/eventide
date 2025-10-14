//
//  EventTests.swift
//  EventideTests
//
//  Created by CHOUPAULT Alexis on 21/03/2025.
//

import XCTest
@testable import eventide

final class EventTests: XCTestCase {
    private let timeout = TimeInterval(5)
    private var calendarImplem: CalendarImplem!

    func testCreateEvent_permissionGranted() {
        let expectation = expectation(description: "Event has been created")
        
        let startDate = Date().millisecondsSince1970
        let endDate = Date().addingTimeInterval(TimeInterval(10)).millisecondsSince1970
        
        let mockEasyEventStore = MockEasyEventStore(
            calendars: [
                MockCalendar(
                    id: "1",
                    title: "title",
                    color: UIColor.red,
                    isWritable: true,
                    account: Account(name: "local", type: "local"),
                    events: []
                )
            ]
        )
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionGranted()
        )
        
        calendarImplem.createEvent(
            calendarId: "1",
            title: "title",
            startDate: startDate,
            endDate: endDate,
            isAllDay: false,
            description: "description",
            url: "url",
            reminders: []
        ) { createEventResult in
            switch (createEventResult) {
            case .success(let event):
                XCTAssert(event.title == "title")
                XCTAssert(event.startDate == startDate)
                XCTAssert(event.endDate == endDate)
                XCTAssert(event.calendarId == "1")
                XCTAssert(event.description == "description")
                XCTAssert(event.url == "url")
                XCTAssert(event.isAllDay == false)
                expectation.fulfill()
            case .failure:
                XCTFail("Event should have been created")
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testCreateEvent_calendarNotFound_permissionGranted() {
        let expectation = expectation(description: "Event has not been created")
        
        let mockEasyEventStore = MockEasyEventStore(
            calendars: [
                MockCalendar(
                    id: "2",
                    title: "title",
                    color: UIColor.red,
                    isWritable: true,
                    account: Account(name: "local", type: "local"),
                    events: []
                )
            ]
        )
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionGranted()
        )
        
        calendarImplem.createEvent(
            calendarId: "1",
            title: "title",
            startDate: Date().millisecondsSince1970,
            endDate: Date().addingTimeInterval(TimeInterval(10)).millisecondsSince1970,
            isAllDay: false,
            description: "description",
            url: "url",
            reminders: []
        ) { createEventResult in
            switch (createEventResult) {
            case .success:
                XCTFail("Event should not have been created")
            case .failure(let error):
                guard let error = error as? PigeonError else {
                    XCTFail("error should be of type PigeonError")
                    return
                }
                XCTAssert(error.code == "NOT_FOUND")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testRetrieveEvents_withinSpecifiedDates_permissionGranted() {
        let expectation = expectation(description: "One event has been retrieved")
        
        let startDate = Date()
        let endDate = Date().addingTimeInterval(TimeInterval(10))
        
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
                            startDate: startDate,
                            endDate: endDate,
                            calendarId: "1",
                            isAllDay: false,
                            description: "description",
                            url: "url"
                        ),
                        MockEvent(
                            id: "2",
                            title: "title",
                            startDate: startDate.addingTimeInterval(TimeInterval(50)),
                            endDate: endDate.addingTimeInterval(TimeInterval(50)),
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
        
        calendarImplem.retrieveEvents(
            calendarId: "1",
            startDate: startDate.addingTimeInterval(TimeInterval(-10)).millisecondsSince1970,
            endDate: endDate.addingTimeInterval(TimeInterval(10)).millisecondsSince1970
        ) { retrieveEventsResult in
            switch (retrieveEventsResult) {
            case .success(let events):
                XCTAssert(events.count == 1)
                XCTAssert(events.first!.id == "1")
                XCTAssert(mockEasyEventStore.calendars.first!.events.first!.id == "1")
                expectation.fulfill()
            case .failure:
                XCTFail("Event should have been retrieved")
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testRetrieveEvents_withAttendeesAndReminders_permissionGranted() {
        let expectation = expectation(description: "Event with attendees has been retrieved")
        
        let startDate = Date()
        let endDate = Date().addingTimeInterval(TimeInterval(10))
        
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
                            startDate: startDate,
                            endDate: endDate,
                            calendarId: "1",
                            isAllDay: false,
                            description: "description",
                            url: "url"
                        ),
                        MockEvent(
                            id: "2",
                            title: "title",
                            startDate: startDate.addingTimeInterval(TimeInterval(50)),
                            endDate: endDate.addingTimeInterval(TimeInterval(50)),
                            calendarId: "1",
                            isAllDay: false,
                            description: "description",
                            url: "url",
                            reminders: [TimeInterval(360), TimeInterval(3600)],
                            attendees: [
                                MockAttendee(
                                    name: "John Doe",
                                    email: "john.doe@example.com",
                                    type: 1,
                                    role: 1,
                                    status: 1
                                )
                            ]
                        )
                    ]
                )
            ]
        )
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionGranted()
        )
        
        calendarImplem.retrieveEvents(
            calendarId: "1",
            startDate: startDate.addingTimeInterval(TimeInterval(40)).millisecondsSince1970,
            endDate: endDate.addingTimeInterval(TimeInterval(60)).millisecondsSince1970
        ) { retrieveEventsResult in
            switch (retrieveEventsResult) {
            case .success(let events):
                XCTAssertEqual(events.count, 1)
                XCTAssertEqual(events.first!.id, "2")
                XCTAssertEqual(events.first!.attendees.count, 1)
                XCTAssertEqual(events.first!.attendees.first!.name, "John Doe")
                XCTAssertEqual(events.first!.attendees.first!.type, 1)
                XCTAssertEqual(events.first!.attendees.first!.role, 1)
                XCTAssertEqual(events.first!.attendees.first!.status, 1)
                XCTAssertEqual(events.first!.reminders.count, 2)
                XCTAssertEqual(events.first!.reminders.first, Int64(360))
                XCTAssertEqual(events.first!.reminders.last, Int64(3600))
                expectation.fulfill()
            case .failure:
                XCTFail("Event should have been retrieved")
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testRetrieveEvents_calendarNotFound_permissionGranted() {
        let expectation = expectation(description: "Events have not been retrieved")
        
        let startDate = Date()
        let endDate = Date().addingTimeInterval(TimeInterval(10))
        
        let mockEasyEventStore = MockEasyEventStore(
            calendars: [
                MockCalendar(
                    id: "2",
                    title: "title",
                    color: UIColor.red,
                    isWritable: true,
                    account: Account(name: "local", type: "local"),
                    events: [
                        MockEvent(
                            id: "1",
                            title: "title",
                            startDate: startDate,
                            endDate: endDate,
                            calendarId: "2",
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
        
        calendarImplem.retrieveEvents(
            calendarId: "1",
            startDate: startDate.addingTimeInterval(TimeInterval(-10)).millisecondsSince1970,
            endDate: endDate.addingTimeInterval(TimeInterval(10)).millisecondsSince1970
        ) { retrieveEventsResult in
            switch (retrieveEventsResult) {
            case .success:
                XCTFail("Event should not have been retrieved")
            case .failure(let error):
                guard let error = error as? PigeonError else {
                    XCTFail("error should be of type PigeonError")
                    return
                }
                XCTAssert(error.code == "NOT_FOUND")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testDeleteEvent_permissionGranted() {
        let expectation = expectation(description: "Event has been deleted")
        
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
        
        calendarImplem.deleteEvent(withId: "1") { deleteEventResult in
            switch (deleteEventResult) {
            case .success:
                XCTAssert(mockEasyEventStore.calendars.first!.events.isEmpty)
                expectation.fulfill()
            case .failure:
                XCTFail("Event should have been deleted")
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testDeleteEvent_notFound_permissionGranted() {
        let expectation = expectation(description: "Event has not been deleted")
        
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
                            id: "2",
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
        
        calendarImplem.deleteEvent(withId: "1") { deleteEventResult in
            switch (deleteEventResult) {
            case .success:
                XCTFail("Event should not have been deleted")
            case .failure(let error):
                guard let error = error as? PigeonError else {
                    XCTFail("error should be of type PigeonError")
                    return
                }
                XCTAssert(error.code == "NOT_FOUND")
                XCTAssert(mockEasyEventStore.calendars.first!.events.count == 1)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testDeleteEvent_calendarNotWritable_permissionGranted() {
        let expectation = expectation(description: "Event has not been deleted")
        
        let mockEasyEventStore = MockEasyEventStore(
            calendars: [
                MockCalendar(
                    id: "1",
                    title: "title",
                    color: UIColor.red,
                    isWritable: false,
                    account: Account(name: "local", type: "local"),
                    events: [
                        MockEvent(
                            id: "2",
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
        
        calendarImplem.deleteEvent(withId: "2") { deleteEventResult in
            switch (deleteEventResult) {
            case .success:
                XCTFail("Event should not have been deleted")
            case .failure(let error):
                guard let error = error as? PigeonError else {
                    XCTFail("error should be of type PigeonError")
                    return
                }
                XCTAssert(error.code == "NOT_EDITABLE")
                XCTAssert(mockEasyEventStore.calendars.first!.events.count == 1)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testCreateEvent_permissionRefused() {
        let expectation = expectation(description: "Event has not been created")
        
        let mockEasyEventStore = MockEasyEventStore(
            calendars: [
                MockCalendar(
                    id: "1",
                    title: "title",
                    color: UIColor.red,
                    isWritable: true,
                    account: Account(name: "local", type: "local"),
                    events: []
                )
            ]
        )
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionRefused()
        )
        
        calendarImplem.createEvent(
            calendarId: "1",
            title: "title",
            startDate: Date().millisecondsSince1970,
            endDate: Date().addingTimeInterval(TimeInterval(10)).millisecondsSince1970,
            isAllDay: false,
            description: "description",
            url: "url",
            reminders: []
        ) { createEventResult in
            switch (createEventResult) {
            case .success:
                XCTFail("Event should not have been created")
            case .failure(let error):
                guard let error = error as? PigeonError else {
                    XCTFail("error should be of type PigeonError")
                    return
                }
                XCTAssert(error.code == "ACCESS_REFUSED")
                XCTAssert(mockEasyEventStore.calendars.first!.events.isEmpty)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testRetrieveEvents_permissionRefused() {
        let expectation = expectation(description: "Events have not been retrieved")
        
        let mockEasyEventStore = MockEasyEventStore(
            calendars: [
                MockCalendar(
                    id: "1",
                    title: "title",
                    color: UIColor.red,
                    isWritable: true,
                    account: Account(name: "local", type: "local"),
                    events: []
                )
            ]
        )
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionRefused()
        )
        
        calendarImplem.retrieveEvents(
            calendarId: "1",
            startDate: Date().millisecondsSince1970,
            endDate: Date().addingTimeInterval(TimeInterval(10)).millisecondsSince1970
        ) { retrieveEventsResult in
            switch (retrieveEventsResult) {
            case .success:
                XCTFail("Events should not have been retrieved")
            case .failure(let error):
                guard let error = error as? PigeonError else {
                    XCTFail("error should be of type PigeonError")
                    return
                }
                XCTAssert(error.code == "ACCESS_REFUSED")
                XCTAssert(mockEasyEventStore.calendars.first!.events.isEmpty)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testDeleteEvent_permissionRefused() {
        let expectation = expectation(description: "Event has not been deleted")
        
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
            permissionHandler: PermissionRefused()
        )
        
        calendarImplem.deleteEvent(withId: "1") { deleteEventResult in
            switch (deleteEventResult) {
            case .success:
                XCTFail("Event should not have been deleted")
            case .failure(let error):
                guard let error = error as? PigeonError else {
                    XCTFail("error should be of type PigeonError")
                    return
                }
                XCTAssert(error.code == "ACCESS_REFUSED")
                XCTAssert(mockEasyEventStore.calendars.first!.events.count == 1)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testCreateEvent_permissionError() {
        let expectation = expectation(description: "Event has not been created")
        
        let mockEasyEventStore = MockEasyEventStore(
            calendars: [
                MockCalendar(
                    id: "1",
                    title: "title",
                    color: UIColor.red,
                    isWritable: true,
                    account: Account(name: "local", type: "local"),
                    events: []
                )
            ]
        )
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionError()
        )
        
        calendarImplem.createEvent(
            calendarId: "1",
            title: "title",
            startDate: Date().millisecondsSince1970,
            endDate: Date().addingTimeInterval(TimeInterval(10)).millisecondsSince1970,
            isAllDay: false,
            description: "description",
            url: "url",
            reminders: []
        ) { createEventResult in
            switch (createEventResult) {
            case .success:
                XCTFail("Event should not have been created")
            case .failure(let error):
                guard let _ = error as? PermissionError.PermErr else {
                    XCTFail("error should be of type PermissionError.PermErr")
                    return
                }
                XCTAssert(mockEasyEventStore.calendars.first!.events.isEmpty)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testRetrieveEvents_permissionError() {
        let expectation = expectation(description: "Events have not been retrieved")
        
        let mockEasyEventStore = MockEasyEventStore(
            calendars: [
                MockCalendar(
                    id: "1",
                    title: "title",
                    color: UIColor.red,
                    isWritable: true,
                    account: Account(name: "local", type: "local"),
                    events: []
                )
            ]
        )
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionError()
        )
        
        calendarImplem.retrieveEvents(
            calendarId: "1",
            startDate: Date().millisecondsSince1970,
            endDate: Date().addingTimeInterval(TimeInterval(10)).millisecondsSince1970
        ) { retrieveEventsResult in
            switch (retrieveEventsResult) {
            case .success:
                XCTFail("Events should not have been retrieved")
            case .failure(let error):
                guard let _ = error as? PermissionError.PermErr else {
                    XCTFail("error should be of type PermissionError.PermErr")
                    return
                }
                XCTAssert(mockEasyEventStore.calendars.first!.events.isEmpty)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testDeleteEvent_permissionError() {
        let expectation = expectation(description: "Event has not been deleted")
        
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
            permissionHandler: PermissionError()
        )
        
        calendarImplem.deleteEvent(withId: "1") { deleteEventResult in
            switch (deleteEventResult) {
            case .success:
                XCTFail("Event should not have been deleted")
            case .failure(let error):
                guard let _ = error as? PermissionError.PermErr else {
                    XCTFail("error should be of type PermissionError.PermErr")
                    return
                }
                XCTAssert(mockEasyEventStore.calendars.first!.events.count == 1)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    // MARK: - Native Platform Event Creation Tests
    
    func testCreateEventThroughNativePlatform_userSaves() {
        let expectation = expectation(description: "Event creation through native platform succeeded")
        
        let mockEasyEventStore = MockEasyEventStore(
            calendars: [
                MockCalendar(
                    id: "1",
                    title: "Test Calendar",
                    color: UIColor.blue,
                    isWritable: true,
                    account: Account(name: "local", type: "local"),
                    events: []
                )
            ]
        )
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionGranted()
        )
        
        calendarImplem.createEventThroughNativePlatform(
            title: "Native Event",
            startDate: Date().millisecondsSince1970,
            endDate: Date().addingTimeInterval(3600).millisecondsSince1970,
            isAllDay: false,
            description: "Created through native UI",
            url: "https://example.com",
            reminders: [900] // 15 minutes
        ) { result in
            switch result {
            case .success:
                // Success means user saved the event
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Event creation should have succeeded, but failed with: \(error)")
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testCreateEventThroughNativePlatform_userCancels() {
        let expectation = expectation(description: "Event creation through native platform was canceled")
        
        // Create a mock that simulates user cancellation
        let mockEasyEventStore = MockEasyEventStoreCanceled()
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionGranted()
        )
        
        calendarImplem.createEventThroughNativePlatform(
            title: "Native Event",
            startDate: Date().millisecondsSince1970,
            endDate: Date().addingTimeInterval(3600).millisecondsSince1970,
            isAllDay: false,
            description: "This should be canceled",
            url: nil,
            reminders: nil
        ) { result in
            switch result {
            case .success:
                XCTFail("Event creation should have been canceled")
            case .failure(let error):
                // Check that it's the right type of error
                if let pigeonError = error as? PigeonError {
                    XCTAssertEqual(pigeonError.code, "USER_CANCELED")
                    XCTAssertEqual(pigeonError.message, "User canceled event creation")
                    expectation.fulfill()
                } else {
                    XCTFail("Expected PigeonError with USER_CANCELED code")
                }
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testCreateEventThroughNativePlatform_presentationError() {
        let expectation = expectation(description: "Event creation through native platform failed to present")
        
        // Create a mock that simulates presentation error
        let mockEasyEventStore = MockEasyEventStorePresentationError()
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionGranted()
        )
        
        calendarImplem.createEventThroughNativePlatform(
            title: "Native Event",
            startDate: nil,
            endDate: nil,
            isAllDay: nil,
            description: nil,
            url: nil,
            reminders: nil
        ) { result in
            switch result {
            case .success:
                XCTFail("Event creation should have failed with presentation error")
            case .failure(let error):
                // Check that it's the right type of error
                if let pigeonError = error as? PigeonError {
                    XCTAssertEqual(pigeonError.code, "PRESENTATION_ERROR")
                    XCTAssertEqual(pigeonError.message, "Unable to present event creation view")
                    expectation.fulfill()
                } else {
                    XCTFail("Expected PigeonError with PRESENTATION_ERROR code")
                }
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testCreateEventThroughNativePlatform_noPermissionsRequired() {
        let expectation = expectation(description: "Event creation through native platform works without permissions")
        
        let mockEasyEventStore = MockEasyEventStore()
        
        // Use PermissionRefused to prove that no permissions are checked
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionRefused()
        )
        
        calendarImplem.createEventThroughNativePlatform(
            title: "No Permissions Event",
            startDate: Date().millisecondsSince1970,
            endDate: Date().addingTimeInterval(3600).millisecondsSince1970,
            isAllDay: true,
            description: "This should work even without permissions",
            url: nil,
            reminders: [300, 600] // 5 and 10 minutes
        ) { result in
            switch result {
            case .success:
                // Success proves that no permission check was performed
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Event creation should have succeeded without permission check, but failed with: \(error)")
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testCreateEventThroughNativePlatform_eventDeleted() {
        let expectation = expectation(description: "Event creation through native platform - event deleted")
        
        let mockEasyEventStore = MockEasyEventStoreEventDeleted()
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionGranted()
        )
        
        calendarImplem.createEventThroughNativePlatform(
            title: "Event to be deleted",
            startDate: Date().millisecondsSince1970,
            endDate: Date().addingTimeInterval(3600).millisecondsSince1970,
            isAllDay: false,
            description: nil,
            url: nil,
            reminders: nil
        ) { result in
            switch result {
            case .success:
                XCTFail("Event creation should have failed with event deleted")
            case .failure(let error):
                if let pigeonError = error as? PigeonError {
                    XCTAssertEqual(pigeonError.code, "EVENT_DELETED")
                    XCTAssertEqual(pigeonError.message, "Event was deleted")
                    expectation.fulfill()
                } else {
                    XCTFail("Expected PigeonError with EVENT_DELETED code")
                }
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testCreateEventThroughNativePlatform_unknownAction() {
        let expectation = expectation(description: "Event creation through native platform - unknown action")
        
        let mockEasyEventStore = MockEasyEventStoreUnknownAction()
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionGranted()
        )
        
        calendarImplem.createEventThroughNativePlatform(
            title: "Unknown action event",
            startDate: nil,
            endDate: nil,
            isAllDay: nil,
            description: nil,
            url: nil,
            reminders: nil
        ) { result in
            switch result {
            case .success:
                XCTFail("Event creation should have failed with unknown action")
            case .failure(let error):
                if let pigeonError = error as? PigeonError {
                    XCTAssertEqual(pigeonError.code, "GENERIC_ERROR")
                    XCTAssertEqual(pigeonError.message, "Unknown action from event edit controller")
                    expectation.fulfill()
                } else {
                    XCTFail("Expected PigeonError with GENERIC_ERROR code")
                }
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
}
