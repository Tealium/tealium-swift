//
//  TealiumModule_CollectTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 11/1/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import Tealium

class TealiumCollectModuleTests: XCTestCase {

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
        let module = TealiumCollectModule(delegate: nil)
        helper.modulesReturnsMinimumProtocols(module: module) { success, failingProtocols in

            expectation.fulfill()
            XCTAssertTrue(success, "Not all protocols returned. Failing protocols: \(failingProtocols)")

        }

        self.waitForExpectations(timeout: 4.0, handler: nil)
    }

    func testEnableDisable() {
        // Need to know that the TealiumCollect instance was instantiated + that we have a base url.

        let collectModule = TealiumCollectModule(delegate: nil)

        let config = testTealiumConfig
        config.setLegacyDispatchMethod(true)
        collectModule.enable(TealiumEnableRequest(config: config, enableCompletion: nil))

        XCTAssertTrue(collectModule.collect != nil, "TealiumCollect did not initialize.")

        if let collect = collectModule.collect as? TealiumCollect {
            XCTAssertTrue(collect.getBaseURLString().isEmpty == false, "No base URL was provided or auto-initialized.")
            collectModule.disable(TealiumDisableRequest())
            let newCollect = collectModule.collect as? TealiumCollect
            XCTAssertTrue(newCollect == nil, "TealiumCollect instance did not de-initialize properly")
        } else {
            XCTFail("Collect module did not initialize properly")
        }
    }

    func testTrackNoAccount() {
        let collectModule = TealiumCollectModule(delegate: nil)
        let waiter = XCTWaiter(delegate: nil)
        let expectation = XCTestExpectation(description: "successful dispatch")
        let config = testTealiumConfig
        config.setLegacyDispatchMethod(true)
        collectModule.enable(TealiumEnableRequest(config: config, enableCompletion: nil))
        let track = TealiumTrackRequest(data: [String: Any]()) { _, info, _ in
            if let payload = info?["payload"] as? [String: Any] {
                XCTAssertNotNil(payload[TealiumKey.account])
                XCTAssertNotNil(payload[TealiumKey.profile])
                expectation.fulfill()
            } else {
                XCTFail("Collect Module: Expected track data was missing")
            }
        }

        collectModule.track(track)
        waiter.wait(for: [expectation], timeout: 1.0)
    }

    func testOverrideCollectURL() {
        testTealiumConfig.setCollectOverrideURL(string: "https://collect.tealiumiq.com/vdata/i.gif?tealium_account=tealiummobile&tealium_profile=someprofile")
        XCTAssertTrue(testTealiumConfig.optionalData[TealiumCollectKey.overrideCollectUrl] as! String == "https://collect.tealiumiq.com/vdata/i.gif?tealium_account=tealiummobile&tealium_profile=someprofile&")
    }

    func testOverrideCollectProfile() {
        testTealiumConfig.setCollectOverrideProfile(profile: "hello")
        XCTAssertTrue(testTealiumConfig.optionalData[TealiumCollectKey.overrideCollectProfile] as! String == "hello")
    }

}
