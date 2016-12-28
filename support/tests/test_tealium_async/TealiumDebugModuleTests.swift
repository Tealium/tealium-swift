//
//  TealiumDebugModuleTests.swift
//  tealium-swift
//
//  Created by Merritt Tidwell on 12/19/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import XCTest

class TealiumDebugModuleTests: XCTestCase {
    
    var debugDataModule: TealiumDebugModule?
    
    override func setUp() {
        super.setUp()
        debugDataModule = TealiumDebugModule(delegate: nil)
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        debugDataModule = nil
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testMinimumProtocolsReturn() {
        
        let helper = test_tealium_helper()
        let module = TealiumAppDataModule(delegate: nil)
        let tuple = helper.modulesReturnsMinimumProtocols(module: module)
        XCTAssertTrue(tuple.success, "Not all protocols returned. Failing protocols: \(tuple.protocolsFailing)")
        
    }

    func testEnable () {
        
        debugDataModule?.enable(config: testTealiumConfig)
     
        //server did start?
    }

    func testDisable () {
        
        debugDataModule?.disable()
        
        //server did stop
    
    }
    

    func testGetDebugTrackInfo() {
        let debugTrackInfo = debugDataModule?.getDebugTrackInfo(["test": "test"],
                                                     trackInfo: ["test": "test"])
        
        let testTrackInfo = ["type": "track",
                             "data": ["test": "test"],
                             "info": ["test": "test"]] as [String : Any]
        
        XCTAssertTrue(debugTrackInfo! == testTrackInfo, "Mismatch between debugInfo:\n\(debugTrackInfo) \nAnd manualTrackData:\n\(testTrackInfo)")
    }
    
    func testGetConfigInfo () {
    
        let configInfo = debugDataModule?.getConfigInfo(testTealiumConfig)
        
        let testConfigInfo = ["type": "config_update",
                              "data": ["account": TealiumTestValue.account,
                                      "profile": TealiumTestValue.profile,
                                      "environment": TealiumTestValue.environment,
                                      "optionalData":testOptionalData],
                              "info": ""] as [String : Any]
        
        XCTAssertTrue(configInfo! == testConfigInfo, "Mismatch between config:\n\(configInfo) \nAnd manualConfigInfo:\n\(testConfigInfo)")
    
    }

}
