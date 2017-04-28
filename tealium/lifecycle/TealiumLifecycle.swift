//
//  TealiumLifecycleData.swift
//
//  Created by Jason Koo on 1/10/17.
//  Copyright © 2017 Apple, Inc. All rights reserved.
//

import Foundation

enum TealiumLifecycleKey {
    static let autotracked = "autotracked"
    static let dayOfWeek = "lifecycle_dayofweek_local"
    static let daysSinceFirstLaunch = "lifecycle_dayssincelaunch"
    static let daysSinceLastUpdate = "lifecycle_dayssinceupdate"
    static let daysSinceLastWake = "lifecycle_dayssincelastwake"
    static let didDetectCrash = "lifecycle_diddetectcrash"
    static let firstLaunchDate = "lifecycle_firstlaunchdate"
    static let firstLaunchDate_MMDDYYYY = "lifecycle_firstlaunchdate_MMDDYYYY"
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
}

enum TealiumLifecycleCodingKey {
    static let sessionFirst = "first"
    static let sessions = "sessions"
    static let sessionsSize = "session_size"
    static let totalSecondsAwake = "totalSecondsAwake"
}

enum TealiumLifecycleType {
    case launch, sleep, wake
    
    var description : String {
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

enum TealiumLifecycleValue {
    static let yes = "true"
}

public class TealiumLifecycle : NSObject, NSCoding {
    
    var autotracked : String?
    
    // Counts being tracked as properties instead of processing through
    //  sessions data every time. Also, not all sessions records will be kept
    //  to prevent memory bloat.
    var countLaunch : Int
    var countSleep : Int
    var countWake : Int
    var countCrashTotal : Int
    var countLaunchTotal: Int
    var countSleepTotal : Int
    var countWakeTotal : Int
    var dateLastUpdate : Date?
    var totalSecondsAwake : Int
    var sessionsSize : Int
    var sessions = [TealiumLifecycleSession]() {
        didSet {
            // Limit size of sessions records
            if sessions.count > sessionsSize &&
                sessionsSize > 1 {
                sessions.remove(at: 1)
            }
        }
    }
    var type : String? = TealiumLifecycleType.launch.description
    
    /// Constructor. Should only be called at first init after install.
    ///
    /// - Parameter date: Date that the object should be created for.
    override init() {
        
        self.countLaunch = 0
        self.countWake = 0
        self.countSleep = 0
        self.countCrashTotal = 0
        self.countLaunchTotal = 0
        self.countWakeTotal = 0
        self.countSleepTotal = 0
        self.sessionsSize = 100     // Need a wide birth to capture wakes, sleeps, and updates
        self.totalSecondsAwake = 0
        super.init()
    }
    
    // MARK:
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
        if let savedSessions = coder.decodeObject(forKey: TealiumLifecycleCodingKey.sessions) as? [TealiumLifecycleSession]{
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
    
    // MARK:
    // MARK: PUBLIC
    
    
    /// Trigger a new launch and return data for it.
    ///
    /// - Parameters:
    ///   - atDate: Date to trigger launch from.
    ///   - overrideSession: Optional override session. For testing main use case.
    /// - Returns: Dictionary of variables in a [String:Any] object
    public func newLaunch(atDate: Date,
                          overrideSession: TealiumLifecycleSession?) -> [String:Any] {
        
        autotracked = TealiumLifecycleValue.yes
        type = "launch"
        countLaunch += 1
        countLaunchTotal += 1
        countWake += 1
        countWakeTotal += 1
        
        let newSession = (overrideSession != nil) ? overrideSession! : TealiumLifecycleSession(withLaunchDate: atDate)
        sessions.append(newSession)
        
        if newCrashDetected() == TealiumLifecycleValue.yes {
            countCrashTotal += 1
        }
        if isFirstLaunchAfterUpdate() == TealiumLifecycleValue.yes {
            resetCountsForNewVersion(forDate: atDate)
        }
        
        return self.asDictionary(forDate: atDate)
        
    }
    
    /// Trigger a new wake and return data for it.
    ///
    /// - Parameters:
    ///   - atDate: Date to trigger wake from.
    ///   - overrideSession: Optional override session.
    /// - Returns: Dictionary of variables in a [String:Any] object
    public func newWake(atDate: Date, overrideSession: TealiumLifecycleSession?) -> [String:Any] {

        autotracked = TealiumLifecycleValue.yes
        type = "wake"
        countWake += 1
        countWakeTotal += 1

        let newSession = (overrideSession != nil) ? overrideSession! : TealiumLifecycleSession(withWakeDate: atDate)
        sessions.append(newSession)
        
        if newCrashDetected() == TealiumLifecycleValue.yes {
            countCrashTotal += 1
        }
        
        return self.asDictionary(forDate:atDate)
        
    }
    
    
    /// Trigger a new sleep and return data for it.
    ///
    /// - Parameter atDate: Date to set sleep to.
    /// - Returns: Dictionary of variables in a [String:Any] object
    public func newSleep(atDate: Date) -> [String:Any] {

        autotracked = TealiumLifecycleValue.yes
        type = "sleep"
        countSleep += 1
        countSleepTotal += 1
        
        guard let currentSession = sessions.last else {
            // Sleep call somehow made prior to the first launch event
            return [:]
        }
        
        currentSession.sleepDate = atDate
        self.totalSecondsAwake += currentSession.secondsElapsed
        return self.asDictionary(forDate:atDate)
        
    }
    
    public func newTrack(atDate: Date) -> [String:Any] {
        
        guard sessions.last != nil else {
            // Track request before launch processed
            return [:]
        }
        
        autotracked = nil
        self.type = nil
        return self.asDictionary(forDate:atDate)
        
    }
    
    // MARK: 
    // MARK: INTERNAL RESETS
    internal func resetCountsForNewVersion(forDate: Date) {
        
        countWake = 1
        countLaunch = 1
        countSleep = 0
        dateLastUpdate = forDate
        
    }
    
    // MARK:
    // MARK: INTERNAL HELPERS
    
    internal func asDictionary(forDate: Date) -> [String:Any] {
        
        var dict = [String:Any]()
        
        let firstSession = sessions.first

        dict[TealiumLifecycleKey.autotracked] = self.autotracked
        dict[TealiumLifecycleKey.didDetectCrash] = newCrashDetected()
        dict[TealiumLifecycleKey.dayOfWeek] = dayOfWeekLocal(forDate: forDate)
        dict[TealiumLifecycleKey.daysSinceFirstLaunch] = daysFrom(earlierDate: firstSession?.wakeDate, laterDate: forDate)
        dict[TealiumLifecycleKey.daysSinceLastUpdate] = daysFrom(earlierDate: dateLastUpdate, laterDate: forDate)
        dict[TealiumLifecycleKey.daysSinceLastWake] = daysSinceLastWake(toDate: forDate)
        dict[TealiumLifecycleKey.firstLaunchDate] = firstSession?.wakeDate?.iso8601String
        dict[TealiumLifecycleKey.firstLaunchDate_MMDDYYYY] = firstSession?.wakeDate?.mmDDYYYYString
        dict[TealiumLifecycleKey.hourOfDayLocal] = hourOfDayLocal(forDate: forDate)
        dict[TealiumLifecycleKey.isFirstLaunch] = isFirstLaunch()
        dict[TealiumLifecycleKey.isFirstLaunchUpdate] = isFirstLaunchAfterUpdate()
        dict[TealiumLifecycleKey.isFirstWakeThisMonth] = isFirstWakeThisMonth()
        dict[TealiumLifecycleKey.isFirstWakeToday] = isFirstWakeToday()
        dict[TealiumLifecycleKey.lastLaunchDate] = lastLaunchDate()?.iso8601String
        dict[TealiumLifecycleKey.lastWakeDate] = lastWakeDate()?.iso8601String
        dict[TealiumLifecycleKey.lastSleepDate] = lastSleepDate()?.iso8601String
        dict[TealiumLifecycleKey.launchCount] = String(countLaunch)
        dict[TealiumLifecycleKey.priorSecondsAwake] = priorSecondsAwake()
        dict[TealiumLifecycleKey.secondsAwake] = secondsAwake(toDate: forDate)
        dict[TealiumLifecycleKey.sleepCount] = String(countSleep)
        dict[TealiumLifecycleKey.type] = type
        dict[TealiumLifecycleKey.totalCrashCount] = String(countCrashTotal)
        dict[TealiumLifecycleKey.totalLaunchCount] = String(countLaunchTotal)
        dict[TealiumLifecycleKey.totalSleepCount] = String(countSleepTotal)
        dict[TealiumLifecycleKey.totalWakeCount] = String(countWakeTotal)
        dict[TealiumLifecycleKey.totalSecondsAwake] = String(totalSecondsAwake)
        dict[TealiumLifecycleKey.wakeCount] = String(countWake)
        
        if dateLastUpdate != nil {
            // We've just reset values
            dict[TealiumLifecycleKey.updateLaunchDate] = dateLastUpdate?.iso8601String
        }
        
        return dict
        
    }
    
    internal func isFirstLaunch() -> String? {
        
        if countLaunchTotal == 1 &&
            countWakeTotal == 1 &&
            countSleepTotal == 0{
            return TealiumLifecycleValue.yes
        }
        return nil
        
    }
    
    
    /// Check if we're launching for first time after an app version update.
    ///
    /// - Returns: String "true" or nil
    internal func isFirstLaunchAfterUpdate() -> String? {
        
        let prior = sessions.beforeLast()
        let current = sessions.last
        
        if prior?.appVersion == current?.appVersion {
            return nil
        }
        return TealiumLifecycleValue.yes
        
    }
    
    internal func isFirstWakeToday() -> String? {
        
        // Wakes array has only 1 date - return true
        if sessions.count < 2 {
            return TealiumLifecycleValue.yes
        }
        
        // Two wake dates on record, if different - return true
        let earlierWake = (sessions.beforeLast()?.wakeDate)!
        let laterWake = (sessions.last?.wakeDate)!
        let earlierDay = Calendar.autoupdatingCurrent.component(.day, from: earlierWake)
        let laterDay = Calendar.autoupdatingCurrent.component(.day, from: laterWake)
        
        if  laterWake > earlierWake &&
            laterDay != earlierDay {
            return TealiumLifecycleValue.yes
        }
        return nil
        
    }
    
    internal func isFirstWakeThisMonth() -> String? {
        
        // Wakes array has only 1 date - return true
        if sessions.count < 2 {
            return TealiumLifecycleValue.yes
        }
        
        // Two wake dates on record, if different - return true
        let earlierWake = (sessions.beforeLast()?.wakeDate)!
        let laterWake = (sessions.last?.wakeDate)!
        let earlier = Calendar.autoupdatingCurrent.component(.month, from: earlierWake)
        let later = Calendar.autoupdatingCurrent.component(.month, from: laterWake)
        
        if  laterWake > earlierWake &&
            later != earlier {
            return TealiumLifecycleValue.yes
        }
        return nil
        
    }
    
    internal func dayOfWeekLocal(forDate: Date) -> String {
        
        let day = Calendar.autoupdatingCurrent.component(.weekday, from: forDate)
        return String(day)
        
    }
    
    internal func daysSinceLastWake(toDate: Date) -> String? {
    
        if type == TealiumLifecycleType.sleep.description {
            let earlierDate = sessions.last!.wakeDate
            return daysFrom(earlierDate: earlierDate, laterDate: toDate)
        }
        guard let targetSession = sessions.beforeLast() else {
            // Shouldn't happen
            return nil
        }
        let earlierDate = targetSession.wakeDate
        return daysFrom(earlierDate: earlierDate, laterDate: toDate)
        
    }
    
    internal func daysFrom(earlierDate: Date?, laterDate: Date) -> String? {
        
        guard let earlyDate = earlierDate else {
            return nil
        }
        let components = Calendar.autoupdatingCurrent.dateComponents([.second], from: earlyDate, to: laterDate)
        
        // NOTE: This is not entirely accurate as it does not adjust for Daylight Savings - 
        //  however this matches up with implmentation in Android, and is off by one day after about 172
        //  days have elapsed
        let days = components.second! / (60 * 60 * 24)
        return String(days)

    }

    internal func hourOfDayLocal(forDate: Date) -> String {
        
        let hour = Calendar.autoupdatingCurrent.component(.hour, from: forDate)
        return String(hour)
    }

    internal func lastLaunchDate() -> Date? {
        
        let lastSession = sessions.last!
        
        if type == TealiumLifecycleType.sleep.description &&
            lastSession.wasLaunch == true {
            return lastSession.wakeDate
        }
        for i in (0..<(sessions.count-1)).reversed() {
            let session = sessions[i]
            if session.wasLaunch == true {
                return session.wakeDate
            }
        }
        // should never happen
        return sessions.first!.wakeDate
        
    }
    
    internal func lastSleepDate() -> Date? {
        
        if sessions.last == sessions.first {
            return nil
        }
        for i in (0..<(sessions.count-1)).reversed() {
            let session = sessions[i]
            if session.sleepDate != nil {
                return session.sleepDate
            }
        }
        return nil
        
    }
    
    internal func lastWakeDate() -> Date? {
        
        if type == TealiumLifecycleType.sleep.description {
            return sessions.last!.wakeDate
        }
        if sessions.last == sessions.first {
            return sessions.last!.wakeDate
        }
        return sessions.beforeLast()!.wakeDate

    }

    
    internal func newCrashDetected() -> String? {
        
        // Still in first session, can't have crashed yet
        if sessions.last == sessions.first {
            return nil
        }
        if sessions.beforeLast()?.secondsElapsed != 0 {
            return nil
        }
        
        // No sleep recorded in session before current
        return TealiumLifecycleValue.yes
        
    }
    
    internal func secondsAwake(toDate: Date) -> String? {
        
        let currentWake = sessions.last!.wakeDate
        return secondsFrom(earlierDate: currentWake, laterDate: toDate)
        
    }
    
    internal func secondsFrom(earlierDate: Date?, laterDate: Date) -> String? {
        
        guard let earlyDate = earlierDate else {
            return nil
        }
        
        let milliseconds = laterDate.timeIntervalSince(earlyDate)
        return String(Int(milliseconds))
        
    }
    
    
    /// Seconds app was awake since last launch. Available only during launch calls.
    ///
    /// - Returns: String of Int Seconds elapsed
    internal func priorSecondsAwake() -> String? {
        
        var secondsAggregate : Int = 0
        var count = sessions.count - 1
        if count < 0 { count = 0 }
        
        for i in (0..<count) {
            let session = sessions[i]
            if session.wasLaunch {
                secondsAggregate = 0
            }
            secondsAggregate += session.secondsElapsed
        }
        return String(describing: secondsAggregate)
        
    }

}

public func ==(lhs: TealiumLifecycle, rhs: TealiumLifecycle ) -> Bool {
    
    if lhs.countCrashTotal != rhs.countCrashTotal { return false }
    if lhs.countLaunchTotal != rhs.countLaunchTotal { return false }
    if lhs.countSleepTotal != rhs.countSleepTotal { return false }
    if lhs.countWakeTotal != rhs.countWakeTotal { return false }

    return true
    
}

extension Array where Element:TealiumLifecycleSession {
    
    
    /// Get item before last
    ///
    /// - Returns: Target item or item at index 0 if only 1 item.
    func beforeLast() -> Element? {
        
        if self.isEmpty {
            return nil
        }
        
        var index = self.count - 2
        if index < 0 {
            index = 0
        }
        return self[index]
        
    }
    
}
extension Date {
    
    struct Formatter {
        static let iso8601 : DateFormatter = {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            return formatter
        }()
        static let MMDDYYYY : DateFormatter = {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "MM/dd/yyyy"
            return formatter
        }()
    }
    
    var iso8601String : String {
        return Formatter.iso8601.string(from: self)
    }
    
    var mmDDYYYYString : String {
        return Formatter.MMDDYYYY.string(from: self)
    }
    
}
