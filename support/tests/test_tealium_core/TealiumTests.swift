//
//  TealiumTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 9/1/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import XCTest



class TealiumTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testInitPerformance() {
        
        let iterations = 100
        
        self.measure {
        
            for _ in 0...iterations {
                
                let _ = Tealium(config: defaultTealiumConfig)
            }
            
        }
        
    }
    
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
    
    func testConvenienceTrack() {
        
        // Only testing that call triggers expected behavior - data content checked by other module unit tests.
        
        let tealium = Tealium(config: defaultTealiumConfig)
        
        let expectation = self.expectation(description: "testCall")
        
        tealium.track(title: "testTrack", data: nil, completion: { (success, info, error) in
            
            print("Tealium dispatch test successful: \(success) info: \(info) error:\(error)")
            
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: 1.5, handler: nil)
        
    }
    
    func testPrimaryTrack() {
        
        // Only testing that call triggers expected behavior - data content checked by other module unit tests.
        
        let tealium = Tealium(config: defaultTealiumConfig)
        
        let expectation = self.expectation(description: "testCall")
        
        tealium.track(type: TealiumTrackType.conversion , title: "testTrack", data: nil, completion: { (success, info, error) in
            
            print("Tealium dispatch test successful: \(success) info: \(info) error:\(error)")
            
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: 3.0, handler: nil)
        
    }
    
}
