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
    
    /// Start a timed event
    /// - Parameters:
    ///   - name: `String` name of the timed event
    ///   - data: `[String: Any` optional data to passed along with the dispatch sent on `endTimedEvent`
    func startTimedEvent(name: String, with data: [String: Any]?) {
        timedEventScheduler?.start(event: name, with: data)
    }
    
    /// End a particular timed event by name
    /// - Parameter name: `String` name provided in the `startTimedEvent` call
    func endTimedEvent(name: String) {
        timedEventScheduler?.stop(event: name)
        let timedEventInfo = timedEventScheduler?.timedEventInfo(for: name)
        track(TealiumEvent(TealiumValue.timedEvent, dataLayer: timedEventInfo))
    }
    
    /// Cancel a particular timed event by name
    /// - Parameter name: `String` name provided in the `startTimedEvent` call
    func cancelTimedEvent(name: String) {
        timedEventScheduler?.cancel(event: name)
    }
    
    /// Clear all the existing timed events
    func clearAllTimedEvents() {
        timedEventScheduler?.clearAll()
    }  
}
