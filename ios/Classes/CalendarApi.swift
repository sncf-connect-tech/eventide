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
    private let converter = Converter()

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
        hexColor: String,
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
            
            guard let uiColor = UIColor(hex: hexColor) else {
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
                    hexColor: uiColor.hexString,
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
                        hexColor: UIColor(cgColor: $0.cgColor).hexString,
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
            
            ekEvent.title = flutterEvent.title
            ekEvent.notes = flutterEvent.description
            ekEvent.startDate = converter.parseDate(from: flutterEvent.startDate)
            ekEvent.endDate = converter.parseDate(from: flutterEvent.endDate)
            ekEvent.calendar = eventStore.calendar(withIdentifier: flutterEvent.calendarId)
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

fileprivate class Converter {
    func parseDate(from millisecondsSinceEpoch: Int64) -> Date {
        let timeInterval = TimeInterval(integerLiteral: millisecondsSinceEpoch)
        return Date(timeIntervalSince1970: timeInterval)
    }
}

extension UIColor {
    var hexString: String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let rgb: UInt32 = (UInt32)(red*255)<<16 | (UInt32)(green*255)<<8 | (UInt32)(blue*255)<<0

        return String(format:"#%06X", rgb)
    }
    
    convenience init?(hex: String) {
        var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.count) != 6) {
            return nil
        }

        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        self.init(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
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
