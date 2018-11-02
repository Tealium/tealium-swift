//
//  DispatchQueueModuleTests.swift
//  tealium-swift
//
//  Created by Craig Rouse on 01/05/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation

@testable import Tealium
import XCTest

class TealiumDispatchQueueModuleTests: XCTestCase {

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
        let module = TealiumDispatchQueueModule(delegate: nil)
        helper.modulesReturnsMinimumProtocols(module: module) { success, failingProtocols in

            expectation.fulfill()
            XCTAssertTrue(success, "Not all protocols returned. Failing protocols: \(failingProtocols)")

        }

        self.waitForExpectations(timeout: 4.0, handler: nil)
    }

}
