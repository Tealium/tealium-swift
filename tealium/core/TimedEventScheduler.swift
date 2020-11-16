//
//  TimedEventScheduler.swift
//  TealiumCore
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol Schedulable {
    var events: Set<TimedEvent> { get }
    func handle(request: TealiumTrackRequest?) -> TealiumTrackRequest?
    func start(event name: String, with data: [String: Any]?)
    func stop(event name: String, with request: TealiumTrackRequest?) -> TealiumTrackRequest?
    func cancel(event name: String)
    func clearAll()
}

public enum TimedEventError: Error {
    case eventNotFound
    case couldNotStopEvent
}

public class TimedEventScheduler: Schedulable {

    var config: TealiumConfig
    public var events: Set<TimedEvent>
    
    public init(config: TealiumConfig, events: Set<TimedEvent> = Set<TimedEvent>()) {
        self.config = config
        self.events = events
    }
    
    public func handle(request: TealiumTrackRequest?) -> TealiumTrackRequest? {
        guard let event = request?.event else {
            log(message: "Tealium event not defined")
            return nil
        }
        var newRequest: TealiumTrackRequest?
        config.timedEventTriggers?.forEach { trigger in
            let name = "\(trigger.start)::\(trigger.stop)"
            if event == trigger.start  {
                self.start(event: name)
            } else if event == trigger.stop {
                newRequest = self.stop(event: name, with: request)
            }
        }
        return newRequest
    }
    
    public func start(event name: String, with data: [String: Any]? = nil) {
        let timedEvent = TimedEvent(name: name, data: data)
        guard events[name] == nil else {
            log(message: "Event already started")
            return
        }
        events.insert(timedEvent)
    }
    
    @discardableResult
    public func stop(event name: String, with request: TealiumTrackRequest? = nil) -> TealiumTrackRequest? {
        guard var timedEvent = events[name],
              let newRequest = timedEvent.stopTimer(with: request) else {
            log(message: "Could not stop event", level: .error)
            return nil
        }
        return newRequest
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
