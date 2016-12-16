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
        
        module?.enable(config: testTealiumConfig)
        
        expectation = self.expectation(description: "testAID")
        
        let testTrack = TealiumTrack(data: [String:AnyObject](),
                                     info: nil,
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
    
    func testProtocolsSupported() {
        
        let helper = test_tealium_helper()
        let protocolsTest = helper.modulesReturnsMinimumProtocols(module: module!)
        XCTAssertTrue(protocolsTest.success, "Failing protocols: \(protocolsTest.protocolsFailing)")
    }
    
}

extension TealiumAttributionModuleTests : TealiumModuleDelegate {
    
    func tealiumModuleFinished(module: TealiumModule, process: TealiumProcess) {
        
        if process.type == .track && process.error == nil {
            
            payload = process.track?.data
            
            expectation?.fulfill()
            
            process.track?.completion?(true, nil, nil)
            
        }
        
        if process.type == .track && process.error != nil {
            
            process.track?.completion?(false, nil, nil)
            
        }
        
    }
    
    func tealiumModuleFinishedReport(fromModule: TealiumModule, module: TealiumModule, process: TealiumProcess) {
        
    }
    
    func tealiumModuleRequests(module: TealiumModule, process: TealiumProcess) {
        
    }


}
