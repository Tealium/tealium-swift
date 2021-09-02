//
//  TealiumConfigTests.swift
//  tealium-swift
//
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
import XCTest

class TealiumConfigTests: XCTestCase {

    var config: TealiumConfig!

    override func setUp() {
        super.setUp()
        config = TealiumConfig(account: TealiumTestValue.account,
                               profile: TealiumTestValue.profile,
                               environment: TealiumTestValue.environment,
                               options: testOptionalData)
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
        config.options[key] = value

        if let retrievedValue = config.options[key] as? String {
            XCTAssertTrue(retrievedValue == value)
            return
        }

        // Value was not as expected
        print("testSetOptionalData: retrievedValue: \(String(describing: config.options[key]))")
        XCTFail("test failed")
    }
    
    func testLogger() {
        let dummyLogger = DummyLogger(config: config)
        config.loggerType = .custom(dummyLogger)
        XCTAssertTrue(config.logger is DummyLogger)
//        XCTAssertIdentical(config.logger as? DummyLogger, dummyLogger) // Only for xcode 12.5+, CICD has older version 
    }

}

class DummyLogger: TealiumLoggerProtocol {
    var config: TealiumConfig?
    
    required init(config: TealiumConfig) {
        self.config = config
    }
    
    func log(_ request: TealiumLogRequest) {
        
    }
    
    
}
