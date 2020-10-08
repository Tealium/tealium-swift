//
//  RemoteCommandConfigTests.swift
//  TealiumRemoteCommandTests-iOS
//
//  Created by Christina S on 12/20/19.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import TealiumRemoteCommands
import XCTest

class RemoteCommandConfigTests: XCTestCase {

    var exampleStub: Data!
    var tealiumRemoteCommandConfig: RemoteCommandConfig!

    override func setUp() {
        exampleStub = loadStub(from: "example", type(of: self))
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
