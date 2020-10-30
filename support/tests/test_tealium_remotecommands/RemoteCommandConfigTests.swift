//
//  RemoteCommandConfigTests.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import TealiumRemoteCommands
import XCTest

class RemoteCommandConfigTests: XCTestCase {

    var exampleStub: Data!
    var tealiumRemoteCommandConfig: RemoteCommandConfig!

    override func setUp() {
        exampleStub = TestTealiumHelper.loadStub(from: "example", type(of: self))
    }

    override func tearDown() {
    }

    func testDecode() {
        tealiumRemoteCommandConfig = try! JSONDecoder().decode(RemoteCommandConfig.self, from: exampleStub)
        XCTAssertNotNil(tealiumRemoteCommandConfig)
    }

    func testEncode() {
        tealiumRemoteCommandConfig = try! JSONDecoder().decode(RemoteCommandConfig.self, from: exampleStub)
        let encoded = try! JSONEncoder().encode(tealiumRemoteCommandConfig)
        XCTAssertNotNil(encoded)
    }

}
