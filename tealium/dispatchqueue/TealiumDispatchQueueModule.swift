//
//  TealiumDispatchQueueModule.swift
//  tealium-swift
//
//  Created by Craig Rouse on 4/9/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation
#if dispatchqueue
import TealiumCore
#endif
#if os(iOS)
import UIKit
#else
#endif

class TealiumDispatchQueueModule: TealiumModule {

    var persistentQueue: TealiumPersistentDispatchQueue!
    var diskStorage: TealiumDiskStorageProtocol!
    // when to start trimming the queue (default 20) - e.g. if offline
    var maxQueueSize = TealiumDispatchQueueConstants.defaultMaxQueueSize
     // max number of events in a single batch
    var maxDispatchSize = TealiumValue.maxEventBatchSize
    var eventsBeforeAutoDispatch = 1
    var isBatchingEnabled = true
    var batchingBypassKeys: [String]?
    var batchExpirationDays: Int = TealiumDispatchQueueConstants.defaultBatchExpirationDays

    #if os(iOS)
    class var sharedApplication: UIApplication? {
        let selector = NSSelectorFromString("sharedApplication")
        return UIApplication.perform(selector)?.takeUnretainedValue() as? UIApplication
    }
    #endif

    override class func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumDispatchQueueConstants.moduleName,
                                   priority: 1000,
                                   build: 1,
                                   enabled: true)
    }

    override func enable(_ request: TealiumEnableRequest) {
        enable(request, diskStorage: nil)
    }

    func enable(_ request: TealiumEnableRequest,
                diskStorage: TealiumDiskStorageProtocol? = nil) {
        batchingBypassKeys = request.config.getBatchingBypassKeys()
        // allows overriding for unit tests, independently of enable call
        if self.diskStorage == nil {
            self.diskStorage = diskStorage ?? TealiumDiskStorage(config: request.config, forModule: TealiumDispatchQueueConstants.moduleName)
        }
        persistentQueue = TealiumPersistentDispatchQueue(diskStorage: self.diskStorage)
        // release any previously-queued track requests
        if let maxSize = request.config.getMaxQueueSize() {
            maxQueueSize = maxSize
        }
        removeOldDispatches()
        eventsBeforeAutoDispatch = request.config.getDispatchAfterEvents()
        maxDispatchSize = request.config.getBatchSize()
        isBatchingEnabled = request.config.getIsEventBatchingEnabled()
        batchExpirationDays = request.config.getBatchExpirationDays()
        isEnabled = true
        Tealium.lifecycleListeners.addDelegate(delegate: self)
        didFinish(request)
    }

    override func handle(_ request: TealiumRequest) {
        switch request {
        case let request as TealiumEnableRequest:
            enable(request)
        case let request as TealiumDisableRequest:
            disable(request)
        case let request as TealiumTrackRequest:
            track(request)
        case let request as TealiumEnqueueRequest:
            queue(request)
        case _ as TealiumReleaseQueuesRequest:
            releaseQueue()
        case _ as TealiumClearQueuesRequest:
            clearQueue()
        default:
            didFinishWithNoResponse(request)
        }
    }

    func queue(_ request: TealiumEnqueueRequest) {
        guard isEnabled else {
            return
        }
        removeOldDispatches()
        let allTrackRequests = request.data

        allTrackRequests.forEach {
            var newData = $0.trackDictionary
            newData[TealiumKey.wasQueued] = "true"
            let newTrack = TealiumTrackRequest(data: newData,
                                               completion: $0.completion)
            persistentQueue.appendDispatch(newTrack)
        }
    }

    func removeOldDispatches() {
        guard isEnabled else {
            return
        }
        let currentDate = Date()
        var components = DateComponents()
        components.calendar = Calendar.autoupdatingCurrent
        components.setValue(-batchExpirationDays, for: .day)
        let sinceDate = Calendar(identifier: .gregorian).date(byAdding: components, to: currentDate)
        persistentQueue.removeOldDispatches(maxQueueSize, since: sinceDate)
    }

    func releaseQueue() {
        // may be nil if module not yet enabled
        guard isEnabled else {
            return
        }

        if let queuedDispatches = persistentQueue.dequeueDispatches() {
            let batches: [[TealiumTrackRequest]] = queuedDispatches.chunks(maxDispatchSize)

            batches.forEach { batch in

                switch batch.count {
                case let val where val <= 1:
                    if var data = batch.first?.trackDictionary {
                        // for all release calls, bypass the queue and send immediately
                        data += ["bypass_queue": true]
                        let request = TealiumTrackRequest(data: data, completion: nil)
                            delegate?.tealiumModuleRequests(module: self,
                                                            process: request)
                    }

                case let val where val > 1:
                    let batchRequest = TealiumBatchTrackRequest(trackRequests: batch, completion: nil)
                        delegate?.tealiumModuleRequests(module: self,
                                                        process: batchRequest)
                default:
                    // should never reach here
                    return
                }

            }
        }
    }

    func clearQueue() {
        guard isEnabled else {
            return
        }
        persistentQueue.clearQueue()
    }

    // swiftlint:disable function_body_length
    override func track(_ request: TealiumTrackRequest) {
        defer {
            if persistentQueue.currentEvents >= self.eventsBeforeAutoDispatch {
                releaseQueue()
            }
        }
        guard isEnabled else {
            didFinishWithNoResponse(request)
            return
        }

        let canWrite = diskStorage.canWrite()
        var data = request.trackDictionary
        var shouldBypass = false
        if data["bypass_queue"] as? Bool == true {
            shouldBypass = data.removeValue(forKey: "bypass_queue") as? Bool ?? false
        }
        let newTrack = TealiumTrackRequest(data: data, completion: request.completion)
        guard isBatchingEnabled else {
            self.didFinishWithNoResponse(newTrack)
            return
        }

        guard eventsBeforeAutoDispatch > 1 else {
            didFinishWithNoResponse(newTrack)
            return
        }

        guard canWrite else {
            let report = TealiumReportRequest(message: "Insufficient disk storage available. Event Batching has been disabled.")
            delegate?.tealiumModuleRequests(module: self, process: report)
            self.didFinishWithNoResponse(newTrack)
            return
        }

        guard maxDispatchSize > 1 else {
            didFinishWithNoResponse(newTrack)
            return
        }

        guard maxQueueSize > 1 else {
            didFinishWithNoResponse(newTrack)
            return
        }

        guard canQueueRequest(newTrack) else {
            releaseQueue()
            didFinishWithNoResponse(newTrack)
            return
        }

        guard !shouldBypass else {
            didFinishWithNoResponse(newTrack)
            return
        }
        // no conditions preventing queueing, so queue request
        var requestData = newTrack.trackDictionary
        requestData[TealiumKey.queueReason] = TealiumDispatchQueueConstants.batchingEnabled
        requestData[TealiumKey.wasQueued] = "true"
        let newRequest = TealiumTrackRequest(data: requestData, completion: newTrack.completion)
        persistentQueue.appendDispatch(newRequest)

        logQueue(request: newRequest)
    }
    // swiftlint:enable function_body_length

    func logQueue(request: TealiumTrackRequest) {
        let message = """
        \n=====================================
        ⏳ Event: \(request.trackDictionary[TealiumKey.event] as? String ?? "") queued for batch dispatch
        =====================================\n
        """
        let report = TealiumReportRequest(message: message)
        delegate?.tealiumModuleRequests(module: self, process: report)
    }

    func canQueueRequest(_ request: TealiumTrackRequest) -> Bool {
        guard let event = request.event() else {
            return false
        }
        var shouldQueue = true
        var bypassKeys = BypassDispatchQueueKeys.allCases.map { $0.rawValue }
        if let batchingBypassKeys = batchingBypassKeys {
            bypassKeys += batchingBypassKeys
        }
        for key in bypassKeys where key == event {
                shouldQueue = false
                break
        }

        return shouldQueue
    }
}
