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
                MockCalendar(
                    id: "1",
                    title: "title",
                    color: UIColor.red,
                    isWritable: true,
                    account: Account(id: "local", name: "local", type: "local"),
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
        
        calendarImplem.createReminder(reminder, forEventId: "1") { createReminderResult in
            switch (createReminderResult) {
            case .success(let event):
                XCTAssert(event.reminders.count == 1)
                XCTAssert(event.reminders.first == -reminder)
                XCTAssert(mockEasyEventStore.calendars.first!.events.first!.reminders!.first! == TimeInterval(-reminder))
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
                MockCalendar(
                    id: "1",
                    title: "title",
                    color: UIColor.red,
                    isWritable: true,
                    account: Account(id: "local", name: "local", type: "local"),
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
                            reminders: [10]
                        )
                    ]
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
                XCTAssert(mockEasyEventStore.calendars.first!.events.first!.reminders!.last! == TimeInterval(-reminder))
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
                MockCalendar(
                    id: "1",
                    title: "title",
                    color: UIColor.red,
                    isWritable: true,
                    account: Account(id: "local", name: "local", type: "local"),
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
                XCTAssert(mockEasyEventStore.calendars.first!.events.first!.reminders == nil)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testDeleteReminder_permissionGranted() {
        let expectation = expectation(description: "Reminder has been deleted")
        
        let mockEasyEventStore = MockEasyEventStore(
            calendars: [
                MockCalendar(
                    id: "1",
                    title: "title",
                    color: UIColor.red,
                    isWritable: true,
                    account: Account(id: "local", name: "local", type: "local"),
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
                            reminders: [3600]
                        )
                    ]
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
                XCTAssert(mockEasyEventStore.calendars.first!.events.first!.reminders!.isEmpty)
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
                MockCalendar(
                    id: "1",
                    title: "title",
                    color: UIColor.red,
                    isWritable: true,
                    account: Account(id: "local", name: "local", type: "local"),
                    events: [
                        MockEvent(
                            id: "2",
                            title: "title",
                            startDate: Date(),
                            endDate: Date().addingTimeInterval(TimeInterval(10)),
                            calendarId: "1",
                            isAllDay: false,
                            description: "description",
                            url: "url",
                            reminders: [3600]
                        )
                    ]
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
                XCTAssert(mockEasyEventStore.calendars.first!.events.first!.reminders!.count == 1)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testDeleteReminder_reminderNotFound_permissionGranted() {
        let expectation = expectation(description: "Reminder has not been deleted")
        
        let mockEasyEventStore = MockEasyEventStore(
            calendars: [
                MockCalendar(
                    id: "1",
                    title: "title",
                    color: UIColor.red,
                    isWritable: true,
                    account: Account(id: "local", name: "local", type: "local"),
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
                            reminders: [3600]
                        )
                    ]
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
                XCTAssert(mockEasyEventStore.calendars.first!.events.first!.reminders!.count == 1)
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
                MockCalendar(
                    id: "1",
                    title: "title",
                    color: UIColor.red,
                    isWritable: true,
                    account: Account(id: "local", name: "local", type: "local"),
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
                XCTAssert(mockEasyEventStore.calendars.first!.events.first!.reminders == nil)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testDeleteReminder_permissionRefused() {
        let expectation = expectation(description: "Reminder has not been deleted")
        
        let mockEasyEventStore = MockEasyEventStore(
            calendars: [
                MockCalendar(
                    id: "1",
                    title: "title",
                    color: UIColor.red,
                    isWritable: true,
                    account: Account(id: "local", name: "local", type: "local"),
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
                            reminders: [3600]
                        )
                    ]
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
                XCTAssert(mockEasyEventStore.calendars.first!.events.first!.reminders!.count == 1)
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
                MockCalendar(
                    id: "1",
                    title: "title",
                    color: UIColor.red,
                    isWritable: true,
                    account: Account(id: "local", name: "local", type: "local"),
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
        
        calendarImplem.createReminder(reminder, forEventId: "1") { createReminderResult in
            switch (createReminderResult) {
            case .success:
                XCTFail("Reminder should not have been created")
            case .failure(let error):
                guard let _ = error as? PermissionError.PermErr else {
                    XCTFail("error should be of type PermissionError.PermErr")
                    return
                }
                XCTAssert(mockEasyEventStore.calendars.first!.events.first!.reminders == nil)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testDeleteReminder_permissionError() {
        let expectation = expectation(description: "Reminder has not been deleted")
        
        let mockEasyEventStore = MockEasyEventStore(
            calendars: [
                MockCalendar(
                    id: "1",
                    title: "title",
                    color: UIColor.red,
                    isWritable: true,
                    account: Account(id: "local", name: "local", type: "local"),
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
                            reminders: [3600]
                        )
                    ]
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
                XCTAssert(mockEasyEventStore.calendars.first!.events.first!.reminders!.count == 1)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
}
