//
//  TimedEventScheduler.swift
//  TealiumCore
//
//  Created by Christina S on 11/12/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol Schedulable {
    func handle(request: inout TealiumTrackRequest)
    func start(event name: String)
    func stop(event name: String, with request: inout TealiumTrackRequest)
    func cancel(event name: String)
    func clearAll()
}

public enum TimedEventError: Error {
    case eventNotFound
    case couldNotStopEvent
}

public class TimedEventScheduler: Schedulable {

    var config: TealiumConfig
    var events: Set<TimedEvent>
    
    public init(config: TealiumConfig, events: Set<TimedEvent> = Set<TimedEvent>()) {
        self.config = config
        self.events = events
    }
    
    public func handle(request: inout TealiumTrackRequest) {
        guard let event = request.event else {
            log(message: "Tealium event not defined")
            return
        }
        config.timedEventTriggers?.forEach { trigger in
            let name = "\(trigger.start)::\(trigger.stop)"
            if event == trigger.start  {
                self.start(event: name)
            } else if event == trigger.stop {
                self.stop(event: name, with: &request)
            }
        }
    }
    
    public func start(event name: String) {
        let timedEvent = TimedEvent(name: name)
        guard events[name] == nil else {
            log(message: "Event already started")
            return
        }
        events.insert(timedEvent)
    }
    
    public func stop(event name: String, with request: inout TealiumTrackRequest) {
        //var event = TimedEvent(name: name, data: request.trackDictionary)
        guard var timedEvent = events[name],
              let newRequest = timedEvent.stopTimer(with: request) else {
            log(message: "Could not stop event", level: .error)
            return
        }
        request = newRequest
    }
    
    public func cancel(event name: String) {
        guard let event = events[name] else {
            log(message: "Event not found")
            return
        }
        events.remove(event)
    }
    
    public func clearAll() {
        events.removeAll()
    }
    
    private func log(message: String, level: TealiumLogLevel = .debug) {
        let request = TealiumLogRequest(title: "Timed Events",
                                        message: message,
                                        logLevel: level,
                                        category: .general)
        config.logger?.log(request)
    }
    
}
