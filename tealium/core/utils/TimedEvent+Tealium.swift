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
        timedEventScheduler?.stop(event: name)
        let timedEventInfo = timedEventScheduler?.timedEventInfo(for: name)
        track(TealiumEvent(TealiumValue.timedEvent, dataLayer: timedEventInfo))
    }
    
    func cancelTimedEvent(name: String) {
        timedEventScheduler?.cancel(event: name)
    }
    
    func clearAllTimedEvents() {
        timedEventScheduler?.clearAll()
    }  
}
