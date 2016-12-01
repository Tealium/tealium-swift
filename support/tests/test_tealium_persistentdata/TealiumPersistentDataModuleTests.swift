//
//  TealiumPersistentDataModuleTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 11/18/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import XCTest

enum PersistantDataModuleTestKey {
    static let payload = "payload"
}

class TealiumPersistentDataModuleTests: XCTestCase {
    
    var delegateExpectationSuccess : XCTestExpectation?
    var delegateExpectationFail : XCTestExpectation?
    
    
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
        let module = TealiumPersistentDataModule(delegate: nil)
        let tuple = helper.modulesReturnsMinimumProtocols(module: module)
        XCTAssertTrue(tuple.success, "Not all protocols returned. Failing protocols: \(tuple.protocolsFailing)")
        
    }
    
    func testEnableDisable(){
        
        let module = TealiumPersistentDataModule(delegate: nil)
        
        module.enable(config: testTealiumConfig)
        
        XCTAssertTrue(module.persistentData != nil, "Persistent Data did not init.")
        
        module.disable()
        
        XCTAssertTrue(module.persistentData == nil, "Persistent Data did not nil out.")
        
        
    }
 
    func testTrackWhileEnabledDisabled(){
        
        delegateExpectationSuccess = self.expectation(description: "trackWhenEnabled")
        
        let module = TealiumPersistentDataModule(delegate: self)
        
        module.enable(config: testTealiumConfig)
        
        let testTrack = TealiumTrack(data: [String:AnyObject](),
                                     info: nil,
                                     completion: {(success, info, error) in

                    XCTAssertTrue(success, "Track mock did not return success.")

                                        
        })
        
        module.track(testTrack)
        
        delegateExpectationFail = self.expectation(description: "trackWhenDisabled")
        
        module.disable()
        
        let testTrackAfter = TealiumTrack(data: [String:AnyObject](),
                                     info: nil,
                                     completion: {(success, info, error) in
                                        
            XCTAssertFalse(success, "Track mock did unexpectedly returned success.")
                                        
        })
        
        module.track(testTrackAfter)
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
        
        
    }
    
    func testBasicTrackCall() {
        
        // Double check that the typeless convenience track correctly converts the title arg to the expected data variables
        delegateExpectationSuccess = self.expectation(description: "trackWhenEnabled")
        
        let module = TealiumPersistentDataModule(delegate: self)
        
        module.enable(config: testTealiumConfig)
        
        let testTrack = TealiumTrack(data: testDataDictionary,
                                     info: nil,
                                     completion: {(success, info, error) in
        
                XCTAssertTrue(success, "Track mock did not return success.")
                
                guard let payload = info?[PersistantDataModuleTestKey.payload] as? [String:AnyObject] else {
                    XCTFail()
                    return
                }
                
                let event = payload[TealiumKey.event] as! String
                let eventName = payload[TealiumKey.eventName] as! String
                let eventType = payload[TealiumKey.eventType] as! String
                
                XCTAssertTrue(event == TealiumTestValue.title)
                XCTAssertTrue(eventName == TealiumTestValue.title)
                XCTAssertTrue(eventType == TealiumTestValue.eventType)
                                        
        })
        
        module.track(testTrack)
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
        
    }
    
}

extension TealiumPersistentDataModuleTests : TealiumModuleDelegate {
    
    
    func tealiumModuleFinished(module: TealiumModule, process: TealiumProcess) {
        
        if process.type == .track && process.error == nil {
            let payload = testDataDictionary
            process.track?.completion?(true, [PersistantDataModuleTestKey.payload: payload as AnyObject], nil)
            delegateExpectationSuccess?.fulfill()
        }
        if process.type == .track && process.error != nil {
            process.track?.completion?(false, nil, nil)
            delegateExpectationFail?.fulfill()
        }
        
        
    }
    
    func tealiumModuleFinishedReport(fromModule: TealiumModule, module: TealiumModule, process: TealiumProcess) {
        
    }
    
    func tealiumModuleRequests(module: TealiumModule, process: TealiumProcess) {
        
    }
    
}
