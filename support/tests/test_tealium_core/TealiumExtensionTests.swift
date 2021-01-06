//
//  TealiumExtensionTests.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

@testable import TealiumCollect
@testable import TealiumCore
@testable import TealiumLifecycle
@testable import TealiumVisitorService
#if os(iOS)
@testable import TealiumAutotracking
@testable import TealiumLocation
@testable import TealiumRemoteCommands
@testable import TealiumTagManagement
#endif

import XCTest

class TealiumExtensionTests: XCTestCase {

    var defaultTealiumConfig = TealiumConfig(account: "tealiummobile",
                                             profile: "demo",
                                             environment: "dev",
                                             options: nil)
    var tealium: Tealium!
    let mockEventScheduler = MockTimedEventScheduler()
    

    override func setUpWithError() throws {

    }

    override func tearDownWithError() throws { }

    func testVisitorIdNotNil() {
        let expect = expectation(description: "Visitor id not nil")
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNotNil(self.tealium.visitorId)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }
    
    func testResetVisitorId() {
        let expect = expectation(description: "Visitor id is reset")
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            let currentVisitorId = self.tealium.visitorId
            let currentUUID = (self.tealium.zz_internal_modulesManager?.collectors
                                .filter { $0 is AppDataModule }
                                .first as? AppDataModule)?.uuid
            self.tealium.resetVisitorId()
            let newVisitorId = self.tealium.visitorId
            XCTAssertEqual(currentUUID, (self.tealium.zz_internal_modulesManager?.collectors
                                            .filter { $0 is AppDataModule }
                                            .first as? AppDataModule)?.uuid)
            XCTAssertEqual(newVisitorId?.count, 32)
            XCTAssertNotEqual(newVisitorId, currentVisitorId)
            XCTAssertEqual(self.tealium.visitorId, newVisitorId)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }

    func testConsentManagerNotNil() {
        let expect = expectation(description: "Consent Manager Module not nil")
        defaultTealiumConfig.consentPolicy = .ccpa
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNotNil(self.tealium.consentManager)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }

    func testConsentManagerNilWhenPolicyNotSet() {
        let expect = expectation(description: "Consent Manager Module nil")
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNil(self.tealium.consentManager)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }

    func testLoggerNotNil() {
        let expect = expectation(description: "Logger not nil")
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNotNil(self.tealium.logger)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }

    func testVisitorServiceNotNil() {
        let expect = expectation(description: "Visitor Service Manager not nil")
        defaultTealiumConfig.collectors = [Collectors.VisitorService]
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNotNil(self.tealium.visitorService)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }

    func testVisitorServiceNilWhenNotSetAsCollector() {
        let expect = expectation(description: "Visitor Service Manager nil")
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNil(self.tealium.visitorService)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testLifecycleNotNil() {
        let expect = expectation(description: "Lifecycle not nil")
        defaultTealiumConfig.collectors = [Collectors.Lifecycle]
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNotNil(self.tealium.lifecycle)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }

    func testLifecycleNilWhenNotSetAsCollector() {
        let expect = expectation(description: "Lifecycle nil")
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNil(self.tealium.lifecycle)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }
    
    func testStartTimedEventCallsEventSchedulerStart() {
        let expect = expectation(description: "Timed event scheduler start called")
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            self.tealium.zz_internal_modulesManager?.dispatchValidators = []
            self.tealium.zz_internal_modulesManager?.addDispatchValidator(self.mockEventScheduler)
            self.tealium.startTimedEvent(name: "testEvent", with: ["test_event": "start"])
            XCTAssertEqual(1, self.mockEventScheduler.startCallCount)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }
    
    func testStopTimedEventCallsEventSchedulerStopAndTimedEventInfo() {
        let expect = expectation(description: "Timed event scheduler stop called")
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            self.mockEventScheduler.events = ["testEvent": TimedEvent(name: "testEvent", data: ["some": "data"])]
            self.tealium.zz_internal_modulesManager?.dispatchValidators = []
            self.tealium.zz_internal_modulesManager?.addDispatchValidator(self.mockEventScheduler)
            self.tealium.stopTimedEvent(name: "testEvent")
            XCTAssertEqual(1, self.mockEventScheduler.stopCallCount)
            XCTAssertEqual(1, self.mockEventScheduler.sendTimedEventCount)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 2.0)
    }
    
    func testCancelTimedEventCallsEventSchedulerCancel() {
        let expect = expectation(description: "Timed event scheduler cancel called")
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            self.tealium.zz_internal_modulesManager?.dispatchValidators = []
            self.tealium.zz_internal_modulesManager?.addDispatchValidator(self.mockEventScheduler)
            self.tealium.cancelTimedEvent(name: "testEvent")
            XCTAssertEqual(1, self.mockEventScheduler.cancelCallCount)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }
    
    func testClearAllTimedEventsCallsEventSchedulerClearAll() {
        let expect = expectation(description: "Timed event scheduler clear all called")
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            self.tealium.zz_internal_modulesManager?.dispatchValidators = []
            self.tealium.zz_internal_modulesManager?.addDispatchValidator(self.mockEventScheduler)
            self.tealium.clearAllTimedEvents()
            XCTAssertEqual(1, self.mockEventScheduler.clearAllCallCount)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }

    #if os(iOS)
    func testLocationNotNil() {
        let expect = expectation(description: "Location not nil")
        defaultTealiumConfig.collectors = [Collectors.Location]
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNotNil(self.tealium.location)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }

    func testLocationNilWhenNotSetAsCollector() {
        let expect = expectation(description: "Location nil")
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNil(self.tealium.location)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }

    func testAutotrackingNotNil() {
        let expect = expectation(description: "Autotracking not nil")
        defaultTealiumConfig.collectors = [Collectors.AutoTracking]
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNotNil(self.tealium.autotracking)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }

    func testAutotrackingNilWhenNotSetAsCollector() {
        let expect = expectation(description: "Autotracking nil")
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNil(self.tealium.autotracking)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }

    func testRemoteCommandsNotNil() {
        let expect = expectation(description: "Remote Commands not nil")
        defaultTealiumConfig.dispatchers = [Dispatchers.RemoteCommands]
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNotNil(self.tealium.remoteCommands)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }

    func testRemoteCommandsNilWhenNotSetAsDispatcher() {
        let expect = expectation(description: "Remote Commands nil")
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNil(self.tealium.remoteCommands)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }

    func testTagManagementNotNil() {
        let expect = expectation(description: "Tag Management not nil")
        defaultTealiumConfig.dispatchers = [Dispatchers.TagManagement]
        defaultTealiumConfig.shouldUseRemotePublishSettings = false
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNotNil(self.tealium.tagManagement)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }

    func testTagManagementNilWhenNotSetAsDispatcher() {
        let expect = expectation(description: "Tag Management nil")
        defaultTealiumConfig.shouldUseRemotePublishSettings = false
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNil(self.tealium.tagManagement)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }
    #endif
    
    private func delay(_ completion: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion()
        }
    }

}
