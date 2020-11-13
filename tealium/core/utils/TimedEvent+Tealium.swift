//
//  TimedEvent+Tealium.swift
//  TealiumCore
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public extension Tealium {
    
    var timedEventScheduler: Schedulable? {
        zz_internal_modulesManager?.dispatchManager?.timedEventScheduler
    }
    
    func startTimedEvent(name: String, _ dispatch: TealiumDispatch) {
        timedEventScheduler?.start(event: name)
        track(dispatch)
    }
    
    func stopTimedEvent(name: String, _ dispatch: TealiumDispatch) {
        guard let tealiumEvent = dispatch.trackRequest.event else {
            return
        }
        var request = TealiumTrackRequest(data: dispatch.trackRequest.trackDictionary)
        timedEventScheduler?.stop(event: name, with: &request)
        track(TealiumEvent(tealiumEvent, dataLayer: request.trackDictionary))
    }
    
    func cancelTimedEvent(name: String) {
        timedEventScheduler?.cancel(event: name)
    }
    
    func clearAllTimedEvents() {
        timedEventScheduler?.clearAll()
    }  
}
