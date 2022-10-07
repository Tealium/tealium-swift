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
    var lastFetch: Date? { get }
    func requestVisitorProfile()
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
    private(set) public var lastFetch: Date?
    public var currentVisitorId: String? {
        didSet {
            if let currentVisitorId = currentVisitorId, oldValue != currentVisitorId {
                releaseState()
            }
        }
    }

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
    ///
    /// Use this method to avoid waiting for the `visitorServiceRefresh` interval between polling requests
    /// if you urgently need an update on the profile.
    public func requestVisitorProfile() { // This is called from outside
        TealiumQueues.backgroundSerialQueue.async {
            // No need to request if no delegates are listening
            guard let visitorId = self.currentVisitorId,
                self.delegate != nil else {
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
            guard let self = self, self.currentVisitorId == visitorId else {
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
            guard let self = self, self.currentVisitorId == visitorId else { return }
            switch result {
            case .success(let profile):
                guard let profile = profile,
                      !profile.isEmpty else {
                    completion(nil, nil)
                    return
                }
                self.lastFetch = Date()
                guard let lifetimeEventCount = profile.lifetimeEventCount,
                      self.lifetimeEventCountHasBeenUpdated(lifetimeEventCount) else {
                    completion(nil, nil)
                    return
                }
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
