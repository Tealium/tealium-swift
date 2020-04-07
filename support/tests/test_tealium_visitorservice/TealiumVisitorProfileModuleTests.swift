//
//  VisitorProfileModuleTests.swift
//  tealium-swift
//
//  Created by Christina Sund on 6/17/19.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumCore
@testable import TealiumVisitorService
import XCTest

class TealiumVisitorProfileModuleTests: XCTestCase {

    var visitorProfileManager: TealiumVisitorProfileManager?
    var mockDiskStorage: MockTealiumDiskStorage!
    let tealHelper = TestTealiumHelper()
    var expectations = [XCTestExpectation]()
    let waiter = XCTWaiter()
    var currentTest = ""
    let maxRuns = 10 // max runs for each test

    func getExpectation(forDescription: String) -> XCTestExpectation? {
        let exp = expectations.filter {
            $0.description == forDescription
        }
        if exp.count > 0 {
            return exp[0]
        }
        return nil
    }

    override func setUp() {
        super.setUp()
        mockDiskStorage = MockTealiumDiskStorage()
        visitorProfileManager = TealiumVisitorProfileManager(config: tealHelper.getConfig(), delegates: nil, diskStorage: mockDiskStorage)
        visitorProfileManager?.visitorId = "test"
    }

    override func tearDown() {
        super.tearDown()
    }

    func testModuleConfig() {
        let module = TealiumVisitorServiceModule.moduleConfig()
        XCTAssertNotNil(module)
    }

    func testEnable() {
        let module = TealiumVisitorServiceModule(delegate: TestTealiumHelper())
        let enableRequest = TealiumEnableRequest(config: testTealiumConfig, enableCompletion: nil)
        module.enable(enableRequest)
        XCTAssertTrue(module.isEnabled)
    }

    func testDisable() {
        let module = TealiumVisitorServiceModule(delegate: TestTealiumHelper())
        let disableRequest = TealiumDisableRequest()
        module.disable(disableRequest)
        XCTAssertFalse(module.isEnabled)
    }

    func testMinimumProtocolsReturn() {
        let expect = expectation(description: "minimumProtocolsReturned")
        let helper = TestTealiumHelper()
        let module = TealiumVisitorServiceModule(delegate: nil)
        helper.modulesReturnsMinimumProtocols(module: module) { success, failingProtocols in
            // track is expected to fail
            expect.fulfill()
            XCTAssertTrue(success, "Not all protocols returned. Failing protocols: \(failingProtocols)")
        }
        waiter.wait(for: [expect], timeout: 1.0)
    }

    func testVisitorProfileServiceDisabled() {
        currentTest = "testVisitorProfileServiceDisabled"
        self.expectations.append(expectation(description: "testVisitorProfileServiceDisabled"))
        let module = TealiumVisitorServiceModule(delegate: nil)
        module.isEnabled = false
        let track = TealiumTrackRequest(data: ["visitor_profile": "true"], completion: nil)
        module.track(track)
        waiter.wait(for: expectations, timeout: 5.0)
    }

    func testRequestVisitorProfileRunWhenFirstEventSentTrue() {
        currentTest = "testRequestVisitorProfileRunWhenFirstEventSentTrue"
        self.expectations.append(expectation(description: "testRequestVisitorProfileRunWhenFirstEventSentTrue"))
        let module = TealiumVisitorServiceModule(delegate: TestTealiumHelper())
        let enableRequest = TealiumEnableRequest(config: testTealiumConfig, enableCompletion: nil)
        let mock = MockTealiumVisitorProfileManager()
        module.enable(enableRequest, visitor: mock)
        module.firstEventSent = true
        module.retrieveProfile(visitorId: "test")
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            XCTAssertEqual(1, mock.requestVisitorProfileCount)
        }
        waiter.wait(for: expectations, timeout: 5.0)
    }

    func testStartProfileUpdatesRunWhenFirstEventSentFalse() {
        currentTest = "testStartProfileUpdatesRunWhenFirstEventSentFalse"
        self.expectations.append(expectation(description: "testStartProfileUpdatesRunWhenFirstEventSentFalse"))
        let module = TealiumVisitorServiceModule(delegate: TestTealiumHelper())
        let enableRequest = TealiumEnableRequest(config: testTealiumConfig, enableCompletion: nil)
        let mock = MockTealiumVisitorProfileManager()
        module.enable(enableRequest, visitor: mock)
        module.firstEventSent = false
        module.retrieveProfile(visitorId: "test")
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            XCTAssertEqual(1, mock.startProfileUpdatesCount)
        }
        waiter.wait(for: expectations, timeout: 5.0)
    }

    func testVisitorServiceNotEnabledUponBatchTrackAndDidFinishWithNoResponseExecuted() {
        expectations.append(expectation(description: "testVisitorServiceNotEnabledUponBatchTrackAndDidFinishWithNoResponseExecuted"))
        currentTest = "testVisitorServiceNotEnabledUponBatchTrackAndDidFinishWithNoResponseExecuted"
        let module = TealiumVisitorServiceModule(delegate: self)
        let trackRequest = TealiumTrackRequest(data: ["hello": "world"], completion: nil)
        let batchTrackRequest = TealiumBatchTrackRequest(trackRequests: [trackRequest], completion: nil)
        module.isEnabled = false
        module.batchTrack(batchTrackRequest)
        currentTest = ""
        waiter.wait(for: expectations, timeout: 5.0)
    }

    func testVisitorIdNilUponBatchTrackAndDidFinishWithNoResponseExecuted() {
        expectations.append(expectation(description: "testVisitorIdNilUponBatchTrackAndDidFinishWithNoResponseExecuted"))
        currentTest = "testVisitorIdNilUponBatchTrackAndDidFinishWithNoResponseExecuted"
        let module = TealiumVisitorServiceModule(delegate: self)
        let trackRequest = TealiumTrackRequest(data: ["hello": "world"], completion: nil)
        let batchTrackRequest = TealiumBatchTrackRequest(trackRequests: [trackRequest], completion: nil)
        module.isEnabled = true
        module.batchTrack(batchTrackRequest)
        currentTest = ""
        waiter.wait(for: expectations, timeout: 10.0)
    }

    func testBatchTrackRetreiveProfileExecuted() {
        expectations.append(expectation(description: "testBatchTrackRetreiveProfileExecuted"))
        let module = TealiumVisitorServiceModule(delegate: self)
        let enableRequest = TealiumEnableRequest(config: testTealiumConfig, enableCompletion: nil)
        let mock = MockTealiumVisitorProfileManager()
        module.enable(enableRequest, visitor: mock)
        module.firstEventSent = true
        let trackRequest = TealiumTrackRequest(data: ["hello": "world", "tealium_visitor_id": "test"], completion: nil)
        let batchTrackRequest = TealiumBatchTrackRequest(trackRequests: [trackRequest], completion: nil)
        module.isEnabled = true
        module.batchTrack(batchTrackRequest)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            XCTAssertEqual(1, mock.requestVisitorProfileCount)
        }
        waiter.wait(for: expectations, timeout: 5.0)
    }

    func testVisitorServiceNotEnabledUponTrackAndDidFinishWithNoResponseExecuted() {
        expectations.append(expectation(description: "testVisitorServiceNotEnabledUponTrackAndDidFinishWithNoResponseExecuted"))
        currentTest = "testVisitorServiceNotEnabledUponTrackAndDidFinishWithNoResponseExecuted"
        let module = TealiumVisitorServiceModule(delegate: self)
        let trackRequest = TealiumTrackRequest(data: ["hello": "world"], completion: nil)
        module.isEnabled = false
        module.track(trackRequest)
        currentTest = ""
        waiter.wait(for: expectations, timeout: 5.0)
    }

    func testVisitorIdNilUponTrackAndDidFinishWithNoResponseExecuted() {
        expectations.append(expectation(description: "testVisitorIdNilUponTrackAndDidFinishWithNoResponseExecuted"))
        currentTest = "testVisitorIdNilUponTrackAndDidFinishWithNoResponseExecuted"
        let module = TealiumVisitorServiceModule(delegate: self)
        let trackRequest = TealiumTrackRequest(data: ["hello": "world"], completion: nil)
        module.isEnabled = true
        module.track(trackRequest)
        currentTest = ""
        waiter.wait(for: expectations, timeout: 5.0)
    }

    func testTrackRetreiveProfileExecuted() {
        expectations.append(expectation(description: "testTrackRetreiveProfileExecuted"))
        let module = TealiumVisitorServiceModule(delegate: self)
        let enableRequest = TealiumEnableRequest(config: testTealiumConfig, enableCompletion: nil)
        let mock = MockTealiumVisitorProfileManager()
        module.enable(enableRequest, visitor: mock)
        module.firstEventSent = true
        let trackRequest = TealiumTrackRequest(data: ["hello": "world", "tealium_visitor_id": "test"], completion: nil)
        module.isEnabled = true
        module.track(trackRequest)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            XCTAssertEqual(1, mock.requestVisitorProfileCount)
        }
        waiter.wait(for: expectations, timeout: 5.0)
    }

}

extension TealiumVisitorProfileModuleTests: TealiumModuleDelegate {
    func tealiumModuleRequests(module: TealiumModule?, process: TealiumRequest) {
        if let _ = process as? TealiumEnableRequest,
            currentTest == "testInitialVisitorProfileSettingsNotEnabled" {
            XCTAssertEqual(module?.isEnabled, false)
            getExpectation(forDescription: "testInitialVisitorProfileSettingsNotEnabled")?.fulfill()
        }
    }

    func tealiumModuleFinished(module: TealiumModule, process: TealiumRequest) {
        if let _ = process as? TealiumBatchTrackRequest {
            switch currentTest {
            case "testVisitorServiceNotEnabledUponBatchTrackAndDidFinishWithNoResponseExecuted":
                XCTAssertEqual(module.isEnabled, false)
                getExpectation(forDescription: "testVisitorServiceNotEnabledUponBatchTrackAndDidFinishWithNoResponseExecuted")?.fulfill()
            case "testVisitorIdNilUponBatchTrackAndDidFinishWithNoResponseExecuted":
                XCTAssertNil(process.moduleResponses.last?.info?["tealium_visitor_id"])
                getExpectation(forDescription: "testVisitorServiceNotEnabledUponBatchTrackAndDidFinishWithNoResponseExecuted")?.fulfill()
            case "testVisitorServiceNotEnabledUponTrackAndDidFinishWithNoResponseExecuted":
                XCTAssertEqual(module.isEnabled, false)
                self.getExpectation(forDescription: "testVisitorServiceNotEnabledUponTrackAndDidFinishWithNoResponseExecuted")?.fulfill()
            case "testVisitorIdNilUponTrackAndDidFinishWithNoResponseExecuted":
                print("")
                XCTAssertNil(process.moduleResponses.last?.info?["tealium_visitor_id"])
                getExpectation(forDescription: "testVisitorIdNilUponTrackAndDidFinishWithNoResponseExecuted")?.fulfill()
            default:
                break
            }
        }

    }

}
