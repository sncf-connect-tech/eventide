//
//  CalendarImplemTests.swift
//  EventideTests
//
//  Created by CHOUPAULT Alexis on 24/01/2025.
//

import XCTest
@testable import eventide

final class CalendarImplemTests: XCTestCase {
    private let timeout = TimeInterval(5)
    private var calendarImplem: CalendarImplem!
    
    func testRequestCalendarPermission_permissionGranted() {
        let expectation = expectation(description: "Permission has been granted")
        
        let mockEasyEventStore = MockEasyEventStore()
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionGranted()
        )
        
        calendarImplem.requestCalendarPermission { permissionResult in
            switch (permissionResult) {
            case .success(let granted):
                XCTAssert(granted)
                expectation.fulfill()
            case .failure:
                XCTFail("Permission should have been granted")
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testRequestCalendarPermission_permissionRefused() {
        let expectation = expectation(description: "Permission has been refused")
        
        let mockEasyEventStore = MockEasyEventStore()
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionRefused()
        )
        
        calendarImplem.requestCalendarPermission { permissionResult in
            switch (permissionResult) {
            case .success(let granted):
                XCTAssert(!granted)
                expectation.fulfill()
            case .failure:
                XCTFail("Permission should have been refused")
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testRequestCalendarPermission_permissionError() {
        let expectation = expectation(description: "Permission error")
        
        let mockEasyEventStore = MockEasyEventStore()
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionError()
        )
        
        calendarImplem.requestCalendarPermission { permissionResult in
            switch (permissionResult) {
            case .success:
                XCTFail("Permission should throw error")
            case .failure(let error):
                XCTAssert(error is PermissionError.PermErr)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testCreateCalendar_permissionGranted() {
        let expectation = expectation(description: "Calendar has been created")
        
        let mockEasyEventStore = MockEasyEventStore()
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionGranted()
        )
        
        calendarImplem.createCalendar(title: "title", color: 0xFF0000, account: Account(name: "local", type: "local")) { createCalendarResult in
            switch (createCalendarResult) {
            case .success(let calendar):
                XCTAssert(calendar.title == "title")
                XCTAssert(calendar.color == 0xFF0000)
                XCTAssert(mockEasyEventStore.calendars.count == 1)
                expectation.fulfill()
            case .failure:
                XCTFail("Calendar should have been created")
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testCreateCalendar_sourceNotFound_permissionGranted() {
        let expectation = expectation(description: "Calendar has been created")
        
        let mockEasyEventStore = MockEasyEventStore()
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionGranted()
        )
        
        calendarImplem.createCalendar(title: "title", color: 0xFF0000, account: Account(name: "local", type: "local")) { createCalendarResult in
            switch (createCalendarResult) {
            case .success(let calendar):
                XCTAssert(calendar.title == "title")
                XCTAssert(calendar.color == 0xFF0000)
                XCTAssert(mockEasyEventStore.calendars.count == 1)
                expectation.fulfill()
            case .failure:
                XCTFail("Calendar should have been created")
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testRetrieveCalendars_onlyWritable_permissionGranted() {
        let expectation = expectation(description: "Calendars have been retrieved")
        
        let mockEasyEventStore = MockEasyEventStore(
            calendars: [
                MockCalendar(
                    id: "1",
                    title: "title",
                    color: UIColor.red,
                    isWritable: false,
                    account: Account(name: "local", type: "local"),
                    events: []
                ),
                MockCalendar(
                    id: "2",
                    title: "title",
                    color: UIColor.blue,
                    isWritable: true,
                    account: Account(name: "iCloud", type: "calDAV"),
                    events: []
                )
            ]
        )
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionGranted()
        )
        
        calendarImplem.retrieveCalendars(onlyWritableCalendars: true) { retrieveCalendarsResult in
            switch (retrieveCalendarsResult) {
            case .success(let calendars):
                XCTAssert(calendars.count == 1)
                XCTAssert(calendars.last!.id == "2")
                expectation.fulfill()
            case .failure:
                XCTFail("Calendars should have been retrieved")
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testRetrieveCalendars_onlyWritableWithAccountFilter_permissionGranted() {
        let expectation = expectation(description: "No eligible calendar")
        
        let account1 = Account(name: "local", type: "local")
        let account2 = Account(name: "iCloud", type: "calDAV")
        let mockEasyEventStore = MockEasyEventStore(
            calendars: [
                MockCalendar(
                    id: "1",
                    title: "title",
                    color: UIColor.red,
                    isWritable: false,
                    account: account1,
                    events: []
                ),
                MockCalendar(
                    id: "2",
                    title: "title",
                    color: UIColor.blue,
                    isWritable: true,
                    account: account2,
                    events: []
                )
            ]
        )
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionGranted()
        )
        
        calendarImplem.retrieveCalendars(onlyWritableCalendars: true, from: account1) { retrieveCalendarsResult in
            switch (retrieveCalendarsResult) {
            case .success(let calendars):
                XCTAssert(calendars.isEmpty)
                expectation.fulfill()
            case .failure:
                XCTFail("Calendars should have been retrieved")
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testRetrieveCalendars_accountFilter_permissionGranted() {
        let expectation = expectation(description: "Calendar has been retrieved")
        
        let account1 = Account(name: "local", type: "local")
        let account2 = Account(name: "iCloud", type: "calDAV")
        let mockEasyEventStore = MockEasyEventStore(
            calendars: [
                MockCalendar(
                    id: "1",
                    title: "title",
                    color: UIColor.red,
                    isWritable: false,
                    account: account1,
                    events: []
                ),
                MockCalendar(
                    id: "2",
                    title: "title",
                    color: UIColor.blue,
                    isWritable: true,
                    account: account2,
                    events: []
                )
            ]
        )
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionGranted()
        )
        
        calendarImplem.retrieveCalendars(onlyWritableCalendars: false, from: account2) { retrieveCalendarsResult in
            switch (retrieveCalendarsResult) {
            case .success(let calendars):
                XCTAssert(calendars.count == 1)
                XCTAssert(calendars.last!.id == "2")
                expectation.fulfill()
            case .failure:
                XCTFail("Calendars should have been retrieved")
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testRetrieveCalendars_all_permissionGranted() {
        let expectation = expectation(description: "Calendars have been retrieved")
        
        let mockEasyEventStore = MockEasyEventStore(
            calendars: [
                MockCalendar(
                    id: "1",
                    title: "title",
                    color: UIColor.red,
                    isWritable: false,
                    account: Account(name: "local", type: "local"),
                    events: []
                ),
                MockCalendar(
                    id: "2",
                    title: "title",
                    color: UIColor.blue,
                    isWritable: true,
                    account: Account(name: "iCloud", type: "calDAV"),
                    events: []
                )
            ]
        )
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionGranted()
        )
        
        calendarImplem.retrieveCalendars(onlyWritableCalendars: false) { retrieveCalendarsResult in
            switch (retrieveCalendarsResult) {
            case .success(let calendars):
                XCTAssert(calendars.count == 2)
                XCTAssert(calendars.first!.id == "1")
                XCTAssert(calendars.last!.id == "2")
                expectation.fulfill()
            case .failure:
                XCTFail("Calendars should have been retrieved")
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testDeleteCalendar_writable_permissionGranted() {
        let expectation = expectation(description: "Calendar has been deleted")
        
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
        
        calendarImplem.deleteCalendar("1") { deleteCalendarResult in
            switch (deleteCalendarResult) {
            case .success:
                XCTAssert(mockEasyEventStore.calendars.isEmpty)
                expectation.fulfill()
            case .failure:
                XCTFail("Calendar should have been deleted")
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testDeleteCalendar_notFound_permissionGranted() {
        let expectation = expectation(description: "Calendar has not been deleted")
        
        let mockEasyEventStore = MockEasyEventStore(
            calendars: [
                MockCalendar(
                    id: "2",
                    title: "title",
                    color: UIColor.red,
                    isWritable: false,
                    account: Account(name: "local", type: "local"),
                    events: []
                )
            ]
        )
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionGranted()
        )
        
        calendarImplem.deleteCalendar("1") { deleteCalendarResult in
            switch (deleteCalendarResult) {
            case .success:
                XCTFail("Calendar should not have been deleted")
            case .failure(let error):
                guard let error = error as? PigeonError else {
                    XCTFail("error should be of type PigeonError")
                    return
                }
                XCTAssert(error.code == "NOT_FOUND")
                XCTAssert(mockEasyEventStore.calendars.count == 1)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testDeleteCalendar_notWritable_permissionGranted() {
        let expectation = expectation(description: "Calendar has not been deleted")
        
        let mockEasyEventStore = MockEasyEventStore(
            calendars: [
                MockCalendar(
                    id: "1",
                    title: "title",
                    color: UIColor.red,
                    isWritable: false,
                    account: Account(name: "local", type: "local"),
                    events: []
                )
            ]
        )
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionGranted()
        )
        
        calendarImplem.deleteCalendar("1") { deleteCalendarResult in
            switch (deleteCalendarResult) {
            case .success:
                XCTFail("Calendar should not have been deleted")
            case .failure(let error):
                guard let error = error as? PigeonError else {
                    XCTFail("error should be of type PigeonError")
                    return
                }
                XCTAssert(error.code == "NOT_EDITABLE")
                XCTAssert(mockEasyEventStore.calendars.count == 1)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
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
            url: "url"
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
            url: "url"
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
        let expectation = expectation(description: "One event have been retrieved")
        
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
        
        calendarImplem.createReminder(reminder, forEventId: "1") { createReminderResult in
            switch (createReminderResult) {
            case .success(let event):
                XCTAssert(event.reminders!.count == 1)
                XCTAssert(event.reminders!.first == -reminder)
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
                XCTAssert(event.reminders!.count == 2)
                XCTAssert(event.reminders!.last == -reminder)
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
                XCTAssert(event.reminders!.isEmpty)
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
    
    func testCreateCalendar_permissionRefused() {
        let expectation = expectation(description: "Calendar has not been created")
        
        let mockEasyEventStore = MockEasyEventStore()
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionRefused()
        )
        
        calendarImplem.createCalendar(title: "title", color: 0xFF0000, account: nil) { createCalendarResult in
            switch (createCalendarResult) {
            case .success:
                XCTFail("Calendar should not have been created")
            case .failure(let error):
                guard let error = error as? PigeonError else {
                    XCTFail("error should be of type PigeonError")
                    return
                }
                XCTAssert(error.code == "ACCESS_REFUSED")
                XCTAssert(mockEasyEventStore.calendars.isEmpty)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testRetrieveCalendars_permissionRefused() {
        let expectation = expectation(description: "Calendars have not been retrieved")
        
        let mockEasyEventStore = MockEasyEventStore()
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionRefused()
        )
        
        calendarImplem.retrieveCalendars(onlyWritableCalendars: true) { retrieveCalendarsResult in
            switch (retrieveCalendarsResult) {
            case .success:
                XCTFail("Calendars should not have been retrieved")
            case .failure(let error):
                guard let error = error as? PigeonError else {
                    XCTFail("error should be of type PigeonError")
                    return
                }
                XCTAssert(error.code == "ACCESS_REFUSED")
                XCTAssert(mockEasyEventStore.calendars.isEmpty)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testDeleteCalendar_permissionRefused() {
        let expectation = expectation(description: "Calendar has not been deleted")
        
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
        
        calendarImplem.deleteCalendar("1") { deleteCalendarResult in
            switch (deleteCalendarResult) {
            case .success:
                XCTFail("Calendar should not have been deleted")
            case .failure(let error):
                guard let error = error as? PigeonError else {
                    XCTFail("error should be of type PigeonError")
                    return
                }
                XCTAssert(error.code == "ACCESS_REFUSED")
                XCTAssert(mockEasyEventStore.calendars.count == 1)
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
            url: "url"
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
    
    func testCreateCalendar_permissionError() {
        let expectation = expectation(description: "Calendar has not been created")
        
        let mockEasyEventStore = MockEasyEventStore()
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionError()
        )
        
        calendarImplem.createCalendar(title: "title", color: 0xFF0000, account: nil) { createCalendarResult in
            switch (createCalendarResult) {
            case .success:
                XCTFail("Calendar should not have been created")
            case .failure(let error):
                guard let _ = error as? PermissionError.PermErr else {
                    XCTFail("error should be of type PermissionError.PermErr")
                    return
                }
                XCTAssert(mockEasyEventStore.calendars.isEmpty)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testRetrieveCalendars_permissionError() {
        let expectation = expectation(description: "Calendars have not been retrieved")
        
        let mockEasyEventStore = MockEasyEventStore()
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionError()
        )
        
        calendarImplem.retrieveCalendars(onlyWritableCalendars: true) { retrieveCalendarsResult in
            switch (retrieveCalendarsResult) {
            case .success:
                XCTFail("Calendars should not have been retrieved")
            case .failure(let error):
                guard let _ = error as? PermissionError.PermErr else {
                    XCTFail("error should be of type PermissionError.PermErr")
                    return
                }
                XCTAssert(mockEasyEventStore.calendars.isEmpty)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testDeleteCalendar_permissionError() {
        let expectation = expectation(description: "Calendar has not been deleted")
        
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
        
        calendarImplem.deleteCalendar("1") { deleteCalendarResult in
            switch (deleteCalendarResult) {
            case .success:
                XCTFail("Calendar should not have been deleted")
            case .failure(let error):
                guard let _ = error as? PermissionError.PermErr else {
                    XCTFail("error should be of type PermissionError.PermErr")
                    return
                }
                XCTAssert(mockEasyEventStore.calendars.count == 1)
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
            url: "url"
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
