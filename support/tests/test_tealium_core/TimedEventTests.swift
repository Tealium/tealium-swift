//
//  TimedEventTests.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
import XCTest

class TimedEventTests: XCTestCase {
    
    var event: TimedEvent!
    var request: TealiumTrackRequest!
    var timeTraveler = TimeTraveler()

    override func setUpWithError() throws {
        request = TealiumTrackRequest(data: ["test_event": "test_event_value"])
    }
    
    func testEventInfoReturnsExpectedData() {
        let mockStartTime = timeTraveler.travel(by: -60).timeIntervalSince1970 // 1 minute in future
        let expectedKeys = ["test_event", "timed_event_name", "timed_event_start", "timed_event_end", "timed_event_duration"]
        event = TimedEvent(name: "mockTimedEvent", start: mockStartTime)
        event.data = ["test_event": "test_event_value"]
        event.stop = Date().timeIntervalSince1970
        event.duration = 60000.0
        let actual = event.eventInfo
        expectedKeys.forEach {
            XCTAssertNotNil(actual[$0])
        }
        XCTAssertEqual(actual[TealiumKey.timedEventName] as! String, "mockTimedEvent")
        XCTAssertEqual(actual[TealiumKey.eventStart] as! Int64, mockStartTime.milliseconds)
        let duration = actual[TealiumKey.eventDuration] as! Int64
        XCTAssert(duration >= 60000)
    }

    func testStopTimerSetsData() {
        let mockStartTime = timeTraveler.travel(by: -60).timeIntervalSince1970 // 1 minute in future
        event = TimedEvent(name: "mockTimedEvent", data: ["hello": "world"], start: mockStartTime)
        event.stopTimer()
        XCTAssertEqual(event.name, "mockTimedEvent")
        XCTAssertEqual(event.start, mockStartTime)
        XCTAssertNotNil(event.stop)
        XCTAssertTrue(event.duration! >= 60)
        XCTAssertTrue(event.data!.equal(to: ["hello": "world"]))
    }
    
    func testStopTimerDoesntSetDurationWhenNoStartTime() {
        event = TimedEvent(name: "mockTimedEvent")
        event.start = nil
        XCTAssertNil(event.duration)
    }
    
    func testEventInfoReturnsEmptyDictionaryWhenNoData() {
        event = TimedEvent(name: "mockTimedEvent")
        XCTAssertEqual(event.eventInfo.count, 0)
    }
    
    func testEventInfoReturnsEmptyDictionaryWhenNoStartTime() {
        event = TimedEvent(name: "mockTimedEvent")
        event.start = nil
        XCTAssertEqual(event.eventInfo.count, 0)
    }
    
    func testEventInfoReturnsEmptyDictionaryWhenNoStopTime() {
        event = TimedEvent(name: "mockTimedEvent")
        event.stop = nil
        XCTAssertEqual(event.eventInfo.count, 0)
    }
    
    func testTimedEventEquatable() {
        event = TimedEvent(name: "mockTimedEvent")
        let event2 = TimedEvent(name: "mockTimedEvent")
        XCTAssert(event == event2)
    }
    
    func testSubscriptExtension() {
        event = TimedEvent(name: "mockTimedEvent")
        var events = Set<TimedEvent>()
        events.insert(event)
        XCTAssertNotNil(events[event.name])
        XCTAssertNil(events["Nonexistent"])
    }

}

fileprivate extension Dictionary where Key == String, Value == Any {
    func equal(to dictionary: [String: Any] ) -> Bool {
        NSDictionary(dictionary: self).isEqual(to: dictionary)
    }
}
