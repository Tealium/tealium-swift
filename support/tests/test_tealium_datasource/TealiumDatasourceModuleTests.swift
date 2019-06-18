//
//  TealiumDatasourceTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 3/8/17.
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import Tealium

class TealiumDatasourceModuleTests: XCTestCase {

    var delegateExpectationSuccess: XCTestExpectation?
    var delegateExpectationFail: XCTestExpectation?
    var process: TealiumRequest?

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testMinimumProtocolsReturn() {
        let expectation = self.expectation(description: "minimumProtocolsReturned")
        let helper = TestTealiumHelper()
        let module = TealiumDatasourceModule(delegate: nil)
        helper.modulesReturnsMinimumProtocols(module: module) { success, failingProtocols in

            expectation.fulfill()
            XCTAssertTrue(success, "Not all protocols returned. Failing protocols: \(failingProtocols)")

        }

        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testConfigExtension() {
        var config = TealiumConfig(account: "test",
                                   profile: "test",
                                   environment: "test",
                                   datasource: nil,
                                   optionalData: nil)
        XCTAssertTrue(config.optionalData.isEmpty)

        let datasourceString = "test_id"
        config = TealiumConfig(account: "test",
                               profile: "test",
                               environment: "test",
                               datasource: datasourceString,
                               optionalData: nil)
        XCTAssertTrue(config.optionalData.isEmpty == false)
        XCTAssertTrue(config.optionalData.count == 1)
        XCTAssertTrue(config.optionalData["com.tealium.datasource"] as! String == datasourceString)

        let optionalData = ["com.tealium.datasource": "b",
                            "x": "y"]
        config = TealiumConfig(account: "test",
                               profile: "test",
                               environment: "test",
                               datasource: datasourceString,
                               optionalData: optionalData)

        XCTAssertTrue(config.optionalData.isEmpty == false)
        XCTAssertTrue(config.optionalData.count == 2)
        XCTAssertTrue(config.optionalData["com.tealium.datasource"] as! String == datasourceString)
    }

    func testTrack() {
        let datasourceString = "test"
        let config = TealiumConfig(account: "test",
                                   profile: "test",
                                   environment: "test",
                                   datasource: datasourceString,
                                   optionalData: nil)
        let module = TealiumDatasourceModule(delegate: self)
        module.enable(TealiumEnableRequest(config: config, enableCompletion: nil))

        delegateExpectationSuccess = self.expectation(description: "datasourceTrack")
        let tealiumTrack = TealiumTrackRequest(data: [:],
                                               completion: nil)
        module.track(tealiumTrack)

        self.waitForExpectations(timeout: 1.0, handler: nil)

        guard let track = self.process as? TealiumTrackRequest else {
            XCTFail("No track data returned from delegate.")
            return
        }

        let data = track.data

        guard let datasource = data["tealium_datasource"] as? String else {
            XCTFail("Datasource string from config was not passed to track call.")
            return
        }

        XCTAssertTrue(datasource == datasourceString, "Datasource variable returned:\(datasource) did not match inserted datasource value:\(datasourceString)")
    }

}

extension TealiumDatasourceModuleTests: TealiumModuleDelegate {

    func tealiumModuleFinished(module: TealiumModule, process: TealiumRequest) {
        delegateExpectationSuccess?.fulfill()

        self.process = process
    }

    func tealiumModuleRequests(module: TealiumModule?, process: TealiumRequest) {
        delegateExpectationSuccess?.fulfill()

        self.process = process
    }

    func tealiumModuleFinishedReport(fromModule: TealiumModule, module: TealiumModule, process: TealiumRequest) {
        delegateExpectationSuccess?.fulfill()

        self.process = process
    }

}
