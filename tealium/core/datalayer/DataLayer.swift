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
    public var sessionData = [String: Any]()
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
        var currentStaticData = [TealiumKey.account: config.account,
                                 TealiumKey.profile: config.profile,
                                 TealiumKey.environment: config.environment,
                                 TealiumKey.libraryName: TealiumValue.libraryName,
                                 TealiumKey.libraryVersion: TealiumValue.libraryVersion,
                                 TealiumKey.origin: TealiumValue.mobile]

        if let dataSource = config.dataSource {
            currentStaticData[TealiumKey.dataSource] = dataSource
        }
        add(data: currentStaticData, expiry: .untilRestart)
        refreshSession()
    }

    /// - Returns: `[String: Any]` containing all stored event data.
    public var all: [String: Any] {
        get {
            var allData = [String: Any]()
            if let persistentData = self.persistentDataStorage {
                allData += persistentData.all
            }
            allData += self.restartData
            allData += self.allSessionData
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

        allSessionData[TealiumKey.random] = random
        if !currentTimestampsExist(allSessionData) {
            allSessionData.merge(currentTimeStamps) { _, new in new }
            allSessionData[TealiumKey.timestampOffset] = timeZoneOffset
        }
        return allSessionData
    }

    /// - Returns: `[String: Any]` containing all current timestamps in volatile data.
    public var currentTimeStamps: [String: Any] {
        let date = Date()
        return [
            TealiumKey.timestampEpoch: date.timestampInSeconds,
            TealiumKey.timestamp: date.iso8601String,
            TealiumKey.timestampLocal: date.iso8601LocalString,
            TealiumKey.timestampUnixMilliseconds: date.unixTimeMilliseconds,
            TealiumKey.timestampUnix: date.unixTimeSeconds
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
                    expiry: Expiry? = .session) {
        self.add(data: [key: value], expiry: expiry)
    }

    /// Adds data to be stored based on the `Expiry`.
    /// - Parameters:
    ///   - data: `[String: Any]` to be stored.
    ///   - expiration: `Expiry` level.
    public func add(data: [String: Any],
                    expiry: Expiry? = .session) {
        guard let expiry = expiry else {
            return
        }
        TealiumQueues.backgroundConcurrentQueue.write {
            switch expiry {
            case .session:
                self.persistentDataStorage?.insert(from: data, expires: expiry.date)
            case .untilRestart:
                self.restartData += data
                self.persistentDataStorage?.insert(from: self.restartData, expires: expiry.date)
            default:
                self.persistentDataStorage?.insert(from: data, expires: expiry.date)
            }
        }
    }

    /// Checks that the active session data contains all expected timestamps.
    ///
    /// - Parameter currentData: `[String: Any]` containing existing session data.
    /// - Returns: `Bool` `true` if current timestamps exist in active session data.
    func currentTimestampsExist(_ currentData: [String: Any]) -> Bool {
        currentData[TealiumKey.timestampEpoch] != nil &&
            currentData[TealiumKey.timestamp] != nil &&
            currentData[TealiumKey.timestampLocal] != nil &&
            currentData[TealiumKey.timestampOffset] != nil &&
            currentData[TealiumKey.timestampUnix] != nil
    }

    /// Deletes specified values from storage.
    /// - Parameter forKeys: `[String]` keys to delete.
    public func delete(for keys: [String]) {
        keys.forEach {
            self.delete(for: $0)
        }
    }

    /// Deletes a value from storage.
    /// - Parameter key: `String` to delete.
    public func delete(for key: String) {
        persistentDataStorage?.remove(key: key)
    }

    /// Deletes all values from storage.
    public func deleteAll() {
        persistentDataStorage?.removeAll()
    }

    /// - Returns: `String` format of random 16 digit number
    private var random: String {
        (1..<16).reduce(into: "") { string, _ in string += String(Int(arc4random_uniform(10))) }
    }

}
