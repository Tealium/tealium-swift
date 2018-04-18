//
//  TealiumConfigTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 9/1/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import Tealium

class TealiumConfigTests: XCTestCase {

    var config: TealiumConfig!

    override func setUp() {
        super.setUp()
        config = TealiumConfig(account: TealiumTestValue.account,
                               profile: TealiumTestValue.profile,
                               environment: TealiumTestValue.environment,
                               optionalData: testOptionalData)
    }

    override func tearDown() {
        config = nil
        super.tearDown()
    }

    func testInit() {
        XCTAssertTrue(config.account == TealiumTestValue.account)
        XCTAssertTrue(config.profile == TealiumTestValue.profile)
        XCTAssertTrue(config.environment == TealiumTestValue.environment)
    }

    func testSetAndGetOptionalData() {
        // TODO: Update this to read from a json file of various options
        let key = "key"
        let value = "value"
        config.optionalData[key] = value

        if let retrievedValue = config.optionalData[key] as? String {
            XCTAssertTrue(retrievedValue == value)
            return
        }

        // Value was not as expected
        print("testSetOptionalData: retrievedValue: \(String(describing: config.optionalData[key]))")
        XCTFail("test failed")
    }

}
