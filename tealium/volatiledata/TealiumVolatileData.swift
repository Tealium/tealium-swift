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

    /// Add data to all dispatches for the remainder of an active session.
    ///
    /// - Parameter data: `[String: Any]`. Values should be of type `String` or `[String]`
    public func add(data: [String: Any]) {
        TealiumQueues.backgroundConcurrentQueue.write {
            self.volatileData += data
        }
    }

    /// Public convenience function to retrieve a copy of volatile data used with dispatches.
    ///
    /// - Returns: `[String: Any]`
    public func getData() -> [String: Any] {
        TealiumQueues.backgroundConcurrentQueue.read {
            return getData(currentData: [String: Any]())
        }
    }

    /// Retrieve a copy of volatile data used with dispatches.
    ///
    /// - Parameter currentData: `[String: Any]` containing existing volatile data
    /// - Returns: `[String: Any]`
    func getData(currentData: [String: Any]) -> [String: Any] {
        TealiumQueues.backgroundConcurrentQueue.read {
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
    }

    /// Checks that the dispatch contains all expected timestamps.
    ///
    /// - Parameter currentData: `[String: Any]` containing existing volatile data
    /// - Returns: `Bool` `true` if dispatch contains existing timestamps
    func dispatchHasExistingTimestamps(_ currentData: [String: Any]) -> Bool {
        TealiumQueues.backgroundConcurrentQueue.read {
        return (currentData[TealiumVolatileDataKey.timestampEpoch] != nil) &&
                (currentData[TealiumVolatileDataKey.timestamp] != nil) &&
                (currentData[TealiumVolatileDataKey.timestampLocal] != nil) &&
                (currentData[TealiumVolatileDataKey.timestampOffset] != nil) &&
                (currentData[TealiumVolatileDataKey.timestampUnix] != nil)
        }
    }

    /// Deletes volatile data for specific keys.
    ///
    /// - Parameter keys: `[String]` to remove from the internal volatile data store.
    public func deleteData(forKeys keys: [String]) {
        TealiumQueues.backgroundConcurrentQueue.write {
            keys.forEach {
                self.volatileData.removeValue(forKey: $0)
            }
        }
    }

    /// Deletes all volatile data.
    public func deleteAllData() {
        TealiumQueues.backgroundConcurrentQueue.write {
            self.volatileData.forEach {
                self.volatileData.removeValue(forKey: $0.key)
            }
        }
    }

    /// Immediately resets the session ID.
    public func resetSessionId() {
        add(data: [TealiumKey.sessionId: TealiumVolatileData.newSessionId() ])
    }

    /// Manually set session id to a specified string.
    ///￼
    /// - Parameter sessionId: `String` id to set session id to.
    public func setSessionId(sessionId: String) {
        add(data: [TealiumKey.sessionId: sessionId])
    }

    // MARK: INTERNAL

    /// Generates a random number of a specific length.
    ///
    /// - Parameter length: `Int` - the length of the random number
    /// - Returns: `String` containing a random integer of the specified length
    class func getRandom(length: Int) -> String {
        var randomNumber: String = ""

        for _ in 1...length {
            let random = Int(arc4random_uniform(10))
            randomNumber += String(random)
        }

        return randomNumber
    }

    /// - Parameter date: `Date`
    /// - Returns: `String` containing the timestamp in seconds from the `Date` object passed in
    public class func getTimestampInSeconds(_ date: Date) -> String {
        let timestamp = date.timeIntervalSince1970

        return "\(Int(timestamp))"
    }

    /// - Parameter date: `Date`
    /// - Returns: `String` containing the timestamp in milliseconds from the `Date` object passed in
    class func getTimestampInMilliseconds(_ date: Date) -> String {
        let timestamp = date.unixTimeMilliseconds

        return timestamp
    }

    /// - Returns: `String` containing a new session ID
    class func newSessionId() -> String {
        return getTimestampInMilliseconds(Date())
    }

    /// - Returns: `Bool` `true` if the session ID should be updated (session has expired)
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

    /// - Returns: `[String: Any]` containing all current timestamps in volatile data
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
            TealiumVolatileDataKey.timestampUnixMilliseconds: date.unixTimeMilliseconds,
            TealiumVolatileDataKey.timestampUnixMillisecondsLegacy: date.unixTimeMilliseconds, // included to prevent mapping issues. Will be removed in future release
            TealiumVolatileDataKey.timestampUnix: date.unixTimeSeconds,
            TealiumVolatileDataKey.timestampUnixLegacy: date.unixTimeSeconds, // included to prevent mapping issues. Will be removed in future release
        ]
    }

    /// - Parameter date: `Date`
    /// - Returns: `String` containing ISO8601 date in local timezone
    class func getDate8601Local(_ date: Date) -> String {
        return date.iso8601LocalString
    }

    /// - Parameter date: `Date`
    /// - Returns: `String` containing ISO8601 date in UTC time
    class func getDate8601UTC(_ date: Date) -> String {
        return date.iso8601String
    }

    /// - Returns: `String` containing the offset from UTC in hours
    func timezoneOffset() -> String {
        let timezone = TimeZone.current
        let offsetSeconds = timezone.secondsFromGMT()
        let offsetHours = offsetSeconds / 3600

        return String(format: "%i", offsetHours)
    }
}
