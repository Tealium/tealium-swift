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
    func setBatchSize(_ size: Int) {
        let size = size > TealiumValue.maxEventBatchSize ? TealiumValue.maxEventBatchSize: size
        optionalData[TealiumDispatchQueueConstants.batchSizeKey] = size
    }

    /// - Returns: `Int` containing the batch size to use. Defaults to 10 if not set
    func getBatchSize() -> Int {
        return optionalData[TealiumDispatchQueueConstants.batchSizeKey] as? Int ?? TealiumValue.maxEventBatchSize
    }

    /// Sets the number of events after which the queue will be flushed
    ///
    /// - Parameter events: `Int`
    func setDispatchAfter(numberOfEvents events: Int) {
        optionalData[TealiumDispatchQueueConstants.eventLimit] = events
    }

    /// - Returns: `Int` - the number of events after which the queue will be flushed
    func getDispatchAfterEvents() -> Int {
        return optionalData[TealiumDispatchQueueConstants.eventLimit] as? Int ?? getBatchSize()
    }

    /// Sets the maximum number of queued events. If this number is reached, and the queue has not been flushed, the oldest events will be deleted.
    ///
    /// - Parameter queueSize: `Int`
    func setMaxQueueSize(_ queueSize: Int) {
        optionalData[TealiumDispatchQueueConstants.queueSizeKey] = queueSize
    }

    /// - Returns: `Int?` - the maximum queue size allowed to be stored on the device
    func getMaxQueueSize() -> Int? {
        return optionalData[TealiumDispatchQueueConstants.queueSizeKey] as? Int
    }

    /// Enables (`true`) or disables (`false`) event batching. Default `false`
    ///
    /// - Parameter enabled: `Bool`
    func setIsEventBatchingEnabled(_ enabled: Bool) {
        // batching requires disk storage
        guard isDiskStorageEnabled() == true else {
            optionalData[TealiumDispatchQueueConstants.batchingEnabled] = false
            return
        }
        optionalData[TealiumDispatchQueueConstants.batchingEnabled] = enabled
    }

    /// - Returns: `Bool` `true` if batching is enabled, else `false`
    func getIsEventBatchingEnabled() -> Bool {
        // batching requires disk storage
        guard isDiskStorageEnabled() == true else {
            return false
        }
        return optionalData[TealiumDispatchQueueConstants.batchingEnabled] as? Bool ?? false
    }

    /// Sets a list of event names for which batching will be bypassed (sent as individual events)
    ///
    /// - Parameter keys: `[String]` containing the event names to be bypassed
    func setBatchingBypassKeys(_ keys: [String]) {
        self.optionalData[TealiumDispatchQueueConstants.batchingBypassKeys] = keys
    }

    /// - Returns: `[String]?` containing a list of keys for which to bypass batching.
    func getBatchingBypassKeys() -> [String]? {
        return self.optionalData[TealiumDispatchQueueConstants.batchingBypassKeys] as? [String]
    }

    /// Sets the batch expiration in days. If the device is offline for an extended period, events older than this will be deleted
    ///
    /// - Parameter days: `Int`
    func setBatchExpirationDays(_ days: Int) {
        self.optionalData[TealiumDispatchQueueConstants.batchExpirationDaysKey] = days
    }

    /// - Returns: `Int` containing the maximum age of any track request in the queue
    func getBatchExpirationDays() -> Int {
        return self.optionalData[TealiumDispatchQueueConstants.batchExpirationDaysKey] as? Int ?? TealiumDispatchQueueConstants.defaultBatchExpirationDays
    }

    #if os(iOS)
    /// Enables (`true`) or disables (`false`) `remote_api` event. Required for RemoteCommands module if DispatchQueue module in use.
    ///
    /// - Parameter enabled: `Bool`
    func setIsRemoteAPIEnabled(_ enabled: Bool) {
        self.optionalData[TealiumDispatchQueueConstants.isRemoteAPIEnabled] = enabled
    }

    /// - Returns: `Bool` if `remote_api` calls have been enabled (required for RemoteCommands module if DispatchQueue module in use).
    func getIsRemoteAPIEnabled() -> Bool {
        return self.optionalData[TealiumDispatchQueueConstants.isRemoteAPIEnabled] as? Bool ?? false
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
                    backgroundTaskId = UIBackgroundTaskInvalid
                }
            }

        TealiumQueues.backgroundSerialQueue.asyncAfter(deadline: DispatchTime.now() + 1.5) {
            self.releaseQueue()
        }
        if let taskId = backgroundTaskId {
            TealiumQueues.backgroundSerialQueue.asyncAfter(deadline: DispatchTime.now() + 3.0) {
                TealiumDispatchQueueModule.sharedApplication?.endBackgroundTask(taskId)
                backgroundTaskId = UIBackgroundTaskInvalid
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
