//
//  TealiumModuleTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 10/11/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import ObjectiveC
@testable import Tealium
import XCTest

class TealiumModuleTests: XCTestCase {

    var defaultModule: TealiumModule?
    var expectationSuccess: XCTestExpectation?
    var expectationFailure: XCTestExpectation?
    var returnedProcess: TealiumRequest?

    override func setUp() {
        super.setUp()

        defaultModule = TealiumModule(delegate: self)
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        defaultModule = nil
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testInitPerformance() {
        let iterations = 1000

        self.measure {

            for _ in 0...iterations {

                _ = TealiumModule(delegate: nil)
            }
        }
    }

    func testMinimumProtocolsReturn() {
        let expectation = self.expectation(description: "minimumProtocolsReturned")
        let helper = TestTealiumHelper()
        let module = TealiumModule(delegate: nil)
        helper.modulesReturnsMinimumProtocols(module: module) { success, failingProtocols in

            expectation.fulfill()
            XCTAssertTrue(success, "Not all protocols returned. Failing protocols: \(failingProtocols)")

        }

        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

    // TODO: Expand auto process checks to subclasses
    func testAutoProcessEnable() {
        // Send various process options into auto process function to make sure routing is correct.
        expectationSuccess = self.expectation(description: "testSuccess")

        // Enable process
        var processSuccess = TealiumEnableRequest(config: testTealiumConfig, enableCompletion: nil)
        let successResponse = TealiumModuleResponse(moduleName: "testModule",
                                                    success: true,
                                                    error: nil)
        processSuccess.moduleResponses.append(successResponse)

        defaultModule?.handle(processSuccess)

        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

//    func testAutoProcessDisable() {
//        
//        expectationSuccess = self.expectation(description: "testSuccess")
//
//        let processSuccess = TealiumDisableRequest()
//        processSuccess.successful = true
//        
//        defaultModule?.auto(processSuccess)
//        
//        self.waitForExpectations(timeout: 1.0, handler: nil)
//    }

    func testAutoProcessTrackSucceed() {
        expectationSuccess = self.expectation(description: "testSuccess")

        var track = TealiumTrackRequest(data: [String: AnyObject](),
                                        completion: nil)
        let successResponse = TealiumModuleResponse(moduleName: "testModule",
                                                    success: true,
                                                    error: nil)
        track.moduleResponses.append(successResponse)

        defaultModule?.handle(track)

        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

    // Nil data not accepted by system.
//    func testAutoProcessTrackFail() {
//        
//        expectationFailure = self.expectation(description: "testFail")
//        
//        // No track data!
//        let processSuccess = TealiumTrackRequest(data: [String:Any](),
//                                                 completion: nil)
//        processSuccess.successful = false
//        
//        defaultModule?.auto(processSuccess)
//        
//        self.waitForExpectations(timeout: 1.0, handler: nil)
//    }

}

extension TealiumModuleTests: TealiumModuleDelegate {

    func tealiumModuleFinished(module: TealiumModule, process: TealiumRequest) {
        returnedProcess = process

        for response in process.moduleResponses where response.success == false {
            expectationFailure?.fulfill()
        }

        expectationSuccess?.fulfill()
    }

    func tealiumModuleRequests(module: TealiumModule?, process: TealiumRequest) {

    }

}
