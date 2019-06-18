//
//  TealiumDefaultsStorageModuleTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 6/13/17.
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import Tealium

class TealiumDefaultsStorageModuleTests: XCTestCase {

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
        let module = TealiumDefaultsStorageModule(delegate: nil)
        helper.modulesReturnsMinimumProtocols(module: module) { success, failingProtocols in

            expectation.fulfill()
            XCTAssertTrue(success, "Not all protocols returned. Failing protocols: \(failingProtocols)")

        }

        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testSaveLoad() {
        let module = TealiumDefaultsStorageModule(delegate: nil)
        let helper = TestTealiumHelper()
        let req = TealiumEnableRequest(config: helper.getConfig(), enableCompletion: nil)
        module.enable(req)
        let saveRequest = TealiumSaveRequest(name: "unittests", data: ["testing": "123"])
        module.save(saveRequest)
        let loadRequest = TealiumLoadRequest(name: "unittests") { _, info, _ in
            guard let inf = info else {
                XCTFail("dictionary not returned")
                return
            }
            XCTAssertTrue(inf["testing"] as? String == "123")
        }
        module.load(loadRequest)
    }

    func testDeleteAll() {
        let module = TealiumDefaultsStorageModule(delegate: nil)
        let helper = TestTealiumHelper()
        let req = TealiumEnableRequest(config: helper.getConfig(), enableCompletion: nil)
        module.enable(req)
        let saveRequest = TealiumSaveRequest(name: "unittests", data: ["testing": "123"])
        module.save(saveRequest)

        let deleteRequest = TealiumDeleteRequest(name: "unittests")
        module.delete(deleteRequest)
        let loadRequest = TealiumLoadRequest(name: "unittests") { _, info, _ in
            XCTAssertTrue(info == nil)
        }
        module.load(loadRequest)
    }

}
