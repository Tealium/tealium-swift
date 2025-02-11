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

    let mockDiskStorage = MockTealiumDiskStorage()
    let mockVisitorServiceManager = MockTealiumVisitorServiceManager()
    let config = TealiumConfig(account: "testAccount", profile: "testProfile", environment: "testEnv")
    lazy var context = TestTealiumHelper.context(with: config)
    lazy var module = VisitorServiceModule(context: context, delegate: self, diskStorage: mockDiskStorage, visitorServiceManager: mockVisitorServiceManager) { block in
        block()
    }

    func testRequestVisitorProfileRun() {
        let expect = expectation(description: "testRequestVisitorProfileRunWhenFirstEventSentTrue")
        module.retrieveProfileDelayed(visitorId: self.mockVisitorServiceManager.currentVisitorId!) {
            XCTAssertEqual(1, self.mockVisitorServiceManager.requestVisitorProfileCount)
            expect.fulfill()
        }
        waitForExpectations(timeout: 0.1)
    }

    func testRequestVisitorProfileNotRun() {
        let expect = expectation(description: "visitor profile not requested when visitor id is different")
        expect.isInverted = true
        module.retrieveProfileDelayed(visitorId: self.mockVisitorServiceManager.currentVisitorId! + "buster") {
            expect.fulfill()
        }
        waitForExpectations(timeout: 0.1)
    }

    func testBatchTrackRetreiveProfileExecuted() {
        let trackRequest = TealiumTrackRequest(data: ["hello": "world", "tealium_visitor_id": self.mockVisitorServiceManager.currentVisitorId!])
        let batchTrackRequest = TealiumBatchTrackRequest(trackRequests: [trackRequest])
        module.willTrack(request: batchTrackRequest)
        XCTAssertEqual(1, self.mockVisitorServiceManager.requestVisitorProfileCount)
    }

    func testTrackRetreiveProfileExecuted() {
        let trackRequest = TealiumTrackRequest(data: ["hello": "world", "tealium_visitor_id": self.mockVisitorServiceManager.currentVisitorId!])
        module.willTrack(request: trackRequest)
        XCTAssertEqual(1, self.mockVisitorServiceManager.requestVisitorProfileCount)
    }

    func testIntervalSince() {
        let timeTraveler = TimeTraveler()

        var mockedLastFetch = timeTraveler.travel(by: (60 * 5 + 1) * -1)
        var expectedResult: Int64 = 301_000

        var actualResult = module.intervalSince(lastFetch: mockedLastFetch, timeTraveler.generateDate())

        XCTAssertEqual(expectedResult, actualResult)

        mockedLastFetch = timeTraveler.travel(by: (60 * 4 + 1) * -1)
        expectedResult = 241_000

        actualResult = module.intervalSince(lastFetch: mockedLastFetch, timeTraveler.generateDate())

        XCTAssertEqual(expectedResult, actualResult)

    }

    func testShouldFetch() {
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
