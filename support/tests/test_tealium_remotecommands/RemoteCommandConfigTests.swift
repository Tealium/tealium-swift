//
//  RemoteCommandConfigTests.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

@testable import TealiumRemoteCommands
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
    func testDefaultDelimiters() throws {
        let config = try JSONDecoder().decode(RemoteCommandConfig.self, from: exampleStub)
        let delimiters = config.keysDelimiters
        XCTAssertEqual(delimiters.keysSeparationDelimiter, ",")
        XCTAssertEqual(delimiters.keysEqualityDelimiter, ":")
    }
    
    func testDelimiters() throws {
        let data = TestTealiumHelper.loadStub(from: "keysDelimiter", type(of: self))
        let config = try JSONDecoder().decode(RemoteCommandConfig.self, from: data)
        let delimiters = config.keysDelimiters
        XCTAssertEqual(delimiters.keysSeparationDelimiter, "&&")
        XCTAssertEqual(delimiters.keysEqualityDelimiter, "==")
    }

}
