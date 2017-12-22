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
    var expectation2 : XCTestExpectation?
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
    
    func testWithoutIDFA(){
        expectation = self.expectation(description: "attribution-disabled")
        let testTrack = TealiumTrackRequest(data: [String:AnyObject](),
                                            completion: {(success, info, error) in
                                                
                                                XCTAssertTrue(success, "Test track call did not return success.")
                                                XCTAssertTrue((info?[TealiumAttributionKey.idfa] == nil), "IDFA was present unexpectedly")
                                                
        })
        
        module?.track(testTrack)
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    // note - test data is mocked to remove reliance on Apple API. Breakpoints in Apple code will not be hit.
    func testFullTrack(){
        expectation = self.expectation(description: "full track")
        testTealiumConfig.setSearchAdsEnabled(true)
        module?.enable(TealiumEnableRequest(config: testTealiumConfig))
        let testTrack = TealiumTrackRequest(data: [String:AnyObject](),
                                            completion: {(success, info, error) in
                                                guard let trackData = info else {
                                                    return
                                                }
                                                // test for expected keys
                                                let expectedKeys = [
                                                    TealiumAttributionKey.adGroupId,
                                                    TealiumAttributionKey.adKeyword,
                                                    TealiumAttributionKey.campaignName,
                                                    TealiumAttributionKey.campaignId,
                                                    TealiumAttributionKey.clickedDate,
                                                    TealiumAttributionKey.conversionDate,
                                                    TealiumAttributionKey.clickedWithin30D,
                                                    TealiumAttributionKey.idfv,
                                                    TealiumAttributionKey.idfa,
                                                    TealiumAttributionKey.isTrackingAllowed
                                                ]
                                                
                                                for key in expectedKeys {
                                                    if trackData[key] == nil {
                                                        XCTFail("Missing expected key: \(key)")
                                                    }
                                                }
                                                
                                                if trackData[TealiumAttributionKey.isTrackingAllowed] as! String != "true" {
                                                    XCTFail("Expected tracking to be enabled. Check device settings")
                                                }
        })
        module?.track(testTrack)
        self.waitForExpectations(timeout: 15.0, handler: nil)
    }
    
    // manually enable limit ad tracking on the device
    /*func testWithLimitTrackingEnabled(){
        expectation = self.expectation(description: "full track")
        module?.enable(TealiumEnableRequest(config: testTealiumConfig))
        let testTrack = TealiumTrackRequest(data: [String:AnyObject](),
                                            completion: {(success, info, error) in
                                                guard let trackData = info else {
                                                    return
                                                }
                                                // test for expected keys
                                                let expectedKeys = [
                                                    TealiumAttributionKey.adDataSource,
                                                    TealiumAttributionKey.adGroupId,
                                                    TealiumAttributionKey.adGroupName,
                                                    TealiumAttributionKey.adKeyword,
                                                    TealiumAttributionKey.campaignName,
                                                    TealiumAttributionKey.campaignId,
                                                    TealiumAttributionKey.clickedDate,
                                                    TealiumAttributionKey.conversionDate,
                                                    TealiumAttributionKey.clickedWithin30D,
                                                    TealiumAttributionKey.idfv,
                                                    TealiumAttributionKey.idfa,
                                                    TealiumAttributionKey.isTrackingAllowed
                                                ]
                                                
                                                for key in expectedKeys {
                                                    if trackData[key] == nil {
                                                        XCTFail("Missing expected key: \(key)")
                                                    }
                                                }
                                                
                                                if trackData[TealiumAttributionKey.isTrackingAllowed] as! String == "true" {
                                                    XCTFail("Expected tracking to be enabled. Check device settings")
                                                }
        })
        
        module?.track(testTrack)
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }*/
    
    func testWithIDFA(){
        expectation = self.expectation(description: "attribution-enabled")
        let testID = "test"
        module?.setIdfa(testID)
        module?.setAllowed("true")
        testTealiumConfig.setSearchAdsEnabled(true)
        module?.enable(TealiumEnableRequest(config: testTealiumConfig))
        
        let testTrack = TealiumTrackRequest(data: [String:AnyObject](),
                                            completion: {(success, info, error) in
                                                
                                                XCTAssertTrue(success, "Test track call did not return success.")
                                                XCTAssertTrue((info?[TealiumAttributionKey.idfa] != nil), "IDFA was missing unexpectedly")
                                                XCTAssertTrue(info?[TealiumAttributionKey.idfa] as? String == testID, "Mismatch in IDFA")
                                                
        })
        
        module?.track(testTrack)
        self.waitForExpectations(timeout: 5.0, handler: nil)
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
        trackRequest.completion?(true, payload, nil)
        
    }
    
    func tealiumModuleFinishedReport(fromModule: TealiumModule, module: TealiumModule, process: TealiumRequest) {
        
    }
    
    func tealiumModuleRequests(module: TealiumModule, process: TealiumRequest) {
        if let p = process as? TealiumLoadRequest {
            let mockData = [
                TealiumAttributionKey.adGroupId : "1234567890",
                TealiumAttributionKey.adGroupName: "adGroupName",
                TealiumAttributionKey.adKeyword: "Keyword",
                TealiumAttributionKey.orgName : "OrgName",
                TealiumAttributionKey.campaignName : "campaignName",
                TealiumAttributionKey.campaignId: "1234567890",
                TealiumAttributionKey.clickedDate: "2017-11-23T09:46:51Z",
                TealiumAttributionKey.conversionDate: "2017-11-23T09:46:51Z",
                TealiumAttributionKey.clickedWithin30D: "true",
                TealiumAttributionKey.idfv: UUID.init().uuidString
            ]
            p.completion?(true, mockData, nil)
        }
    }


}
