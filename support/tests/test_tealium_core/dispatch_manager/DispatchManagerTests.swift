//
//  DispatchQueueModuleTests.swift
//  tealium-swift
//
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumCore
import XCTest

class DispatchQueueModuleTests: XCTestCase {

    static var releaseExpectation: XCTestExpectation?
    static var remoteAPIExpectation: XCTestExpectation?
    static var expiredDispatchesExpectation: XCTestExpectation?
    static var connectivity: ConnectivityModule {
        let context = TestTealiumHelper.context(with: testTealiumConfig)
        let connectivity = ConnectivityModule(context: context, delegate: nil, diskStorage: nil) { _ in }
        connectivity.forceConnectionOverride = true
        return connectivity
    }
    var dispatchManager: DispatchManager!
    var diskStorage = DispatchQueueMockDiskStorage()

    var persistentQueue: TealiumPersistentDispatchQueue!
    weak var delegate: ModuleDelegate?
    override func setUp() {
        super.setUp()
        self.persistentQueue = TealiumPersistentDispatchQueue(diskStorage: diskStorage)
        // Put setup code here. This method is called before the invocation of each test method in the class.

    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testNegativeDispatchLimit() {
        dispatchManager = DispatchManager(dispatchers: nil, dispatchValidators: nil, dispatchListeners: nil, connectivityManager: DispatchQueueModuleTests.connectivity, config: testTealiumConfig.copy, diskStorage: DispatchQueueMockDiskStorage())
        dispatchManager.config.dispatchQueueLimit = -1
        XCTAssertEqual(dispatchManager.maxQueueSize, TealiumValue.defaultMaxQueueSize)
        dispatchManager.config.dispatchQueueLimit = -100
        XCTAssertEqual(dispatchManager.maxQueueSize, TealiumValue.defaultMaxQueueSize)
        dispatchManager.config.dispatchQueueLimit = -5
        XCTAssertEqual(dispatchManager.maxQueueSize, TealiumValue.defaultMaxQueueSize)
    }

    func testTrack() {

        let config = TestTealiumHelper().getConfig()
        config.batchingEnabled = true
        dispatchManager = DispatchManager(dispatchers: nil, dispatchValidators: nil, dispatchListeners: nil, connectivityManager: DispatchQueueModuleTests.connectivity, config: config, diskStorage: DispatchQueueMockDiskStorage())
        dispatchManager.clearQueue()
        let trackRequest = TealiumTrackRequest(data: ["tealium_event": "hello"])
        dispatchManager.processTrack(trackRequest)
        XCTAssertEqual(dispatchManager.persistentQueue.currentEvents, 1)
        dispatchManager.processTrack(trackRequest)
        XCTAssertEqual(dispatchManager.persistentQueue.currentEvents, 2)
        // wake event should not be queued
        let wakeRequest = TealiumTrackRequest(data: ["tealium_event": "wake"])
        dispatchManager.processTrack(wakeRequest)
        XCTAssertEqual(dispatchManager.persistentQueue.currentEvents, 3)
    }

    func testQueue() {
        let config = TestTealiumHelper().getConfig()
        config.batchingEnabled = true
        dispatchManager = DispatchManager(dispatchers: nil, dispatchValidators: nil, dispatchListeners: nil, connectivityManager: DispatchQueueModuleTests.connectivity, config: config, diskStorage: DispatchQueueMockDiskStorage())
        dispatchManager.clearQueue()
        let trackRequest = TealiumTrackRequest(data: ["tealium_event": "wake"])
        dispatchManager.enqueue(trackRequest, reason: nil)
        dispatchManager.enqueue(trackRequest, reason: nil)
        XCTAssertEqual(dispatchManager.persistentQueue.currentEvents, 2)
    }

    func testRemoveOldDispatches() {
        DispatchQueueModuleTests.expiredDispatchesExpectation = self.expectation(description: "remove old dispatches")
        let config = testTealiumConfig
        config.dispatchExpiration = 1
        dispatchManager = DispatchManager(dispatchers: nil, dispatchValidators: nil, dispatchListeners: nil, connectivityManager: DispatchQueueModuleTests.connectivity, config: testTealiumConfig.copy, diskStorage: DispatchQueueMockDiskStorage())
        dispatchManager.persistentQueue = MockPersistentQueue(diskStorage: diskStorage)
        dispatchManager.config = config
        dispatchManager.removeOldDispatches()
        wait(for: [DispatchQueueModuleTests.expiredDispatchesExpectation!], timeout: 5.0)
    }

    #if os(iOS)
    func testRemoteAPIEnabled() {
        let config = defaultTealiumConfig
        config.remoteAPIEnabled = true
        dispatchManager = DispatchManager(dispatchers: nil, dispatchValidators: nil, dispatchListeners: nil, connectivityManager: DispatchQueueModuleTests.connectivity, config: config, diskStorage: DispatchQueueMockDiskStorage())
        DispatchQueueModuleTests.remoteAPIExpectation = self.expectation(description: "remote api")

        let dispatcher = DispatchQueueDummyDispatcher(config: config, delegate: self, completion: nil)
        dispatchManager.dispatchers = [dispatcher]

        let trackRequest = TealiumTrackRequest(data: ["tealium_event": "myevent"])
        dispatchManager.processTrack(trackRequest)
        wait(for: [DispatchQueueModuleTests.remoteAPIExpectation!], timeout: 5.0)
    }
    #endif

    func testDequeue() {
        let config = TealiumConfig(account: "account", profile: "profile", environment: "env")
        #if os(iOS)
        config.remoteAPIEnabled = true
        #endif
        config.logLevel = .silent
        dispatchManager = DispatchManager(dispatchers: nil, dispatchValidators: nil, dispatchListeners: nil, connectivityManager: DispatchQueueModuleTests.connectivity, config: config, diskStorage: DispatchQueueMockDiskStorage())
        dispatchManager.clearQueue()
        let trackRequest = TealiumTrackRequest(data: ["tealium_event": "wake"])
        dispatchManager.enqueue(trackRequest, reason: nil)
        dispatchManager.enqueue(trackRequest, reason: nil)
        XCTAssertEqual(dispatchManager.persistentQueue.currentEvents, 2)
        dispatchManager.dequeue()
        XCTAssertEqual(dispatchManager.persistentQueue.currentEvents, 0)
    }

    func testClearQueue() {
        let config = TestTealiumHelper().getConfig()
        #if os(iOS)
        config.remoteAPIEnabled = true
        #endif
        config.logLevel = .silent
        dispatchManager = DispatchManager(dispatchers: nil, dispatchValidators: nil, dispatchListeners: nil, connectivityManager: DispatchQueueModuleTests.connectivity, config: config, diskStorage: DispatchQueueMockDiskStorage())
        dispatchManager.clearQueue()
        let trackRequest = TealiumTrackRequest(data: ["tealium_event": "wake"])
        dispatchManager.enqueue(trackRequest, reason: nil)
        dispatchManager.enqueue(trackRequest, reason: nil)
        XCTAssertEqual(dispatchManager.persistentQueue.currentEvents, 2)
        dispatchManager.clearQueue()
        XCTAssertEqual(dispatchManager.persistentQueue.currentEvents, 0)
    }

    func testCanQueueRequest() {
        let config = TestTealiumHelper().getConfig()
        #if os(iOS)
        config.remoteAPIEnabled = true
        #endif
        config.logLevel = .silent
        dispatchManager = DispatchManager(dispatchers: nil, dispatchValidators: nil, dispatchListeners: nil, connectivityManager: DispatchQueueModuleTests.connectivity, config: config, diskStorage: DispatchQueueMockDiskStorage())
        XCTAssertFalse(dispatchManager.canQueueRequest(TealiumTrackRequest(data: ["tealium_event": "grant_full_consent"])))
        XCTAssertTrue(dispatchManager.canQueueRequest(TealiumTrackRequest(data: ["tealium_event": "view"])))
        config.batchingBypassKeys = ["view"]
        dispatchManager.config = config
        XCTAssertFalse(dispatchManager.canQueueRequest(TealiumTrackRequest(data: ["tealium_event": "view"])))
    }

}

class MockPersistentQueue: TealiumPersistentDispatchQueue {
    override func removeOldDispatches(_ maxQueueSize: Int, since: Date? = nil) {
        XCTAssertNotNil(since)
        DispatchQueueModuleTests.expiredDispatchesExpectation!.fulfill()
    }
}

extension DispatchQueueModuleTests: ModuleDelegate {
    func processRemoteCommandRequest(_ request: TealiumRequest) {

    }

    func requestTrack(_ track: TealiumTrackRequest) {

    }

    func requestDequeue(reason: String) {

    }

}

class DispatchQueueDummyDispatcher: Dispatcher {
    var isReady: Bool = true

    required init(config: TealiumConfig, delegate: ModuleDelegate, completion: ModuleCompletion?) {
        self.config = config
    }

    func dynamicTrack(_ request: TealiumRequest, completion: ModuleCompletion?) {
        guard request is TealiumRemoteAPIRequest else {
            return
        }
        DispatchQueueModuleTests.remoteAPIExpectation!.fulfill()
    }

    var id: String = "DispatchQueueDummyDispatcher"

    var config: TealiumConfig

}
