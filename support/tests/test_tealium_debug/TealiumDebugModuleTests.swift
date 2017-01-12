//
//  TealiumDebugModuleTests.swift
//  tealium-swift
//
//  Created by Merritt Tidwell on 12/19/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import XCTest

class TealiumDebugModuleTests: XCTestCase {
    
    var debugModule: TealiumDebugModule?
    var expectationFinished : XCTestExpectation?
    
    override func setUp() {
        super.setUp()
        debugModule = TealiumDebugModule(delegate: nil)
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        debugModule = nil
        expectationFinished = nil
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testMinimumProtocolsReturn() {
        
        let helper = test_tealium_helper()
        let module = TealiumDebugModule(delegate: nil)
        let tuple = helper.modulesReturnsMinimumProtocols(module: module)
        XCTAssertTrue(tuple.success, "Not all protocols returned. Failing protocols: \(tuple.protocolsFailing)")
        
    }
    
    func testEnable () {
        
        expectationFinished = expectation(description: "startup")
        
        guard let module = self.debugModule else {
            XCTFail()
            return
        }
        
        module.delegate = self
        module.enable(config: testTealiumConfig)
     
        waitForExpectations(timeout: 1.0, handler: nil)

        let httpServer = module.server.server
        let state = httpServer.state

        // Check Swifter server up and running
        XCTAssertTrue(state == .running, "Server state: \(state)")
        
        // Check that Swift server delegate is now the module Server
        guard let httpServerDelegate = httpServer.delegate else {
            XCTFail("Swifter server delegate did not get set.")
            return
        }
        
        if type(of:httpServerDelegate) != type(of:module.server) {
            XCTFail("Server delegate did not (likely) set to the module server.")
            return
        }
        
    }

    func testEnableWithPortOverride () {
        
        expectationFinished = expectation(description: "startup-override")
        
        guard let module = self.debugModule else {
            XCTFail()
            return
        }
        
        module.delegate = self
        
        let testPort = 8090
        testOptionalData += ["debug_port": testPort]
        
        module.enable(config: testTealiumConfig)
        
        waitForExpectations(timeout: 1.0, handler: nil)
        
        let httpServer = module.server.server
        
        do {
            let port = try httpServer.port()
            XCTAssertTrue(port == testPort, "Expected port\(port) didn't match port override\(testPort)")
            
        } catch let error {
            XCTFail("couldn't find a port", file: error as! StaticString)
        }
        
    }
    
    func testDisable () {
        
        debugModule?.disable()
        
        // Check that module is running
        guard let moduleServer = debugModule?.server else {
            XCTFail("Debug Module did not start.")
            return
        }
        
        let httpServer = moduleServer.server
        let state = httpServer.state
        
        XCTAssertTrue(state == .stopped, "Swifter server did not go into a stopped state.")
    
    }
    

    func testGetDebugTrackInfo() {
        let debugTrackInfo = debugModule?.getDebugTrackInfo(["test": "test"])
        
        let testTrackInfo = ["type": "track",
                             "info": ["test": "test"]] as [String : Any]
        
        XCTAssertTrue(debugTrackInfo! == testTrackInfo, "Mismatch between debugInfo:\n\(debugTrackInfo) \nAnd manualTrackData:\n\(testTrackInfo)")
    }
    
    func testGetConfigInfo () {
    
        guard let debugModule = self.debugModule else {
            XCTFail()
            return
        }
        
        let configInfo = debugModule.getConfigInfo(testTealiumConfig)
        
        let testConfigInfo = ["type": "config",
                              "info": ["account": TealiumTestValue.account,
                                      "profile": TealiumTestValue.profile,
                                      "environment": TealiumTestValue.environment,
                                      "optionalData":testOptionalData]] as [String : Any]
        
        XCTAssertTrue(configInfo == testConfigInfo, "Mismatch between config:\n\(configInfo) \nAnd manualConfigInfo:\n\(testConfigInfo)")
    
    }

}

extension TealiumDebugModuleTests : TealiumModuleDelegate {
    
    func tealiumModuleFinished(module: TealiumModule, process: TealiumProcess) {
        
        expectationFinished?.fulfill()
        
    }
    
    func tealiumModuleRequests(module: TealiumModule, process: TealiumProcess) {
        
    }
    
    func tealiumModuleFinishedReport(fromModule: TealiumModule, module: TealiumModule, process: TealiumProcess) {
        
    }
}
