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
    
    func testTrackRequestReturnsExpectedData() {
        let mockStartTime = timeTraveler.travel(by: -60).timeIntervalSince1970 // 1 minute in future
        let expectedKeys = ["test_event", "timed_event_name", "timed_event_start", "timed_event_stop", "request_uuid"]
        event = TimedEvent(name: "mockTimedEvent", start: mockStartTime)
        event.data = ["test_event": "test_event_value"]
        event.stop = Date().timeIntervalSince1970
        event.duration = 60000.0
        let actual = event.trackRequest
        expectedKeys.forEach {
            XCTAssertNotNil(actual?.trackDictionary[$0])
        }
        XCTAssertEqual(actual?.trackDictionary[TealiumKey.timedEventName] as! String, "mockTimedEvent")
        XCTAssertEqual(actual?.trackDictionary[TealiumKey.eventStart] as! TimeInterval, mockStartTime)
        let duration = actual?.trackDictionary[TealiumKey.eventDuration] as! Double
        XCTAssert(duration >= 60000.0)
    }

    func testStopTimerReturnsExpectedData() {
        let mockStartTime = timeTraveler.travel(by: -60).timeIntervalSince1970 // 1 minute in future
        let expectedKeys = ["test_event", "timed_event_name", "timed_event_start", "timed_event_stop", "request_uuid"]
        event = TimedEvent(name: "mockTimedEvent", start: mockStartTime)
        let actual = event.stopTimer(with: request)
        expectedKeys.forEach {
            XCTAssertNotNil(actual?.trackDictionary[$0])
        }
        XCTAssertEqual(actual?.trackDictionary[TealiumKey.timedEventName] as! String, "mockTimedEvent")
        XCTAssertEqual(actual?.trackDictionary[TealiumKey.eventStart] as! TimeInterval, mockStartTime)
        let duration = actual?.trackDictionary[TealiumKey.eventDuration] as! Double
        XCTAssert(duration >= 60000.0)
    }
    
    func testTrackRequestReturnsNilWhenNoData() {
        event = TimedEvent(name: "mockTimedEvent")
        let actual = event.trackRequest
        XCTAssertNil(actual)
    }
    
    func testTrackRequestReturnsNilWhenNoStartTime() {
        event = TimedEvent(name: "mockTimedEvent")
        event.start = nil
        let actual = event.trackRequest
        XCTAssertNil(actual)
    }
    
    func testTrackRequestReturnsNilWhenNoStopTime() {
        event = TimedEvent(name: "mockTimedEvent")
        event.stop = nil
        let actual = event.trackRequest
        XCTAssertNil(actual)
    }
    
    func testStopTimerReturnsNilWhenNoStartTime() {
        event = TimedEvent(name: "mockTimedEvent")
        event.start = nil
        let actual = event.stopTimer(with: request)
        XCTAssertNil(actual)
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
