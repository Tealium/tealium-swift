//
//  Lifecycle.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

// swiftlint:disable type_body_length
// swiftlint:disable file_length
public struct Lifecycle: Codable {

    var autotracked: String?

    // Cache of session properties to avoid iterating sessions for each event
    var countLaunch: Int
    var countSleep: Int
    var countWake: Int
    var countCrashTotal: Int
    var countLaunchTotal: Int
    var countSleepTotal: Int
    var countWakeTotal: Int
    var dateLastUpdate: Date?
    var totalSecondsAwake: Int
    var sessionsSize: Int
    var sessions = [LifecycleSession]() {
        didSet {
            // Limit size of sessions records
            while sessions.count > sessionsSize &&
                    sessionsSize > 1 {
                sessions.remove(at: 1)
            }
        }
    }

    /// Constructor. Should only be called at first init after install.
    init() {
        countLaunch = 0
        countWake = 0
        countSleep = 0
        countCrashTotal = 0
        countLaunchTotal = 0
        countWakeTotal = 0
        countSleepTotal = 0
        sessionsSize = LifecycleKey.defaultSessionsSize
        totalSecondsAwake = 0
    }

    /// Used when migrating data from Objective-C library
    public init(from dictionary: [String: Any]) {
        countLaunch = dictionary[LifecycleKey.launchCount] as? Int ?? 0
        countWake = dictionary[LifecycleKey.wakeCount] as? Int ?? 0
        countSleep = dictionary[LifecycleKey.sleepCount] as? Int ?? 0
        countCrashTotal = dictionary[LifecycleKey.totalCrashCount] as? Int ?? 0
        countLaunchTotal = dictionary[LifecycleKey.totalLaunchCount] as? Int ?? 0
        countWakeTotal = dictionary[LifecycleKey.totalWakeCount] as? Int ?? 0
        countSleepTotal = dictionary[LifecycleKey.totalSleepCount] as? Int ?? 0
        dateLastUpdate = Date()
        totalSecondsAwake = dictionary[LifecycleKey.totalSecondsAwake] as? Int ?? 0
        sessionsSize = LifecycleKey.defaultSessionsSize
        sessions = [LifecycleSession(from: dictionary)]
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.countLaunch = try values.decode(Int.self, forKey: .countLaunch)
        self.countSleep = try values.decode(Int.self, forKey: .countSleep)
        self.countWake = try values.decode(Int.self, forKey: .countWake)
        self.countCrashTotal = try values.decode(Int.self, forKey: .countCrashTotal)
        self.countLaunchTotal = try values.decode(Int.self, forKey: .countLaunchTotal)
        self.countSleepTotal = try values.decode(Int.self, forKey: .countSleepTotal)
        self.countWakeTotal = try values.decode(Int.self, forKey: .countWakeTotal)
        self.dateLastUpdate = try values.decodeIfPresent(Date.self, forKey: .dateLastUpdate)
        self.totalSecondsAwake = try values.decode(Int.self, forKey: .totalSecondsAwake)
        self.sessions = try values.decode([LifecycleSession].self, forKey: .sessions)
        self.sessionsSize = LifecycleKey.defaultSessionsSize
    }

    /// - Returns: `String?` `true` if crash was detected (new launch with no previous sleep event)
    var crashDetected: String? {
        // Still in first session, can't have crashed yet
        if sessions.last == sessions.first {
            return nil
        }
        if sessions.beforeLast?.secondsElapsed != 0 {
            return nil
        }

        // No sleep recorded in session before current
        return "true"
    }

    /// - Returns: `Bool` `true` if this is the first launch
    var firstLaunch: Bool {
        return countLaunchTotal == 1 &&
            countWakeTotal == 1 &&
            countSleepTotal == 0
    }

    /// Check if we're launching for first time after an app version update.
    ///
    /// - Returns: `Bool` `true` if this is the first launch after an app version update.
    var firstLaunchAfterUpdate: Bool {
        let prior = sessions.beforeLast
        let current = sessions.last

        return prior?.appVersion != current?.appVersion
    }

    /// - Returns: `Bool` `true` if this is the first wake this month
    var firstWakeThisMonth: Bool {
        // Wakes array has only 1 date - return true
        guard sessions.count >= 2 else {
            return true
        }

        // Two wake dates on record, if different - return true
        let earlierWake = (sessions.beforeLast?.wakeDate)!
        let laterWake = (sessions.last?.wakeDate)!
        let earlier = Calendar.autoupdatingCurrent.component(.month, from: earlierWake)
        let later = Calendar.autoupdatingCurrent.component(.month, from: laterWake)

        return laterWake > earlierWake &&
            later != earlier
    }

    /// - Returns: `Bool` `true` if this is the first wake today
    var firstWakeToday: Bool {
        // Wakes array has only 1 date - return true
        guard sessions.count >= 2 else {
            return true
        }

        // Two wake dates on record, if different - return true
        let earlierWake = (sessions.beforeLast?.wakeDate)!
        let laterWake = (sessions.last?.wakeDate)!
        let earlierDay = Calendar.autoupdatingCurrent.component(.day, from: earlierWake)
        let laterDay = Calendar.autoupdatingCurrent.component(.day, from: laterWake)

        return  laterWake > earlierWake &&
            laterDay != earlierDay
    }

    /// Seconds app was awake since last launch. Available only during launch calls.
    ///
    /// - Returns: `String?` of Int Seconds elapsed
    var priorSecondsAwake: String? {
        var secondsAggregate = 0
        var count = sessions.count - 1
        if count < 0 { count = 0 }

        for itr in (0..<count) {
            let session = sessions[itr]
            if session.wasLaunch {
                secondsAggregate = 0
            }
            secondsAggregate += session.secondsElapsed
        }
        return String(describing: secondsAggregate)
    }

    /// Returns a copy of the current lifecycle data as a dictionary.
    ///
    /// - Parameters:
    ///     - type: `String` containing the lifecycle type to be tracked
    ///     - date: `Date` for the lifecycle event
    /// - Returns: `[String: Any]` of lifecycle data
    public func asDictionary(type: String?,
                             for date: Date) -> [String: Any] {
        var dict = [String: Any]()

        let firstSession = sessions.first

        dict[LifecycleKey.autotracked] = autotracked
        if type == "launch" {
            dict[LifecycleKey.didDetectCrash] = crashDetected
            if firstLaunch {
                dict[LifecycleKey.isFirstLaunch] = "true"
            }
        }
        dict[LifecycleKey.dayOfWeek] = dayOfWeekLocal(for: date)
        dict[LifecycleKey.daysSinceFirstLaunch] = daysFrom(earlierDate: firstSession?.wakeDate, laterDate: date)
        dict[LifecycleKey.daysSinceLastUpdate] = daysFrom(earlierDate: dateLastUpdate, laterDate: date)
        dict[LifecycleKey.daysSinceLastWake] = daysSinceLastWake(type: type, toDate: date)
        dict[LifecycleKey.firstLaunchDate] = firstSession?.firstLaunchDate?.iso8601String ?? firstSession?.wakeDate?.iso8601String
        dict[LifecycleKey.firstLaunchDateMMDDYYYY] = firstSession?.wakeDate?.mmDDYYYYString
        dict[LifecycleKey.hourOfDayLocal] = hourOfDayLocal(for: date)

        if firstLaunchAfterUpdate {
            dict[LifecycleKey.isFirstLaunchUpdate] = "true"
        }
        if firstWakeThisMonth {
            dict[LifecycleKey.isFirstWakeThisMonth] = "true"
        }
        if firstWakeToday {
            dict[LifecycleKey.isFirstWakeToday] = true
        }
        dict[LifecycleKey.lastLaunchDate] = lastLaunchDate(type: type)?.iso8601String
        dict[LifecycleKey.lastWakeDate] = lastWakeDate(type: type)?.iso8601String
        dict[LifecycleKey.lastSleepDate] = lastSleepDate()?.iso8601String
        dict[LifecycleKey.launchCount] = String(countLaunch)
        dict[LifecycleKey.priorSecondsAwake] = priorSecondsAwake
        dict[LifecycleKey.secondsAwake] = secondsAwake(to: date)
        dict[LifecycleKey.sleepCount] = String(countSleep)
        dict[LifecycleKey.type] = type
        dict[LifecycleKey.totalCrashCount] = String(countCrashTotal)
        dict[LifecycleKey.totalLaunchCount] = String(countLaunchTotal)
        dict[LifecycleKey.totalSleepCount] = String(countSleepTotal)
        dict[LifecycleKey.totalWakeCount] = String(countWakeTotal)
        dict[LifecycleKey.totalSecondsAwake] = String(totalSecondsAwake)
        dict[LifecycleKey.wakeCount] = String(countWake)

        if dateLastUpdate != nil {
            // We've just reset values
            dict[LifecycleKey.updateLaunchDate] = dateLastUpdate?.iso8601String
        }
        return dict
    }

    /// Utility method to count the whole days between 2 dates.
    ///
    /// - Parameters:
    ///     - earlierDate: `Date?`
    ///     - laterDate: `Date`
    /// - Returns: `String?` containing the number of days between the 2 dates
    func daysFrom(earlierDate: Date?, laterDate: Date) -> String? {
        guard let earlierDate = earlierDate else {
            return nil
        }
        let components = Calendar.autoupdatingCurrent.dateComponents([.second], from: earlierDate, to: laterDate)

        // NOTE: This is not entirely accurate as it does not adjust for Daylight Savings -
        //  however this matches up with implementation in Android, and is off by one day after about 172
        //  days have elapsed
        let days = components.second! / (60 * 60 * 24)
        return String(days)
    }

    /// - Returns: `String` containing the day of the week
    func dayOfWeekLocal(for date: Date) -> String {
        let day = Calendar.autoupdatingCurrent.component(.weekday, from: date)
        return String(day)
    }

    /// Calculates the number of days since the last wake event.
    ///
    /// - Parameters:
    ///     - type: `String?` containing the lifecycle type
    ///     - date: `Date` - the current date for this event
    /// - Returns: `String?` of days since last awake
    func daysSinceLastWake(type: String?,
                           toDate date: Date) -> String? {
        if type == "sleep" {
            let earlierDate = sessions.last!.wakeDate
            return daysFrom(earlierDate: earlierDate, laterDate: date)
        }
        guard let targetSession = sessions.beforeLast else {
            // Shouldn't happen
            return nil
        }
        let earlierDate = targetSession.wakeDate
        return daysFrom(earlierDate: earlierDate, laterDate: date)
    }

    /// - Parameter date: `Date`
    /// - Returns: `String` containing the hour of the day in local timezone
    func hourOfDayLocal(for date: Date) -> String {
        let hour = Calendar.autoupdatingCurrent.component(.hour, from: date)
        return String(hour)
    }

    /// - Parameter type: `String` containing the current lifecycle type
    /// - Returns: `Date?` containing the last launch date
    func lastLaunchDate(type: String?) -> Date? {
        guard let lastSession = sessions.last else {
            return nil
        }

        if type == LifecycleType.sleep.description &&
            lastSession.wasLaunch == true {
            return lastSession.wakeDate
        }
        for itr in (0..<(sessions.count - 1)).reversed() {
            let session = sessions[itr]
            if session.wasLaunch == true {
                return session.wakeDate
            }
        }
        // should never happen
        return sessions.first?.wakeDate
    }

    /// - Returns: `Date?` containing the last sleep date
    func lastSleepDate() -> Date? {
        if sessions.last == sessions.first {
            return nil
        }
        for itr in (0..<(sessions.count - 1)).reversed() {
            let session = sessions[itr]
            if session.sleepDate != nil {
                return session.sleepDate
            }
        }
        return nil
    }

    /// - Parameter type: `String` containing the current lifecycle type
    /// - Returns: `Date?` containing the last wake date
    func lastWakeDate(type: String?) -> Date? {
        guard let lastSession = sessions.last else {
            return nil
        }

        if type == LifecycleType.sleep.description {
            return lastSession.wakeDate
        }
        if sessions.last == sessions.first {
            return lastSession.wakeDate
        }

        guard let beforeLastSession = sessions.beforeLast else {
            return nil
        }
        return beforeLastSession.wakeDate
    }

    /// Trigger a new launch and return data for it.
    ///
    /// - Parameters:
    ///   - date: `Date` to trigger launch from.
    ///   - overrideSession: `LifecycleSession? `override session. Mainly for testing.
    /// - Returns: `[String:Any]` containing lifecycle launch variables
    public mutating func newLaunch(at date: Date,
                                   overrideSession: LifecycleSession?) -> [String: Any] {
        autotracked = "true"
        countLaunch += 1
        countLaunchTotal += 1
        countWake += 1
        countWakeTotal += 1

        let newSession = overrideSession ?? LifecycleSession(launchDate: date)
        sessions.append(newSession)

        if crashDetected == "true" {
            countCrashTotal += 1
        }
        if firstLaunchAfterUpdate {
            resetCountsAfterUpdate(for: date)
        }

        return asDictionary(type: LifecycleType.launch.description,
                            for: date)
    }

    /// Trigger a new sleep and return data for it.
    ///
    /// - Parameters:
    ///   - date: `Date` to trigger sleep from.
    /// - Returns: `[String:Any]` containing lifecycle sleep variables
    public mutating func newSleep(at date: Date) -> [String: Any] {
        autotracked = "true"
        countSleep += 1
        countSleepTotal += 1

        guard var currentSession = sessions.last else {
            // Sleep call somehow made prior to the first launch event
            return [:]
        }

        currentSession.sleepDate = date
        totalSecondsAwake += currentSession.secondsElapsed
        sessions.removeLast()
        sessions.append(currentSession)
        return asDictionary(type: LifecycleType.sleep.description,
                            for: date)
    }

    /// Generates a dictionary of data to add to the tracking call from the current lifecycle data.
    ///
    /// - Parameter date: `Date`for the event
    /// - Returns: `[String: Any]` containing current lifecycle data
    public func newTrack(at date: Date) -> [String: Any] {
        guard sessions.last != nil else {
            // Track request before launch processed
            return [:]
        }

        return asDictionary(type: nil,
                            for: date)
    }

    /// Trigger a new wake and return data for it.
    ///
    /// - Parameters:
    ///   - date: `Date` to trigger wake from.
    ///   - overrideSession: `LifecycleSession?` override session. Mainly for testing.
    /// - Returns: `[String:Any]` containing lifecycle wake variables
    public mutating func newWake(at date: Date, overrideSession: LifecycleSession?) -> [String: Any] {
        autotracked = "true"
        countWake += 1
        countWakeTotal += 1

        let newSession = overrideSession ?? LifecycleSession(wakeDate: date)
        sessions.append(newSession)

        return asDictionary(type: LifecycleType.wake.description,
                            for: date)
    }

    /// - Parameter date: `Date`
    mutating func resetCountsAfterUpdate(for date: Date) {
        countWake = 1
        countLaunch = 1
        countSleep = 0
        dateLastUpdate = date
    }

    /// - Parameter date: `Date` containing the current date
    /// - Returns: `String?` containing the number of seconds the app has been in the foreground
    func secondsAwake(to date: Date) -> String? {
        guard let lastSession = sessions.last else {
            return nil
        }
        let currentWake = lastSession.wakeDate
        return secondsFrom(currentWake, laterDate: date)
    }

    /// Utility method to count the whole seconds between 2 dates.
    ///
    /// - Parameters:
    ///     - earlierDate: `Date?`
    ///     - laterDate: `Date`
    /// - Returns: `String` containing the number of seconds between the 2 dates
    func secondsFrom(_ earlierDate: Date?, laterDate: Date) -> String? {
        guard let earlierDate = earlierDate else {
            return nil
        }

        let milliseconds = laterDate.timeIntervalSince(earlierDate)
        return String(Int(milliseconds))
    }

}
// swiftlint:enable file_length
