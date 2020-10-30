//
//  LifecycleConstants.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if lifecycle
import TealiumCore
#endif

public enum LifecycleKey {

    static let moduleName = "lifecycle"
    static let migratedLifecycle = "migrated_lifecycle"
    static let defaultSessionsSize = 20
    static let autotracked = "autotracked"
    static let dayOfWeek = "lifecycle_dayofweek_local"
    static let daysSinceFirstLaunch = "lifecycle_dayssincelaunch"
    static let daysSinceLastUpdate = "lifecycle_dayssinceupdate"
    static let daysSinceLastWake = "lifecycle_dayssincelastwake"
    static let didDetectCrash = "lifecycle_diddetectcrash"
    static let firstLaunchDate = "lifecycle_firstlaunchdate"
    static let firstLaunchDateMMDDYYYY = "lifecycle_firstlaunchdate_MMDDYYYY"
    static let hourOfDayLocal = "lifecycle_hourofday_local"
    static let isFirstLaunch = "lifecycle_isfirstlaunch"
    static let isFirstLaunchUpdate = "lifecycle_isfirstlaunchupdate"
    static let isFirstWakeThisMonth = "lifecycle_isfirstwakemonth"
    static let isFirstWakeToday = "lifecycle_isfirstwaketoday"
    static let lastLaunchDate = "lifecycle_lastlaunchdate"
    static let lastSleepDate = "lifecycle_lastsleepdate"
    static let lastWakeDate = "lifecycle_lastwakedate"
    static let lastUpdateDate = "lifecycle_lastupdatedate"
    static let launchCount = "lifecycle_launchcount"
    static let priorSecondsAwake = "lifecycle_priorsecondsawake"
    static let secondsAwake = "lifecycle_secondsawake"
    static let sleepCount = "lifecycle_sleepcount"
    static let type = "lifecycle_type"
    static let totalCrashCount = "lifecycle_totalcrashcount"
    static let totalLaunchCount = "lifecycle_totallaunchcount"
    static let totalWakeCount = "lifecycle_totalwakecount"
    static let totalSleepCount = "lifecycle_totalsleepcount"
    static let totalSecondsAwake = "lifecycle_totalsecondsawake"
    static let updateLaunchDate = "lifecycle_updatelaunchdate"
    static let wakeCount = "lifecycle_wakecount"

    enum Session {
        static let wakeDate = "wake"
        static let sleepDate = "sleep"
        static let secondsElapsed = "seconds"
        static let wasLaunch = "wasLaunch"
        static let sessionFirst = "first"
        static let sessions = "sessions"
        static let sessionsSize = "session_size"
        static let totalSecondsAwake = "totalSecondsAwake"
    }

}

public enum LifecycleType {
    case launch, sleep, wake

    public var description: String {
        switch self {
        case .launch:
            return "launch"
        case .sleep:
            return "sleep"
        case .wake:
            return "wake"
        }
    }
}
