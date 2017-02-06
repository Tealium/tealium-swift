//
//  TealiumTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 9/1/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import XCTest

// These are really integration tests that depend on dispatch service also being spun up.

class TealiumTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // Not useful - save for automated UI testing
//    func testInitPerformance() {
//        
//        let iterations = 100
//        
//        self.measure {
//        
//            for _ in 0...iterations {
//                
//                let _ = Tealium(config: defaultTealiumConfig)
//            }
//            
//        }
//        
//    }
    
    // MARK:
    // MARK: INTEGRATION TESTS as Tealium is more-or-less a public fascade
    
    func testEnableDisable() {
        
        // Just checking if the module manager isEnabled flag flips -- modules themselves will test enable disable behavior
        let tealium = Tealium(config: defaultTealiumConfig)

        let modulesManager = tealium.modulesManager
        
        XCTAssertTrue(modulesManager.isEnabled)
        
        tealium.disable()
        
        XCTAssertFalse(modulesManager.isEnabled)
        
    }

    // Not tests track calls any longer, calls are only fascades, module track calls should be tested directly.
    
}
