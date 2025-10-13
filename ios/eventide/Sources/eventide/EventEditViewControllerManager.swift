//
//  EventEditViewControllerManager.swift
//  eventide
//
//  Created by CHOUPAULT Alexis on 10/10/2025.
//

import EventKit
import EventKitUI
import UIKit

class EventEditViewControllerManager: NSObject {
    private let eventStore: EKEventStore
    private var completion: ((Result<Void, Error>) -> Void)?
    
    init(eventStore: EKEventStore) {
        self.eventStore = eventStore
        super.init()
    }
    
    func presentEventEditViewController(
        title: String?,
        startDate: Date?,
        endDate: Date?,
        isAllDay: Bool?,
        description: String?,
        url: String?,
        timeIntervals: [TimeInterval]?,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        self.completion = completion
        
        let event = EKEvent(eventStore: eventStore)
        
        if let title = title {
            event.title = title
        }
        
        if let startDate = startDate {
            event.startDate = startDate
        } else {
            event.startDate = Date()
        }
        
        if let endDate = endDate {
            event.endDate = endDate
        } else {
            event.endDate = event.startDate.addingTimeInterval(3600)
        }
        
        if let isAllDay = isAllDay {
            event.isAllDay = isAllDay
        }
        
        if let description = description {
            event.notes = description
        }
        
        if let urlString = url, let eventUrl = URL(string: urlString) {
            event.url = eventUrl
        }
        
        if let timeIntervals = timeIntervals {
            event.alarms = timeIntervals.compactMap { EKAlarm(relativeOffset: $0) }
        }
        
        let eventEditVC = EKEventEditViewController()
        eventEditVC.event = event
        eventEditVC.eventStore = eventStore
        eventEditVC.editViewDelegate = self
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                completion(.failure(PigeonError(
                    code: "PRESENTATION_ERROR",
                    message: "Manager was deallocated before presentation",
                    details: nil
                )))
                return
            }
            
            if let rootViewController = self.getRootViewController() {
                rootViewController.present(eventEditVC, animated: true, completion: nil)
            } else {
                self.completion?(.failure(PigeonError(
                    code: "PRESENTATION_ERROR", 
                    message: "Unable to find root view controller for presentation", 
                    details: nil
                )))
                self.completion = nil
            }
        }
    }
    
    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        
        var rootViewController = window.rootViewController
        
        while let presentedViewController = rootViewController?.presentedViewController {
            rootViewController = presentedViewController
        }
        
        return rootViewController
    }
}

// MARK: - EKEventEditViewDelegate
extension EventEditViewControllerManager: EKEventEditViewDelegate {
    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        controller.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            
            switch action {
            case .saved:
                self.completion?(.success(()))
                
            case .canceled:
                self.completion?(.failure(PigeonError(
                    code: "USER_CANCELED",
                    message: "User canceled event creation",
                    details: nil
                )))
                
            default:
                self.completion?(.failure(PigeonError(
                    code: "GENERIC_ERROR",
                    message: "Unknown action from event edit controller",
                    details: nil
                )))
            }
            
            self.completion = nil
        }
    }
}
