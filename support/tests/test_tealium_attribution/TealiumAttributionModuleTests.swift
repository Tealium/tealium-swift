//
//  TealiumAttributionModuleTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 11/16/16.
//  Copyright © 2016 tealium. All rights reserved.
//
//  Application Test do to UIKit not being available to Unit Test Bundle

import XCTest

class TealiumAttributionModuleTests: XCTestCase {
    
    var module : TealiumAttributionModule?
    var expectation : XCTestExpectation?
    var payload : [String:Any]?
    
    override func setUp() {
        super.setUp()
        
        module = TealiumAttributionModule(delegate: self)
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        module = nil
        payload = nil
        
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAIDAdded() {
        
        let testID = "test"
        // Manually set a string for the advertiser ID
        module?.advertisingId = testID
        
        module?.enable(TealiumEnableRequest(config: testTealiumConfig))
        
        expectation = self.expectation(description: "testAID")
        
        let testTrack = TealiumTrackRequest(data: [String:AnyObject](),
                                            completion: {(success, info, error) in
        
                XCTAssertTrue(success, "Test track call did not return success.")

        })
        
        module?.track(testTrack)
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
        
        // check the return
        guard let id = payload?[TealiumAttributionKey.advertisingId] as? String else {
            XCTFail("Id value from payload could not be coerced into String")
            return
        }
        
        XCTAssertTrue(id == testID, "Mismatch in test advertisingId. Received:\(id), originally inserted:\(testID)")
        
    }
    
    func testMinimumProtocolsReturn() {
        
        let expectation = self.expectation(description: "minimumProtocolsReturned")
        let helper = test_tealium_helper()
        let module = TealiumAttributionModule(delegate: nil)
        helper.modulesReturnsMinimumProtocols(module: module) { (success, failingProtocols) in
            
            expectation.fulfill()
            XCTAssertTrue(success, "Not all protocols returned. Failing protocols: \(failingProtocols)")
            
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)

    }
    
}

extension TealiumAttributionModuleTests : TealiumModuleDelegate {
    
    func tealiumModuleFinished(module: TealiumModule, process: TealiumRequest) {
        
        if process is TealiumEnableRequest {
            return
        }
        
        guard let trackRequest = process as? TealiumTrackRequest else {
            XCTFail("Process not of track type.")
            return
        }
        
        // Look through responses for any errors
        for response in trackRequest.moduleResponses {
            if response.error != nil {
                trackRequest.completion?(false, nil, response.error)
                return
            }
            
        }
        payload = trackRequest.data
        expectation?.fulfill()
        trackRequest.completion?(true, nil, nil)
        
    }
    
    func tealiumModuleFinishedReport(fromModule: TealiumModule, module: TealiumModule, process: TealiumRequest) {
        
    }
    
    func tealiumModuleRequests(module: TealiumModule, process: TealiumRequest) {
        
    }


}
