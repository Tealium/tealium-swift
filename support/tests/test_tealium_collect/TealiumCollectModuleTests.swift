//
//  TealiumModule_CollectTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 11/1/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import XCTest

class TealiumCollectModuleTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testMinimumProtocolsReturn() {
        
        let expectation = self.expectation(description: "minimumProtocolsReturned")
        let helper = test_tealium_helper()
        let module = TealiumCollectModule(delegate: nil)
        helper.modulesReturnsMinimumProtocols(module: module) { (success, failingProtocols) in
            
            expectation.fulfill()
            XCTAssertTrue(success, "Not all protocols returned. Failing protocols: \(failingProtocols)")
            
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)

    }
    
    func testEnableDisable(){
        
        // Need to know that the TealiumCollect instance was instantiated + that we have a base url.
        
        let collectModule = TealiumCollectModule(delegate: nil)
        
        collectModule.enable(TealiumEnableRequest(config: testTealiumConfig))
        
        XCTAssertTrue(collectModule.collect != nil, "TealiumCollect did not initialize.")
        XCTAssertTrue(collectModule.collect?.getBaseURLString().isEmpty == false, "No base URL was provided or auto-initialized.")
        
        
        collectModule.disable(TealiumDisableRequest())
        
        XCTAssertTrue(collectModule.collect == nil, "TealiumCollect instance did not nil out.")
    }
    
    // This is an integration test, will only work in a non-command line environment
//    func testLegacyTrackWithEncodedURL() {
//        
//        // Just checking that the url passed in is returned from info["encodedURLString"]
//        
//        let expectation = self.expectation(description: "testLegacyTrack")
//        let tealium = Tealium(config: testTealiumConfig)
//        
//        // track call will fail for a non-existent url
//        // tracl call will SUCCEED for any existing url that simply returns 200 to these requests.
//        // Should return encoded url in info["payload"] regardless
//        let urlString = "http://www.google.com"
//        tealium?.track(encodedURLString: urlString,
//                       completion: { (success, encodedURL, error) in
//                                
//                XCTAssertTrue(encodedURL == urlString, "Returned encoded URL String: \(encodedURL) - should have been: \(urlString)")
//                        
//                expectation.fulfill()
//        })
//        
//        self.waitForExpectations(timeout: 1.0, handler: nil)
//        
//    }

}
