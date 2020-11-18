//
//  TimedEventScheduler.swift
//  TealiumCore
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol Schedulable {
    var events: Set<TimedEvent> { get }
    func handle(request: inout TealiumTrackRequest)
    func start(event name: String, with data: [String: Any]?)
    func stop(event name: String)
    func timedEventInfo(for event: String) -> [String: Any]
    func update(request: inout TealiumTrackRequest, for event: String)
    func cancel(event name: String)
    func clearAll()
}

public class TimedEventScheduler: Schedulable {

    var config: TealiumConfig
    public var events: Set<TimedEvent>

    
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
                self.start(event: trigger.name ?? name)
            } else if event == trigger.stop {
                self.stop(event: name)
                self.update(request: &request, for: name)
            }
        }
    }
    
    public func start(event name: String, with data: [String: Any]? = [String: Any]()) {
        let timedEvent = TimedEvent(name: name, data: data)
        guard events[name] == nil else {
            log(message: "Event already started", level: .debug)
            return
        }
        events.insert(timedEvent)
    }
    
    public func stop(event name: String) {
        guard var timedEvent = events[name] else {
            log(message: "Event not found")
            return
        }
        timedEvent.stopTimer()
        events.remove(timedEvent)
        events.insert(timedEvent)
    }
    
    public func update(request: inout TealiumTrackRequest, for event: String) {
        guard let timedEvent = events[event] else {
            log(message: "Event not found")
            return
        }
        var trackInfo = request.trackDictionary
        trackInfo += timedEvent.eventInfo
        request = TealiumTrackRequest(data: trackInfo)
    }
    
    public func timedEventInfo(for event: String) -> [String: Any] {
        guard let timedEvent = events[event] else {
            log(message: "Event not found")
            return [String: Any]()
        }
        return timedEvent.eventInfo
    }
    
    public func cancel(event name: String) {
        guard let event = events[name] else {
            log(message: "Event not found", level: .debug)
            return
        }
        events.remove(event)
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
        config.logger?.log(request)
    }
    
}
