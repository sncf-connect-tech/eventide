//
//  Utils.swift
//  easy_calendar
//
//  Created by CHOUPAULT Alexis on 31/12/2024.
//

import Foundation
import EventKit

extension Date {
    var millisecondsSince1970: Int64 {
        Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }
    
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
