//
//  PermissionHandlerTest.swift
//  EasyCalendarTests
//
//  Created by CHOUPAULT Alexis on 15/01/2025.
//

import XCTest
import EventKit
@testable import easy_calendar

class CalendarImplemTests: XCTestCase {
    var calendarImplem: CalendarImplem!
    var mockEventStore: MockEventStore!
    var mockPermissionHandler: MockPermissionHandler!
    
    override func setUp() {
        mockEventStore = MockEventStore(requestAccessResult: true)
        mockPermissionHandler = MockPermissionHandler(mockEventStore)
        calendarImplem = CalendarImplem(mockEventStore, mockPermissionHandler)
    }
    
    
    func testCreateAccessEventReminderAndDeleteAll() {
        let expectation = self.expectation(description: "Create calendar, access it, add event, retrieve event, create reminder, and delete all")
        
        // Step 1: Create Calendar
        self.calendarImplem.createCalendar(title: "Test Calendar", color: 0xFF0000) { createCalendarResult in
            switch createCalendarResult {
            case .success(let createdCalendar):
                XCTAssertEqual(createdCalendar.title, "Test Calendar")
                XCTAssertEqual(createdCalendar.color, 0xFF0000)
                
                // Step 2: Retrieve Calendars
                self.calendarImplem.retrieveCalendars(onlyWritableCalendars: false) { retrieveCalendarsResult in
                    switch retrieveCalendarsResult {
                    case .success(let calendars):
                        XCTAssertTrue(calendars.contains(where: { $0.id == createdCalendar.id }))
                        
                        // Step 3: Create Event
                        self.calendarImplem.createEvent(
                            title: "Test Event",
                            startDate: 1672531200000,
                            endDate: 1672534800000,
                            calendarId: createdCalendar.id,
                            description: "Test Description",
                            url: "https://example.com"
                        ) { createEventResult in
                            switch createEventResult {
                            case .success(let createdEvent):
                                XCTAssertEqual(createdEvent.title, "Test Event")
                                XCTAssertEqual(createdEvent.startDate, 1672531200000)
                                XCTAssertEqual(createdEvent.endDate, 1672534800000)
                                
                                // Step 4: Retrieve Events
                                self.calendarImplem.retrieveEvents(
                                    calendarId: createdCalendar.id,
                                    startDate: 1672531200000,
                                    endDate: 1672534800000
                                ) { retrieveEventsResult in
                                    switch retrieveEventsResult {
                                    case .success(let events):
                                        XCTAssertTrue(events.contains(where: { $0.id == createdEvent.id }))
                                        
                                        // Step 5: Create Reminder
                                        self.calendarImplem.createReminder(600, forEventId: createdEvent.id) { createReminderResult in
                                            switch createReminderResult {
                                            case .success(let eventWithReminder):
                                                XCTAssertEqual(eventWithReminder.reminders?.first, -600)
                                                
                                                // Step 6: Delete Reminder
                                                self.calendarImplem.deleteReminder(600, withEventId: createdEvent.id) { deleteReminderResult in
                                                    switch deleteReminderResult {
                                                    case .success(let eventWithoutReminder):
                                                        XCTAssertNil(eventWithoutReminder.reminders?.first(where: { $0 == 600 }))
                                                        
                                                        // Step 7: Delete Event
                                                        self.calendarImplem.deleteEvent(withId: createdEvent.id, createdCalendar.id) { deleteEventResult in
                                                            switch deleteEventResult {
                                                            case .success:
                                                                
                                                                // Step 8: Delete Calendar
                                                                self.calendarImplem.deleteCalendar(createdCalendar.id) { deleteCalendarResult in
                                                                    switch deleteCalendarResult {
                                                                    case .success:
                                                                        expectation.fulfill()
                                                                    case .failure:
                                                                        XCTFail("Calendar deletion should succeed")
                                                                    }
                                                                }
                                                            case .failure:
                                                                XCTFail("Event deletion should succeed")
                                                            }
                                                        }
                                                    case .failure:
                                                        XCTFail("Reminder deletion should succeed")
                                                    }
                                                }
                                            case .failure:
                                                XCTFail("Reminder creation should succeed")
                                            }
                                        }
                                    case .failure:
                                        XCTFail("Event retrieval should succeed")
                                    }
                                }
                            case .failure:
                                XCTFail("Event creation should succeed")
                            }
                        }
                    case .failure:
                        XCTFail("Calendar retrieval should succeed")
                    }
                }
            case .failure:
                XCTFail("Calendar creation should succeed")
            }
        }
        
        waitForExpectations(timeout: 5)
    }

    func testCreateCalendarWithoutSource() {
        let expectation = self.expectation(description: "Create calendar without source should fail")
        self.mockEventStore.noSource = true
        
        self.calendarImplem.createCalendar(title: "Test Calendar", color: 0xFF0000) { result in
            switch result {
            case .success:
                XCTFail("Calendar creation should fail without source")
            case .failure(let error):
                if let pigeonError = error as? PigeonError {
                    XCTAssertEqual(pigeonError.code, "NOT_FOUND")
                    XCTAssertEqual(pigeonError.message, "Calendar source was not found")
                } else {
                    XCTFail("Error should be of type PigeonError")
                }
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5)
    }

    func testDeleteNonExistentCalendar() {
        let expectation = self.expectation(description: "Delete non-existent calendar should fail")
        
        self.calendarImplem.deleteCalendar("nonExistentCalendarId") { result in
            switch result {
            case .success:
                XCTFail("Calendar deletion should fail for non-existent calendar")
            case .failure(let error):
                if let pigeonError = error as? PigeonError {
                    XCTAssertEqual(pigeonError.code, "NOT_FOUND")
                    XCTAssertEqual(pigeonError.message, "Calendar not found")
                } else {
                    XCTFail("Error should be of type PigeonError")
                }
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5)
    }

    func testCreateEventWithInvalidCalendarId() {
        let expectation = self.expectation(description: "Create event with invalid calendar ID should fail")
        
        self.calendarImplem.createEvent(
            title: "Test Event",
            startDate: 1672531200000,
            endDate: 1672534800000,
            calendarId: "invalidCalendarId",
            description: "Test Description",
            url: "https://example.com"
        ) { result in
            switch result {
            case .success:
                XCTFail("Event creation should fail with invalid calendar ID")
            case .failure(let error):
                if let pigeonError = error as? PigeonError {
                    XCTAssertEqual(pigeonError.code, "NOT_FOUND")
                    XCTAssertEqual(pigeonError.message, "Calendar not found")
                } else {
                    XCTFail("Error should be of type PigeonError")
                }
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5)
    }

    func testDeleteNonExistentEvent() {
        let expectation = self.expectation(description: "Delete non-existent event should fail")
        
        self.calendarImplem.createCalendar(title: "test", color: 0xFF0000) { result in
            switch result {
            case .success(let calendar):
                self.calendarImplem.deleteEvent(withId: "nonExistentEventId", calendar.id) { result in
                    switch result {
                    case .success:
                        XCTFail("Event deletion should fail for non-existent event")
                    case .failure(let error):
                        if let pigeonError = error as? PigeonError {
                            XCTAssertEqual(pigeonError.code, "NOT_FOUND")
                            XCTAssertEqual(pigeonError.message, "Event not found")
                        } else {
                            XCTFail("Error should be of type PigeonError")
                        }
                    }
                    expectation.fulfill()
                }
            case .failure(_):
                XCTFail("Event creation should succeed")
            }
        }
        
        waitForExpectations(timeout: 5)
    }

    func testCreateReminderForNonExistentEvent() {
        let expectation = self.expectation(description: "Create reminder for non-existent event should fail")
        
        self.calendarImplem.createReminder(600, forEventId: "nonExistentEventId") { result in
            switch result {
            case .success:
                XCTFail("Reminder creation should fail for non-existent event")
            case .failure(let error):
                if let pigeonError = error as? PigeonError {
                    XCTAssertEqual(pigeonError.code, "NOT_FOUND")
                    XCTAssertEqual(pigeonError.message, "Event not found")
                } else {
                    XCTFail("Error should be of type PigeonError")
                }
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5)
    }

    func testDeleteNonExistentReminder() {
        let expectation = self.expectation(description: "Delete non-existent reminder should fail")
        
        // setup
        self.calendarImplem.createCalendar(title: "test", color: 0xFF0000) { result in
            switch result {
            case .success(let calendar):
                self.calendarImplem.createEvent(title: "test", startDate: Date().millisecondsSince1970, endDate: Date().millisecondsSince1970, calendarId: calendar.id, description: nil, url: nil) { result in
                    switch result {
                    case .success(let event):
                        self.calendarImplem.deleteReminder(600, withEventId: event.id) { result in
                            switch result {
                            case .success:
                                XCTFail("Reminder deletion should fail for non-existent reminder")
                            case .failure(let error):
                                if let pigeonError = error as? PigeonError {
                                    XCTAssertEqual(pigeonError.code, "NOT_FOUND")
                                    XCTAssertEqual(pigeonError.message, "Reminder not found")
                                } else {
                                    XCTFail("Error should be of type PigeonError")
                                }
                            }
                            expectation.fulfill()
                        }
                    case .failure(_):
                        XCTFail("Event creation should succeed")
                    }
                }
            case .failure(_):
                XCTFail("Calendar creation should succeed")
            }
        }
        
        waitForExpectations(timeout: 5)
    }
}
