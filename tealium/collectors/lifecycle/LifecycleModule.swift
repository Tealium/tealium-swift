//
//  LifecycleModule.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
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

public class LifecycleModule: Collector {

    public let id: String = ModuleNames.lifecycle
    weak var delegate: ModuleDelegate?
    var enabledPrior = false
    var lifecycleData = [String: Any]()
    var lastLifecycleEvent: LifecycleType?
    let backupStorage: TealiumBackupStorage
    var diskStorage: TealiumDiskStorageProtocol!
    var userDefaults: Storable?
    public var config: TealiumConfig
    var migrated = false
    private var lifecycleDisposeBag = TealiumDisposeBag()

    public var data: [String: Any]? {
        lifecycle?.asDictionary(type: nil, for: Date())
    }

    /// Initializes the module
    ///
    /// - Parameters:
    ///     -  context: `TealiumContext` instance
    ///     - delegate: `TealiumModuleDelegate` instance
    ///     - diskStorage: `TealiumDiskStorageProtocol` instance
    ///     - completion: `ModuleCompletion` block to be called when init is finished
    required public init(context: TealiumContext,
                         delegate: ModuleDelegate?,
                         diskStorage: TealiumDiskStorageProtocol?,
                         completion: ModuleCompletion) {
        self.backupStorage = context.tealiumBackup
        self.config = context.config
        self.delegate = delegate
        self.diskStorage = diskStorage ?? TealiumDiskStorage(config: config,
                                                             forModule: ModuleNames.lifecycle.lowercased(),
                                                             isCritical: true)
        if let dataLayer = context.dataLayer,
           let migratedLifecycle = dataLayer.all[TealiumDataKey.migratedLifecycle] as? [String: Any] {
            lifecycle = Lifecycle(from: migratedLifecycle)
            dataLayer.delete(for: TealiumDataKey.migratedLifecycle)
        }
        migrated = true
        enabledPrior = false
        if config.lifecycleAutoTrackingEnabled {
            lifecycleDetected(type: .launch, at: Tealium.lifecycleListeners.launchDate)
            Tealium.lifecycleListeners.onBackgroundStateChange.subscribe { [weak self] state in
                guard let self = self else {
                    return
                }
                switch state {
                case .wake(let date):
                    self.lifecycleDetected(type: .wake, at: date)
                case .sleep(let date):
                    self.lifecycleDetected(type: .sleep, at: date)
                }
            }.toDisposeBag(self.lifecycleDisposeBag)
        }
        completion((.success(true), nil))
    }

    var lifecycle: Lifecycle? {
        get {
            guard let storedData = diskStorage.retrieve(as: Lifecycle.self) else {
                return backupStorage.lifecycle ?? Lifecycle()
            }
            return storedData
        }
        set {
            if let newData = newValue {
                backupStorage.lifecycle = newData
                diskStorage.save(newData, completion: nil)
            }
        }
    }

    /// Determines if a lifecycle event should be triggered and requests a track.
    ///
    /// - Parameters:
    ///     - type: `LifecycleType`
    ///     - date: `Date` at which the event occurred
    ///     - autotracked: `Bool` indicates whether or not the lifecycle call was autotracked
    public func process(type: LifecycleType,
                        at date: Date, autotracked: Bool = false) {
        guard var lifecycle = self.lifecycle else {
            return
        }
        if type != .launch {
            lifecycleData[TealiumDataKey.didDetectCrash] = nil
        }
        switch type {
        case .launch:
            if enabledPrior == true { return }
            enabledPrior = true
            lifecycleData += lifecycle.newLaunch(at: date,
                                                 overrideSession: nil)
        case .sleep:
            lifecycleData += lifecycle.newSleep(at: date)
        case .wake:
            lifecycleData += lifecycle.newWake(at: date,
                                               overrideSession: nil)
        }
        self.lifecycle = lifecycle

        lifecycleData[TealiumDataKey.lifecycleAutotracked] = autotracked
        if migrated {
            requestTrack(data: lifecycleData)
        }
    }

    /// Prevent manual spanning of repeated lifecycle calls to system.
    ///
    /// - Parameter type: `LifecycleType`
    /// - Returns: `Bool` `true` if process should be allowed to continue
    public func lifecycleAcceptable(type: LifecycleType) -> Bool {
        switch type {
        case .launch:
            if enabledPrior == true || lastLifecycleEvent != nil {
                return false
            }
        case .sleep:
            if lastLifecycleEvent != .wake && lastLifecycleEvent != .launch {
                return false
            }
        case .wake:
            if lastLifecycleEvent != .sleep {
                return false
            }
        }
        return true
    }

    /// Lifecycle event detected.
    /// - Parameters:
    ///   - type: `LifecycleType` launch, sleep, wake
    ///   - date: `Date` of lifecycle event
    func lifecycleDetected(type: LifecycleType,
                           at date: Date = Date()) {
        guard lifecycleAcceptable(type: type) else {
            return
        }
        lastLifecycleEvent = type
        self.process(type: type, at: date, autotracked: true)
    }

    /// Sends a track request to the module delegate.
    ///
    /// - Parameter data: `[String: Any]` containing the lifecycle data to track
    func requestTrack(data: [String: Any]) {
        guard let title = data[TealiumDataKey.lifecycleType] as? String else {
            return
        }
        let dispatch = TealiumEvent(title, dataLayer: data)
        delegate?.requestTrack(dispatch.trackRequest)
    }
}
