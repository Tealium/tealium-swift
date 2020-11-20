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
            zz_internal_modulesManager?.dispatchValidators
                .filter { $0 is Schedulable }.first as? Schedulable
        }
    }
    
    /// Start a timed event
    /// - Parameters:
    ///   - name: `String` name of the timed event
    ///   - data: `[String: Any]` optional data to passed along with the dispatch sent on `stopTimedEvent`
    func startTimedEvent(name: String, with data: [String: Any]? = nil) {
        timedEventScheduler?.start(event: name, with: data)
    }
    
    /// End a particular timed event by name
    /// - Parameter name: `String` name provided in the `startTimedEvent` call
    func stopTimedEvent(name: String) {
        guard let event = timedEventScheduler?.stop(event: name) else {
            return
        }
        timedEventScheduler?.sendTimedEvent(event)
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
