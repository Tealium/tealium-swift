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
    var context: TealiumContext!

    override func setUp() {
        super.setUp()
        config = TealiumConfig(account: "testAccount", profile: "testProfile", environment: "testEnv")
        context = TestTealiumHelper.context(with: config)
        mockDiskStorage = MockTealiumDiskStorage()
        visitorServiceManager = VisitorServiceManager(config: config, delegate: nil, diskStorage: mockDiskStorage)
    }

    func testRequestVisitorProfileRun() {
        let expect = expectation(description: "testRequestVisitorProfileRunWhenFirstEventSentTrue")
        let module = VisitorServiceModule(context: context, delegate: self, diskStorage: mockDiskStorage, visitorServiceManager: mockVisitorServiceManager)
        TealiumQueues.backgroundSerialQueue.async {
            module.retrieveProfileDelayed(visitorId: self.mockVisitorServiceManager.currentVisitorId!) {
                XCTAssertEqual(2, self.mockVisitorServiceManager.requestVisitorProfileCount)
                expect.fulfill()
            }
        }
        wait(for: [expect], timeout: 10.0)
    }

    func testRequestVisitorProfileNotRun() {
        let expect = expectation(description: "visitor profile not requested when visitor id is different")
        expect.isInverted = true
        let module = VisitorServiceModule(context: context, delegate: self, diskStorage: mockDiskStorage, visitorServiceManager: mockVisitorServiceManager)
        TealiumQueues.backgroundSerialQueue.async {
            module.retrieveProfileDelayed(visitorId: self.mockVisitorServiceManager.currentVisitorId! + "buster") {
                expect.fulfill()
            }
        }
        wait(for: [expect], timeout: 5.0)
    }

    func testBatchTrackRetreiveProfileExecuted() {
        let expect = expectation(description: "testBatchTrackRetreiveProfileExecuted")
        let context = TestTealiumHelper.context(with: config)
        let module = VisitorServiceModule(context: context, delegate: self, diskStorage: mockDiskStorage, visitorServiceManager: mockVisitorServiceManager)
        TealiumQueues.backgroundSerialQueue.async {
            let trackRequest = TealiumTrackRequest(data: ["hello": "world", "tealium_visitor_id": self.mockVisitorServiceManager.currentVisitorId!])
            let batchTrackRequest = TealiumBatchTrackRequest(trackRequests: [trackRequest])
            module.willTrack(request: batchTrackRequest)
            TealiumQueues.backgroundSerialQueue.asyncAfter(deadline: .now() + 3.0) {
                XCTAssertEqual(2, self.mockVisitorServiceManager.requestVisitorProfileCount)
                expect.fulfill()
            }
        }
        wait(for: [expect], timeout: 10.0)
    }

    func testTrackRetreiveProfileExecuted() {
        let expect = expectation(description: "testTrackRetreiveProfileExecuted")
        let context = TestTealiumHelper.context(with: config)
        let module = VisitorServiceModule(context: context, delegate: self, diskStorage: mockDiskStorage, visitorServiceManager: mockVisitorServiceManager)
        TealiumQueues.backgroundSerialQueue.async {
            let trackRequest = TealiumTrackRequest(data: ["hello": "world", "tealium_visitor_id": self.mockVisitorServiceManager.currentVisitorId!])
            module.willTrack(request: trackRequest)
            TealiumQueues.backgroundSerialQueue.asyncAfter(deadline: .now() + 3.0) {
                TealiumQueues.backgroundSerialQueue.async {
                    XCTAssertEqual(2, self.mockVisitorServiceManager.requestVisitorProfileCount)
                    expect.fulfill()
                }
            }
        }
        wait(for: [expect], timeout: 10)
    }

    func testIntervalSince() {
        let timeTraveler = TimeTraveler()

        var mockedLastFetch = timeTraveler.travel(by: (60 * 5 + 1) * -1)
        var expectedResult: Int64 = 301_000
        
        let module = VisitorServiceModule(context: context, delegate: self, diskStorage: mockDiskStorage, visitorServiceManager: mockVisitorServiceManager)

        var actualResult = module.intervalSince(lastFetch: mockedLastFetch)

        XCTAssertEqual(expectedResult, actualResult)

        mockedLastFetch = timeTraveler.travel(by: (60 * 4 + 1) * -1)
        expectedResult = 241_000

        actualResult = module.intervalSince(lastFetch: mockedLastFetch)

        XCTAssertEqual(expectedResult, actualResult)

    }

    func testShouldFetch() {
        
        let module = VisitorServiceModule(context: context, delegate: self, diskStorage: mockDiskStorage, visitorServiceManager: mockVisitorServiceManager)
        var result = module.shouldFetch(basedOn: Date(), interval: 300_000, environment: "dev")
        XCTAssertTrue(result)

        result = module.shouldFetch(basedOn: Date(), interval: nil, environment: "prod")
        XCTAssertTrue(result)

        let timeTraveler = TimeTraveler()
        var mockedLastFetch = timeTraveler.travel(by: (60 * 5 + 1) * -1)
        result = module.shouldFetch(basedOn: mockedLastFetch, interval: 300_000, environment: "prod")
        XCTAssertTrue(result)

        mockedLastFetch = timeTraveler.travel(by: (60 * 4 + 1) * -1)
        result = module.shouldFetch(basedOn: mockedLastFetch, interval: 300_000, environment: "prod")
        XCTAssertFalse(result)
    }

    func testShouldFetchVisitorProfile() {
        let timeTraveler = TimeTraveler()

        var tealConfig = TealiumConfig(account: "test", profile: "test", environment: "dev")
        
        let module = VisitorServiceModule(context: context, delegate: self, diskStorage: mockDiskStorage, visitorServiceManager: mockVisitorServiceManager)
        module.config = tealConfig
        mockVisitorServiceManager.lastFetch = timeTraveler.travel(by: (60 * 2 + 1) * -1)
        XCTAssertTrue(module.shouldFetchVisitorProfile)

        tealConfig = TealiumConfig(account: "test", profile: "test", environment: "prod")
        tealConfig.visitorServiceRefresh = .every(0, .seconds)
        mockVisitorServiceManager.lastFetch = timeTraveler.travel(by: (60 * 2 + 1) * -1)
        XCTAssertTrue(module.shouldFetchVisitorProfile)

        module.config = tealConfig
        mockVisitorServiceManager.lastFetch = timeTraveler.travel(by: (60 * 5 + 1) * -1)
        XCTAssertTrue(module.shouldFetchVisitorProfile)

        // resetting back to default
        tealConfig.visitorServiceRefresh = .every(5, .minutes)
        mockVisitorServiceManager.lastFetch = timeTraveler.travel(by: (60 * 2 + 1) * -1)
        XCTAssertFalse(module.shouldFetchVisitorProfile)
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
