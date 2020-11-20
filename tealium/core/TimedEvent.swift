//
//  TimedEvent.swift
//  TealiumCore
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public struct TimedEventTrigger {
    var start: String
    var end: String
    var name: String?
    
    public init(start: String, end: String, name: String? = nil) {
        self.start = start
        self.end = end
        self.name = name
    }
}

public struct TimedEvent: Hashable {

    var start: TimeInterval?
    var name: String
    var stop: TimeInterval?
    var duration: TimeInterval?
    var data: [String: Any]?

    public init(name: String,
                data: [String: Any]? = nil,
                start: TimeInterval = Date().timeIntervalSince1970) {
        self.name = name
        self.data = data ?? [String: Any]()
        self.start = start
    }
    
    public mutating func stopTimer() {
        stop = Date().timeIntervalSince1970
        guard let start = start,
              let stop = stop else {
                return
        }
        self.duration = stop - start
    }

    public var eventInfo: [String: Any] {
        guard var data = data,
              let start = start?.milliseconds,
              let stop = stop?.milliseconds,
              let duration = duration?.milliseconds else {
            return [String: Any]()
        }
        data[TealiumKey.timedEventName] = self.name
        data[TealiumKey.eventStart] = start
        data[TealiumKey.eventStop] = stop
        data[TealiumKey.eventDuration] = duration
        return data
    }
    
    public static func ==(lhs: TimedEvent, rhs: TimedEvent) -> Bool {
        lhs.name == rhs.name
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
}

public extension Set where Element == TimedEvent {
    subscript(_ name: String) -> TimedEvent? {
        return self.first { event -> Bool in
            event.name == name
        }
    }
}
