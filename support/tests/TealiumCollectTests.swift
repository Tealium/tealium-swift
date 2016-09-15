//
//  TealiumCollectTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 9/6/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import XCTest


class TealiumCollectTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testDataDictionary() -> [String:AnyObject] {
        
        return [
            tealiumKey_event_name : "eventName",
            tealiumKey_account : "account",
            tealiumKey_profile : "profile",
            tealiumKey_environment : "environment",
            tealiumKey_library_name : "swift",
            tealiumKey_library_version : "1.0.0",
            tealiumKey_session_id : "someSessionId",
            tealiumKey_visitor_id :"someVisitorId",
            tealiumKey_legacy_vid : "someVID",
            tealiumKey_random :"someRandomNumber"
        ]
        
    }
    
    func testEncodeDictionaryToString() {
        
        let expectedString = "buzz=chi&key=%5B%22foo%22,%20%22bar%22,%20%22alpha%22,%20%22segment%22,%20%22sigma%22%5D&gamma=fizz&lambda=closure"
        
        let dictionary = ["key": ["foo", "bar", "alpha", "segment", "sigma"],
                          "gamma": "fizz",
                          "buzz" : "chi",
                          "lambda": "closure"]
        
        let collect = TealiumCollect(baseURL: TealiumCollect.defaultBaseURLString())
        let testString = collect.encodeDictionaryToString(dictionary)
        
        XCTAssertTrue(expectedString == testString, "test string \(testString) is not encoded properly: expected \(expectedString).")
        
    }
    
    func testInitWithBaseURLString() {
        
        let string = "http://www.blingbling.com"
        let collect = TealiumCollect(baseURL: string)
        let baseURLString = collect.getBaseURLString()
        
        XCTAssertTrue(string == baseURLString, "baseURLString did not set property: \(baseURLString) detected.")
        
    }

    //Fails as part of a group test but works individually

    func testDispatch() {
        
        // Check to see that encoding with dispatch was correctly converted to expected URL
      
        let expectedURL = "https://collect.tealiumiq.com/vdata/i.gif?tealium_library_version=1.0.0&tealium_session_id=someSessionId&tealium_library_name=swift&tealium_vid=someVID&tealium_random=someRandomNumber&event_name=eventName&tealium_account=account&tealium_profile=profile&tealium_environment=environment&tealium_visitor_id=someVisitorId"
        
        let collect = TealiumCollect(baseURL: TealiumCollect.defaultBaseURLString())
        let expectation = self.expectationWithDescription("dispatch")
        
        collect.dispatch(testDataDictionary()) { (success, encodedURLString, error) in
            
            XCTAssertTrue(expectedURL == encodedURLString, "Unexpected encoded url string used by dispatch: \(encodedURLString)")
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)

    }

    func testInvalidSend() {
    
        // Fire off to a non-existent URL
        let invalidURL = "https://this.site.doesnotexist"
        let collect = TealiumCollect(baseURL: "thisURLdoesntMatter")
        let expectation = self.expectationWithDescription("invalidSend")
        
        collect.send(invalidURL) { (success, encodedURLString, error) in
            print (success)
            XCTAssertTrue(success == false, "Send did not result in expected fail for address: \(invalidURL)")
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
        
    }
    
    func testValidSend() {
        
        let validURL = "https://collect.tealiumiq.com/vdata/i.gif?tealium_library_version=1.0.0&tealium_session_id=someSessionId&tealium_library_name=swift&tealium_vid=someVID&tealium_random=someRandomNumber&event_name=eventName&tealium_account=account&tealium_profile=profile&tealium_environment=environment&tealium_visitor_id=someVisitorId"
        
        let collect = TealiumCollect(baseURL: "thisURLdoesntMatter")
        let expectation = self.expectationWithDescription("validSend")
        
        collect.send(validURL) { (success, encodedURLString, error) in
            
            XCTAssertTrue(success == true, "Send failed to this address: \(validURL)")
            expectation.fulfill()
            
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)

    }

}
