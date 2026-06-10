//
//  ReminderTests.swift
//  EventideTests
//
//  Created by CHOUPAULT Alexis on 21/03/2025.
//

import XCTest
@testable import eventide

final class ReminderTests: XCTestCase {
    private let timeout = TimeInterval(5)
    private var calendarImplem: CalendarImplem!

    func testCreateReminder_permissionGranted() {
        let expectation = expectation(description: "Reminder has been created")
        
        let reminder: Int64 = 3600
        
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
                    startDate: Date().millisecondsSince1970,
                    endDate: Date().addingTimeInterval(TimeInterval(10)).millisecondsSince1970,
                    reminders: [],
                    attendees: [],
                    description: "description",
                    url: "url"
                )
            ]
        )
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionGranted()
        )
        
        calendarImplem.createReminder(reminder, forEventId: "1") { createReminderResult in
            switch (createReminderResult) {
            case .success(let event):
                XCTAssert(event.reminders.count == 1)
                XCTAssert(event.reminders.first == -reminder)
                XCTAssert(mockEasyEventStore.events.first!.reminders.first! == -reminder)
                expectation.fulfill()
            case .failure:
                XCTFail("Reminder should have been created")
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testCreateReminder_withExistingReminder_permissionGranted() {
        let expectation = expectation(description: "Reminder has been created")
        
        let reminder: Int64 = 3600
        
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
                    startDate: Date().millisecondsSince1970,
                    endDate: Date().addingTimeInterval(TimeInterval(10)).millisecondsSince1970,
                    reminders: [10],
                    attendees: [],
                    description: "description",
                    url: "url"
                )
            ]
        )
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionGranted()
        )
        
        calendarImplem.createReminder(reminder, forEventId: "1") { createReminderResult in
            switch (createReminderResult) {
            case .success(let event):
                XCTAssert(event.reminders.count == 2)
                XCTAssert(event.reminders.last == -reminder)
                XCTAssert(mockEasyEventStore.events.first!.reminders.last! == -reminder)
                expectation.fulfill()
            case .failure:
                XCTFail("Reminder should have been created")
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testCreateReminder_eventNotFound_permissionGranted() {
        let expectation = expectation(description: "Reminder has not been created")
        
        let reminder: Int64 = 3600
        
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
                    id: "2",
                    calendarId: "1",
                    title: "title",
                    isAllDay: false,
                    startDate: Date().millisecondsSince1970,
                    endDate: Date().addingTimeInterval(TimeInterval(10)).millisecondsSince1970,
                    reminders: [],
                    attendees: [],
                    description: "description",
                    url: "url"
                )
            ]
        )
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionGranted()
        )
    
        calendarImplem.createReminder(reminder, forEventId: "1") { createReminderResult in
            switch (createReminderResult) {
            case .success:
                XCTFail("Reminder should not have been created")
            case .failure(let error):
                guard let error = error as? PigeonError else {
                    XCTFail("error should be of type PigeonError")
                    return
                }
                XCTAssert(error.code == "NOT_FOUND")
                XCTAssert(mockEasyEventStore.events.first!.reminders.isEmpty)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testDeleteReminder_permissionGranted() {
        let expectation = expectation(description: "Reminder has been deleted")
        
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
                    startDate: Date().millisecondsSince1970,
                    endDate: Date().addingTimeInterval(TimeInterval(10)).millisecondsSince1970,
                    reminders: [3600],
                    attendees: [],
                    description: "description",
                    url: "url"
                )
            ]
        )
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionGranted()
        )
        
        calendarImplem.deleteReminder(3600, withEventId: "1") { createReminderResult in
            switch (createReminderResult) {
            case .success(let event):
                XCTAssert(event.reminders.isEmpty)
                XCTAssert(mockEasyEventStore.events.first!.reminders.isEmpty)
                expectation.fulfill()
            case .failure:
                XCTFail("Reminder should have been deleted")
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testDeleteReminder_eventNotFound_permissionGranted() {
        let expectation = expectation(description: "Reminder has not been deleted")
        
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
                    id: "2",
                    calendarId: "1",
                    title: "title",
                    isAllDay: false,
                    startDate: Date().millisecondsSince1970,
                    endDate: Date().addingTimeInterval(TimeInterval(10)).millisecondsSince1970,
                    reminders: [3600],
                    attendees: [],
                    description: "description",
                    url: "url"
                )
            ]
        )
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionGranted()
        )
        
        calendarImplem.deleteReminder(3600, withEventId: "1") { createReminderResult in
            switch (createReminderResult) {
            case .success:
                XCTFail("Reminder should not have been deleted")
            case .failure(let error):
                guard let error = error as? PigeonError else {
                    XCTFail("error should be of type PigeonError")
                    return
                }
                XCTAssert(error.code == "NOT_FOUND")
                XCTAssert(mockEasyEventStore.events.first!.reminders.count == 1)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testDeleteReminder_reminderNotFound_permissionGranted() {
        let expectation = expectation(description: "Reminder has not been deleted")
        
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
                    startDate: Date().millisecondsSince1970,
                    endDate: Date().addingTimeInterval(TimeInterval(10)).millisecondsSince1970,
                    reminders: [3600],
                    attendees: [],
                    description: "description",
                    url: "url"
                )
            ]
        )
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionGranted()
        )
        
        calendarImplem.deleteReminder(10, withEventId: "1") { createReminderResult in
            switch (createReminderResult) {
            case .success:
                XCTFail("Reminder should not have been deleted")
            case .failure(let error):
                guard let error = error as? PigeonError else {
                    XCTFail("error should be of type PigeonError")
                    return
                }
                XCTAssert(error.code == "NOT_FOUND")
                XCTAssert(mockEasyEventStore.events.first!.reminders.count == 1)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testCreateReminder_permissionRefused() {
        let expectation = expectation(description: "Reminder has not been created")
        
        let reminder: Int64 = 3600
        
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
                    startDate: Date().millisecondsSince1970,
                    endDate: Date().addingTimeInterval(TimeInterval(10)).millisecondsSince1970,
                    reminders: [],
                    attendees: [],
                    description: "description",
                    url: "url"
                )
            ]
        )
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionRefused()
        )
        
        calendarImplem.createReminder(reminder, forEventId: "1") { createReminderResult in
            switch (createReminderResult) {
            case .success:
                XCTFail("Reminder should not have been created")
            case .failure(let error):
                guard let error = error as? PigeonError else {
                    XCTFail("error should be of type PigeonError")
                    return
                }
                XCTAssert(error.code == "ACCESS_REFUSED")
                XCTAssert(mockEasyEventStore.events.first!.reminders.isEmpty)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testDeleteReminder_permissionRefused() {
        let expectation = expectation(description: "Reminder has not been deleted")
        
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
                    startDate: Date().millisecondsSince1970,
                    endDate: Date().addingTimeInterval(TimeInterval(10)).millisecondsSince1970,
                    reminders: [3600],
                    attendees: [],
                    description: "description",
                    url: "url"
                )
            ]
        )
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionRefused()
        )
        
        calendarImplem.deleteReminder(3600, withEventId: "1") { createReminderResult in
            switch (createReminderResult) {
            case .success:
                XCTFail("Reminder should not have been deleted")
            case .failure(let error):
                guard let error = error as? PigeonError else {
                    XCTFail("error should be of type PigeonError")
                    return
                }
                XCTAssert(error.code == "ACCESS_REFUSED")
                XCTAssert(mockEasyEventStore.events.first!.reminders.count == 1)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testCreateReminder_permissionError() {
        let expectation = expectation(description: "Reminder has not been created")
        
        let reminder: Int64 = 3600
        
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
                    startDate: Date().millisecondsSince1970,
                    endDate: Date().addingTimeInterval(TimeInterval(10)).millisecondsSince1970,
                    reminders: [],
                    attendees: [],
                    description: "description",
                    url: "url"
                )
            ]
        )
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionError()
        )
        
        calendarImplem.createReminder(reminder, forEventId: "1") { createReminderResult in
            switch (createReminderResult) {
            case .success:
                XCTFail("Reminder should not have been created")
            case .failure(let error):
                guard let _ = error as? PermissionError.PermErr else {
                    XCTFail("error should be of type PermissionError.PermErr")
                    return
                }
                XCTAssert(mockEasyEventStore.events.first!.reminders.isEmpty)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testDeleteReminder_permissionError() {
        let expectation = expectation(description: "Reminder has not been deleted")
        
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
                    startDate: Date().millisecondsSince1970,
                    endDate: Date().addingTimeInterval(TimeInterval(10)).millisecondsSince1970,
                    reminders: [3600],
                    attendees: [],
                    description: "description",
                    url: "url"
                )
            ]
        )
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionError()
        )
        
        calendarImplem.deleteReminder(3600, withEventId: "1") { createReminderResult in
            switch (createReminderResult) {
            case .success:
                XCTFail("Reminder should not have been deleted")
            case .failure(let error):
                guard let _ = error as? PermissionError.PermErr else {
                    XCTFail("error should be of type PermissionError.PermErr")
                    return
                }
                XCTAssert(mockEasyEventStore.events.first!.reminders.count == 1)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
}
