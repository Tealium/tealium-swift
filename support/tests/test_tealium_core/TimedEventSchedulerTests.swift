//
//  TimedEventSchedulerTests.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import TealiumCore

class TimedEventSchedulerTests: XCTestCase {

    var config: TealiumConfig?
    var timedEventScheduler: Schedulable?
    var events: Set<TimedEvent>?
    var tealium: Tealium?

    override func setUpWithError() throws {
        events = Set<TimedEvent>()
    }

    func testHandleStartsTimedEvent()  {
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        config!.timedEventTriggers = [TimedEventTrigger(start: "start_event", end: "stop_event")]
        timedEventScheduler = TimedEventScheduler(config: config!)
        var request = TealiumTrackRequest(data: ["tealium_event": "start_event"])
        timedEventScheduler?.handle(request: &request)
        guard let event = timedEventScheduler?.events.first else {
            XCTFail("Event does not exist")
            return
        }
        XCTAssertNotNil(event.start)
    }
    
    func testHandleStopsTimedEvent()  {
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        config!.timedEventTriggers = [TimedEventTrigger(start: "start_event", end: "stop_event")]
        timedEventScheduler = TimedEventScheduler(config: config!)
        var request = TealiumTrackRequest(data: ["tealium_event": "start_event"])
        timedEventScheduler?.handle(request: &request)
        request = TealiumTrackRequest(data: ["tealium_event": "stop_event"])
        timedEventScheduler!.handle(request: &request)
        XCTAssertNotNil(request.trackDictionary["timed_event_end"])
    }
    
    func testHandleReturnsWhenTealiumEventNil() {
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        config!.timedEventTriggers = [TimedEventTrigger(start: "start_event", end: "stop_event")]
        timedEventScheduler = TimedEventScheduler(config: config!)
        var request = TealiumTrackRequest(data: ["non_tealium_event": "stop_event"])
        _ = timedEventScheduler?.handle(request: &request)
        XCTAssertNil(timedEventScheduler?.events.first)
    }
    
    func testStartInsertsNewEvent() {
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        timedEventScheduler = TimedEventScheduler(config: config!)
        timedEventScheduler?.start(event: "testEvent", with: nil)
        guard let event = timedEventScheduler?.events.first else {
            XCTFail("Event does not exist")
            return
        }
        XCTAssertEqual(event.name, "testEvent")
    }
    
    func testStartReturnsWhenEventExists() {
        let existsingEvent = TimedEvent(name: "testEvent")
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        timedEventScheduler = TimedEventScheduler(config: config!, events: [existsingEvent])
        timedEventScheduler?.start(event: "testEvent", with: nil)
        guard let event = timedEventScheduler?.events.first else {
            XCTFail("Event does not exist")
            return
        }
        XCTAssertEqual(timedEventScheduler?.events.count, 1)
        XCTAssertEqual(event.name, "testEvent")
    }
    
    func testStopCallsStopTimerWhenEventExists() {
        let existsingEvent = TimedEvent(name: "testEvent")
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        timedEventScheduler = TimedEventScheduler(config: config!, events: [existsingEvent])
        timedEventScheduler?.stop(event: "testEvent")
        let updatedEvent = timedEventScheduler?.events["testEvent"]
        XCTAssertNotNil(updatedEvent?.stop)
    }
    
    func testStopReturnsNilWhenTimedEventDoesntExist() {
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        timedEventScheduler = TimedEventScheduler(config: config!)
        timedEventScheduler?.stop(event: "testEvent")
        timedEventScheduler?.events.forEach {
            XCTAssertNil($0.stop)
        }
    }
    
    func testCancelRemovesEventWhenExists() {
        let existingEvent = TimedEvent(name: "testEvent")
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        timedEventScheduler = TimedEventScheduler(config: config!, events: [existingEvent])
        timedEventScheduler?.cancel(event: "testEvent")
        XCTAssertEqual(timedEventScheduler?.events.count, 0)
    }
    
    func testUpdateAddsExpectedDataToRequest() {
        let existingEvent = TimedEvent(name: "testEvent", data: ["some_custom_key": "some_custom_value"])
        var request = TealiumTrackRequest(data: ["regular_track_call_key": "regular_track_call_value"])
        let expectedKeys = ["regular_track_call_key", "some_custom_key", "timed_event_name", "timed_event_start", "timed_event_end", "request_uuid"]
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        timedEventScheduler = TimedEventScheduler(config: config!, events: [existingEvent])
        timedEventScheduler?.stop(event: "testEvent")
        timedEventScheduler?.update(request: &request, for: "testEvent")
        expectedKeys.forEach {
            XCTAssertNotNil(request.trackDictionary[$0])
        }
        XCTAssertEqual(request.trackDictionary[TealiumKey.timedEventName] as! String, "testEvent")
    }
    
    func testUpdateReturnsWhenEventDoesntExist() {
        var request = TealiumTrackRequest(data: ["regular_track_call_key": "regular_track_call_value"])
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        timedEventScheduler = TimedEventScheduler(config: config!)
        timedEventScheduler?.update(request: &request, for: "testEvent")
        XCTAssertNil(request.trackDictionary["timed_event_name"])
        XCTAssertNotNil(request.trackDictionary["regular_track_call_key"])
    }
    
    func testTimedEventInfoReturnsExpectedData() {
        let existingEvent = TimedEvent(name: "testEvent", data: ["some_custom_key": "some_custom_value"])
        let expectedKeys = ["some_custom_key", "timed_event_name", "timed_event_start", "timed_event_end", "timed_event_duration"]
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        timedEventScheduler = TimedEventScheduler(config: config!, events: [existingEvent])
        timedEventScheduler?.stop(event: "testEvent")
        let actual = timedEventScheduler?.timedEventInfo(for: "testEvent")
        expectedKeys.forEach {
            XCTAssertNotNil(actual?[$0])
        }
        XCTAssertEqual(actual?[TealiumKey.timedEventName] as! String, "testEvent")
    }
    
    func testTimedEventInfoReturnsEmptyDictionaryWhenEventDoesntExist() {
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        timedEventScheduler = TimedEventScheduler(config: config!)
        let actual = timedEventScheduler?.timedEventInfo(for: "testEvent")
        XCTAssertEqual(actual?.count, 0)
    }
    
    func testCancelReturnsWhenEventDoesntExist() {
        let existsingEvent = TimedEvent(name: "testEvent")
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        timedEventScheduler = TimedEventScheduler(config: config!, events: [existsingEvent])
        timedEventScheduler?.cancel(event: "testEvent2")
        XCTAssertEqual(timedEventScheduler?.events.count, 1)
    }
    
    func testClearAllRemovesAllEvents() {
        let existsingEvent = TimedEvent(name: "testEvent")
        let existsingEvent2 = TimedEvent(name: "testEvent2")
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        timedEventScheduler = TimedEventScheduler(config: config!, events: [existsingEvent, existsingEvent2])
        XCTAssertEqual(2, timedEventScheduler?.events.count)
        timedEventScheduler?.clearAll()
        XCTAssertEqual(timedEventScheduler?.events.count, 0)
    }
    
    func testExpectedEventNameWhenTriggersAreSetNoEventName() {
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        config!.timedEventTriggers = [TimedEventTrigger(start: "start_event", end: "stop_event")]
        timedEventScheduler = TimedEventScheduler(config: self.config!)
        var request = TealiumTrackRequest(data: ["tealium_event": "start_event"])
        timedEventScheduler?.handle(request: &request)
        guard let event = timedEventScheduler?.events.first else {
            XCTFail("Event should be present")
            return
        }
        XCTAssertEqual(event.name, "start_event::stop_event")
    }
    
    func testExpectedEventNamWhenTriggersAreSetWithEventName() {
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        config!.timedEventTriggers = [TimedEventTrigger(start: "start_event", end: "stop_event", name: "customEventName")]
        timedEventScheduler = TimedEventScheduler(config: self.config!)
        var request = TealiumTrackRequest(data: ["tealium_event": "start_event"])
        timedEventScheduler?.handle(request: &request)
        guard let event = timedEventScheduler?.events.first else {
            XCTFail("Event should be present")
            return
        }
        XCTAssertEqual(event.name, "customEventName")
    }
    
    func testProcessTrackCallsHandleWhenTriggersAreSet() {
        let mockTimedEventScheduler = MockTimedEventScheduler()
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        config!.timedEventTriggers = [TimedEventTrigger(start: "start_event", end: "stop_event")]
        tealium = Tealium(config: config!) { _ in
            self.tealium?.timedEventScheduler = mockTimedEventScheduler
            self.tealium?.track(TealiumEvent("test"))
        }
        delay {
            XCTAssertEqual(mockTimedEventScheduler.handleCallCount, 1)
        }
    }
    
    func testProcessTrackDoesntCallHandleWhenTriggersArentSet() {
        let mockTimedEventScheduler = MockTimedEventScheduler()
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        tealium = Tealium(config: config!) { _ in
            self.tealium?.timedEventScheduler = mockTimedEventScheduler
            self.tealium?.track(TealiumEvent("test"))
        }
        delay {
            XCTAssertEqual(mockTimedEventScheduler.handleCallCount, 0)
        }
    }
    
    private func delay(_ completion: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion()
        }
    }

}
