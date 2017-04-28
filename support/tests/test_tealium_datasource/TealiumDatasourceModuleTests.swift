//
//  TealiumDatasourceTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 3/8/17.
//  Copyright © 2017 tealium. All rights reserved.
//

import XCTest

class TealiumDatasourceModuleTests: XCTestCase {
    
    var delegateExpectationSuccess : XCTestExpectation?
    var delegateExpectationFail : XCTestExpectation?
    var process : TealiumProcess?
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testMinimumProtocolsReturn() {
        
        let helper = test_tealium_helper()
        let module = TealiumDatasourceModule(delegate: nil)
        let tuple = helper.modulesReturnsMinimumProtocols(module: module)
        XCTAssertTrue(tuple.success, "Not all protocols returned. Failing protocols: \(tuple.protocolsFailing)")
        
    }
    
    func testConfigExtension() {
        
        var config = TealiumConfig(account: "test",
                                   profile: "test",
                                   environment: "test",
                                   datasource: nil,
                                   optionalData: nil)
        XCTAssertTrue(config.optionalData.isEmpty)
        
        let datasourceString = "test_id"
        config = TealiumConfig(account: "test",
                               profile: "test",
                               environment: "test",
                               datasource: datasourceString,
                               optionalData: nil)
        XCTAssertTrue(config.optionalData.isEmpty == false)
        XCTAssertTrue(config.optionalData.count == 1)
        XCTAssertTrue(config.optionalData["com.tealium.datasource"] as! String == datasourceString)
        
        let optionalData = ["com.tealium.datasource":"b",
                            "x":"y"]
        config = TealiumConfig(account: "test",
                               profile: "test",
                               environment: "test",
                               datasource: datasourceString,
                               optionalData: optionalData)
        
        XCTAssertTrue(config.optionalData.isEmpty == false)
        XCTAssertTrue(config.optionalData.count == 2)
        XCTAssertTrue(config.optionalData["com.tealium.datasource"] as! String == datasourceString)
        
    }
    
    func testTrack() {
        
        let datasourceString = "test"
        let config = TealiumConfig(account: "test",
                               profile: "test",
                               environment: "test",
                               datasource: datasourceString,
                               optionalData: nil)
        let module = TealiumDatasourceModule(delegate: self)
        module.enable(config: config)
        
        delegateExpectationSuccess = self.expectation(description: "datasourceTrack")
        let tealiumTrack = TealiumTrack(data: [:],
                                        info: [:],
                                        completion: nil)
        module.track(tealiumTrack)
    
        self.waitForExpectations(timeout: 1.0, handler: nil)
        
        guard let track = self.process?.track else {
            XCTFail("No track data returned from delegate.")
            return
        }
        
        let data = track.data
        
        guard let datasource = data["tealium_datasource"] as? String else {
            XCTFail("Datasource string from config was not passed to track call.")
            return
        }
        
        XCTAssertTrue(datasource == datasourceString, "Datasource variable returned:\(datasource) did not match inserted datasource value:\(datasourceString)")
        
        
        
    }
    
}

extension TealiumDatasourceModuleTests : TealiumModuleDelegate {
    
    func tealiumModuleFinished(module: TealiumModule, process: TealiumProcess) {
        
        delegateExpectationSuccess?.fulfill()
        
        self.process = process
    }
    
    func tealiumModuleRequests(module: TealiumModule, process: TealiumProcess) {
        
        delegateExpectationSuccess?.fulfill()
        
        self.process = process
    }
    
    func tealiumModuleFinishedReport(fromModule: TealiumModule, module: TealiumModule, process: TealiumProcess) {
        
        delegateExpectationSuccess?.fulfill()
        
        self.process = process
    }
    
    
}
