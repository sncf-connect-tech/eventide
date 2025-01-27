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
        noAccess permissionsRefusedCallback: @escaping () -> Void,
        error errorCallback: @escaping (any Error) -> Void
    )
}
