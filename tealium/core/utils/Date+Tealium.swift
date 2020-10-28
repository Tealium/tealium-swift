//
//  Date+Tealium.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public extension Date {

    fileprivate struct Formatter {
        static let iso8601: DateFormatter = {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            return formatter
        }()
        static let extendedIso8601: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(abbreviation: "GMT")
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
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

    var extendedIso8601String: String {
        return Formatter.extendedIso8601.string(from: self).appending("Z")
    }

    var iso8601LocalString: String {
        return Formatter.iso8601Local.string(from: self)
    }

    var mmDDYYYYString: String {
        return Formatter.MMDDYYYY.string(from: self)
    }

    var unixTimeMilliseconds: String {
        // must be forced to Int64 to avoid overflow on watchOS (32 bit)
        let time = Int64(self.timeIntervalSince1970 * 1000)

        return String(describing: time)
    }

    var unixTimeSeconds: String {
        // must be forced to Int64 to avoid overflow on watchOS (32 bit)
        let time = Int64(self.timeIntervalSince1970)

        return String(describing: time)
    }

    var httpIfModifiedHeader: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E, dd MMM YYYY HH:mm:ss"
        return "\(dateFormatter.string(from: self)) GMT"
    }

    func millisecondsFrom(earlierDate: Date) -> Int64 {
        return Int64(self.timeIntervalSince(earlierDate) * 1000)
    }

    func addSeconds(_ seconds: Double?) -> Date? {
        guard let seconds = seconds else {
            return nil
        }
        guard let timeInterval = TimeInterval(exactly: seconds) else {
            return nil
        }
        return addingTimeInterval(timeInterval)
    }

    func addMinutes(_ mins: Double?) -> Date? {
        guard let mins = mins else {
            return nil
        }
        let seconds = mins * 60
        guard let timeInterval = TimeInterval(exactly: seconds) else {
            return nil
        }
        return addingTimeInterval(timeInterval)
    }

}
