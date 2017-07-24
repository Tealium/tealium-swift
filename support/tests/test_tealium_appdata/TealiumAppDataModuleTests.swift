//
//  TealiumAppDataModuleTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 11/21/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import XCTest

class TealiumAppDataModuleTests: XCTestCase {
    
    var delegateExpectationSuccess : XCTestExpectation?
    var delegateExpectationFail : XCTestExpectation?
    var appDataModule : TealiumAppDataModule?
    var trackData : [String:Any]?
    
    override func setUp() {
        super.setUp()
        appDataModule = TealiumAppDataModule(delegate: nil)
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        
        appDataModule = nil
        trackData = nil
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testForFailingRequests() {
        
        let helper = test_tealium_helper()
        let module = TealiumAppDataModule(delegate: nil)
        
        let failing = helper.failingRequestsFor(module: module)
        XCTAssert(failing.count == 0, "Unexpected failing requests: \(failing)")
        
    }
    
    func testMinimumProtocolsReturn() {
        
        let expectation = self.expectation(description: "allRequestsReturn")
        let helper = test_tealium_helper()
        let module = TealiumAppDataModule(delegate: nil)
        
        helper.modulesReturnsMinimumProtocols(module: module) { (success, failing) in
            
            expectation.fulfill()
            XCTAssert(failing.count == 0, "Unexpected failing requests: \(failing)")
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
                                
        
    }

    func testVID() {
        
        let testUuid = "123e4567-e89b-12d3-a456-426655440000"
        let vid = appDataModule?.visitorId(fromUuid: testUuid)
        
        let vidCheck = "123e4567e89b12d3a456426655440000"
        
        XCTAssertTrue(vidCheck == vid, "Visitor id mismatch between returned vid:\(String(describing: vid)) \nAnd manual check:\(vidCheck)")
        
        
    }
    
    func testNewPersistentData() {
        
        let testUuid = "123e4567-e89b-12d3-a456-426655440000"
        let manualVid = "123e4567e89b12d3a456426655440000"
        let vid = appDataModule?.visitorId(fromUuid: testUuid)
        
        XCTAssertTrue(manualVid == vid, "VisitorId method does not modify string correctly. \n Returned:\(String(describing: vid)) \n Expected:\(manualVid)")
        guard let newData = appDataModule?.newPersistentData(forUuid: testUuid) else {
            
            XCTFail("Could not create newPersistent data from appDataModule")
            return
        }
        
        let checkData = [
                "app_uuid":testUuid as AnyObject,
                "tealium_vid":manualVid as AnyObject,
                "tealium_visitor_id": manualVid as AnyObject
        ]
        
        XCTAssertTrue(checkData == newData, "Mismatch between newPersistentData:\n\(newData) \nAnd manualCheckData:\n\(checkData)")
        
    }
    
    func testTrack() {
    
        let expectation = self.expectation(description: "appDataTrack")
        let module = TealiumAppDataModule(delegate: self)
        module.isEnabled = true
        
        let track = TealiumTrackRequest(data: [:]) { (success, info, error) in
            
            expectation.fulfill()
            
            guard let trackData = self.trackData else {
                XCTFail("No track data detected from test.")
                return
            }
            
            let isMissingKeys = TealiumAppDataModule.isMissingPersistentKeys(trackData)
            XCTAssert(success)
            XCTAssertFalse(isMissingKeys, "Info missing from post track call: \(trackData)")
            
        }
        
        module.track(track)
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
        
    }
    
    func testIsMissingKeys() {
        
        let emptyDict = [String:Any]()
        let failingDict = ["blah":"hah"]
        let numericDict = ["23": 56]
        let passingDict = ["app_uuid":"abc123",
                           "tealium_visitor_id":"abc123",
                           "tealium_vid":"abc123"]
        
        XCTAssertTrue(TealiumAppDataModule.isMissingPersistentKeys(emptyDict))
        XCTAssertTrue(TealiumAppDataModule.isMissingPersistentKeys(failingDict))
        XCTAssertTrue(TealiumAppDataModule.isMissingPersistentKeys(numericDict))
        
        XCTAssertFalse(TealiumAppDataModule.isMissingPersistentKeys(passingDict))
        
    }
}


// For future tests
extension TealiumAppDataModuleTests : TealiumModuleDelegate {
    
    func tealiumModuleFinished(module: TealiumModule, process: TealiumRequest) {
        
        if let process = process as? TealiumTrackRequest {
            trackData = process.data
            process.completion?(true,
                                nil,
                                nil)
        }
    }
    
    func tealiumModuleRequests(module: TealiumModule, process: TealiumRequest) {
        
    }
    
}
