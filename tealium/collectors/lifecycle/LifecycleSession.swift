//
//  TealiumLifecycleSession.swift
//  tealium-swift
//
//  Created by Craig Rouse on 05/07/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

// Represents a serializable block of time between a given wake and a sleep
public struct LifecycleSession: Codable, Equatable {

    var appVersion: String = LifecycleSession.currentAppVersion
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

    init(launchDate: Date) {
        self.wakeDate = launchDate
        self.wasLaunch = true
    }

    init(wakeDate: Date) {
        self.wakeDate = wakeDate
    }

    public init?(coder aDecoder: NSCoder) {
        self.wakeDate = aDecoder.decodeObject(forKey: LifecycleKey.Session.wakeDate) as? Date
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
