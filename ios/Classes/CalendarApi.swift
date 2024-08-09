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
            
            guard let cgColor = UIColor(hex: hexColor)?.cgColor else {
                completion(.failure(PigeonError(
                    code: "400",
                    message: "Unable to parse cgColor from hex",
                    details: "hexadecimal number needs to start with 0x and to be 8 char long"
                )))
                return
            }
            
            let ekCalendar = EKCalendar.init(for: .event, eventStore: eventStore)
            
            ekCalendar.title = title
            ekCalendar.cgColor = cgColor
            ekCalendar.source = source
            
            do {
                try eventStore.saveCalendar(ekCalendar, commit: true)
                let calendar = Calendar(
                    id: ekCalendar.calendarIdentifier,
                    title: title,
                    hexColor: hexColor,
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

    func retrieveCalendars(completion: @escaping (Result<[Calendar], Error>) -> Void) {
        checkCalendarAccessThenExecute {
            let calendars = eventStore.calendars(for: .event).map {
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
        let cgColorInRGB = cgColor.converted(to: CGColorSpace(name: CGColorSpace.sRGB)!, intent: .defaultIntent, options: nil)!
        let colorRef = cgColorInRGB.components
        let r = colorRef?[0] ?? 0
        let g = colorRef?[1] ?? 0
        let b = ((colorRef?.count ?? 0) > 2 ? colorRef?[2] : g) ?? 0
        let a = cgColor.alpha

        var color = String(
            format: "#%02lX%02lX%02lX",
            lroundf(Float(r * 255)),
            lroundf(Float(g * 255)),
            lroundf(Float(b * 255))
        )

        if a < 1 {
            color += String(format: "%02lX", lroundf(Float(a * 255)))
        }

        return color
    }
    
    public convenience init?(hex: String) {
        let r, g, b, a: CGFloat
        
        if hex.hasPrefix("0x") {
            let start = hex.index(hex.startIndex, offsetBy: 2)
            let hexColor = String(hex[start...])
            
            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0
                
                if scanner.scanHexInt64(&hexNumber) {
                    a = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                    r = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    g = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    b = CGFloat((hexNumber & 0x000000ff)) / 255
                    
                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }
        
        return nil
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
