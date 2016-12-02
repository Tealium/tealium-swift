//
//  TealiumConfigTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 9/1/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import XCTest

class TealiumConfigTests: XCTestCase {
    
    var config : TealiumConfig!
    
    override func setUp() {
        
        super.setUp()
        config = testTealiumConfig

    }
    
    override func tearDown() {
        
        config = nil
        super.tearDown()
    }

    
    func testInit() {
        
        XCTAssertTrue(config.account == TealiumTestValue.account)
        XCTAssertTrue(config.profile == TealiumTestValue.profile)
        XCTAssertTrue(config.environment == TealiumTestValue.environment)
        
    }
    
    func testSetAndGetOptionalData() {
        
        // TODO: Update this to read from a json file of various options
        let key = "key"
        let value = "value"
        config.setOptionalData(key: key, value: value as AnyObject)
        
        if let retrievedValue = config.getOptionalData(key: key) as? String {
            XCTAssertTrue(retrievedValue == value)
            return
        }
        
        // Value was not as expected
        print("testSetOptionalData: retrievedValue: \(config.getOptionalData(key: key))")
        XCTFail()
        
    }

}
