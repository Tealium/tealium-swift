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
    func setBatchSize(_ size: Int) {
        let size = size > TealiumValue.maxEventBatchSize ? TealiumValue.maxEventBatchSize: size
        optionalData[TealiumDispatchQueueConstants.batchSizeKey] = size
    }

    func getBatchSize() -> Int {
        return optionalData[TealiumDispatchQueueConstants.batchSizeKey] as? Int ?? TealiumValue.maxEventBatchSize
    }

    func setDispatchAfter(numberOfEvents events: Int) {
        optionalData[TealiumDispatchQueueConstants.eventLimit] = events
    }

    func getDispatchAfterEvents() -> Int {
        return optionalData[TealiumDispatchQueueConstants.eventLimit] as? Int ?? getBatchSize()
    }

    func setMaxQueueSize(_ queueSize: Int) {
        optionalData[TealiumDispatchQueueConstants.queueSizeKey] = queueSize
    }

    func getMaxQueueSize() -> Int? {
        return optionalData[TealiumDispatchQueueConstants.queueSizeKey] as? Int
    }

    func setIsEventBatchingEnabled(_ enabled: Bool) {
        // batching requires disk storage
        guard isDiskStorageEnabled() == true else {
            optionalData[TealiumDispatchQueueConstants.batchingEnabled] = false
            return
        }
        optionalData[TealiumDispatchQueueConstants.batchingEnabled] = enabled
    }

    func getIsEventBatchingEnabled() -> Bool {
        // batching requires disk storage
        guard isDiskStorageEnabled() == true else {
            return false
        }
        return optionalData[TealiumDispatchQueueConstants.batchingEnabled] as? Bool ?? true
    }

    func setBatchingBypassKeys(_ keys: [String]) {
        self.optionalData[TealiumDispatchQueueConstants.batchingBypassKeys] = keys
    }

    func getBatchingBypassKeys() -> [String]? {
        return self.optionalData[TealiumDispatchQueueConstants.batchingBypassKeys] as? [String]
    }

    func setBatchExpirationDays(_ days: Int) {
        self.optionalData[TealiumDispatchQueueConstants.batchExpirationDaysKey] = days
    }

    func getBatchExpirationDays() -> Int {
        return self.optionalData[TealiumDispatchQueueConstants.batchExpirationDaysKey] as? Int ?? TealiumDispatchQueueConstants.defaultBatchExpirationDays
    }

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
