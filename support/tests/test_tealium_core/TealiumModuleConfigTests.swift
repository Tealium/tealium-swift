//
//  TealiumModuleConfigTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 10/11/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import Tealium

class TealiumModuleConfigTests: XCTestCase {

    let configA = TealiumModuleConfig(name: "a", priority: 100, build: 1, enabled: true)
    let configA2 = TealiumModuleConfig(name: "a", priority: 100, build: 1, enabled: true)
    let configB = TealiumModuleConfig(name: "b", priority: 100, build: 1, enabled: true)
    let configC = TealiumModuleConfig(name: "a", priority: 101, build: 1, enabled: true)
    let configD = TealiumModuleConfig(name: "a", priority: 100, build: 1, enabled: false)

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testEquitableOperatorPass() {
        XCTAssertTrue(configA == configA2)
    }

    func testEquitableOperatorFail() {
        XCTAssertFalse(configA == configB)
    }

    func testPriorityMismatch() {
        XCTAssertTrue(configA != configC)
    }

    func testEnableMismatch() {
        XCTAssertTrue(configA != configD)
    }
}
