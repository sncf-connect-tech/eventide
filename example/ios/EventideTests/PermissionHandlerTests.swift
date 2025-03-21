//
//  PermissionHandlerTests.swift
//  EventideTests
//
//  Created by CHOUPAULT Alexis on 21/03/2025.
//

import XCTest
@testable import eventide

final class PermissionHandlerTests: XCTestCase {
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
}
