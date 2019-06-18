//
//  TealiumLifecycleModuleTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 2/14/17.
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import Tealium

class TealiumLifecycleModuleTests: XCTestCase {

    var expectationRequest: XCTestExpectation?
    var requestProcess: TealiumRequest?

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        expectationRequest = nil
        requestProcess = nil
        super.tearDown()
    }

    func testMinimumProtocolsReturn() {
        let expectation = self.expectation(description: "minimumProtocolsReturned")
        let helper = TestTealiumHelper()
        let module = TealiumLifecycleModule(delegate: nil)
        helper.modulesReturnsMinimumProtocols(module: module) { success, failingProtocols in

            expectation.fulfill()
            XCTAssertTrue(success, "Not all protocols returned. Failing protocols: \(failingProtocols)")

        }

        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testProcessAcceptable() {
        let lifecycleModule = TealiumLifecycleModule(delegate: nil)
        // Should only accept launch calls for first events
        XCTAssertTrue(lifecycleModule.processAcceptable(type: .launch))
        XCTAssertFalse(lifecycleModule.processAcceptable(type: .sleep))
        XCTAssertFalse(lifecycleModule.processAcceptable(type: .wake))

        lifecycleModule.lastProcess = .launch
        XCTAssertFalse(lifecycleModule.processAcceptable(type: .launch))
        XCTAssertTrue(lifecycleModule.processAcceptable(type: .sleep))
        XCTAssertFalse(lifecycleModule.processAcceptable(type: .wake))

        lifecycleModule.lastProcess = .sleep
        XCTAssertFalse(lifecycleModule.processAcceptable(type: .launch))
        XCTAssertFalse(lifecycleModule.processAcceptable(type: .sleep))
        XCTAssertTrue(lifecycleModule.processAcceptable(type: .wake))

        lifecycleModule.lastProcess = .wake
        XCTAssertFalse(lifecycleModule.processAcceptable(type: .launch))
        XCTAssertTrue(lifecycleModule.processAcceptable(type: .sleep))
        XCTAssertFalse(lifecycleModule.processAcceptable(type: .wake))
    }

    func testAllAdditionalKeysPresent() {
        expectationRequest = expectation(description: "allKeysPresent")

        let lifecycleModule = TealiumLifecycleModule(delegate: self)
        let config = TealiumConfig(account: "",
                                   profile: "",
                                   environment: "",
                                   optionalData: nil)
        lifecycleModule.enable(TealiumEnableRequest(config: config, enableCompletion: nil))
        self.waitForExpectations(timeout: 20.0, handler: nil)

        guard let request = requestProcess as? TealiumTrackRequest else {
            XCTFail("\n\nFailure: Process not a track request.\n")
            return
        }
        let returnData = request.data

        let expectedKeys = ["tealium_event"]

        let missingKeys = TestTealiumHelper.missingKeys(fromDictionary: returnData, keys: expectedKeys)

        XCTAssertTrue(missingKeys.count == 0, "Unexpected keys missing:\(missingKeys)")
    }

}

extension TealiumLifecycleModuleTests: TealiumModuleDelegate {

    func tealiumModuleFinished(module: TealiumModule, process: TealiumRequest) {
        // Lifecycle listening for all modules to finish enabling, since we're testing, mock all modules ready.
        if process as? TealiumEnableRequest != nil {
            module.handleReport(testEnableRequest)
            return
        }
    }

    func tealiumModuleRequests(module: TealiumModule?, process: TealiumRequest) {
        if let p = process as? TealiumTrackRequest {
            expectationRequest?.fulfill()
            requestProcess = p
        }
    }

}
