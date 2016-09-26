//
//  TealiumConfigTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 9/1/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import XCTest

class TealiumConfigTests: XCTestCase {

    let account = "account"
    let profile = "profile"
    let env = "env"
    var config : TealiumConfig!
    
    override func setUp() {
        
        super.setUp()
        config = TealiumConfig(account: account, profile: profile, environment: env)

    }
    
    override func tearDown() {
        
        config = nil
        super.tearDown()
    }

    
    func testInit() {
        
        XCTAssertTrue(config.account == account)
        XCTAssertTrue(config.profile == profile)
        XCTAssertTrue(config.environment == env)
        
    }
    
    func testSetLogLevel() {
        
        let logLevelSet = LogLevel.verbose
        config.setLogLevel(logLevelSet)

        let logLevel = config.getLogLevel()
        
        XCTAssertTrue(logLevel == logLevelSet)
        
    }
    
    // Redundant as log level uses the optional data property
    func testSetOptionalData() {
        
        // TODO: Update this to read from a json file of various options
        let key = "key"
        let value = "value"
        config.setOptionalData(key, value: value as AnyObject)
        
        if let retrievedValue = config.getOptionalData(key) as? String {
            XCTAssertTrue(retrievedValue == value)
            return
        }
        
        // Value was not as expected
        print("testSetOptionalData: retrievedValue: \(config.getOptionalData(key))")
        XCTFail()
        
    }

}
