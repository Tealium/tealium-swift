//
//  TimedEvent.swift
//  TealiumCore
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public struct TimedEventTrigger {
    var start: String
    var stop: String
    
    public init(start: String, stop: String) {
        self.start = start
        self.stop = stop
    }
}

public struct TimedEvent: Hashable {

    var start: TimeInterval?
    var name: String
    var stop: TimeInterval?
    var duration: TimeInterval?
    var data: [String: Any]?

    public init(name: String) {
        self.name = name
        self.start = Date().timeIntervalSince1970
    }

    public mutating func stopTimer(with request: TealiumTrackRequest?) -> TealiumTrackRequest? {
        self.data = request?.trackDictionary
        stop = Date().timeIntervalSince1970
        guard let start = start,
              let stop = stop else {
                return nil
        }
        self.duration = (stop - start) * 1000
        return trackRequest
    }

    public var trackRequest: TealiumTrackRequest? {
        guard var data = data,
              let start = start,
              let stop = stop,
              let duration = duration else {
                return nil
        }
        data[TealiumKey.timedEventName] = self.name
        data[TealiumKey.eventStart] = start
        data[TealiumKey.eventStop] = stop
        data[TealiumKey.eventDuration] = duration
        return TealiumTrackRequest(data: data)
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
