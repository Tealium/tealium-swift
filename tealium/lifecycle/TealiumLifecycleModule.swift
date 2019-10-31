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

#if lifecycle
import TealiumCore
#endif

public class TealiumLifecycleModule: TealiumModule {
    var enabledPrior = false    // To differentiate between new launches and re-enables.
    var lifecycle: TealiumLifecycle?
    var uniqueId = ""
    var lastProcess: TealiumLifecycleType?
    var lifecyclePersistentData: TealiumLifecyclePersistentData!
    var diskStorage: TealiumDiskStorageProtocol!

    override public class func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumLifecycleModuleKey.moduleName,
                                   priority: 175,
                                   build: 3,
                                   enabled: true)
    }

    /// Enable function required by TealiumModule.
    override public func enable(_ request: TealiumEnableRequest) {
        self.enable(request, diskStorage: nil)
    }

    /// Enables the module and loads Lifecycle data into memory￼￼￼.
    ///
    /// - Parameters:
    ///     - request: `TealiumEnableRequest` - the request from the core library to enable this module￼￼
    ///     - diskStorage: `TealiumDiskStorageProtocol` instance to allow overriding for unit testing
    public func enable(_ request: TealiumEnableRequest,
                       diskStorage: TealiumDiskStorageProtocol? = nil) {
        let config = request.config
        uniqueId = "\(config.account).\(config.profile).\(config.environment)"
        // allows overriding for unit tests, indepdendently of enable call
        if self.diskStorage == nil {
            self.diskStorage = diskStorage ?? TealiumDiskStorage(config: request.config, forModule: TealiumLifecycleModuleKey.moduleName)
        }
        self.lifecyclePersistentData = TealiumLifecyclePersistentData(diskStorage: self.diskStorage, uniqueId: uniqueId)

        lifecycle = savedOrNewLifeycle()
        save()
        isEnabled = true
        Tealium.lifecycleListeners.addDelegate(delegate: self)
        didFinish(request)
    }

    /// Disables the module and deletes all associated data￼￼.
    ///
    /// - Parameter request: `TealiumDisableRequest`
    override public func disable(_ request: TealiumDisableRequest) {
        isEnabled = false
        lifecycle = nil
        didFinish(request)
    }

    /// Adds current Lifecycle data to the track request￼￼.
    ///
    /// - Parameter track: `TealiumTrackRequest` to be modified
    override public func track(_ track: TealiumTrackRequest) {

        guard isEnabled else {
            didFinishWithNoResponse(track)
            return
        }

        // do not add data to queued hits
        guard track.trackDictionary[TealiumKey.wasQueued] as? String == nil else {
            didFinishWithNoResponse(track)
            return
        }

        // Lifecycle ready?
        guard var lifecycle = lifecycle else {
            didFinish(track)
            return
        }

        var newData = lifecycle.newTrack(at: Date())
        newData += track.trackDictionary
        let newTrack = TealiumTrackRequest(data: newData,
                                           completion: track.completion)
        didFinish(newTrack)
    }

    // MARK: INTERNAL

    func processDetected(type: TealiumLifecycleType,
                         at date: Date = Date()) {
        guard processAcceptable(type: type) else {
            return
        }

        lastProcess = type
        self.process(type: type, at: date)
    }

    /// Determines if a lifecycle event should be triggered and requests a track.
    ///
    /// - Parameters:
    ///     - type: `TealiumLifecycleType`
    ///     - date: `Date` at which the event occurred
    func process(type: TealiumLifecycleType,
                 at date: Date) {
        guard isEnabled else {
            return
        }
        // If lifecycle has been nil'd out - module not ready or has been disabled
        guard var lifecycle = self.lifecycle else { return }

        // Setup data to be used in switch statement
        var data: [String: Any]

        // Update internal model and retrieve data for a track call
        switch type {
        case .launch:
            if enabledPrior == true { return }
            enabledPrior = true
            data = lifecycle.newLaunch(at: date,
                                       overrideSession: nil)
        case .sleep:
            data = lifecycle.newSleep(at: date)
        case .wake:
            data = lifecycle.newWake(at: date,
                                     overrideSession: nil)
        }
        self.lifecycle = lifecycle
        // Save now in case we crash later
        save()

        // Make the track request to the modulesManager
        requestTrack(data: data)
    }

    /// Prevent manual spanning of repeated lifecycle calls to system.
    ///
    /// - Parameter type: `TealiumLifecycleType`
    /// - Returns: `Bool` `true` if process should be allowed to continue
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

    /// Sends a track request to the module delegate.
    ///
    /// - Parameter data: `[String: Any]` containing the lifecycle data to track
    func requestTrack(data: [String: Any]) {
        guard isEnabled else {
            return
        }
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

    /// Saves current lifecycle data to persistent storage.
    func save() {
        // Error handling?
        guard let lifecycle = self.lifecycle else {
            return
        }
        _ = lifecyclePersistentData.save(lifecycle)
    }

    /// Attempts to load lifecycle data from persistent storage, or returns new lifecycle data if not found.
    ///
    /// - Returns: `TealiumLifecycle`
    func savedOrNewLifeycle() -> TealiumLifecycle {
        // Attempt to load first
        if let loadedLifecycle = lifecyclePersistentData.load() {
            return loadedLifecycle
        }
        return TealiumLifecycle()
    }

}
// swiftlint:enable type_body_length

public func == (lhs: TealiumLifecycle, rhs: TealiumLifecycle ) -> Bool {
    if lhs.countCrashTotal != rhs.countCrashTotal { return false }
    if lhs.countLaunchTotal != rhs.countLaunchTotal { return false }
    if lhs.countSleepTotal != rhs.countSleepTotal { return false }
    if lhs.countWakeTotal != rhs.countWakeTotal { return false }

    return true
}

extension Array where Element == TealiumLifecycleSession {

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
