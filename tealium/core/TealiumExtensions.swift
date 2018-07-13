//
//  TealiumExtensions.swift
//  tealium-swift
//
//  Created by Jason Koo on 11/1/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

/**
     General Extensions that may be used by multiple objects.
*/
import Foundation

/**
 Extend boolvalue NSString function to Swift strings.
 */
extension String {
    var boolValue: Bool {
        return NSString(string: self).boolValue
    }
}

extension Dictionary where Key == String, Value == Any {

    mutating func safelyAdd(key: String, value: Any?) {
        if let value = value {
            self += [key: value]
        }
    }

}

/**
 Allows use of plus operator for array reduction calls.
 */
private func +<Key, Value> (lhs: [Key: Value], rhs: [Key: Value]) -> [Key: Value] {
    var result = lhs
    rhs.forEach { result[$0] = $1 }
    return result
}

extension Date {

    struct Formatter {
        static let iso8601: DateFormatter = {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            return formatter
        }()
        static let MMDDYYYY: DateFormatter = {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "MM/dd/yyyy"
            return formatter
        }()
        static let iso8601Local: DateFormatter = {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: TimeZone.current.secondsFromGMT())
            // note that local time should NOT have a 'Z' after it, as the 'Z' indicates UTC (zero meridian)
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'"
            return formatter
        }()
    }

    var iso8601String: String {
        return Formatter.iso8601.string(from: self)
    }

    var iso8601LocalString: String {
        return Formatter.iso8601Local.string(from: self)
    }

    var mmDDYYYYString: String {
        return Formatter.MMDDYYYY.string(from: self)
    }

    var unixTime: String {
        // must be forced to Int64 to avoid overflow on watchOS (32 bit)
        let time = Int64(self.timeIntervalSince1970 * 1000)

        return String(describing: time)
    }

}
