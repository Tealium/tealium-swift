//
//  TealiumLifecycleModule.swift
//  tealium-swift
//
//  Created by Jason Koo on 1/10/17.
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//
//

import Foundation

#if TEST
#else
#if os(OSX)
#else
import UIKit
#endif
#endif

// MARK: 
// MARK: ENUMS

enum TealiumLifecycleModuleKey {
    static let moduleName = "lifecycle"
    static let queueName = "com.tealium.lifecycle"
}

enum TealiumLifecycleModuleError: Error {
    case unableToSaveToDisk
}

// MARK: 
// MARK: EXTENSIONS

public extension Tealium {

    func lifecycle() -> TealiumLifecycleModule? {
        guard let module = modulesManager.getModule(forName: TealiumLifecycleModuleKey.moduleName) as? TealiumLifecycleModule else {
            return nil
        }

        return module
    }

}

// MARK: 
// MARK: MODULE SUBCLASS

public class TealiumLifecycleModule: TealiumModule {

    fileprivate weak var _dispatchQueue: DispatchQueue?
    var areListenersActive = false
    var enabledPrior = false    // To differentiate between new launches and re-enables.
    var lifecycle: TealiumLifecycle?
    var uniqueId: String = ""
    var lastProcess: TealiumLifecycleType?

    // MARK: TEALIUM MODULE CONFIG
    override public class func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumLifecycleModuleKey.moduleName,
                                   priority: 175,
                                   build: 3,
                                   enabled: true)
    }

    override public func enable(_ request: TealiumEnableRequest) {
        if areListenersActive == false {
            addListeners()

            delegate?.tealiumModuleRequests(module: self,
                                            process: TealiumReportNotificationsRequest())
        }
        _dispatchQueue = OperationQueue.current?.underlyingQueue

        let config = request.config
        uniqueId = "\(config.account).\(config.profile).\(config.environment)"
        lifecycle = savedOrNewLifeycle(uniqueId: uniqueId)
        let save = TealiumLifecyclePersistentData.save(lifecycle!, usingUniqueId: uniqueId)

        if save.success == false {
            self.didFailToFinish(request,
                                 error: save.error!)
            return
        }

        isEnabled = true

        didFinish(request)
    }

    override public func disable(_ request: TealiumDisableRequest) {
        isEnabled = false
        lifecycle = nil
        _dispatchQueue = nil
        didFinish(request)
    }

    override public func handleReport(_ request: TealiumRequest) {
        if isEnabled == false {
            return
        }

        if request as? TealiumEnableRequest != nil {

            launchDetected()
        }

        // NOTE: This type of check will fail.
        //        if request is TealiumEnableRequest {
        //        }
    }

    override public func track(_ track: TealiumTrackRequest) {
        // Lifecycle ready?
        guard let lifecycle = self.lifecycle else {
            didFinish(track)
            return
        }

        var newData = lifecycle.newTrack(atDate: Date())
        newData += track.data
        let newTrack = TealiumTrackRequest(data: newData,
                                           completion: track.completion)
        didFinish(newTrack)
    }

    // MARK: 
    // MARK: PUBLIC

    public func launchDetected() {
        processDetected(type: .launch)
    }

    @objc
    public func sleepDetected() {
        processDetected(type: .sleep)
    }

    @objc
    public func wakeDetected() {
        processDetected(type: .wake)
    }

    // MARK: 
    // MARK: INTERNAL

    func addListeners() {
        #if TEST
        #else
        #if os(watchOS)
        #else
        #if os(OSX)
        #else

        #if swift(>=4.2)
        let notificationNameApplicationDidBecomeActive = UIApplication.didBecomeActiveNotification
        let notificationNameApplicationWillResignActive = UIApplication.willResignActiveNotification
        #else
        let notificationNameApplicationDidBecomeActive = NSNotification.Name.UIApplicationDidBecomeActive
        let notificationNameApplicationWillResignActive = NSNotification.Name.UIApplicationWillResignActive
        #endif

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(wakeDetected),
                                               name: notificationNameApplicationDidBecomeActive,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sleepDetected),
                                               name: notificationNameApplicationWillResignActive,
                                               object: nil)

        #endif
        #endif
        #endif
        areListenersActive = true
    }

    func processDetected(type: TealiumLifecycleType) {
        if processAcceptable(type: type) == false {
            return
        }

        lastProcess = type
        _dispatchQueue?.async { [weak self] in
            guard let sel = self else {
                return
            }
            sel.process(type: type)
        }
    }

    func process(type: TealiumLifecycleType) {
        // If lifecycle has been nil'd out - module not ready or has been disabled
        guard let lifecycle = self.lifecycle else { return }

        // Setup data to be used in switch statement
        let date = Date()
        var data: [String: Any]

        // Update internal model and retrieve data for a track call
        switch type {
        case .launch:
            if enabledPrior == true { return }
            enabledPrior = true
            data = lifecycle.newLaunch(atDate: date,
                                       overrideSession: nil)
        case .sleep:
            data = lifecycle.newSleep(atDate: date)
        case .wake:
            data = lifecycle.newWake(atDate: date,
                                     overrideSession: nil)
        }

        // Save now in case we crash later
        save()

        // Make the track request to the modulesManager
        requestTrack(data: data)
    }

    /// Prevent manual spanning of repeated lifecycle calls to system.
    ///
    /// - Parameters:
    ///   - type: Lifecycle event type
    ///   - lastProcess: Last lifecycle event type recorded
    /// - Returns: Bool is process should be allowed to continue
    func processAcceptable(type: TealiumLifecycleType) -> Bool {
        switch type {
        case .launch:
            // Can only occur once per app lifecycle
            if enabledPrior == true {
                return false
            }
            if lastProcess != nil {
                // Should never have more than 1 launch event per app lifecycle run
                return false
            }
        case .sleep:
            guard let lastProcess = lastProcess else {
                // Should not be possible
                return false
            }
            if lastProcess != .wake && lastProcess != .launch {
                return false
            }
        case .wake:
            guard let lastProcess = lastProcess else {
                // Should not be possible
                return false
            }
            if lastProcess != .sleep {
                return false
            }
        }
        return true
    }

    func requestTrack(data: [String: Any]) {
        guard let title = data[TealiumLifecycleKey.type] as? String else {
            // Should not happen
            return
        }

        // Conforming to universally available Tealium data variables
        let trackData = Tealium.trackDataFor(title: title,
                                             optionalData: data)
        let track = TealiumTrackRequest(data: trackData,
                                        completion: nil)
        self.delegate?.tealiumModuleRequests(module: self,
                                             process: track)
    }

    func save() {
        // Error handling?
        guard let lifecycle = self.lifecycle else {
            return
        }
        _ = TealiumLifecyclePersistentData.save(lifecycle, usingUniqueId: uniqueId)
    }

    func savedOrNewLifeycle(uniqueId: String) -> TealiumLifecycle {
        // Attempt to load first
        if let loadedLifecycle = TealiumLifecyclePersistentData.load(uniqueId: uniqueId) {
            return loadedLifecycle
        }
        return TealiumLifecycle()
    }

    deinit {
        if areListenersActive == true {
            #if os(OSX)
            #else
            NotificationCenter.default.removeObserver(self)
            #endif
        }
    }

}

// MARK: 
// MARK: LIFECYCLE

enum TealiumLifecycleKey {
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
}

enum TealiumLifecycleCodingKey {
    static let sessionFirst = "first"
    static let sessions = "sessions"
    static let sessionsSize = "session_size"
    static let totalSecondsAwake = "totalSecondsAwake"
}

public enum TealiumLifecycleType {
    case launch, sleep, wake

    var description: String {
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

public class TealiumLifecycle: NSObject, NSCoding {

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
    var sessions = [TealiumLifecycleSession]() {
        didSet {
            // Limit size of sessions records
            if sessions.count > sessionsSize &&
                sessionsSize > 1 {
                sessions.remove(at: 1)
            }
        }
    }

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
        if let savedSessions = coder.decodeObject(forKey: TealiumLifecycleCodingKey.sessions) as? [TealiumLifecycleSession] {
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
                          overrideSession: TealiumLifecycleSession?) -> [String: Any] {
        autotracked = TealiumLifecycleValue.yes
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

        return self.asDictionary(type: TealiumLifecycleType.launch.description,
                                 forDate: atDate)
    }

    /// Trigger a new wake and return data for it.
    ///
    /// - Parameters:
    ///   - atDate: Date to trigger wake from.
    ///   - overrideSession: Optional override session.
    /// - Returns: Dictionary of variables in a [String:Any] object
    public func newWake(atDate: Date, overrideSession: TealiumLifecycleSession?) -> [String: Any] {
        autotracked = TealiumLifecycleValue.yes
        countWake += 1
        countWakeTotal += 1

        let newSession = (overrideSession != nil) ? overrideSession! : TealiumLifecycleSession(withWakeDate: atDate)
        sessions.append(newSession)

        if newCrashDetected() == TealiumLifecycleValue.yes {
            countCrashTotal += 1
        }

        return self.asDictionary(type: TealiumLifecycleType.wake.description,
                                 forDate: atDate)
    }

    /// Trigger a new sleep and return data for it.
    ///
    /// - Parameter atDate: Date to set sleep to.
    /// - Returns: Dictionary of variables in a [String:Any] object
    public func newSleep(atDate: Date) -> [String: Any] {
        autotracked = TealiumLifecycleValue.yes
        countSleep += 1
        countSleepTotal += 1

        guard let currentSession = sessions.last else {
            // Sleep call somehow made prior to the first launch event
            return [:]
        }

        currentSession.sleepDate = atDate
        self.totalSecondsAwake += currentSession.secondsElapsed
        return self.asDictionary(type: TealiumLifecycleType.sleep.description,
                                 forDate: atDate)
    }

    public func newTrack(atDate: Date) -> [String: Any] {
        guard sessions.last != nil else {
            // Track request before launch processed
            return [:]
        }

        autotracked = nil
        return self.asDictionary(type: nil,
                                 forDate: atDate)
    }

    // MARK: 
    // MARK: INTERNAL RESETS
    func resetCountsForNewVersion(forDate: Date) {
        countWake = 1
        countLaunch = 1
        countSleep = 0
        dateLastUpdate = forDate
    }

    // MARK: 
    // MARK: INTERNAL HELPERS

    func asDictionary(type: String?,
                      forDate: Date) -> [String: Any] {
        var dict = [String: Any]()

        let firstSession = sessions.first

        dict[TealiumLifecycleKey.autotracked] = self.autotracked
        dict[TealiumLifecycleKey.didDetectCrash] = newCrashDetected()
        dict[TealiumLifecycleKey.dayOfWeek] = dayOfWeekLocal(forDate: forDate)
        dict[TealiumLifecycleKey.daysSinceFirstLaunch] = daysFrom(earlierDate: firstSession?.wakeDate, laterDate: forDate)
        dict[TealiumLifecycleKey.daysSinceLastUpdate] = daysFrom(earlierDate: dateLastUpdate, laterDate: forDate)
        dict[TealiumLifecycleKey.daysSinceLastWake] = daysSinceLastWake(type: type, toDate: forDate)
        dict[TealiumLifecycleKey.firstLaunchDate] = firstSession?.wakeDate?.iso8601String
        dict[TealiumLifecycleKey.firstLaunchDateMMDDYYYY] = firstSession?.wakeDate?.mmDDYYYYString
        dict[TealiumLifecycleKey.hourOfDayLocal] = hourOfDayLocal(forDate: forDate)
        dict[TealiumLifecycleKey.isFirstLaunch] = isFirstLaunch()
        dict[TealiumLifecycleKey.isFirstLaunchUpdate] = isFirstLaunchAfterUpdate()
        dict[TealiumLifecycleKey.isFirstWakeThisMonth] = isFirstWakeThisMonth()
        dict[TealiumLifecycleKey.isFirstWakeToday] = isFirstWakeToday()
        dict[TealiumLifecycleKey.lastLaunchDate] = lastLaunchDate(type: type)?.iso8601String
        dict[TealiumLifecycleKey.lastWakeDate] = lastWakeDate(type: type)?.iso8601String
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

    func isFirstLaunch() -> String? {
        if countLaunchTotal == 1 &&
            countWakeTotal == 1 &&
            countSleepTotal == 0 {
            return TealiumLifecycleValue.yes
        }
        return nil
    }

    /// Check if we're launching for first time after an app version update.
    ///
    /// - Returns: String "true" or nil
    func isFirstLaunchAfterUpdate() -> String? {
        let prior = sessions.beforeLast()
        let current = sessions.last

        if prior?.appVersion == current?.appVersion {
            return nil
        }
        return TealiumLifecycleValue.yes
    }

    func isFirstWakeToday() -> String? {
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

    func isFirstWakeThisMonth() -> String? {
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

    func dayOfWeekLocal(forDate: Date) -> String {
        let day = Calendar.autoupdatingCurrent.component(.weekday, from: forDate)
        return String(day)
    }

    func daysSinceLastWake(type: String?,
                           toDate: Date) -> String? {
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

    func daysFrom(earlierDate: Date?, laterDate: Date) -> String? {
        guard let earlyDate = earlierDate else {
            return nil
        }
        let components = Calendar.autoupdatingCurrent.dateComponents([.second], from: earlyDate, to: laterDate)

        // NOTE: This is not entirely accurate as it does not adjust for Daylight Savings -
        //  however this matches up with implementation in Android, and is off by one day after about 172
        //  days have elapsed
        let days = components.second! / (60 * 60 * 24)
        return String(days)
    }

    func hourOfDayLocal(forDate: Date) -> String {
        let hour = Calendar.autoupdatingCurrent.component(.hour, from: forDate)
        return String(hour)
    }

    func lastLaunchDate(type: String?) -> Date? {
        guard let lastSession = sessions.last else {
            return nil
        }

        if type == TealiumLifecycleType.sleep.description &&
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
        return sessions.first!.wakeDate
    }

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

    func lastWakeDate(type: String?) -> Date? {
        guard let lastSession = sessions.last else {
            return nil
        }

        if type == TealiumLifecycleType.sleep.description {
            return lastSession.wakeDate
        }
        if sessions.last == sessions.first {
            return lastSession.wakeDate
        }

        guard let beforeLastSession = sessions.beforeLast() else {
            return nil
        }
        return beforeLastSession.wakeDate
    }

    func newCrashDetected() -> String? {
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

    func secondsAwake(toDate: Date) -> String? {
        guard let lastSession = sessions.last else {
            return nil
        }
        let currentWake = lastSession.wakeDate
        return secondsFrom(earlierDate: currentWake, laterDate: toDate)
    }

    func secondsFrom(earlierDate: Date?, laterDate: Date) -> String? {
        guard let earlyDate = earlierDate else {
            return nil
        }

        let milliseconds = laterDate.timeIntervalSince(earlyDate)
        return String(Int(milliseconds))
    }

    /// Seconds app was awake since last launch. Available only during launch calls.
    ///
    /// - Returns: String of Int Seconds elapsed
    func priorSecondsAwake() -> String? {
        var secondsAggregate: Int = 0
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

}

public func == (lhs: TealiumLifecycle, rhs: TealiumLifecycle ) -> Bool {
    if lhs.countCrashTotal != rhs.countCrashTotal { return false }
    if lhs.countLaunchTotal != rhs.countLaunchTotal { return false }
    if lhs.countSleepTotal != rhs.countSleepTotal { return false }
    if lhs.countWakeTotal != rhs.countWakeTotal { return false }

    return true
}

extension Array where Element: TealiumLifecycleSession {

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

// MARK: 
// MARK: LIFECYCLE SESSION

enum TealiumLifecycleSessionKey {
    static let wakeDate = "wake"
    static let sleepDate = "sleep"
    static let secondsElapsed = "seconds"
    static let wasLaunch = "wasLaunch"
}

// Represents a serializable block of time between a given wake and a sleep
public class TealiumLifecycleSession: NSObject, NSCoding {

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

    class func getCurrentAppVersion() -> String {
        let bundleInfo = Bundle.main.infoDictionary

        if let shortString = bundleInfo?["CFBundleShortVersionString"] as? String {
            return shortString
        }

        if let altString = bundleInfo?["CFBundleVersion"] as? String {
            return altString
        }

        return "(unknown)"
    }

    public override var debugDescription: String {
        return "<TealiumLifecycleSession: appVersion:\(appVersion): wake:\(String(describing: wakeDate)) sleep:\(String(describing: sleepDate)) secondsElapsed: \(secondsElapsed) wasLaunch: \(wasLaunch)>"
    }
}

public func == (lhs: TealiumLifecycleSession, rhs: TealiumLifecycleSession ) -> Bool {

    if lhs.wakeDate != rhs.wakeDate { return false }
    if lhs.sleepDate != rhs.sleepDate { return false }
    if lhs.secondsElapsed != rhs.secondsElapsed { return false }
    if lhs.wasLaunch != rhs.wasLaunch { return false }
    return true
}
