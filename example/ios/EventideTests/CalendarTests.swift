//
//  CalendarTests.swift
//  EventideTests
//
//  Created by CHOUPAULT Alexis on 21/03/2025.
//

import XCTest
@testable import eventide

final class CalendarTests: XCTestCase {
    private let timeout = TimeInterval(5)
    private var calendarImplem: CalendarImplem!

    func testCreateCalendar_permissionGranted() {
        let expectation = expectation(description: "Calendar has been created")
        
        let mockEasyEventStore = MockEasyEventStore()
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionGranted()
        )
        
        calendarImplem.createCalendar(title: "title", color: 0xFF0000, localAccountName: "Test account") { createCalendarResult in
            switch (createCalendarResult) {
            case .success(let calendar):
                XCTAssert(calendar.title == "title")
                XCTAssert(calendar.color == 0xFF0000)
                XCTAssert(calendar.account.name == "Test account")
                XCTAssert(calendar.account.type == "local")
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
        
        calendarImplem.retrieveCalendars(onlyWritableCalendars: true, fromLocalAccountName: nil) { retrieveCalendarsResult in
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
        
        calendarImplem.retrieveCalendars(onlyWritableCalendars: true, fromLocalAccountName: account1.name) { retrieveCalendarsResult in
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
        
        calendarImplem.retrieveCalendars(onlyWritableCalendars: false, fromLocalAccountName: account2.name) { retrieveCalendarsResult in
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
        
        calendarImplem.retrieveCalendars(onlyWritableCalendars: false, fromLocalAccountName: nil) { retrieveCalendarsResult in
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
    
    func testCreateCalendar_permissionRefused() {
        let expectation = expectation(description: "Calendar has not been created")
        
        let mockEasyEventStore = MockEasyEventStore()
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionRefused()
        )
        
        calendarImplem.createCalendar(title: "title", color: 0xFF0000, localAccountName: "Test account") { createCalendarResult in
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
        
        calendarImplem.retrieveCalendars(onlyWritableCalendars: true, fromLocalAccountName: nil) { retrieveCalendarsResult in
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
    
    func testCreateCalendar_permissionError() {
        let expectation = expectation(description: "Calendar has not been created")
        
        let mockEasyEventStore = MockEasyEventStore()
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionError()
        )
        
        calendarImplem.createCalendar(title: "title", color: 0xFF0000, localAccountName: "Test account") { createCalendarResult in
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
        
        calendarImplem.retrieveCalendars(onlyWritableCalendars: true, fromLocalAccountName: nil) { retrieveCalendarsResult in
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
}
