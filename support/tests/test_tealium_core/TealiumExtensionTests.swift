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
@testable import TealiumMedia
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
    
    func waitOnTealiumSerialQueue<T>(_ block: () -> T) -> T {
        return TealiumQueues.backgroundSerialQueue.sync {
            return block()
        }
    }
    
    func testVisitorIdNotNil() {
        let config = TealiumConfig(account: "test", profile: "test", environment: "test")
        let expect = expectation(description: "Visitor id not nil")
        tealium = Tealium(config: config) { _ in
            XCTAssertNotNil(self.tealium.visitorId)
            expect.fulfill()
        }
        waitOnTealiumSerialQueue {
            wait(for: [expect], timeout: 1.0)
        }
    }
    
    func testResetVisitorId() {
        let tealiumInitialized = expectation(description: "Tealium is initialized")
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            tealiumInitialized.fulfill()
        }
        waitOnTealiumSerialQueue {
            wait(for: [tealiumInitialized], timeout: 1.0)
        }
        let currentVisitorId = self.tealium.visitorId
        let currentUUID = self.tealium.dataLayer.all[TealiumDataKey.uuid] as? String
        self.tealium.resetVisitorId()
        waitOnTealiumSerialQueue {
            let newVisitorId = self.tealium.visitorId
            XCTAssertEqual(currentUUID, self.tealium.dataLayer.all[TealiumDataKey.uuid] as? String)
            XCTAssertEqual(newVisitorId?.count, 32)
            XCTAssertNotEqual(newVisitorId, currentVisitorId)
            XCTAssertEqual(self.tealium.visitorId, newVisitorId)
        }
    }

    func testClearStoredVisitorIdsWithoutDeletingFromDataLayer() {
        let tealiumInitialized = expectation(description: "Tealium is initialized")
        let config = defaultTealiumConfig.copy
        config.visitorIdentityKey = "someId"
        let identity = "identity"
        let hashedIdentity = identity.sha256()!
        tealium = Tealium(config: config) { _ in
            tealiumInitialized.fulfill()
        }
        waitOnTealiumSerialQueue {
            wait(for: [tealiumInitialized], timeout: 1.0)
        }
        self.tealium.dataLayer.add(key: "someId", value: identity, expiry: .untilRestart)
        let idProvider = self.tealium.appDataModule!.visitorIdProvider
        let firstId = waitOnTealiumSerialQueue {
            XCTAssertGreaterThan(idProvider.visitorIdStorage.cachedIds.count, 0)
            let firstId = idProvider.getVisitorId(forKey: hashedIdentity)
            XCTAssertEqual(firstId, idProvider.visitorIdStorage.visitorId)
            return firstId
        }
        self.tealium.clearStoredVisitorIds()
            
        waitOnTealiumSerialQueue {
            XCTAssertNotEqual(idProvider.visitorIdStorage.cachedIds[hashedIdentity], firstId)
            XCTAssertEqual(idProvider.getVisitorId(forKey: hashedIdentity), idProvider.visitorIdStorage.visitorId)
            XCTAssertNotNil(idProvider.visitorIdStorage.currentIdentity)
            XCTAssertEqual(hashedIdentity, idProvider.visitorIdStorage.currentIdentity)
        }
    }

    func testClearStoredVisitorIdsCorrectly() {
        let expect = expectation(description: "Visitor id is reset")
        let config = defaultTealiumConfig.copy
        config.visitorIdentityKey = "someId"
        let identity = "identity"
        let hashedIdentity = identity.sha256()!
        tealium = Tealium(config: config) { _ in
            self.tealium.dataLayer.add(key: "someId", value: identity, expiry: .untilRestart)
            let idProvider = self.tealium.appDataModule!.visitorIdProvider
            TealiumQueues.backgroundSerialQueue.async {
                XCTAssertGreaterThan(idProvider.visitorIdStorage.cachedIds.count, 0)
                let firstId = idProvider.getVisitorId(forKey: hashedIdentity)
                XCTAssertEqual(firstId, idProvider.visitorIdStorage.visitorId)
                self.tealium.dataLayer.delete(for: "someId")
                self.tealium.clearStoredVisitorIds()
                TealiumQueues.backgroundSerialQueue.async {
                    XCTAssertNil(idProvider.visitorIdStorage.cachedIds[hashedIdentity])
                    XCTAssertNil(idProvider.getVisitorId(forKey: hashedIdentity))
                    XCTAssertNil(idProvider.visitorIdStorage.currentIdentity)
                    expect.fulfill()
                }
            }
        }
        wait(for: [expect], timeout: 5.0)
    }

    func testConsentManagerNotNil() {
        let expect = expectation(description: "Consent Manager Module not nil")
        defaultTealiumConfig.consentPolicy = .ccpa
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNotNil(self.tealium.consentManager)
            expect.fulfill()
        }
        waitOnTealiumSerialQueue {
            wait(for: [expect], timeout: 1.0)
        }
    }

    func testConsentManagerNilWhenPolicyNotSet() {
        let expect = expectation(description: "Consent Manager Module nil")
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNil(self.tealium.consentManager)
            expect.fulfill()
        }
        waitOnTealiumSerialQueue {
            wait(for: [expect], timeout: 1.0)
        }
    }

    func testLoggerNotNil() {
        let expect = expectation(description: "Logger not nil")
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNotNil(self.tealium.logger)
            expect.fulfill()
        }
        waitOnTealiumSerialQueue {
            wait(for: [expect], timeout: 1.0)
        }
    }

    func testVisitorServiceNotNil() {
        let expect = expectation(description: "Visitor Service Manager not nil")
        defaultTealiumConfig.collectors = [Collectors.VisitorService]
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNotNil(self.tealium.visitorService)
            expect.fulfill()
        }
        waitOnTealiumSerialQueue {
            wait(for: [expect], timeout: 1.0)
        }
    }
    
    func testMediaServiceNotNilWhenAddedToCollectors() {
        let expect = expectation(description: "Media Not not nil")
        defaultTealiumConfig.collectors = [Collectors.Media]
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNotNil(self.tealium.media)
            expect.fulfill()
        }
        waitOnTealiumSerialQueue {
            wait(for: [expect], timeout: 1.0)
        }
    }
    
    func testMediaServiceNilWhenAddedToCollectors() {
        let expect = expectation(description: "Media Nil")
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNil(self.tealium.media)
            expect.fulfill()
        }
        waitOnTealiumSerialQueue {
            wait(for: [expect], timeout: 1.0)
        }
    }

    func testVisitorServiceNilWhenNotSetAsCollector() {
        let expect = expectation(description: "Visitor Service Manager nil")
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNil(self.tealium.visitorService)
            expect.fulfill()
        }
        waitOnTealiumSerialQueue {
            wait(for: [expect], timeout: 1.0)
        }
    }

    func testLifecycleNotNil() {
        let expect = expectation(description: "Lifecycle not nil")
        defaultTealiumConfig.collectors = [Collectors.Lifecycle]
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNotNil(self.tealium.lifecycle)
            expect.fulfill()
        }
        waitOnTealiumSerialQueue {
            wait(for: [expect], timeout: 1.0)
        }
    }

    func testLifecycleNilWhenNotSetAsCollector() {
        let expect = expectation(description: "Lifecycle nil")
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNil(self.tealium.lifecycle)
            expect.fulfill()
        }
        waitOnTealiumSerialQueue {
            wait(for: [expect], timeout: 1.0)
        }
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
        waitOnTealiumSerialQueue {
            wait(for: [expect], timeout: 1.0)
        }
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
        waitOnTealiumSerialQueue {
            wait(for: [expect], timeout: 1.0)
        }
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
        waitOnTealiumSerialQueue {
            wait(for: [expect], timeout: 1.0)
        }
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
        waitOnTealiumSerialQueue {
            wait(for: [expect], timeout: 1.0)
        }
    }
    

    #if os(iOS)
    func testLocationNotNil() {
        let expect = expectation(description: "Location not nil")
        defaultTealiumConfig.collectors = [Collectors.Location]
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNotNil(self.tealium.location)
            expect.fulfill()
        }
        waitOnTealiumSerialQueue {
            wait(for: [expect], timeout: 1.0)
        }
    }

    func testLocationNilWhenNotSetAsCollector() {
        let expect = expectation(description: "Location nil")
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNil(self.tealium.location)
            expect.fulfill()
        }
        waitOnTealiumSerialQueue {
            wait(for: [expect], timeout: 1.0)
        }
    }

    func testRemoteCommandsNotNil() {
        let expect = expectation(description: "Remote Commands not nil")
        defaultTealiumConfig.dispatchers = [Dispatchers.RemoteCommands]
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNotNil(self.tealium.remoteCommands)
            expect.fulfill()
        }
        waitOnTealiumSerialQueue {
            wait(for: [expect], timeout: 1.0)
        }
    }

    func testRemoteCommandsNilWhenNotSetAsDispatcher() {
        let expect = expectation(description: "Remote Commands nil")
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNil(self.tealium.remoteCommands)
            expect.fulfill()
        }
        waitOnTealiumSerialQueue {
            wait(for: [expect], timeout: 1.0)
        }
    }

    func testTagManagementNotNil() {
        let expect = expectation(description: "Tag Management not nil")
        defaultTealiumConfig.dispatchers = [Dispatchers.TagManagement]
        defaultTealiumConfig.shouldUseRemotePublishSettings = false
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNotNil(self.tealium.tagManagement)
            expect.fulfill()
        }
        waitOnTealiumSerialQueue {
            wait(for: [expect], timeout: 1.0)
        }
    }

    func testTagManagementNilWhenNotSetAsDispatcher() {
        let expect = expectation(description: "Tag Management nil")
        defaultTealiumConfig.shouldUseRemotePublishSettings = false
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNil(self.tealium.tagManagement)
            expect.fulfill()
        }
        waitOnTealiumSerialQueue {
            wait(for: [expect], timeout: 1.0)
        }
    }
    #endif

    func testAppendingQueryItems() {
        let url = URL(string: "www.tealium.com")
        let queryItems = [URLQueryItem(name: "key1", value: "value1"), URLQueryItem(name: "key2", value: "value2")]
        XCTAssertTrue(URLComponents(url: url!.appendingQueryItems(queryItems), resolvingAgainstBaseURL: false)!.queryItems!.elementsEqual(queryItems))
    }
}
