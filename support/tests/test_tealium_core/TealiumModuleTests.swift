//
//  TealiumModuleTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 10/11/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import XCTest
import ObjectiveC

class TealiumModuleTests: XCTestCase {

    var defaultModule : TealiumModule?
    var expectationSuccess: XCTestExpectation?
    var expectationFailure: XCTestExpectation?
    var returnedProcess: TealiumProcess?
    
    override func setUp() {
        super.setUp()
        
        defaultModule = TealiumModule(delegate: self)
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        defaultModule = nil
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testInitPerformance() {
        
        let iterations = 1000
        
        self.measure {
            
            for _ in 0...iterations {
                
                let _ = TealiumModule(delegate: nil)
            }
            
        }
        
    }
    
    func testMinimumProtocolsReturn() {
        
        let helper = test_tealium_helper()
        let module = TealiumModule(delegate: nil)
        let tuple = helper.modulesReturnsMinimumProtocols(module: module)
        XCTAssertTrue(tuple.success, "Not all protocols returned. Failing protocols: \(tuple.protocolsFailing)")
        
    }

    // TODO: Expand auto process checks to subclasses

    func testAutoProcessEnable() {
        
        // Send various process options into auto process function to make sure routing is correct.
        expectationSuccess = self.expectation(description: "testSuccess")
        // Enable process
        let processSuccess = TealiumProcess(type: .enable,
                                            successful: true,
                                            track: nil,
                                            error: nil)
        
        
        defaultModule?.auto(processSuccess,
                            config: testTealiumConfig)
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
        
        
    }
    
    func testAutoProcessDisable() {
        
        expectationSuccess = self.expectation(description: "testSuccess")

        let processSuccess = TealiumProcess(type: .disable,
                                            successful: true,
                                            track: nil,
                                            error: nil)
        
        
        defaultModule?.auto(processSuccess,
                            config: testTealiumConfig)
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testAutoProcessTrackSucceed() {
        
        expectationSuccess = self.expectation(description: "testSuccess")
        
        let track = TealiumTrack(data: [String:AnyObject](),
                                 info: nil,
                                 completion: nil)
        
        let processSuccess = TealiumProcess(type: .track,
                                            successful: true,
                                            track: track,
                                            error: nil)
        
        
        defaultModule?.auto(processSuccess,
                            config: testTealiumConfig)
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testAutoProcessTrackFail() {
        
        expectationFailure = self.expectation(description: "testFail")
        
        // No track data!
        let processSuccess = TealiumProcess(type: .track,
                                            successful: true,
                                            track: nil,
                                            error: nil)
        
        
        defaultModule?.auto(processSuccess,
                            config: testTealiumConfig)
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
}

extension TealiumModuleTests : TealiumModuleDelegate {
    
    
    func tealiumModuleFinished(module: TealiumModule, process: TealiumProcess) {
        
        returnedProcess = process
        
        if process.successful == true {
            expectationSuccess?.fulfill()
        } else {
            expectationFailure?.fulfill()
        }
    }
    
    func tealiumModuleFinishedReport(fromModule: TealiumModule, module: TealiumModule, process: TealiumProcess) {
        
        returnedProcess = process
        
        if process.successful == true {
            expectationSuccess?.fulfill()
        } else {
            expectationFailure?.fulfill()
        }
        
    }
    
    func tealiumModuleRequests(module: TealiumModule, process: TealiumProcess) {
        
    }
    
}
