//
//  TealiumConfigTests.swift
//  tealium-swift
//
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
import XCTest
import WebKit

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
    
    func testSameConfigsAreEqual() {
        let config1 = config.copy
        let config2 = config.copy
        config1.overrideCollectURL = "url"
        config2.overrideCollectURL = "url"
        XCTAssertEqual(config1, config2)
    }
    
    func testDifferentConfigsAreNotEqual() {
        let config1 = config.copy
        let config2 = config.copy
        config1.overrideCollectURL = "url"
        config2.overrideCollectURL = "other_url"
        XCTAssertNotEqual(config1, config2)
    }
    
    func testDifferentConfigKeysAreNotEqual() {
        let config1 = config.copy
        let config2 = config.copy
        config1.overrideCollectURL = "url"
        config2.overrideCollectDomain = "url"
        XCTAssertNotEqual(config1, config2)
    }
    
    class TestObject: CustomStringConvertible {
        var expectation: XCTestExpectation?
        var description: String {
            expectation?.fulfill()
            return "Custom TestObject Description"
        }
    }
    
    func testConfigsWithSameObjectAreEqual() {
        let config1 = config.copy
        let config2 = config.copy
        let obj = TestObject()
        obj.expectation = expectation(description: "Description should not be used for objects!")
        obj.expectation?.isInverted = true
        config1.options["test_obj"] = obj
        config2.options["test_obj"] = obj
        XCTAssertEqual(config1, config2)
        waitForExpectations(timeout: 1.0)
    }
    
    class MyWebviewConfig: WKWebViewConfiguration {
        var expectation: XCTestExpectation?
        override var description: String {
            expectation?.fulfill()
            return super.description
        }
    }
    
    func testConfigsWithWebViewConfigAreEqual() {
        let config1 = config.copy
        let config2 = config.copy
        let obj = MyWebviewConfig()
        obj.expectation = expectation(description: "Description MUST not be used for WKWebview or can cause crashes when accessed out of main thread!")
        obj.expectation?.isInverted = true
        config1.webviewConfig = obj
        config2.webviewConfig = obj
        XCTAssertEqual(config1, config2)
        waitForExpectations(timeout: 1.0)
    }
    
    func testConfigsWithDifferentObjectsAreNotEqual() {
        let config1 = config.copy
        let config2 = config.copy
        let expect = expectation(description: "Description should not be used for objects!")
        expect.isInverted = true
        let obj1 = TestObject()
        obj1.expectation = expect
        let obj2 = TestObject()
        obj2.expectation = expect
        config1.options["test_obj"] = obj1
        config2.options["test_obj"] = obj2
        XCTAssertNotEqual(config1, config2)
        waitForExpectations(timeout: 1.0)
    }
    
    func testConfigsWithObjectAndValueTypeAreNotEqual() {
        let config1 = config.copy
        let config2 = config.copy
        let expect = expectation(description: "Description should not be used for objects!")
        expect.isInverted = true
        let obj = TestObject()
        obj.expectation = expect
        config1.options["test_obj"] = obj
        config2.options["test_obj"] = "someValue"
        XCTAssertNotEqual(config1, config2)
        waitForExpectations(timeout: 1.0)
    }
    
    func testConfigsWithSameDictionariesAreEqual() {
        let config1 = config.copy
        let config2 = config.copy
        let dict1 = ["someKey" : "someValue"]
        let dict2 = ["someKey" : "someValue"]
        config1.options["test_dict"] = dict1
        config2.options["test_dict"] = dict2
        XCTAssertEqual(config1, config2)
    }
    
    func testConfigsWithDifferentDictionariesAreNotEqual() {
        let config1 = config.copy
        let config2 = config.copy
        let dict1 = ["someKey" : "someValue"]
        let dict2 = ["someKey" : "someOtherValue"]
        config1.options["test_dict"] = dict1
        config2.options["test_dict"] = dict2
        XCTAssertNotEqual(config1, config2)
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
