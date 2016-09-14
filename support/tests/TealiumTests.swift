//
//  TealiumTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 9/1/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import XCTest

class TealiumTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    //TODO: multiple test tracks
    func testTrack () {
        
        guard let tealium = Tealium(config: getConfig()) else{
            XCTFail("Unable to start Tealium Library")
            return
        }
        
        tealium.track("test", data: ["cool": "story"], completion: { (success : Bool, encodedURLString: String, error: NSError?) in
            
            XCTAssert(success)
            
            if error != nil {
                XCTFail()
            }
            
        })
        
        
    }
    
    
    func testEncodedURLStringHasExpectedDataSourceKeys() {
        let tealium = Tealium(config: getConfig())
        let arrayDataSources : [String] = [tealiumKey_account, tealiumKey_profile, tealiumKey_environment, tealiumKey_event, tealiumKey_event_name, tealiumKey_library_version, tealiumKey_library_name, tealiumKey_random, tealiumKey_session_id, tealiumKey_timestamp_epoch, tealiumKey_visitor_id, tealiumKey_legacy_vid]
        
        let expectation = self.expectationWithDescription("testTrackEncodedURL")
        
        
        
        tealium!.track("my event name", data: nil) { (success, encodedURLString, error) in
            
            XCTAssert(self.stringDoesContainKeys(encodedURLString, arrayOfKeys: arrayDataSources), " Expected string does not contain required data sources %@" + encodedURLString)
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    
    //test helper, consider making helper class
    func getConfig() -> TealiumConfig{
        
        let config = TealiumConfig(account: "your_account",
                                   profile: "you_profile",
                                   environment: "dev_qa_or_prod")
        
        return config
    }
    
    func stringDoesContainKeys(string: String, arrayOfKeys: [String])-> Bool{
        
        for key in arrayOfKeys{
            
            if (string.lowercaseString.rangeOfString(key) != nil){
                continue
            }else {
                print("stringDoesContainKeys: \(key) is missing")
                return false
            }
            
        }
        return true
    }
    
}