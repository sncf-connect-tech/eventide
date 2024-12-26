//
//  CalendarApi.swift
//  calendar_plugin
//
//  Created by CHOUPAULT Alexis on 18/07/2024.
//

import Flutter
import EventKit

class EventStoreManager: ObservableObject {
    static let shared = EventStoreManager()
    
    let eventStore: EKEventStore
    
    private init() {
        self.eventStore = EKEventStore()
    }
}

public class CalendarApi: CalendarActions {
    let eventStore = EventStoreManager.shared.eventStore

    public func requestCalendarAccess(completion: @escaping (Result<Bool, Error>) -> Void) {
        let handler: EKEventStoreRequestAccessCompletionHandler = { isGranted, error in
            guard error == nil else {
                let pigeonError = PigeonError(code: error!.localizedDescription, message: nil, details: nil)
                completion(.failure(pigeonError))
                return
            }
            
            completion(.success(isGranted))
        }
        
        if #available(iOS 17, *) {
            eventStore.requestFullAccessToEvents(completion: handler)
        } else {
            eventStore.requestAccess(to: .event, completion: handler)
        }
    }
    
    func createCalendar(
        title: String,
        color: Int64,
        completion: @escaping (Result<Calendar, Error>) -> Void
    ) {
        checkCalendarAccessThenExecute {
            guard let source = getSource() else {
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
            
            let ekCalendar = EKCalendar.init(for: .event, eventStore: eventStore)
            
            ekCalendar.title = title
            ekCalendar.cgColor = uiColor.cgColor
            ekCalendar.source = source
            
            do {
                try eventStore.saveCalendar(ekCalendar, commit: true)
                let calendar = Calendar(
                    id: ekCalendar.calendarIdentifier,
                    title: title,
                    color: uiColor.toInt64(),
                    sourceName: source.sourceName
                )
                completion(.success(calendar))
                
            } catch {
                eventStore.reset()
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
            let calendars = eventStore.calendars(for: .event)
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
    
    func createOrUpdateEvent(flutterEvent: Event, completion: @escaping (Result<Bool, Error>) -> Void) {
        checkCalendarAccessThenExecute {
            var ekEvent: EKEvent?
            
            if flutterEvent.id == nil {
                ekEvent = EKEvent(eventStore: eventStore)
            } else {
                ekEvent = eventStore.event(withIdentifier: flutterEvent.id!)
            }
            
            guard let ekEvent else {
                completion(.failure(PigeonError(
                    code: "404",
                    message: "Event not found",
                    details: "The provided flutterEvent.id is certainly incorrect"
                )))
                return
            }
            
            // TODO: location
            ekEvent.calendar = eventStore.calendar(withIdentifier: flutterEvent.calendarId)
            ekEvent.title = flutterEvent.title
            ekEvent.notes = flutterEvent.description
            ekEvent.startDate = Date(from: flutterEvent.startDate)
            ekEvent.endDate = Date(from: flutterEvent.endDate)
            ekEvent.timeZone = TimeZone(identifier: flutterEvent.timeZone)
            
            if flutterEvent.url != nil {
                ekEvent.url = URL(string: flutterEvent.url!)
            }
            
            var alarms = [EKAlarm]()
            for alarm in flutterEvent.alarms.compactMap({ $0 }) {
                let timeInterval = TimeInterval(-alarm.minutes)
                alarms.append(EKAlarm(relativeOffset: timeInterval))
            }
            
            ekEvent.alarms = alarms
            
            do {
                try eventStore.save(ekEvent, span: EKSpan.thisEvent, commit: true)
                completion(.success(true))
                
            } catch {
                eventStore.reset()
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
        _ permissionsGrantedCallback: () -> Void,
        noAccess permissionsRefusedCallback: () -> Void
    ) {
        if hasCalendarAccess() {
            permissionsGrantedCallback()
        } else {
            permissionsRefusedCallback()
        }
    }
}

extension Date {
    init(from millisecondsSinceEpoch: Int64) {
        self.init(timeIntervalSince1970: Double(millisecondsSinceEpoch) / 1000)
    }
}

extension UIColor {
    func toInt64() -> Int64 {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            let redInt = Int(red * 255)
            let greenInt = Int(green * 255)
            let blueInt = Int(blue * 255)
            let alphaInt = Int(alpha * 255)

            // Format ARGB
            let rgb = (alphaInt << 24) + (redInt << 16) + (greenInt << 8) + blueInt
            return Int64(rgb)
        } else {
            return Int64(0xFF000000)
        }
    }
    
    convenience init?(int64: Int64) {
        let hexString = String(int64, radix: 16)
        var rgbValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgbValue)

        self.init(
            red: CGFloat((rgbValue & 0x00ff0000) >> 16) / 255,
            green: CGFloat((rgbValue & 0x0000ff00) >> 8) / 255,
            blue: CGFloat((rgbValue & 0x000000ff)) / 255,
            alpha: CGFloat((rgbValue & 0xff000000) >> 24) / 255
        )
    }
}

extension EKSource {
    var sourceName: String? {
        guard sourceType != .local else {
            return nil
        }
        
        return title
    }
}
