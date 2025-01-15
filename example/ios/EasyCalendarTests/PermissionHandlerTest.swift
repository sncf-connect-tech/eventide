//
//  PermissionHandlerTest.swift
//  EasyCalendarTests
//
//  Created by CHOUPAULT Alexis on 15/01/2025.
//

import XCTest
import EventKit
@testable import easy_calendar

class PermissionHandlerTests: XCTestCase {
    func testCheckCalendarAccessThenExecute_AccessGranted() {
        let mockEventStore = MockEventStore(requestAccessResult: true)
        let permissionHandler = PermissionHandler(mockEventStore)
        let expectation = self.expectation(description: "Access granted callback")
        
        permissionHandler.checkCalendarAccessThenExecute {
            expectation.fulfill()
        } noAccess: {
            XCTFail("Access should be granted")
        } error: { _ in
            XCTFail("There should be no error")
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testCheckCalendarAccessThenExecute_AccessNotDeterminedThenGranted() {
        let mockEventStore = MockEventStore(requestAccessResult: true)
        let permissionHandler = PermissionHandler(mockEventStore)
        let expectation = self.expectation(description: "Access granted callback")
        
        permissionHandler.checkCalendarAccessThenExecute {
            expectation.fulfill()
        } noAccess: {
            XCTFail("Access should be granted")
        } error: { _ in
            XCTFail("There should be no error")
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testCheckCalendarAccessThenExecute_AccessDenied() {
        let mockEventStore = MockEventStore(requestAccessResult: false)
        let permissionHandler = PermissionHandler(mockEventStore)
        let expectation = self.expectation(description: "Access denied callback")
        
        permissionHandler.checkCalendarAccessThenExecute {
            XCTFail("Access should not be granted")
        } noAccess: {
            expectation.fulfill()
        } error: { _ in
            XCTFail("There should be no error")
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testCheckCalendarAccessThenExecute_Error() {
        let error = EKError(.internalFailure)
        let mockEventStore = MockEventStore(
            requestAccessResult: true,
            requestAccessError: error
        )
        let permissionHandler = PermissionHandler(mockEventStore)
        let expectation = self.expectation(description: "Access denied callback")
        
        permissionHandler.checkCalendarAccessThenExecute {
            XCTFail("Access should not be granted")
        } noAccess: {
            XCTFail("Access should not be denied")
        } error: { error in
            expectation.fulfill()
            XCTAssert((error as? PigeonError)?.code == "GENERIC_ERROR")
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
}
