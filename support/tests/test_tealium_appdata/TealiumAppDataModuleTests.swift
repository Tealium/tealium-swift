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
    
    override func setUp() {
        super.setUp()
        appDataModule = TealiumAppDataModule(delegate: nil)
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        
        appDataModule = nil
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testMinimumProtocolsReturn() {
        
        let helper = test_tealium_helper()
        let module = TealiumAppDataModule(delegate: nil)
        let tuple = helper.modulesReturnsMinimumProtocols(module: module)
        XCTAssertTrue(tuple.success, "Not all protocols returned. Failing protocols: \(tuple.protocolsFailing)")
        
    }
    
    func testVID() {
        
        let testUuid = "123e4567-e89b-12d3-a456-426655440000"
        let vid = appDataModule?.visitorId(fromUuid: testUuid)
        
        let vidCheck = "123e4567e89b12d3a456426655440000"
        
        XCTAssertTrue(vidCheck == vid, "Visitor id mismatch between returned vid:\(vid) \nAnd manual check:\(vidCheck)")
        
        
    }
    
    func testNewPersistentData() {
        
        let testUuid = "123e4567-e89b-12d3-a456-426655440000"
        let manualVid = "123e4567e89b12d3a456426655440000"
        let vid = appDataModule?.visitorId(fromUuid: testUuid)
        
        XCTAssertTrue(manualVid == vid, "VisitorId method does not modify string correctly. \n Returned:\(vid) \n Expected:\(manualVid)")
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
}


// For future tests
extension TealiumAppDataModuleTests : TealiumModuleDelegate {
    
    
    
    func tealiumModuleFinished(module: TealiumModule, process: TealiumProcess) {
        
    }
    
    func tealiumModuleRequests(module: TealiumModule, process: TealiumProcess) {
        
    }
    
    func tealiumModuleFinishedReport(fromModule: TealiumModule, module: TealiumModule, process: TealiumProcess) {
        
    }
    
}
