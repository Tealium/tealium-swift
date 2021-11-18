//
//  LifecycleSession.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

#if lifecycle
import TealiumCore
#endif

// Represents a serializable block of time between a given wake and a sleep
public struct LifecycleSession: Codable, Equatable {

    var appVersion: String = LifecycleSession.currentAppVersion
    var firstLaunchDate: Date?
    let wakeDate: Date
    var sleepDate: Date? {
        didSet {
            guard let sleep = sleepDate else {
                return
            }
            let milliseconds = sleep.timeIntervalSince(wakeDate)
            secondsElapsed = Int(milliseconds)
        }
    }
    var secondsElapsed: Int = 0
    var wasLaunch = false

    init(launchDate: Date) {
        self.wakeDate = launchDate
        self.wasLaunch = true
    }

    init(wakeDate: Date) {
        self.wakeDate = wakeDate
    }

    init?(from dictionary: [String: Any]) {
        guard let stringWake = dictionary[TealiumDataKey.lastWakeDate] as? String,
              let wakeDate = stringWake.dateFromISOStringShort else {
            return nil
        }
        self.wakeDate = wakeDate
        if let stringFirstLaunch = dictionary[TealiumDataKey.firstLaunchDate] as? String,
           let firstLaunchDate = stringFirstLaunch.dateFromISOStringShort {
            self.firstLaunchDate = firstLaunchDate
        }
        if let stringSleep = dictionary[TealiumDataKey.lastSleepDate] as? String,
           let sleepDate = stringSleep.dateFromISOStringShort {
            self.sleepDate = sleepDate
        }
        self.wasLaunch = true
    }

    public init?(coder aDecoder: NSCoder) {
        guard let wakeDate = aDecoder.decodeObject(forKey: LifecycleKey.Session.wakeDate) as? Date else {
            return nil
        }
        self.wakeDate = wakeDate
        self.sleepDate = aDecoder.decodeObject(forKey: LifecycleKey.Session.sleepDate) as? Date
        self.secondsElapsed = aDecoder.decodeInteger(forKey: LifecycleKey.Session.secondsElapsed) as Int
        self.wasLaunch = aDecoder.decodeBool(forKey: LifecycleKey.Session.wasLaunch) as Bool
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.wakeDate, forKey: LifecycleKey.Session.wakeDate)
        aCoder.encode(self.sleepDate, forKey: LifecycleKey.Session.sleepDate)
        aCoder.encode(self.secondsElapsed, forKey: LifecycleKey.Session.secondsElapsed)
        aCoder.encode(self.wasLaunch, forKey: LifecycleKey.Session.wasLaunch)
    }

    static var currentAppVersion: String {
        return Bundle.main.version ?? "(unknown)"
    }

    public static func == (lhs: LifecycleSession, rhs: LifecycleSession ) -> Bool {
        if lhs.wakeDate != rhs.wakeDate { return false }
        if lhs.sleepDate != rhs.sleepDate { return false }
        if lhs.secondsElapsed != rhs.secondsElapsed { return false }
        if lhs.wasLaunch != rhs.wasLaunch { return false }
        return true
    }
}
