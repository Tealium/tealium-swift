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
    var context: TealiumContext?
    var timedEventScheduler: Schedulable?
    var events: [String: TimedEvent]?
    var tealium: Tealium?
    var willTrackExpectation: XCTestExpectation?

    override func setUpWithError() throws {
        events = [String: TimedEvent]()
    }
    
    override func tearDownWithError() throws {
        timedEventScheduler = nil
    }

    func testShouldQueueStartsTimedEvent()  {
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        config!.timedEventTriggers = [TimedEventTrigger(start: "start_event", end: "stop_event")]
        context = TestTealiumHelper.context(with: config!)
        timedEventScheduler = TimedEventScheduler(context: context!)
        let request = TealiumTrackRequest(data: ["tealium_event": "start_event"])
        _ = timedEventScheduler?.shouldQueue(request: request)
        guard let events = timedEventScheduler?.events,
              let eventStart = events["start_event::stop_event"] else {
            XCTFail("Event does not exist")
            return
        }
        XCTAssertNotNil(eventStart)
    }
    
    func testShouldQueueStopsTimedEvent()  {
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        config!.timedEventTriggers = [TimedEventTrigger(start: "start_event", end: "stop_event")]
        let context = MockTealiumContextTimedEvent(config: config!)
        timedEventScheduler = TimedEventScheduler(context: context)
        var request = TealiumTrackRequest(data: ["tealium_event": "start_event"])
        _ = timedEventScheduler?.shouldQueue(request: request)
        request = TealiumTrackRequest(data: ["tealium_event": "stop_event"])
        let _ = timedEventScheduler?.shouldQueue(request: request)
        XCTAssertNotNil(context.dispatchDictionaries[0][TealiumKey.eventStop])
    }
    
    func testShouldQueueChecksTriggersAndStopsMultipleTimedEvent() {
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        config!.timedEventTriggers = [TimedEventTrigger(start: "start_event", end: "stop_event"), TimedEventTrigger(start: "different_start_event", end: "stop_event")]
        let context = MockTealiumContextTimedEvent(config: config!)
        timedEventScheduler = TimedEventScheduler(context: context)
        let requests = [TealiumTrackRequest(data: ["tealium_event": "start_event"]),
                        TealiumTrackRequest(data: ["tealium_event": "different_start_event"]),
                        TealiumTrackRequest(data: ["tealium_event": "stop_event"])]
        requests.forEach {
            _ = timedEventScheduler?.shouldQueue(request: $0)
        }
        XCTAssertEqual(context.trackCallCount, 2)
        XCTAssertEqual(context.dispatchDictionaries.count, 2)
        let timedEvent1 = context.dispatchDictionaries
            .filter { $0[TealiumKey.timedEventName] as! String == "start_event::stop_event" }
        let timedEvent2 = context.dispatchDictionaries
            .filter { $0[TealiumKey.timedEventName] as! String == "different_start_event::stop_event" }
        XCTAssertEqual(timedEvent1.count, 1)
        XCTAssertEqual(timedEvent2.count, 1)
    }
    
    func testShouldQueuReturnsWhenRequestNotTrackRequest() {
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        config!.timedEventTriggers = [TimedEventTrigger(start: "start_event", end: "stop_event")]
        context = TestTealiumHelper.context(with: config!)
        timedEventScheduler = TimedEventScheduler(context: context!)
        let request = TealiumTrackRequest(data: ["tealium_event": "stop_event"])
        let batchRequest = TealiumBatchTrackRequest(trackRequests: [request])
        let shouldQueue = timedEventScheduler?.shouldQueue(request: batchRequest)
        XCTAssertEqual(shouldQueue?.0, false)
        XCTAssertNil(shouldQueue?.1)
        XCTAssertNil(timedEventScheduler?.events.first)
    }
    
    func testShouldQueuReturnsWhenTriggersNotDefined() {
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        context = TestTealiumHelper.context(with: config!)
        timedEventScheduler = TimedEventScheduler(context: context!)
        context = TestTealiumHelper.context(with: config!)
        let request = TealiumTrackRequest(data: ["tealium_event": "stop_event"])
        let shouldQueue = timedEventScheduler?.shouldQueue(request: request)
        XCTAssertEqual(shouldQueue?.0, false)
        XCTAssertNil(shouldQueue?.1)
        XCTAssertNil(timedEventScheduler?.events.first)
    }
    
    func testShouldQueuReturnsWhenTealiumEventNil() {
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        config!.timedEventTriggers = [TimedEventTrigger(start: "start_event", end: "stop_event")]
        context = TestTealiumHelper.context(with: config!)
        timedEventScheduler = TimedEventScheduler(context: context!)
        let request = TealiumTrackRequest(data: ["non_tealium_event": "stop_event"])
        guard let shouldQueue = timedEventScheduler?.shouldQueue(request: request) else {
            XCTFail("should Queue should not be nil")
            return
        }
        XCTAssertFalse(shouldQueue.0)
        XCTAssertNil(shouldQueue.1)
        XCTAssertNil(timedEventScheduler?.events.first)
    }
    
    func testShouldCallsSendTrackAfterStop() {
        let startRequest = TealiumTrackRequest(data: ["tealium_event": "start_event"])
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        config!.timedEventTriggers = [TimedEventTrigger(start: "start_event", end: "stop_event")]
        let context = MockTealiumContextTimedEvent(config: config!)
        timedEventScheduler = TimedEventScheduler(context: context)
        _ = timedEventScheduler?.shouldQueue(request: startRequest)
        let stopRequest = TealiumTrackRequest(data: ["tealium_event": "stop_event"])
        guard let _ = timedEventScheduler?.shouldQueue(request: stopRequest) else {
            XCTFail("Should Queue should not return nil")
            return
        }
        XCTAssertEqual(context.trackCallCount, 1)
    }
    
    func testShouldDropReturnsFalse() {
        let request = TealiumTrackRequest(data: ["hello": "world"])
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        config!.timedEventTriggers = [TimedEventTrigger(start: "start_event", end: "stop_event")]
        context = TestTealiumHelper.context(with: config!)
        timedEventScheduler = TimedEventScheduler(context: context!)
        let shouldDrop = timedEventScheduler?.shouldDrop(request: request)
        XCTAssertFalse(shouldDrop!)
    }
    
    func testShouldPurgeReturnsFalse() {
        let request = TealiumTrackRequest(data: ["hello": "world"])
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        config!.timedEventTriggers = [TimedEventTrigger(start: "start_event", end: "stop_event")]
        context = TestTealiumHelper.context(with: config!)
        timedEventScheduler = TimedEventScheduler(context: context!)
        let shouldPurge = timedEventScheduler?.shouldPurge(request: request)
        XCTAssertFalse(shouldPurge!)
    }
    
    func testStartAddsNewEvent() {
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        context = TestTealiumHelper.context(with: config!)
        timedEventScheduler = TimedEventScheduler(context: context!)
        timedEventScheduler?.start(event: "testEvent", with: nil)
        guard let events = timedEventScheduler?.events else {
            XCTFail("Events not defined")
            return
        }
        XCTAssertNotNil(events["testEvent"])
    }
    
    func testStartReturnsWhenEventAlreadyStarted() {
        let existsingEvent = TimedEvent(name: "testEvent")
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        context = TestTealiumHelper.context(with: config!)
        timedEventScheduler = TimedEventScheduler(context: context!, events: ["testEvent": existsingEvent])
        timedEventScheduler?.start(event: "testEvent", with: nil)
        guard let events = timedEventScheduler?.events else {
            XCTFail("Events not defined")
            return
        }
        XCTAssertEqual(timedEventScheduler?.events.count, 1)
        XCTAssertNotNil(events["testEvent"])
    }
    
    func testStopCallsStopTimerWhenEventExists() {
        let existsingEvent = TimedEvent(name: "testEvent")
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        context = TestTealiumHelper.context(with: config!)
        timedEventScheduler = TimedEventScheduler(context: context!, events: ["testEvent": existsingEvent])
        let updatedEvent = timedEventScheduler?.stop(event: "testEvent")
        XCTAssertNotNil(updatedEvent?.stop)
    }
    
    func testStopReturnsNilWhenTimedEventDoesntExist() {
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        context = TestTealiumHelper.context(with: config!)
        timedEventScheduler = TimedEventScheduler(context: context!)
        let event = timedEventScheduler?.stop(event: "testEvent")
        XCTAssertNil(event)
    }
    
    func testSendTimedEventRemovesEventFromEventsDictionary() {
        let existsingEvent = TimedEvent(name: "testEvent")
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        context = TestTealiumHelper.context(with: config!)
        timedEventScheduler = TimedEventScheduler(context: context!, events: ["testEvent": existsingEvent])
        timedEventScheduler?.sendTimedEvent(existsingEvent)
        XCTAssertEqual(timedEventScheduler?.events.count, 0)
    }
    
    func testSendTimedEventCallsTrack() {
        let existsingEvent = TimedEvent(name: "testEvent")
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        let context = MockTealiumContextTimedEvent(config: config!)
        timedEventScheduler = TimedEventScheduler(context: context, events: ["testEvent": existsingEvent])
        timedEventScheduler?.sendTimedEvent(existsingEvent)
        XCTAssertEqual(context.trackCallCount, 1)
    }
    
    func testCancelRemovesEventWhenExists() {
        let existingEvent = TimedEvent(name: "testEvent")
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        context = TestTealiumHelper.context(with: config!)
        timedEventScheduler = TimedEventScheduler(context: context!, events: ["testEvent": existingEvent])
        timedEventScheduler?.cancel(event: "testEvent")
        XCTAssertEqual(timedEventScheduler?.events.count, 0)
    }
    
    func testCancelReturnsWhenEventDoesntExist() {
        let existsingEvent = TimedEvent(name: "testEvent")
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        context = TestTealiumHelper.context(with: config!)
        timedEventScheduler = TimedEventScheduler(context: context!, events: ["testEvent": existsingEvent])
        timedEventScheduler?.cancel(event: "testEvent2")
        XCTAssertEqual(timedEventScheduler?.events.count, 1)
    }
    
    func testClearAllRemovesAllEvents() {
        let existsingEvent = TimedEvent(name: "testEvent")
        let existsingEvent2 = TimedEvent(name: "testEvent2")
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        context = TestTealiumHelper.context(with: config!)
        timedEventScheduler = TimedEventScheduler(context: context!, events: ["testEvent": existsingEvent, "testEvent2": existsingEvent2])
        XCTAssertEqual(2, timedEventScheduler?.events.count)
        timedEventScheduler?.clearAll()
        XCTAssertEqual(timedEventScheduler?.events.count, 0)
    }
    
    func testExpectedEventNameWhenTriggersAreSetNoEventName() {
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        config!.timedEventTriggers = [TimedEventTrigger(start: "start_event", end: "stop_event")]
        context = TestTealiumHelper.context(with: config!)
        timedEventScheduler = TimedEventScheduler(context: context!)
        let request = TealiumTrackRequest(data: ["tealium_event": "start_event"])
        _ = timedEventScheduler?.shouldQueue(request: request)
        guard let events = timedEventScheduler?.events else {
            XCTFail("Events not defined")
            return
        }
        XCTAssertNotNil(events["start_event::stop_event"])
    }
    
    func testExpectedEventNamWhenTriggersAreSetWithEventName() {
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        config!.timedEventTriggers = [TimedEventTrigger(start: "start_event", end: "stop_event", name: "customEventName")]
        context = TestTealiumHelper.context(with: config!)
        timedEventScheduler = TimedEventScheduler(context: context!)
        let request = TealiumTrackRequest(data: ["tealium_event": "start_event"])
        _ = timedEventScheduler?.shouldQueue(request: request)
        guard let events = timedEventScheduler?.events else {
            XCTFail("Events not defined")
            return
        }
        XCTAssertNotNil(events["customEventName"])
    }
    
    func testProcessTrackCallsStartWhenTriggersAreSet() {
        let mockTimedEventScheduler = MockTimedEventScheduler()
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        config!.timedEventTriggers = [TimedEventTrigger(start: "start_event", end: "stop_event")]
        tealium = Tealium(config: config!) { _ in
            self.tealium?.zz_internal_modulesManager?.dispatchValidators = []
            self.tealium?.zz_internal_modulesManager?.addDispatchValidator(mockTimedEventScheduler)
            self.tealium?.track(TealiumEvent("start_event"))
        }
        TestTealiumHelper.delay {
            XCTAssertEqual(mockTimedEventScheduler.shouldQueueCallCount, 1)
            XCTAssertEqual(mockTimedEventScheduler.startCallCount, 1)
        }
    }
    
    func testProcessTrackCallsStopWhenTriggersAreSet() {
        let mockTimedEventScheduler = MockTimedEventScheduler()
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        config!.timedEventTriggers = [TimedEventTrigger(start: "start_event", end: "stop_event")]
        tealium = Tealium(config: config!) { _ in
            self.tealium?.zz_internal_modulesManager?.dispatchValidators = []
            self.tealium?.zz_internal_modulesManager?.addDispatchValidator(mockTimedEventScheduler)
            self.tealium?.track(TealiumEvent("start_event"))
            self.tealium?.track(TealiumEvent("stop_event"))
        }
        TestTealiumHelper.delay {
            XCTAssertEqual(mockTimedEventScheduler.shouldQueueCallCount, 2)
            XCTAssertEqual(mockTimedEventScheduler.stopCallCount, 1)
        }
    }
    
    func testProcessTrackDoesntCallStartWhenTriggersArentSet() {
        let mockTimedEventScheduler = MockTimedEventScheduler()
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnv")
        tealium = Tealium(config: config!) { _ in
            self.tealium?.zz_internal_modulesManager?.dispatchValidators = []
            self.tealium?.zz_internal_modulesManager?.addDispatchValidator(mockTimedEventScheduler)
            self.tealium?.track(TealiumEvent("test"))
        }
        TestTealiumHelper.delay {
            XCTAssertEqual(mockTimedEventScheduler.shouldQueueCallCount, 0)
            XCTAssertEqual(mockTimedEventScheduler.startCallCount, 0)
        }
    }

}

class MockTealiumContextTimedEvent: TealiumContextProtocol {
    var config: TealiumConfig
    var dispatchDictionaries = [[String: Any]]()
    var trackCallCount = 0
    init(config: TealiumConfig) {
        self.config = config
    }
    func track(_ dispatch: TealiumDispatch) {
        dispatchDictionaries.append(dispatch.trackRequest.trackDictionary)
        trackCallCount += 1
    }
}
