//
//  TealiumLifecycleLegacyData.swift
//  tealium-swift
//
//  Created by Craig Rouse on 19/08/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

// This will be removed in a future release. Only included to allow migration from legacy NSKeyedArchiver implementation
public class TealiumLifecycleLegacy: NSObject, NSCoding, Encodable {

    var autotracked: String?

    // Counts being tracked as properties instead of processing through
    //  sessions data every time. Also, not all sessions records will be kept
    //  to prevent memory bloat.
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
    var sessions = [TealiumLifecycleLegacySession]() {
        didSet {
            // Limit size of sessions records
            if sessions.count > sessionsSize &&
                sessionsSize > 1 {
                sessions.remove(at: 1)
            }
        }
    }

    /// Constructor. Should only be called at first init after install.
    ///￼
    /// - Parameter date: Date that the object should be created for.
    override init() {
        self.countLaunch = 0
        self.countWake = 0
        self.countSleep = 0
        self.countCrashTotal = 0
        self.countLaunchTotal = 0
        self.countWakeTotal = 0
        self.countSleepTotal = 0
        self.sessionsSize = 100
        self.totalSecondsAwake = 0
        super.init()
    }

    // MARK: PERSISTENCE SUPPORT
    required public init?(coder: NSCoder) {
        self.countLaunch = coder.decodeInteger(forKey: TealiumLifecycleKey.launchCount)
        self.countSleep = coder.decodeInteger(forKey: TealiumLifecycleKey.sleepCount)
        self.countWake = coder.decodeInteger(forKey: TealiumLifecycleKey.wakeCount)
        self.countCrashTotal = coder.decodeInteger(forKey: TealiumLifecycleKey.totalCrashCount)
        self.countLaunchTotal = coder.decodeInteger(forKey: TealiumLifecycleKey.totalLaunchCount)
        self.countSleepTotal = coder.decodeInteger(forKey: TealiumLifecycleKey.totalSleepCount)
        self.countWakeTotal = coder.decodeInteger(forKey: TealiumLifecycleKey.totalWakeCount)
        self.dateLastUpdate = coder.decodeObject(forKey: TealiumLifecycleKey.lastUpdateDate) as? Date
        if let savedSessions = coder.decodeObject(forKey: TealiumLifecycleCodingKey.sessions) as? [TealiumLifecycleLegacySession] {
            self.sessions = savedSessions
        }
        self.sessionsSize = coder.decodeInteger(forKey: TealiumLifecycleCodingKey.sessionsSize)
        self.totalSecondsAwake = coder.decodeInteger(forKey: TealiumLifecycleCodingKey.totalSecondsAwake)
    }

    public func encode(with: NSCoder) {
        with.encode(self.countLaunch, forKey: TealiumLifecycleKey.launchCount)
        with.encode(self.countSleep, forKey: TealiumLifecycleKey.sleepCount)
        with.encode(self.countWake, forKey: TealiumLifecycleKey.wakeCount)
        with.encode(self.countCrashTotal, forKey: TealiumLifecycleKey.totalCrashCount)
        with.encode(self.countLaunchTotal, forKey: TealiumLifecycleKey.totalLaunchCount)
        with.encode(self.countLaunchTotal, forKey: TealiumLifecycleKey.totalSleepCount)
        with.encode(self.countLaunchTotal, forKey: TealiumLifecycleKey.totalWakeCount)
        with.encode(self.dateLastUpdate, forKey: TealiumLifecycleKey.lastUpdateDate)
        with.encode(self.sessions, forKey: TealiumLifecycleCodingKey.sessions)
        with.encode(self.sessionsSize)
        with.encode(self.totalSecondsAwake, forKey: TealiumLifecycleCodingKey.totalSecondsAwake)
    }

}

// Represents a serializable block of time between a given wake and a sleep
public class TealiumLifecycleLegacySession: NSObject, NSCoding, Encodable {

        var appVersion: String = TealiumLifecycleSession.getCurrentAppVersion()
        var wakeDate: Date?
        var sleepDate: Date? {
            didSet {
                guard let wake = wakeDate else {
                    return
                }
                guard let sleep = sleepDate else {
                    return
                }
                let milliseconds = sleep.timeIntervalSince(wake)
                secondsElapsed = Int(milliseconds)
            }
        }
        var secondsElapsed: Int = 0
        var wasLaunch = false

        init(withLaunchDate: Date) {
            self.wakeDate = withLaunchDate
            self.wasLaunch = true
            super.init()
        }

        init(withWakeDate: Date) {
            self.wakeDate = withWakeDate
            super.init()
        }

        public required init?(coder aDecoder: NSCoder) {
            self.wakeDate = aDecoder.decodeObject(forKey: TealiumLifecycleSessionKey.wakeDate) as? Date
            self.sleepDate = aDecoder.decodeObject(forKey: TealiumLifecycleSessionKey.sleepDate) as? Date
            self.secondsElapsed = aDecoder.decodeInteger(forKey: TealiumLifecycleSessionKey.secondsElapsed) as Int
            self.wasLaunch = aDecoder.decodeBool(forKey: TealiumLifecycleSessionKey.wasLaunch) as Bool
        }

        public func encode(with aCoder: NSCoder) {
            aCoder.encode(self.wakeDate, forKey: TealiumLifecycleSessionKey.wakeDate)
            aCoder.encode(self.sleepDate, forKey: TealiumLifecycleSessionKey.sleepDate)
            aCoder.encode(self.secondsElapsed, forKey: TealiumLifecycleSessionKey.secondsElapsed)
            aCoder.encode(self.wasLaunch, forKey: TealiumLifecycleSessionKey.wasLaunch)
        }
}
