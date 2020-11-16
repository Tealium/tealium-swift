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
        config!.timedEventTriggers = [TimedEventTrigger(start: "start_event", stop: "stop_event")]
        timedEventScheduler = TimedEventScheduler(config: config!)
        let request = TealiumTrackRequest(data: ["tealium_event": "start_event"])
        _ = timedEventScheduler?.handle(request: request)
        guard let event = timedEventScheduler?.events.first else {
            XCTFail("Event does not exist")
            return
        }
        XCTAssertNotNil(event.start)
    }
    
    func testHandleStopsTimedEvent()  {
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        config!.timedEventTriggers = [TimedEventTrigger(start: "start_event", stop: "stop_event")]
        timedEventScheduler = TimedEventScheduler(config: config!)
        var request = TealiumTrackRequest(data: ["tealium_event": "start_event"])
        _ = timedEventScheduler?.handle(request: request)
        request = TealiumTrackRequest(data: ["tealium_event": "stop_event"])
        request = timedEventScheduler!.handle(request: request)!
        XCTAssertNotNil(request.trackDictionary["timed_event_stop"])
    }
    
    func testHandleReturnsWhenTealiumEventNil() {
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        config!.timedEventTriggers = [TimedEventTrigger(start: "start_event", stop: "stop_event")]
        timedEventScheduler = TimedEventScheduler(config: config!)
        let request = TealiumTrackRequest(data: ["non_tealium_event": "stop_event"])
        _ = timedEventScheduler?.handle(request: request)
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
    
    func testStopReturnsExpectedRequestWhenEventExists() {
        let existsingEvent = TimedEvent(name: "testEvent")
        let expectedKeys = ["timed_event_name", "timed_event_start", "timed_event_stop", "request_uuid"]
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        timedEventScheduler = TimedEventScheduler(config: config!, events: [existsingEvent])
        guard let request = timedEventScheduler?.stop(event: "testEvent", with: nil) else {
            XCTFail("Event does not exist")
            return
        }
        expectedKeys.forEach {
            XCTAssertNotNil(request.trackDictionary[$0])
        }
        XCTAssertEqual(request.trackDictionary[TealiumKey.timedEventName] as! String, "testEvent")
    }
    
    func testStopReturnsNilWhenTimedEventDoesntExist() {
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        timedEventScheduler = TimedEventScheduler(config: config!)
        let request = timedEventScheduler?.stop(event: "testEvent", with: nil)
        XCTAssertNil(request)
    }
    
    func testCancelRemovesEventWhenExists() {
        let existsingEvent = TimedEvent(name: "testEvent")
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        timedEventScheduler = TimedEventScheduler(config: config!, events: [existsingEvent])
        timedEventScheduler?.cancel(event: "testEvent")
        XCTAssertEqual(timedEventScheduler?.events.count, 0)
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
    
    func testProcessTrackCallsHandleWhenTriggersAreSet() {
        let mockTimedEventScheduler = MockTimedEventScheduler()
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        config!.timedEventTriggers = [TimedEventTrigger(start: "start_event", stop: "stop_event")]
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
