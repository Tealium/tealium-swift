//
//  TimedEventScheduler.swift
//  TealiumCore
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol Schedulable: DispatchValidator {
    var events: [String: TimedEvent] { get }
    func sendTimedEvent(_ event: TimedEvent)
    func start(event name: String, with data: [String: Any]?)
    func stop(event name: String) -> TimedEvent?
    func cancel(event name: String)
    func clearAll()
}

public class TimedEventScheduler: Schedulable {

    public var id: String = "TimedEventScheduler"
    var context: TealiumContextProtocol
    public var events: [String: TimedEvent]

    public init(context: TealiumContextProtocol,
                events: [String: TimedEvent] = [String: TimedEvent]()) {
        self.context = context
        self.events = events
    }
    
    public func shouldQueue(request: TealiumRequest) -> (Bool, [String : Any]?) {
        
        guard let dispatch = request as? TealiumTrackRequest else {
            return(false, nil)
        }
        
        guard let triggers = context.config.timedEventTriggers else {
            return (false, nil)
        }
        
        guard let event = dispatch.event else {
            return (false, nil)
        }
        
        triggers.forEach { trigger in
            let name = "\(trigger.start)::\(trigger.end)"
            if event == trigger.start  {
                self.start(event: trigger.name ?? name)
            } else if event == trigger.end {
                guard let event = self.stop(event: name) else {
                    return
                }
                self.sendTimedEvent(event)
            }
        }
        
        return (false, nil)
    }
    
    public func shouldDrop(request: TealiumRequest) -> Bool {
        return false
    }
    
    public func shouldPurge(request: TealiumRequest) -> Bool {
        return false
    }
    
    public func start(event name: String,
                      with data: [String: Any]? = [String: Any]()) {
        let timedEvent = TimedEvent(name: name, data: data)
        guard events[name] == nil else {
            log(message: "Event already started", level: .debug)
            return
        }
        events[name] = timedEvent
    }
    
    public func stop(event name: String) -> TimedEvent? {
        guard var timedEvent = events[name] else {
            log(message: "Event not found")
            return nil
        }
        timedEvent.stopTimer()
        events[name] = timedEvent
        return timedEvent
    }
    
    public func sendTimedEvent(_ event: TimedEvent) {
        events[event.name] = nil
        let dispatch = TealiumEvent(TealiumValue.timedEvent,
                                    dataLayer: event.eventInfo)
        context.track(dispatch)
    }
    
    public func cancel(event name: String) {
        events[name] = nil
    }
    
    public func clearAll() {
        events.removeAll()
    }
    
    private func log(message: String,
                     level: TealiumLogLevel = .error) {
        let request = TealiumLogRequest(title: "Timed Events",
                                        message: message,
                                        logLevel: level,
                                        category: .general)
        context.config.logger?.log(request)
    }
    
}
