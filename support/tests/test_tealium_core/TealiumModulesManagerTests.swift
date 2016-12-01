//
//  TealiumModulesManagerTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 10/11/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import XCTest

//let mmtAccountInfo : [String:String] = [
//    TealiumKey.account: "tealiummobile",
//    TealiumKey.profile: "demo",
//    TealiumKey.environment: "dev",
//]

class TealiumTestModule : TealiumModule {
    
    override func enable(config: TealiumConfig) {
        super.enable(config: config)
    }
}

class TealiumModulesManagerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }


    func testInitPerformance() {
        
        let iterations = 1000
        
        self.measure {
            
            for _ in 0..<iterations {
                
                let _ = TealiumModulesManager(config: defaultTealiumConfig)
            }
            
        }
        
    }
    
    func testPublicTrackWithNoModules() {
        
        let manager = TealiumModulesManager(config: testTealiumConfig)
        
        let expectation = self.expectation(description: "testPublicTrack")
        
        let testTrack = TealiumTrack(data: [:],
                                     info: nil,
                                     completion: {(success, info, error) in
        
                guard let error = error else {
                    XCTFail("Error should have returned")
                    return
                }
                
                XCTAssertFalse(success, "Track did not fail as expected. Error: \(error)")
                
                expectation.fulfill()
                                        
        })
        
        manager.track(testTrack)
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
        
    }
    
    func testPublicTrackWithDefaultModules() {
        
        let manager = TealiumModulesManager(config: testTealiumConfig)
        
        manager.updateAll()
        
        let expectation = self.expectation(description: "testPublicTrack")
        
        let testTrack = TealiumTrack(data: [:],
                                     info: nil,
                                     completion: {(success, info, error) in
                        
                expectation.fulfill()
        })
        
        manager.track(testTrack)
        
        // Only testing that the completion handler is called.
        self.waitForExpectations(timeout: 1.0, handler: nil)
        
    }

    
    func testStringToBool() {
        
        // Not entirely necessary as long as we're using NSString.boolValue
        // ...but just in case it gets swapped out
        
        let stringTrue = "true"
        let stringYes = "yes"
        let stringFalse = "false"
        let stringFALSE = "FALSE"
        let stringNo = "no"
        let stringOtherTrue = "35a"
        let stringOtherFalse = "xyz"
        
        XCTAssertTrue(stringTrue.boolValue)
        XCTAssertTrue(stringYes.boolValue)
        XCTAssertFalse(stringFalse.boolValue)
        XCTAssertFalse(stringFALSE.boolValue)
        XCTAssertFalse(stringNo.boolValue)
        XCTAssertTrue(stringOtherTrue.boolValue, "String other converted to \(stringOtherTrue.boolValue)")
        XCTAssertFalse(stringOtherFalse.boolValue, "String other converted to \(stringOtherFalse.boolValue)")
    }

}
