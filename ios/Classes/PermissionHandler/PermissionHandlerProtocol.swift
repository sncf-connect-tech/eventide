//
//  PermissionHandlerProtocol.swift
//  easy_calendar
//
//  Created by CHOUPAULT Alexis on 23/01/2025.
//

import Foundation

protocol PermissionHandlerProtocol {
    func checkCalendarAccessThenExecute(
        _ permissionsGrantedCallback: @escaping () -> Void,
        onPermissionRefused permissionsRefusedCallback: @escaping () -> Void,
        onPermissionError errorCallback: @escaping (any Error) -> Void
    )
}
