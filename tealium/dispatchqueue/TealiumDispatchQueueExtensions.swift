//
//  TealiumDispatchQueueExtensions.swift
//  tealium-swift
//
//  Created by Craig Rouse on 22/07/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if dispatchqueue
import TealiumCore
#endif

#if os(iOS)
import UIKit
#else
#endif

public extension TealiumConfig {

    /// Sets the amount of events to combine into a single batch request. Maxiumum 10.
    ///
    /// - Parameter size: `Int` representing the max event batch size
    @available(*, deprecated, message: "Please switch to config.batchSize")
    func setBatchSize(_ size: Int) {
        batchSize = size
    }

    /// - Returns: `Int` containing the batch size to use. Defaults to 10 if not set
    @available(*, deprecated, message: "Please switch to config.batchSize")
    func getBatchSize() -> Int {
        batchSize
    }

    // config.batchSize in `Core` module, since it's required for remote publish settings

    /// Sets the number of events after which the queue will be flushed
    ///
    /// - Parameter events: `Int`
    @available(*, deprecated, message: "Please switch to config.dispatchAfter")
    func setDispatchAfter(numberOfEvents events: Int) {
        dispatchAfter = events
    }

    /// - Returns: `Int` - the number of events after which the queue will be flushed
    @available(*, deprecated, message: "Please switch to config.dispatchAfter")
    func getDispatchAfterEvents() -> Int? {
        dispatchAfter
    }

    /// The number of events after which the queue will be flushed
    var dispatchAfter: Int {
        get {
            optionalData[TealiumKey.eventLimit] as? Int ?? batchSize
        }

        set {
            optionalData[TealiumKey.eventLimit] = newValue
        }
    }

    /// Sets the maximum number of queued events. If this number is reached, and the queue has not been flushed, the oldest events will be deleted.
    ///
    /// - Parameter queueSize: `Int`
    @available(*, deprecated, message: "Please switch to config.dispatchQueueLimit")
    func setMaxQueueSize(_ queueSize: Int) {
        optionalData[TealiumKey.queueSizeKey] = queueSize
    }

    /// - Returns: `Int?` - the maximum queue size allowed to be stored on the device
    @available(*, deprecated, message: "Please switch to config.dispatchQueueLimit")
    func getMaxQueueSize() -> Int? {
        return optionalData[TealiumKey.eventLimit] as? Int
    }

    // config.dispatchQueueLimit in `Core` module, since it's required for remote publish settings

    /// Enables (`true`) or disables (`false`) event batching. Default `false`
    ///
    /// - Parameter enabled: `Bool`
    @available(*, deprecated, message: "Please switch to config.batchingEnabled")
    func setIsEventBatchingEnabled(_ enabled: Bool) {
        batchingEnabled = enabled
    }

    /// - Returns: `Bool` `true` if batching is enabled, else `false`
    @available(*, deprecated, message: "Please switch to config.batchingEnabled")
    func getIsEventBatchingEnabled() -> Bool {
        batchingEnabled ?? false
    }

    /// Sets a list of event names for which batching will be bypassed (sent as individual events)
    ///
    /// - Parameter keys: `[String]` containing the event names to be bypassed
    @available(*, deprecated, message: "Please switch to config.batchingBypassKeys")
    func setBatchingBypassKeys(_ keys: [String]) {
        batchingBypassKeys = keys
    }

    /// - Returns: `[String]?` containing a list of keys for which to bypass batching.
    @available(*, deprecated, message: "Please switch to config.batchingBypassKeys")
    func getBatchingBypassKeys() -> [String]? {
        batchingBypassKeys
    }

    var batchingBypassKeys: [String]? {
        get {
            optionalData[TealiumDispatchQueueConstants.batchingBypassKeys] as? [String]
        }

        set {
            optionalData[TealiumDispatchQueueConstants.batchingBypassKeys] = newValue
        }
    }

    /// Sets the batch expiration in days. If the device is offline for an extended period, events older than this will be deleted
    ///
    /// - Parameter days: `Int`
    @available(*, deprecated, message: "Please switch to config.dispatchExpiration")
    func setBatchExpirationDays(_ days: Int) {
        dispatchExpiration = days
    }

    /// - Returns: `Int` containing the maximum age of any track request in the queue
    @available(*, deprecated, message: "Please switch to config.dispatchExpiration")
    func getBatchExpirationDays() -> Int {
        dispatchExpiration ?? TealiumValue.defaultBatchExpirationDays
    }

    // config.dispatchExpiration in `Core` module, since it's required for remote publish settings

    #if os(iOS)
    /// Enables (`true`) or disables (`false`) `remote_api` event. Required for RemoteCommands module if DispatchQueue module in use.
    ///
    /// - Parameter enabled: `Bool`
    @available(*, deprecated, message: "Please switch to config.remoteAPIEnabled")
    func setIsRemoteAPIEnabled(_ enabled: Bool) {
        remoteAPIEnabled = enabled
    }

    /// - Returns: `Bool` if `remote_api` calls have been enabled (required for RemoteCommands module if DispatchQueue module in use).
    @available(*, deprecated, message: "Please switch to config.remoteAPIEnabled")
    func getIsRemoteAPIEnabled() -> Bool {
        remoteAPIEnabled ?? false
    }

    var remoteAPIEnabled: Bool? {
        get {
            optionalData[TealiumDispatchQueueConstants.isRemoteAPIEnabled] as? Bool
        }

        set {
            optionalData[TealiumDispatchQueueConstants.isRemoteAPIEnabled] = newValue
        }
    }
    #endif
}

extension TealiumDispatchQueueModule: TealiumLifecycleEvents {
    func sleep() {
        #if os(iOS)
        var backgroundTaskId: UIBackgroundTaskIdentifier?
            backgroundTaskId = TealiumDispatchQueueModule.sharedApplication?.beginBackgroundTask {
                if let taskId = backgroundTaskId {
                    TealiumDispatchQueueModule.sharedApplication?.endBackgroundTask(taskId)
                    backgroundTaskId = UIBackgroundTaskIdentifier(rawValue: convertFromUIBackgroundTaskIdentifier(UIBackgroundTaskIdentifier.invalid))
                }
            }

        TealiumQueues.backgroundSerialQueue.asyncAfter(deadline: DispatchTime.now() + 1.5) {
            self.releaseQueue()
        }
        if let taskId = backgroundTaskId {
            TealiumQueues.backgroundSerialQueue.asyncAfter(deadline: DispatchTime.now() + 3.0) {
                TealiumDispatchQueueModule.sharedApplication?.endBackgroundTask(taskId)
                backgroundTaskId = UIBackgroundTaskIdentifier(rawValue: convertFromUIBackgroundTaskIdentifier(UIBackgroundTaskIdentifier.invalid))
            }
        }
        #elseif os(watchOS)
        let pInfo = ProcessInfo()
        pInfo.performExpiringActivity(withReason: "Tealium Swift: Dispatch Queued Events") { willBeSuspended in
            if !willBeSuspended {
                TealiumQueues.backgroundSerialQueue.asyncAfter(deadline: DispatchTime.now() + 1.5) {
                    self.releaseQueue()
                }
            }
        }
        #else
        self.releaseQueue()
        #endif
    }

    func wake() {
        TealiumQueues.backgroundSerialQueue.asyncAfter(deadline: DispatchTime.now() + 3.0) {
            self.releaseQueue()
        }
    }

    func launch(at date: Date) {
        TealiumQueues.backgroundSerialQueue.asyncAfter(deadline: DispatchTime.now() + 3.0) {
            self.releaseQueue()
        }
    }

}
#if os(iOS)
// Helper function inserted by Swift 4.2 migrator.
private func convertFromUIBackgroundTaskIdentifier(_ input: UIBackgroundTaskIdentifier) -> Int {
	return input.rawValue
}
#endif
// Power state notifications
extension TealiumDispatchQueueModule {

    func registerForPowerNotifications() {
        #if os(macOS)
        self.lowPowerModeEnabled = false
        #else
        lowPowerNotificationObserver = NotificationCenter.default.addObserver(forName: .NSProcessInfoPowerStateDidChange, object: nil, queue: nil) { [weak self] _ in
            guard let self = self else {
                return
            }

            if ProcessInfo.processInfo.isLowPowerModeEnabled {
                self.lowPowerModeEnabled = true
            } else {
                self.lowPowerModeEnabled = false
                self.releaseQueue()
            }
        }
        #endif
    }

}
