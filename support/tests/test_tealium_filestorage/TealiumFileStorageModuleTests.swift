//
//  TealiumFileStorageModuleTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 6/13/17.
//  Copyright © 2017 tealium. All rights reserved.
//

import XCTest

// TODO: write test to fully test filestorage mechanism

class TealiumFileStorageModuleTests: XCTestCase {
    
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
        let module = TealiumFileStorageModule(delegate: nil)
        helper.modulesReturnsMinimumProtocols(module: module) { (success, failingProtocols) in
            
            expectation.fulfill()
            XCTAssertTrue(success, "Not all protocols returned. Failing protocols: \(failingProtocols)")
            
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
        
    }
    
    func testSaveLoad() {
        let module = TealiumFileStorageModule(delegate: nil)
        let helper = test_tealium_helper()
        let req = TealiumEnableRequest(config: helper.getConfig())
        module.enable(req)
        let saveRequest = TealiumSaveRequest(name: "unittests", data: ["testing":  "123"])
        module.save(saveRequest)
        let loadRequest = TealiumLoadRequest(name: "unittests") { (success, info, error) in
            guard let inf = info else {
                XCTFail("dictionary not returned")
                return
            }
            XCTAssertTrue(inf["testing"] as? String == "123")
        }
        module.load(loadRequest)
    }
    
    func testDeleteAll() {
        let module = TealiumFileStorageModule(delegate: nil)
        let helper = test_tealium_helper()
        let req = TealiumEnableRequest(config: helper.getConfig())
        module.enable(req)
        let saveRequest = TealiumSaveRequest(name: "unittests", data: ["testing":  "123"])
        module.save(saveRequest)
        
        let deleteRequest = TealiumDeleteRequest(name: "unittests")
        module.delete(deleteRequest)
        let loadRequest = TealiumLoadRequest(name: "unittests") { (success, info, error) in
            XCTAssertTrue(info == nil)
        }
        module.load(loadRequest)
    }
    
}
