//
//  CalendarImplem.swift
//  flutter_calendar_connect
//
//  Created by CHOUPAULT Alexis on 31/12/2024.
//

import Foundation
import EventKit

class CalendarImplem: CalendarApi {
    let eventStore = EventStoreManager.shared.eventStore
    
    func createCalendar(
        title: String,
        color: Int64,
        completion: @escaping (Result<Calendar, Error>) -> Void
    ) {
        checkCalendarAccessThenExecute {
            guard let source = self.getSource() else {
                completion(.failure(PigeonError(
                    code: "404",
                    message: "Calendar source was not found",
                    details: "No source has been found between local, iCloud nor default sources"
                )))
                return
            }
            
            guard let uiColor = UIColor(int64: color) else {
                completion(.failure(PigeonError(
                    code: "400",
                    message: "Unable to parse cgColor from hex",
                    details: "hexadecimal number needs to start with # and to be 8 or 6 char long"
                )))
                return
            }
            
            let ekCalendar = EKCalendar.init(for: .event, eventStore: self.eventStore)
            
            ekCalendar.title = title
            ekCalendar.cgColor = uiColor.cgColor
            ekCalendar.source = source
            
            do {
                try self.eventStore.saveCalendar(ekCalendar, commit: true)
                let calendar = Calendar(
                    id: ekCalendar.calendarIdentifier,
                    title: title,
                    color: uiColor.toInt64(),
                    sourceName: source.sourceName
                )
                completion(.success(calendar))
                
            } catch {
                self.eventStore.reset()
                completion(.failure(PigeonError(
                    code: "500",
                    message: "Error while saving calendar",
                    details: nil
                )))
            }
            
        } noAccess: {
            completion(.failure(PigeonError(
                code: "403",
                message: "Calendar access has been refused or has not been given yet",
                details: nil
            )))
        }

    }

    func retrieveCalendars(onlyWritableCalendars: Bool, completion: @escaping (Result<[Calendar], Error>) -> Void) {
        checkCalendarAccessThenExecute {
            let calendars = self.eventStore.calendars(for: .event)
                .filter({ calendar in
                    guard onlyWritableCalendars else {
                        return true
                    }
                    return calendar.allowsContentModifications
                })
                .map {
                    Calendar(
                        id: $0.calendarIdentifier,
                        title: $0.title,
                        color: UIColor(cgColor: $0.cgColor).toInt64(),
                        sourceName: $0.source.sourceName
                    )
                }
            
            completion(.success(calendars))
            
        } noAccess: {
            completion(.failure(PigeonError(
                code: "403",
                message: "Calendar access has been refused or has not been given yet",
                details: nil
            )))
        }
    }
    
    func createOrUpdate(event: Event, completion: @escaping (Result<Bool, Error>) -> Void) {
        checkCalendarAccessThenExecute {
            var ekEvent: EKEvent?
            
            if event.id == nil {
                ekEvent = EKEvent(eventStore: self.eventStore)
            } else {
                ekEvent = self.eventStore.event(withIdentifier: event.id!)
            }
            
            guard let ekEvent else {
                completion(.failure(PigeonError(
                    code: "404",
                    message: "Event not found",
                    details: "The provided event.id is certainly incorrect"
                )))
                return
            }
            
            ekEvent.calendar = self.eventStore.calendar(withIdentifier: event.calendarId)
            ekEvent.title = event.title
            ekEvent.notes = event.description
            ekEvent.startDate = Date(from: event.startDate)
            ekEvent.endDate = Date(from: event.endDate)
            ekEvent.timeZone = TimeZone(identifier: event.timeZone)
            // TODO: location
            
            if event.url != nil {
                ekEvent.url = URL(string: event.url!)
            }
            
            var alarms = [EKAlarm]()
            for alarm in event.alarms.compactMap({ $0 }) {
                let timeInterval = TimeInterval(-alarm.minutes)
                alarms.append(EKAlarm(relativeOffset: timeInterval))
            }
            
            ekEvent.alarms = alarms
            
            do {
                try self.eventStore.save(ekEvent, span: EKSpan.thisEvent, commit: true)
                completion(.success(true))
                
            } catch {
                self.eventStore.reset()
                completion(.failure(PigeonError(
                    code: "500",
                    message: "Event not created",
                    details: nil
                )))
            }
        } noAccess: {
            completion(.failure(PigeonError(
                code: "403",
                message: "Calendar access has been refused or has not been given yet",
                details: nil
            )))
        }


    }
    
    private func getSource() -> EKSource? {
        guard let defaultSource = eventStore.defaultCalendarForNewEvents?.source else {
            // if eventStore.defaultCalendarForNewEvents?.source is nil then eventStore.sources is empty
            return nil
        }
        
        let iCloudSources = eventStore.sources.filter { $0.sourceType == .calDAV && $0.sourceIdentifier == "iCloud" }

        if (!iCloudSources.isEmpty) {
            return iCloudSources.first
        }
        
        let localSources = eventStore.sources.filter { $0.sourceType == .local }

        if (!localSources.isEmpty) {
            return localSources.first
        }

        return defaultSource
    }
    
    private func hasCalendarAccess() -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        
        if #available(iOS 17, *) {
            return status == EKAuthorizationStatus.fullAccess
        } else {
            return status == EKAuthorizationStatus.authorized
        }
    }
    
    private func checkCalendarAccessThenExecute(
        _ permissionsGrantedCallback: @escaping () -> Void,
        noAccess permissionsRefusedCallback: @escaping () -> Void
    ) {
        if hasCalendarAccess() {
            permissionsGrantedCallback()
        } else {
            requestCalendarAccess { granted in
                if (granted) {
                    permissionsGrantedCallback()
                } else {
                    permissionsRefusedCallback()
                }
            }
        }
    }
    
    private func requestCalendarAccess(completion: @escaping (_ isGranted: Bool) -> Void) {
        let handler: EKEventStoreRequestAccessCompletionHandler = { isGranted, error in
            guard error == nil else {
                let pigeonError = PigeonError(code: error!.localizedDescription, message: nil, details: nil)
                completion(isGranted)
                return
            }
            
            completion(isGranted)
        }
        
        if #available(iOS 17, *) {
            eventStore.requestFullAccessToEvents(completion: handler)
        } else {
            eventStore.requestAccess(to: .event, completion: handler)
        }
    }
}
