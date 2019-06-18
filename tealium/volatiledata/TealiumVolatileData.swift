//
//  TealiumVolatileData.swift
//  tealium-swift
//
//  Created by Jonathan Wong on 1/10/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation
#if volatiledata
import TealiumCore
#endif
public protocol TealiumVolatileDataCollection {
    func currentTimeStamps() -> [String: Any]
}

public class TealiumVolatileData: NSObject, TealiumVolatileDataCollection {

    fileprivate var volatileData = [String: Any]()
    public var minutesBetweenSessionIdentifier: TimeInterval = 30.0
    var lastTrackEvent: Date?

    func sync(lock: NSObject, closure: () -> Void) {
        objc_sync_enter(lock)
        closure()
        objc_sync_exit(lock)
    }

    /// Add data to all dispatches for the remainder of an active session.
    ///
    /// - Parameters:
    /// - data: A [String: Any] dictionary. Values should be of type String or [String]
    public func add(data: [String: Any]) {
        sync(lock: self) {
            volatileData += data
        }
    }

    /// Public convenience function to retrieve a copy of volatile data used with dispatches.
    ///
    /// - Returns: A dictionary
    public func getData() -> [String: Any] {
        return getData(currentData: [String: Any]())
    }

    /// Retrieve a copy of volatile data used with dispatches.
    ///
    /// - Returns: A dictionary
    func getData(currentData: [String: Any]) -> [String: Any] {
        var data = [String: Any]()

        data[TealiumVolatileDataKey.random] = TealiumVolatileData.getRandom(length: 16)
        if !dispatchHasExistingTimestamps(currentData) {
            data.merge(currentTimeStamps()) { _, new -> Any in
                new
            }
            data[TealiumVolatileDataKey.timestampOffset] = timezoneOffset()
            data[TealiumVolatileDataKey.timestampOffsetLegacy] = timezoneOffset()
        }
        data += volatileData

        return data
    }

    /// - Returns: `true` if dispatch contains existing timestamps
    func dispatchHasExistingTimestamps(_ currentData: [String: Any]) -> Bool {
        return (currentData[TealiumVolatileDataKey.timestampEpoch] != nil) &&
                (currentData[TealiumVolatileDataKey.timestamp] != nil) &&
                (currentData[TealiumVolatileDataKey.timestampLocal] != nil) &&
                (currentData[TealiumVolatileDataKey.timestampOffset] != nil) &&
                (currentData[TealiumVolatileDataKey.timestampUnix] != nil)
    }

    /// Delete volatile data.
    ///
    /// - Parameters:
    /// - keys: An array of String keys to remove from the internal volatile data store.
    public func deleteData(forKeys: [String]) {
        sync(lock: self) {
            for key in forKeys {
                volatileData.removeValue(forKey: key)
            }
        }
    }

    /// Delete all volatile data.
    public func deleteAllData() {
        sync(lock: self) {
            for key in volatileData.keys {
                volatileData.removeValue(forKey: key)
            }
        }
    }

    /// Auto reset the session id now.
    public func resetSessionId() {
        add(data: [TealiumVolatileDataKey.sessionId: TealiumVolatileData.newSessionId() ])
    }

    /// Manually set session id to a specified string
    ///
    /// - Parameter sessionId: String id to set session id to.
    public func setSessionId(sessionId: String) {
        add(data: [TealiumVolatileDataKey.sessionId: sessionId])
    }

    // MARK: INTERNAL

    class func getRandom(length: Int) -> String {
        var randomNumber: String = ""

        for _ in 1...length {
            let random = Int(arc4random_uniform(10))
            randomNumber += String(random)
        }

        return randomNumber
    }

    public class func getTimestampInSeconds(_ date: Date) -> String {
        let timestamp = date.timeIntervalSince1970

        return "\(Int(timestamp))"
    }

    class func getTimestampInMilliseconds(_ date: Date) -> String {
        let timestamp = date.unixTime

        return timestamp
    }

    class func newSessionId() -> String {
        return getTimestampInMilliseconds(Date())
    }

    func shouldRefreshSessionIdentifier() -> Bool {
        guard let lastTrackEvent = lastTrackEvent else {
            return true
        }

        let timeDifference = lastTrackEvent.timeIntervalSinceNow
        if abs(timeDifference) > minutesBetweenSessionIdentifier * 60 {
            return true
        }

        return false
    }

    public func currentTimeStamps() -> [String: Any] {
        // having this in a single function guarantees we're sending the exact same timestamp,
        // as the date object only gets created once
        let date = Date()
        return [
            TealiumVolatileDataKey.timestampEpoch: TealiumVolatileData.getTimestampInSeconds(date),
            TealiumVolatileDataKey.timestamp: TealiumVolatileData.getDate8601UTC(date),
            TealiumVolatileDataKey.timestampLegacy: TealiumVolatileData.getDate8601UTC(date), // included to prevent mapping issues. Will be removed in future release
            TealiumVolatileDataKey.timestampLocal: TealiumVolatileData.getDate8601Local(date),
            TealiumVolatileDataKey.timestampLocalLegacy: TealiumVolatileData.getDate8601Local(date), // included to prevent mapping issues. Will be removed in future release
            TealiumVolatileDataKey.timestampUnixMilliseconds: date.unixTime,
            TealiumVolatileDataKey.timestampUnixMillisecondsLegacy: date.unixTime, // included to prevent mapping issues. Will be removed in future release
            TealiumVolatileDataKey.timestampUnix: date.unixTimeSeconds,
            TealiumVolatileDataKey.timestampUnixLegacy: date.unixTimeSeconds, // included to prevent mapping issues. Will be removed in future release
        ]
    }

    class func getDate8601Local(_ date: Date) -> String {
        return date.iso8601LocalString
    }

    class func getDate8601UTC(_ date: Date) -> String {
        return date.iso8601String
    }

    func timezoneOffset() -> String {
        let timezone = TimeZone.current
        let offsetSeconds = timezone.secondsFromGMT()
        let offsetHours = offsetSeconds / 3600

        return String(format: "%i", offsetHours)
    }
}
