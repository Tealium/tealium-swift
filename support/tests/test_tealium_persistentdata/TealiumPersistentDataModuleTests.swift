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
        
        let expectation = self.expectation(description: "minimumProtocolsReturned")
        let helper = test_tealium_helper()
        let module = TealiumPersistentDataModule(delegate: nil)
        helper.modulesReturnsMinimumProtocols(module: module) { (success, failingProtocols) in
            
            expectation.fulfill()
            XCTAssertTrue(success, "Not all protocols returned. Failing protocols: \(failingProtocols)")
            
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)

    }
    
    func testEnableDisable(){
        
        let module = TealiumPersistentDataModule(delegate: nil)
        
        module.enable(TealiumEnableRequest(config: testTealiumConfig))
        
        XCTAssertTrue(module.persistentData != nil, "Persistent Data did not init.")
        
        module.disable(TealiumDisableRequest())
        
        XCTAssertTrue(module.persistentData == nil, "Persistent Data did not nil out.")
        
        
    }

    // TODO: Decide if we want persistence to report ok even if unable to load persistence
    //  rather than blocking further processing.
    
//    func testTrackWhileEnabledDisabled(){
//        
//        delegateExpectationSuccess = self.expectation(description: "trackWhenEnabled")
//        
//        let module = TealiumPersistentDataModule(delegate: self)
//        
//        module.enable(config: testTealiumConfig)
//        
//        let testTrack = TealiumTrack(data: [String:AnyObject](),
//                                     info: nil,
//                                     completion: {(success, info, error) in
//
//                XCTAssertTrue(success, "Track mock did not return success.")
//
//                                        
//        })
//        
//        module.track(testTrack)
//        
//        delegateExpectationFail = self.expectation(description: "trackWhenDisabled")
//        
//        module.disable()
//        
//        let testTrackAfter = TealiumTrack(data: [String:AnyObject](),
//                                     info: nil,
//                                     completion: {(success, info, error) in
//                                        
//            XCTAssertFalse(success, "Track mock did unexpectedly returned success.")
//                                        
//        })
//        
//        module.track(testTrackAfter)
//        
//        self.waitForExpectations(timeout: 1.0, handler: nil)
//        
//        
//    }
    
    func testBasicTrackCall() {
        
        // Double check that the typeless convenience track correctly converts the title arg to the expected data variables
        delegateExpectationSuccess = self.expectation(description: "trackWhenEnabled")
        
        let module = TealiumPersistentDataModule(delegate: self)
        
        module.enable(TealiumEnableRequest(config: testTealiumConfig))
        
        let testTrack = TealiumTrackRequest(data: testDataDictionary,
                                            info: nil,
                                            completion: {(success, info, error) in
        
                XCTAssertTrue(success, "Track mock did not return success.")
                
                guard let payload = info?[PersistantDataModuleTestKey.payload] as? [String:AnyObject] else {
                    XCTFail()
                    return
                }
                
                let event = payload[TealiumKey.event] as! String
                let eventType = payload[TealiumKey.eventType] as! String
                
                XCTAssertTrue(event == TealiumTestValue.title)
                XCTAssertTrue(eventType == TealiumTestValue.eventType)
                                        
        })
        
        module.track(testTrack)
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
        
    }
    
}

extension TealiumPersistentDataModuleTests : TealiumModuleDelegate {
    
    
    func tealiumModuleFinished(module: TealiumModule, process: TealiumRequest) {
        
        guard let trackRequest = process as? TealiumTrackRequest else {
            return
        }
        
        // Look through responses for any errors
        for response in trackRequest.moduleResponses {
            if response.error != nil {
                delegateExpectationFail?.fulfill()
                trackRequest.completion?(false, trackRequest.info, response.error)
                return
            }
            
        }
        let payload = trackRequest.data
        delegateExpectationSuccess?.fulfill()
        trackRequest.completion?(true, [PersistantDataModuleTestKey.payload: payload as AnyObject], nil)
        
    }
    
    func tealiumModuleFinishedReport(fromModule: TealiumModule, module: TealiumModule, process: TealiumRequest) {
        
    }
    
    func tealiumModuleRequests(module: TealiumModule, process: TealiumRequest) {
        
    }
    
}
