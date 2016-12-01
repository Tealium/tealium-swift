//
//  TealiumConfig_LoggerExtensionTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 10/25/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import XCTest

class TealiumConfig_LoggerExtensionTests: XCTestCase {

    let config = testTealiumConfig
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testLegacySetLogLevel() {
        
        let logLevelSet = LogLevel.verbose
        
        // This method deprecated - just checking that method still compiles and correct warning appears.
        config.setLogLevel(logLevel: logLevelSet)
        
        // This method now only returns .none - check for proper deprecation message
        let logLevel = config.getLogLevel()
        
        XCTAssertTrue(logLevel == LogLevel.none)
        
    }
    
}
