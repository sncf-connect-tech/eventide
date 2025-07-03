//
//  PermissionHandlerProtocol.swift
//  eventide
//
//  Created by CHOUPAULT Alexis on 23/01/2025.
//

import Foundation

enum AccessLevel {
    case writeOnly
    case fullAccess
}

protocol PermissionHandlerProtocol {
    func checkCalendarAccessThenExecute(
        _ accessLevel: AccessLevel,
        onPermissionGranted permissionsGrantedCallback: @escaping () -> Void,
        onPermissionRefused permissionsRefusedCallback: @escaping () -> Void,
        onPermissionError errorCallback: @escaping (any Error) -> Void
    )
}
