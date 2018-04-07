//
//  TealiumLoggerTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 9/1/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import Tealium

class TealiumLoggerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testDescriptions() {
        XCTAssertTrue(TealiumLogLevel.errors.description == "errors")
        XCTAssertTrue(TealiumLogLevel.none.description == "none")
        XCTAssertTrue(TealiumLogLevel.warnings.description == "warnings")
        XCTAssertTrue(TealiumLogLevel.verbose.description == "verbose")
    }

    func testFromString() {
        XCTAssertTrue(TealiumLogLevel.fromString("errors") == TealiumLogLevel.errors)
        XCTAssertTrue(TealiumLogLevel.fromString("none") == TealiumLogLevel.none)
        XCTAssertTrue(TealiumLogLevel.fromString("warnings") == TealiumLogLevel.warnings)
        XCTAssertTrue(TealiumLogLevel.fromString("verbose") == TealiumLogLevel.verbose)
    }

    func testTealiumLogLevelErrors() {
        let logLevel = TealiumLogLevel.errors
        let logger = TealiumLogger(loggerId: "test", logLevel: logLevel)
        let message = "test"
        let string = logger.log(message: message, logLevel: logLevel)

        XCTAssertTrue(message == string)
    }

    func testTealiumLogLevelWarnings() {
        let logLevel = TealiumLogLevel.warnings
        let logger = TealiumLogger(loggerId: "test", logLevel: logLevel)
        let message = "test"
        let string = logger.log(message: message, logLevel: logLevel)

        XCTAssertTrue(message == string)
    }

    func testTealiumLogLevelVerbose () {

        let logLevel = TealiumLogLevel.verbose
        let logger = TealiumLogger(loggerId: "test", logLevel: logLevel)
        let message = "test"
        let string = logger.log(message: message, logLevel: logLevel)

        XCTAssertTrue(message == string)    }

    func testTealiumLogLevelNone () {
        let logLevel = TealiumLogLevel.none
        let logger = TealiumLogger(loggerId: "test", logLevel: logLevel)
        let message = "test"
        let string = logger.log(message: message, logLevel: logLevel)

        XCTAssertTrue(message == string)
    }

    func testLogMessageSuppressed() {
        let logLevel = TealiumLogLevel.warnings
        let logger = TealiumLogger(loggerId: "test", logLevel: logLevel)
        let message = "test"
        let string = logger.log(message: message, logLevel: TealiumLogLevel.verbose)

        XCTAssertTrue(string == nil)
    }

}
