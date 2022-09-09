//
//  VisitorServiceManager.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if visitorservice
import TealiumCore
#endif

public protocol VisitorServiceDelegate: AnyObject {
    func didUpdate(visitorProfile: TealiumVisitorProfile)
}

public enum VisitorServiceStatus: Int {
    case ready = 0
    case blocked = 1
}

public protocol VisitorServiceManagerProtocol {
    var currentVisitorId: String? { get set }
    var cachedProfile: TealiumVisitorProfile? { get }
    func requestVisitorProfile(waitTimeout: Bool)
}

public class VisitorServiceManager: VisitorServiceManagerProtocol {

    weak public var delegate: VisitorServiceDelegate?
    var visitorServiceRetriever: VisitorServiceRetriever
    var diskStorage: TealiumDiskStorageProtocol
    var timer: TealiumRepeatingTimer?
    var lifetimeEvents: Double {
        cachedProfile?.lifetimeEventCount ?? -1.0
    }
    var tealiumConfig: TealiumConfig
    var currentState = VisitorServiceStatus.ready
    var pollingAttempts = 0
    var maxPollingAttempts = 5
    var lastFetch: Date?
    public var currentVisitorId: String?

    /// Initializes the Visitor Service Manager
    ///
    /// - Parameter config: `TealiumConfig` instance
    /// - Parameter delegate: `VisitorServiceDelegate` instance
    /// - Parameter diskStorage: `TealiumDiskStorageProtocol` instance
    init(config: TealiumConfig,
         delegate: VisitorServiceDelegate?,
         diskStorage: TealiumDiskStorageProtocol) {
        tealiumConfig = config
        self.delegate = delegate
        self.diskStorage = diskStorage
        self.visitorServiceRetriever = VisitorServiceRetriever(config: config)
        guard let profile = diskStorage.retrieve(as: TealiumVisitorProfile.self) else {
            return
        }
        self.didUpdate(visitorProfile: profile)
    }

    /// - Returns: `TealiumVisitorProfile?` - the currrent cached profile from persistent storage.
    ///             As long as a previous fetch has been made, this should always return a profile, even if the device is offline
    public var cachedProfile: TealiumVisitorProfile? {
        diskStorage.retrieve(as: TealiumVisitorProfile.self)
    }

    /// Retrieves and saves the visitor profile for the current visitorId
    public func requestVisitorProfile() { // This is called from outside
        TealiumQueues.backgroundSerialQueue.async {
            self.requestVisitorProfile(waitTimeout: false)
        }
    }

    /// Retrieves and saves the visitor profile for the current visitorId if the timeout has expired
    public func requestVisitorProfile(waitTimeout: Bool) {
        // No need to request if no delegates are listening
        guard let visitorId = self.currentVisitorId,
            self.delegate != nil else {
            return
        }
        let mustWaitTimeout = waitTimeout && !shouldFetchVisitorProfile
        guard !mustWaitTimeout else {
            return
        }
        guard self.currentState == VisitorServiceStatus.ready else {
            return
        }
        self.blockState()
        self.fetchProfileOrRetry(visitorId: visitorId) {
            self.startPolling(visitorId: visitorId)
        }
    }

    func blockState() {
        currentState = VisitorServiceStatus.blocked
    }

    func releaseState() {
        currentState = VisitorServiceStatus.ready
    }

    func startPolling(visitorId: String) {
        if timer != nil {
            timer = nil
        }
        pollingAttempts = 0
        // No need to request if no delegates are listening
        guard delegate != nil else {
            releaseState()
            return
        }
        self.timer = TealiumRepeatingTimer(timeInterval: VisitorServiceConstants.pollingInterval)
        self.timer?.eventHandler = { [weak self] in
            guard let self = self else {
                return
            }
            self.fetchProfileOrRetry(visitorId: visitorId) {
                self.pollingAttempts += 1
                let attempts = self.pollingAttempts
                if attempts == self.maxPollingAttempts {
                    self.releaseState()
                    self.timer?.suspend()
                    self.pollingAttempts = 0
                }
            }
        }
        self.timer?.resume()
    }

    func fetchProfileOrRetry(visitorId: String, onShouldRetry: @escaping () -> Void) {
        self.fetchProfile(visitorId: visitorId) { profile, error in
            guard error == nil else {
                self.releaseState()
                self.timer?.suspend()
                return
            }
            guard let profile = profile else {
                onShouldRetry()
                return
            }
            self.timer?.suspend()
            self.releaseState()
            self.diskStorage.save(profile, completion: nil)
            self.didUpdate(visitorProfile: profile)
        }
    }

    func fetchProfile(visitorId: String, completion: @escaping (TealiumVisitorProfile?, NetworkError?) -> Void) {
        // No need to request if no delegates are listening
        guard delegate != nil else {
            completion(nil, nil)
            return
        }
        visitorServiceRetriever.fetchVisitorProfile(visitorId: visitorId) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let profile):
                guard let profile = profile,
                      !profile.isEmpty else {
                    completion(nil, nil)
                    return
                }
                guard let lifetimeEventCount = profile.lifetimeEventCount,
                      self.lifetimeEventCountHasBeenUpdated(lifetimeEventCount) else {
                    completion(nil, nil)
                    return
                }
                self.lastFetch = Date()
                completion(profile, nil)
            case .failure(let error):
                completion(nil, error)
            }
        }
    }

    /// Checks metric 22 (lifetime event count) within AudienceStream to see if the current value is greater than the previous.
    /// This will indicate whether or not the visitor profile has been updated since the last fetch.
    ///
    /// - Parameter count: `Double?` - Current value of the Lifetime Event Count (metric 22)
    /// - Returns: `Bool` `true` if lifetime event count has been updated
    func lifetimeEventCountHasBeenUpdated(_ count: Double?) -> Bool {
        guard let currentCount = count else {
            return false
        }
        let eventCountUpdated = currentCount > lifetimeEvents
        return eventCountUpdated
    }

    /// Should fetch visitor profile based on interval set in the config or defaults to every 5 minutes
    var shouldFetchVisitorProfile: Bool {
        guard let refresh = tealiumConfig.visitorServiceRefresh else {
            return shouldFetch(basedOn: lastFetch, interval: VisitorServiceConstants.defaultRefreshInterval.milliseconds, environment: tealiumConfig.environment)
        }
        return shouldFetch(basedOn: lastFetch, interval: refresh.interval.milliseconds, environment: tealiumConfig.environment)
    }

    /// Calculates the milliseconds since the last time the visitor profile was fetched
    ///
    /// - Parameters:
    ///   - lastFetch: The date the visitor profile was last retrieved
    ///   - currentDate: The current date/timestamp in milliseconds
    /// - Returns: `Int64` - milliseconds since last fetch
    func intervalSince(lastFetch: Date, _ currentDate: Date = Date()) -> Int64 {
        return currentDate.millisecondsFrom(earlierDate: lastFetch)
    }

    /// Checks if the profile should be fetched based on the date of last fetch,
    /// the interval set in the config (default 5 minutes) and the current environment.
    /// If the environment is dev or qa, the profile will be fetched every tracking call.
    ///
    /// - Parameters:
    ///   - lastFetch: The date the visitor profile was last retrieved
    ///   - interval: The interval, in milliseconds, between visitor profile retrieval
    ///   - environment: The environment set in TealiumConfig
    /// - Returns: `Bool` - whether or not the profile should be fetched
    func shouldFetch(basedOn lastFetch: Date?,
                     interval: Int64?,
                     environment: String) -> Bool {
        guard let lastFetch = lastFetch else {
            return true
        }
        guard environment == TealiumKey.prod else {
            return true
        }
        guard let interval = interval else {
            return true
        }
        let millisecondsFromLastFetch = intervalSince(lastFetch: lastFetch)
        return millisecondsFromLastFetch >= interval
    }
}

public extension VisitorServiceManager {

    /// Called when the visitor profile has been updated
    ///
    /// - Parameter profile: `TealiumVisitorProfile` - Updated visitor profile accessible through helper methods
    func didUpdate(visitorProfile: TealiumVisitorProfile) {
        delegate?.didUpdate(visitorProfile: visitorProfile)
    }
}

extension TealiumVisitorProfile {
    var lifetimeEventCount: Double? {
        get { numbers?[VisitorServiceConstants.eventCountMetric] }
        set { numbers?[VisitorServiceConstants.eventCountMetric] = newValue }
    }
}
