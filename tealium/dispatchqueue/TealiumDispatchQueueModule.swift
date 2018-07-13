//
//  TealiumDispatchQueueModule.swift
//  tealium-swift
//
//  Created by Craig Rouse on 09/04/2018.
//  Copyright © 2018 Tealium. All rights reserved.
//

import Foundation

class TealiumDispatchQueueModule: TealiumModule {

    var persistentQueue: TealiumPersistentDispatchQueue?
    var maxQueueSize = TealiumDispatchQueueConstants.defaultMaxQueueSize

    override class func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumDispatchQueueConstants.moduleName,
                                   priority: 1000,
                                   build: 1,
                                   enabled: true)
    }

    override func enable(_ request: TealiumEnableRequest) {
        persistentQueue = TealiumPersistentDispatchQueue(request.config)
        // release any previously-queued track requests
        if let maxSize = request.config.getMaxQueueSize() {
            maxQueueSize = maxSize
        }
        releaseQueue(request)
        isEnabled = true
        didFinish(request)
    }

    override func handle(_ request: TealiumRequest) {
        if let request = request as? TealiumEnableRequest {
            enable(request)
        } else if let request = request as? TealiumDisableRequest {
            disable(request)
        } else if let request = request as? TealiumTrackRequest {
            track(request)
        } else if let request = request as? TealiumEnqueueRequest {
            queue(request)
        } else if let request = request as? TealiumReleaseQueuesRequest {
            releaseQueue(request)
        } else if let request = request as? TealiumClearQueuesRequest {
            clearQueue(request)
        } else {
            didFinishWithNoResponse(request)
        }
    }

    func queue(_ request: TealiumEnqueueRequest) {
        removeOldDispatches()
        let track = request.data
        var newData = track.data
        newData[TealiumKey.wasQueued] = "true"
        let newTrack = TealiumTrackRequest(data: newData,
                                           completion: track.completion)
        persistentQueue?.saveDispatch(newTrack)
    }

    func removeOldDispatches() {
        persistentQueue?.removeOldDispatches(maxQueueSize)
    }

    func releaseQueue(_ request: TealiumRequest) {
        persistentQueue?.dequeueDispatches()?.forEach({ data in
            let track = TealiumTrackRequest(data: data, completion: request.completion)
            delegate?.tealiumModuleRequests(module: self,
                                                 process: track)
        })
    }

    func clearQueue(_ request: TealiumRequest) {
        persistentQueue?.clearQueue()
    }

}

public extension TealiumConfig {
    func setMaxQueueSize(_ queueSize: Int) {
        optionalData[TealiumDispatchQueueConstants.queueSizeKey] = queueSize
    }
    func getMaxQueueSize() -> Int? {
        return optionalData[TealiumDispatchQueueConstants.queueSizeKey] as? Int
    }
}
