//
//  TealiumLoggerTests.swift
//  tealium-swift
//
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
import XCTest

class TealiumLoggerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testTealiumLogLevelError() {
        let logLevel = TealiumLogLevel.error
        _ = TealiumLogger(config: testTealiumConfig)
        let message = "test"
        let logRequest = TealiumLogRequest(title: message, message: message, info: nil, logLevel: logLevel, category: .general)

        XCTAssertTrue(message == logRequest.messages.first)
    }

    func testTealiumLogLevelSilent() {
        let logLevel = TealiumLogLevel.silent
        _ = TealiumLogger(config: testTealiumConfig)
        let message = "test"
        let logRequest = TealiumLogRequest(title: message, message: message, info: nil, logLevel: logLevel, category: .general)

        XCTAssertTrue(message == logRequest.messages.first)
    }

    func testTealiumLogLevelDebug () {
        let logLevel = TealiumLogLevel.debug
        _ = TealiumLogger(config: testTealiumConfig)
        let message = "test"
        let logRequest = TealiumLogRequest(title: message, message: message, info: nil, logLevel: logLevel, category: .general)

        XCTAssertTrue(message == logRequest.messages.first)
    }

    func testTealiumLogLevelFault () {
        let logLevel = TealiumLogLevel.fault
        _ = TealiumLogger(config: testTealiumConfig)
        let message = "test"
        let logRequest = TealiumLogRequest(title: message, message: message, info: nil, logLevel: logLevel, category: .general)

        XCTAssertTrue(message == logRequest.messages.first)
    }

    func testTealiumLogLevelInfo () {
        let logLevel = TealiumLogLevel.info
        _ = TealiumLogger(config: testTealiumConfig)
        let message = "test"
        let logRequest = TealiumLogRequest(title: message, message: message, info: nil, logLevel: logLevel, category: .general)

        XCTAssertTrue(message == logRequest.messages.first)
    }

}
