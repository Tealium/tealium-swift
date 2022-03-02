//
//  DataLayer.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public class DataLayer: DataLayerManagerProtocol, SessionManagerProtocol, TimestampCollection {

    var data = Set<DataLayerItem>()
    var diskStorage: TealiumDiskStorageProtocol
    var restartData = [String: Any]()
    var config: TealiumConfig
    public var lastTrackDate: Date?
    public var minutesBetweenSessionIdentifier: TimeInterval
    public var numberOfTrackRequests = 0
    public var secondsBetweenTrackEvents: TimeInterval = TealiumValue.defaultsSecondsBetweenTrackEvents
    var sessionStarter: SessionStarterProtocol
    public var shouldTriggerSessionRequest = false
    public var isTagManagementEnabled = false

    public init(config: TealiumConfig,
                diskStorage: TealiumDiskStorageProtocol? = nil,
                sessionStarter: SessionStarterProtocol? = nil) {
        self.config = config
        self.diskStorage = diskStorage ?? TealiumDiskStorage(config: config, forModule: "eventdata")
        self.sessionStarter = sessionStarter ?? SessionStarter(config: config)
        self.minutesBetweenSessionIdentifier = TimeInterval(TealiumValue.defaultMinutesBetweenSession)
        var currentStaticData = [TealiumDataKey.account: config.account,
                                 TealiumDataKey.profile: config.profile,
                                 TealiumDataKey.environment: config.environment,
                                 TealiumDataKey.libraryName: TealiumValue.libraryName,
                                 TealiumDataKey.libraryVersion: TealiumValue.libraryVersion,
                                 TealiumDataKey.origin: TealiumValue.mobile]

        if let dataSource = config.dataSource {
            currentStaticData[TealiumDataKey.dataSource] = dataSource
        }
        add(data: currentStaticData, expiry: .untilRestart)
        refreshSession()
    }

    /// - Returns: `[String: Any]` containing all stored event data.
    public var all: [String: Any] {
        get {
            var allData = [String: Any]()
            TealiumQueues.backgroundConcurrentQueue.read {
                allData += self.restartData
                allData += self.allSessionData
            }
            return allData
        }
        set {
            self.add(data: newValue, expiry: .forever)
        }
    }

    /// - Returns: `[String: Any]` containing all data for the active session.
    public var allSessionData: [String: Any] {
        var allSessionData = [String: Any]()
        if let persistentData = self.persistentDataStorage {
            allSessionData += persistentData.all
        }

        allSessionData[TealiumDataKey.random] = random
        if !currentTimestampsExist(allSessionData) {
            allSessionData.merge(currentTimeStamps) { _, new in new }
            allSessionData[TealiumDataKey.timestampOffset] = timeZoneOffset
        }
        return allSessionData
    }

    /// - Returns: `[String: Any]` containing all current timestamps in volatile data.
    public var currentTimeStamps: [String: Any] {
        let date = Date()
        return [
            TealiumDataKey.timestampEpoch: date.timestampInSeconds,
            TealiumDataKey.timestamp: date.iso8601String,
            TealiumDataKey.timestampLocal: date.iso8601LocalString,
            TealiumDataKey.timestampUnixMilliseconds: date.unixTimeMilliseconds,
            TealiumDataKey.timestampUnix: date.unixTimeSeconds
        ]
    }

    /// - Returns: `Set<DataLayerItem>` containing all stored event data.
    public var persistentDataStorage: Set<DataLayerItem>? {
        get {
            TealiumQueues.backgroundConcurrentQueue.read {
                guard let storedData = self.diskStorage.retrieve(as: Set<DataLayerItem>.self) else {
                    return Set<DataLayerItem>()
                }
                return storedData
            }
        }
        set {
            if let newData = newValue?.removeExpired() {
                self.diskStorage.save(newData, completion: nil)
            }
        }
    }

    /// - Returns: `String` containing the offset from UTC in hours.
    var timeZoneOffset: String {
        let timezone = TimeZone.current
        let offsetSeconds = timezone.secondsFromGMT()
        let offsetHours = offsetSeconds / 3600
        return String(format: "%i", offsetHours)
    }

    /// Adds data to be stored based on the `Expiry`.
    /// - Parameters:
    ///   - key: `String` name of key to be stored.
    ///   - value: `Any` should be `String` or `[String]`.
    ///   - expiration: `Expiry` level.
    public func add(key: String,
                    value: Any,
                    expiry: Expiry = .session) {
        self.add(data: [key: value], expiry: expiry)
    }

    /// Adds data to be stored based on the `Expiry`.
    /// - Parameters:
    ///   - data: `[String: Any]` to be stored.
    ///   - expiration: `Expiry` level.
    public func add(data: [String: Any],
                    expiry: Expiry = .session) {
        TealiumQueues.backgroundConcurrentQueue.write {
            let dataToInsert: [String: Any]
            switch expiry {
            case .untilRestart:
                self.restartData += data
                // Adding this to the persistent storage will trigger a new clean of expired entries and save, and eventually remove entries with the same id but higher expiry date
                dataToInsert = self.restartData
            default:
                dataToInsert = data
            }
            self.persistentDataStorage?.insert(from: dataToInsert, expiry: expiry)
        }
    }

    /// Checks that the active session data contains all expected timestamps.
    ///
    /// - Parameter currentData: `[String: Any]` containing existing session data.
    /// - Returns: `Bool` `true` if current timestamps exist in active session data.
    func currentTimestampsExist(_ currentData: [String: Any]) -> Bool {
        currentData[TealiumDataKey.timestampEpoch] != nil &&
            currentData[TealiumDataKey.timestamp] != nil &&
            currentData[TealiumDataKey.timestampLocal] != nil &&
            currentData[TealiumDataKey.timestampOffset] != nil &&
            currentData[TealiumDataKey.timestampUnix] != nil
    }

    /// Deletes specified values from storage.
    /// - Parameter forKeys: `[String]` keys to delete.
    public func delete(for keys: [String]) {
        keys.forEach {
            self.deletePersistent(key: $0)
        }
        TealiumQueues.backgroundConcurrentQueue.write { [weak self] in
            keys.forEach {
                self?.deleteteRestart(key: $0)
            }
        }
    }

    private func deletePersistent(key: String) {
        persistentDataStorage?.remove(key: key)
    }

    private func deleteteRestart(key: String) {
        TealiumQueues.backgroundConcurrentQueue.write { [weak self] in
            self?.restartData.removeValue(forKey: key)
        }
    }

    /// Deletes a value from storage.
    /// - Parameter key: `String` to delete.
    public func delete(for key: String) {
        deletePersistent(key: key)
        deleteteRestart(key: key)
    }

    /// Deletes all values from storage.
    public func deleteAll() {
        persistentDataStorage?.removeAll()
        TealiumQueues.backgroundConcurrentQueue.write { [weak self] in
            self?.restartData.removeAll()
        }
    }

    /// - Returns: `String` format of random 16 digit number
    private var random: String {
        (1..<16).reduce(into: "") { string, _ in string += String(Int(arc4random_uniform(10))) }
    }

    deinit {
        sessionStarter.urlSession.finishTealiumTasksAndInvalidate()
    }

}
