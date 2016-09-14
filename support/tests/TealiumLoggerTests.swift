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

    func testLogLevelErrors() {
        
        let logLevel = LogLevel.Errors
        let logger = TealiumLogger(loggerId: "test", logLevel: logLevel)
        let message = "test"
        let string = logger.log(message, logLevel: logLevel)
        
        XCTAssertTrue(message == string)
        
    }
    
    func testLogLevelWarnings() {
        
        let logLevel = LogLevel.Warnings
        let logger = TealiumLogger(loggerId: "test",logLevel: logLevel)
        let message = "test"
        let string = logger.log(message, logLevel: logLevel)
        
        XCTAssertTrue(message == string)
        
    }
    
    func testLogLevelVerbose () {
        
        let logLevel = LogLevel.Verbose
        let logger = TealiumLogger(loggerId: "test",logLevel: logLevel)
        let message = "test"
        let string = logger.log(message, logLevel: logLevel)
        
        XCTAssertTrue(message == string)    }
    
    func testLogLevelNone () {
        
        let logLevel = LogLevel.None
        let logger = TealiumLogger(loggerId: "test",logLevel: logLevel)
        let message = "test"
        let string = logger.log(message, logLevel: logLevel)
        
        XCTAssertTrue(message == string)
        
    }
    
//    func testExample() {
//        // This is an example of a functional test case.
//        // Use XCTAssert and related functions to verify your tests produce the correct results.
//    }
//
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measureBlock {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
