//
//  TealiumModule_LoggerTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 11/1/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import XCTest

class TealiumLoggerModuleTests: XCTestCase {

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
        let module = TealiumLoggerModule(delegate: nil)
        let tuple = helper.modulesReturnsMinimumProtocols(module: module)
        XCTAssertTrue(tuple.success, "Not all protocols returned. Failed protocols: \(tuple.protocolsFailing)")
        
    }

}
