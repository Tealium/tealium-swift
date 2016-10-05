//
//  TealiumLoggerTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 9/1/16.
//  Copyright © 2016 tealium. All rights reserved.
//

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
    
    func testDescriptions() {
        
        XCTAssertTrue(LogLevel.errors.description == "errors")
        XCTAssertTrue(LogLevel.none.description == "none")
        XCTAssertTrue(LogLevel.warnings.description == "warnings")
        XCTAssertTrue(LogLevel.verbose.description == "verbose")
        
    }
    
    func testFromString() {
        
        XCTAssertTrue(LogLevel.fromString("errors") == LogLevel.errors)
        XCTAssertTrue(LogLevel.fromString("none") == LogLevel.none)
        XCTAssertTrue(LogLevel.fromString("warnings") == LogLevel.warnings)
        XCTAssertTrue(LogLevel.fromString("verbose") == LogLevel.verbose)
        
    }
    
    func testLogLevelErrors() {
        
        let logLevel = LogLevel.errors
        let logger = TealiumLogger(loggerId: "test", logLevel: logLevel)
        let message = "test"
        let string = logger.log(message: message, logLevel: logLevel)
        
        XCTAssertTrue(message == string)
        
    }
    
    func testLogLevelWarnings() {
        
        let logLevel = LogLevel.warnings
        let logger = TealiumLogger(loggerId: "test",logLevel: logLevel)
        let message = "test"
        let string = logger.log(message: message, logLevel: logLevel)
        
        XCTAssertTrue(message == string)
        
    }
    
    func testLogLevelVerbose () {
        
        let logLevel = LogLevel.verbose
        let logger = TealiumLogger(loggerId: "test",logLevel: logLevel)
        let message = "test"
        let string = logger.log(message: message, logLevel: logLevel)
        
        XCTAssertTrue(message == string)    }
    
    func testLogLevelNone () {
        
        let logLevel = LogLevel.none
        let logger = TealiumLogger(loggerId: "test",logLevel: logLevel)
        let message = "test"
        let string = logger.log(message: message, logLevel: logLevel)
        
        XCTAssertTrue(message == string)
        
    }
    
    func testLogMessageSuppressed() {
        
        let logLevel = LogLevel.warnings
        let logger = TealiumLogger(loggerId: "test",logLevel: logLevel)
        let message = "test"
        let string = logger.log(message: message, logLevel: LogLevel.verbose)
        
        XCTAssertTrue(string == nil)
    }


}
