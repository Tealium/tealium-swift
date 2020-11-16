//
//  TimedEvent+Tealium.swift
//  TealiumCore
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public extension Tealium {
    
    var timedEventScheduler: Schedulable? {
        get {
            zz_internal_modulesManager?.dispatchManager?.timedEventScheduler
        }
        set {
            zz_internal_modulesManager?.dispatchManager?.timedEventScheduler = newValue
        }
    }
    
    func startTimedEvent(name: String, with data: [String: Any]?) {
        timedEventScheduler?.start(event: name, with: data)
    }
    
    func stopTimedEvent(name: String) {
        guard let request = timedEventScheduler?.stop(event: name, with: nil) else {
            return
        }
        let tealiumEvent = TealiumEvent(name, dataLayer: request.trackDictionary)
        track(tealiumEvent)
    }
    
    func cancelTimedEvent(name: String) {
        timedEventScheduler?.cancel(event: name)
    }
    
    func clearAllTimedEvents() {
        timedEventScheduler?.clearAll()
    }  
}
