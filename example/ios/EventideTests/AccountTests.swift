//
//  AccountTests.swift
//  EventideTests
//
//  Created by CHOUPAULT Alexis on 15/12/2025.
//

import XCTest
@testable import eventide

final class AccountTests: XCTestCase {
    private let timeout = TimeInterval(5)
    private var calendarImplem: CalendarImplem!
    
    func testRetrieveAccounts_permissionGranted() {
        let expectation = expectation(description: "Accounts have been retrieved")
        
        let mockEasyEventStore = MockEasyEventStore(
            calendars: [
                MockCalendar(
                    id: "1",
                    title: "title",
                    color: UIColor.red,
                    isWritable: false,
                    account: Account(id: "test", name: "test", type: "local"),
                    events: []
                ),
                MockCalendar(
                    id: "2",
                    title: "title",
                    color: UIColor.blue,
                    isWritable: true,
                    account: Account(id: "iCloud", name: "iCloud", type: "calDAV"),
                    events: []
                )
            ]
        )
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionGranted()
        )
        
        calendarImplem.retrieveAccounts { retrieveAccountsResult in
            switch (retrieveAccountsResult) {
            case .success(let accounts):
                XCTAssert(accounts.count == 2)
                XCTAssert(accounts.first!.id == "test")
                XCTAssert(accounts.last!.id == "iCloud")
                expectation.fulfill()
            case .failure:
                XCTFail("Accounts should have been retrieved")
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testRetrieveAccounts_permissionRefused() {
        let expectation = expectation(description: "Accounts have not been retrieved")
        
        let mockEasyEventStore = MockEasyEventStore()
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionRefused()
        )
        
        calendarImplem.retrieveAccounts{ retrieveAccountsResult in
            switch (retrieveAccountsResult) {
            case .success:
                XCTFail("Accounts should not have been retrieved")
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
    
    func testRetrieveCalendars_permissionError() {
        let expectation = expectation(description: "Accounts have not been retrieved")
        
        let mockEasyEventStore = MockEasyEventStore()
        
        calendarImplem = CalendarImplem(
            easyEventStore: mockEasyEventStore,
            permissionHandler: PermissionError()
        )
        
        calendarImplem.retrieveAccounts { retrieveAccountsResult in
            switch (retrieveAccountsResult) {
            case .success:
                XCTFail("Accounts should not have been retrieved")
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
