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
    }

    func testRequestVisitorProfileRun() {
        let expect = expectation(description: "testRequestVisitorProfileRunWhenFirstEventSentTrue")
        let context = TestTealiumHelper.context(with: config)
        let module = VisitorServiceModule(context: context, delegate: self, diskStorage: mockDiskStorage, visitorServiceManager: mockVisitorServiceManager)
        module.retrieveProfileDelayed(visitorId: "test") {
            XCTAssertEqual(2, self.mockVisitorServiceManager.requestVisitorProfileCount)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 3.0)
    }

    func testBatchTrackRetreiveProfileExecuted() {
        let expect = expectation(description: "testBatchTrackRetreiveProfileExecuted")
        let context = TestTealiumHelper.context(with: config)
        let module = VisitorServiceModule(context: context, delegate: self, diskStorage: mockDiskStorage, visitorServiceManager: mockVisitorServiceManager)
        let trackRequest = TealiumTrackRequest(data: ["hello": "world", "tealium_visitor_id": "test"])
        let batchTrackRequest = TealiumBatchTrackRequest(trackRequests: [trackRequest])
        module.willTrack(request: batchTrackRequest)
        TealiumQueues.backgroundSerialQueue.asyncAfter(deadline: .now() + 3.0) {
            XCTAssertEqual(2, self.mockVisitorServiceManager.requestVisitorProfileCount)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 10.0)
    }

    func testTrackRetreiveProfileExecuted() {
        let expect = expectation(description: "testTrackRetreiveProfileExecuted")
        let context = TestTealiumHelper.context(with: config)
        let module = VisitorServiceModule(context: context, delegate: self, diskStorage: mockDiskStorage, visitorServiceManager: mockVisitorServiceManager)
        let trackRequest = TealiumTrackRequest(data: ["hello": "world", "tealium_visitor_id": "test"])
        module.willTrack(request: trackRequest)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            TealiumQueues.backgroundSerialQueue.async {
                XCTAssertEqual(2, self.mockVisitorServiceManager.requestVisitorProfileCount)
                expect.fulfill()
            }
        }
        wait(for: [expect], timeout: 10)
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
