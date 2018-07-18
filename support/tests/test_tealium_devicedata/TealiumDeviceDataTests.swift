//
//  TealiumDeviceDataTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 8/1/17.
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//

@testable import Tealium
import XCTest

class TealiumDeviceDataTests: XCTestCase {

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
        let module = TealiumDeviceDataModule(delegate: nil)
        helper.modulesReturnsMinimumProtocols(module: module) { success, failingProtocols in

            expectation.fulfill()
            XCTAssertTrue(success, "Not all protocols returned. Failing protocols: \(failingProtocols)")

        }

        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

}
