//
//  VisitorServiceModuleTests.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumCore
@testable import TealiumVisitorService
import XCTest

class VisitorServiceModuleTests: XCTestCase {

    var visitorServiceManager: VisitorServiceManager?
    var mockDiskStorage: MockTealiumDiskStorage!
    var mockVisitorServiceManager = MockTealiumVisitorServiceManager()
    var config: TealiumConfig!

    override func setUp() {
        super.setUp()
        config = TealiumConfig(account: "testAccount", profile: "testProfile", environment: "testEnv")
        mockDiskStorage = MockTealiumDiskStorage()
        visitorServiceManager = VisitorServiceManager(config: config, delegate: nil, diskStorage: mockDiskStorage)
        visitorServiceManager?.visitorId = "test"
    }

    func testRequestVisitorProfileRunWhenFirstEventSentTrue() {
        let expect = expectation(description: "testRequestVisitorProfileRunWhenFirstEventSentTrue")
        let context = TestTealiumHelper.context(with: config)
        let module = VisitorServiceModule(context: context, delegate: self, diskStorage: mockDiskStorage, visitorServiceManager: mockVisitorServiceManager)
        module.firstEventSent = true
        module.retrieveProfile(visitorId: "test") {
            XCTAssertEqual(1, self.mockVisitorServiceManager.requestVisitorProfileCount)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 3.0)
    }

    func testStartProfileUpdatesRunWhenFirstEventSentFalse() {
        let expect = expectation(description: "testStartProfileUpdatesRunWhenFirstEventSentFalse")
        let context = TestTealiumHelper.context(with: config)
        let module = VisitorServiceModule(context: context, delegate: self, diskStorage: mockDiskStorage, visitorServiceManager: mockVisitorServiceManager)
        module.firstEventSent = false
        module.retrieveProfile(visitorId: "test") {
            XCTAssertEqual(1, self.mockVisitorServiceManager.startProfileUpdatesCount)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 3.0)
    }

    func testBatchTrackRetreiveProfileExecuted() {
        let expect = expectation(description: "testBatchTrackRetreiveProfileExecuted")
        let context = TestTealiumHelper.context(with: config)
        let module = VisitorServiceModule(context: context, delegate: self, diskStorage: mockDiskStorage, visitorServiceManager: mockVisitorServiceManager)
        module.firstEventSent = true
        let trackRequest = TealiumTrackRequest(data: ["hello": "world", "tealium_visitor_id": "test"])
        let batchTrackRequest = TealiumBatchTrackRequest(trackRequests: [trackRequest])
        module.willTrack(request: batchTrackRequest)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            XCTAssertEqual(1, self.mockVisitorServiceManager.requestVisitorProfileCount)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 3.0)
    }

    func testTrackRetreiveProfileExecuted() {
        let expect = expectation(description: "testTrackRetreiveProfileExecuted")
        let context = TestTealiumHelper.context(with: config)
        let module = VisitorServiceModule(context: context, delegate: self, diskStorage: mockDiskStorage, visitorServiceManager: mockVisitorServiceManager)
        module.firstEventSent = true
        let trackRequest = TealiumTrackRequest(data: ["hello": "world", "tealium_visitor_id": "test"])
        module.willTrack(request: trackRequest)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            XCTAssertEqual(1, self.mockVisitorServiceManager.requestVisitorProfileCount)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 3.0)
    }

}

extension VisitorServiceModuleTests: ModuleDelegate {
    func processRemoteCommandRequest(_ request: TealiumRequest) {

    }

    func requestDequeue(reason: String) {

    }

    func requestTrack(_ track: TealiumTrackRequest) {

    }

}
