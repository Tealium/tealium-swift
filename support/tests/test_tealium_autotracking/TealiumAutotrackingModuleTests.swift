//
//  TealiumAutotrackingModuleTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 12/22/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import XCTest

class TealiumAutotrackingModuleTests: XCTestCase {
    
    var module : TealiumAutotrackingModule?
    var expectationRequest : XCTestExpectation?
    var expectationShouldTrack : XCTestExpectation?
    var expectationDidComplete : XCTestExpectation?
    var requestProcess : TealiumProcess?
    
    override func setUp() {
        super.setUp()
        module = TealiumAutotrackingModule(delegate: self)
        module?.enable(config: testTealiumConfig)
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        expectationRequest = nil
        expectationDidComplete = nil
        expectationShouldTrack = nil
        requestProcess = nil
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testMinimumProtocolsReturn() {
        
        let helper = test_tealium_helper()
        let module = TealiumAutotrackingModule(delegate: nil)
        let tuple = helper.modulesReturnsMinimumProtocols(module: module)
        XCTAssertTrue(tuple.success, "Not all protocols returned. Failing protocols: \(tuple.protocolsFailing)")
        
    }
    
    func testEnableDisable() {
        
        XCTAssertTrue(module!.notificationsEnabled)
        
        module!.disable()
        
        XCTAssertFalse(module!.notificationsEnabled)
        
    }
    
    func testRequestNoObjectEventTrack() {
        
        // Should ignore requests from missing objects
        
        let notification = Notification(name: Notification.Name(rawValue: "com.tealium.autotracking.event"),
                                        object: nil,
                                        userInfo: nil)
        
        module?.requestEventTrack(sender: notification)
        
        XCTAssertTrue(requestProcess == nil, "Request process found when none should exists.")
    
    }
    
    func testRequestEmptyEventTrack() {
        
        let testObject = TestObject()

        let notification = Notification(name: Notification.Name(rawValue: "com.tealium.autotracking.event"),
                                        object: testObject,
                                        userInfo: nil)
        
        expectationRequest = expectation(description: "emptyEventDetected")
        
        module?.requestEventTrack(sender: notification)
        
        waitForExpectations(timeout: 1.0, handler: nil)
        
        XCTAssertTrue(requestProcess != nil, "Request process missing.")
        
        let data: [String : Any] = ["tealium_event": "TestObject",
                                    "event_name": "TestObject" ,
                                    "tealium_event_type": "activity",
                                    "autotracked" : "true"
        ]

        guard let process = requestProcess else {
            XCTFail("Process was unavailable.")
            return
        }
        guard let recievedData = process.track?.data else {
            
            XCTFail("No track data retured with request: \(process)")
            return
        }
        
        XCTAssertTrue(recievedData == data, "Mismatch between data expected: \n \(data as AnyObject) and data received post processing: \n \(recievedData as AnyObject)")
        
        
    }
    
    func testRequestEmptyEventTrackWhenDisabled() {
        
        module?.disable()
        
        let notification = Notification(name: Notification.Name(rawValue: "com.tealium.autotracking.event"),
                                        object: nil,
                                        userInfo: nil)
        
        module?.requestEventTrack(sender: notification)

        
        XCTAssertTrue(requestProcess == nil, "Module not disabled as expected")
        
    }
    
    
    func testRequestEventTrack() {
        
        let testObject = TestObject()
        
        let notification = Notification(name: Notification.Name(rawValue: "com.tealium.autotracking.event"),
                                        object: testObject,
                                        userInfo: nil)
        
        expectationRequest = expectation(description: "eventDetected")
        
        module?.requestEventTrack(sender: notification)
        
        waitForExpectations(timeout: 1.0, handler: nil)
        
        // The request process should have been populated by the requestEventTrack call
        
        XCTAssertTrue(requestProcess != nil)
        
        let data: [String : Any] = ["tealium_event": "TestObject",
                                    "event_name": "TestObject" ,
                                    "tealium_event_type": "activity",
                                    "autotracked" : "true"
        ]
        
        guard let recievedData = requestProcess?.track?.data else {
            XCTFail("No track data retured with request: \(requestProcess!)")
            return
        }
        
        XCTAssertTrue(recievedData == data, "Mismatch between data expected: \n \(data as AnyObject) and data received post processing: \n \(recievedData as AnyObject)")
        
    }
    
    func testRequestEventTrackDelegate() {
        
        module?.autotracking.delegate = self
        
        let testObject = TestObject()
        
        let notification = Notification(name: Notification.Name(rawValue: "com.tealium.autotracking.event"),
                                        object: testObject,
                                        userInfo: nil)
        
        expectationShouldTrack = expectation(description: "autotrackShouldTrack")
        expectationDidComplete = expectation(description: "autotrackDidComplete")
        
        module?.requestEventTrack(sender: notification)
        
        waitForExpectations(timeout: 1.0, handler: nil)
        
    }
    
    func testAddCustomData() {
        
        let testObject = TestObject()

        let customData = ["a":"b",
                          "c":"d"]
        
        TealiumAutotracking.addCustom(data: customData,
                                      toObject: testObject)
        
        let notification = Notification(name: Notification.Name(rawValue: "com.tealium.autotracking.event"),
                                        object: testObject,
                                        userInfo: nil)
        
        expectationRequest = expectation(description: "customDataRequest")

        module?.requestEventTrack(sender: notification)
        
        waitForExpectations(timeout: 1.0, handler: nil)
        
        guard let recievedData = requestProcess?.track?.data else {
            XCTFail("No track data retured with request: \(requestProcess!)")
            return
        }
        
        XCTAssertTrue(recievedData.contains(smallerDictionary: customData), "Custom data: \(customData) missing from track payload: \(recievedData)")
        
    }
    
    func testRemoveCustomData() {
        
        let testObject = TestObject()
        
        let customData = ["a":"b",
                          "c":"d"]
        
        TealiumAutotracking.addCustom(data: customData,
                                      toObject: testObject)
        
        TealiumAutotracking.removeCustomData(fromObject: testObject)
        
        let notification = Notification(name: Notification.Name(rawValue: "com.tealium.autotracking.event"),
                                        object: testObject,
                                        userInfo: nil)
        
        expectationRequest = expectation(description: "customDataRequest")
        
        module?.requestEventTrack(sender: notification)
        
        waitForExpectations(timeout: 1.0, handler: nil)
        
        guard let recievedData = requestProcess?.track?.data else {
            XCTFail("No track data retured with request: \(requestProcess!)")
            return
        }
        
        XCTAssertFalse(recievedData.contains(smallerDictionary: customData), "Custom data: \(customData) was unexpectedly found in track payload: \(recievedData)")
        
        
    }
    
    // Cannot unit test requestViewTrack
    
    // Cannot unit test swizzling
    
}

extension TealiumAutotrackingModuleTests : TealiumModuleDelegate {
    
    func tealiumModuleFinished(module: TealiumModule, process: TealiumProcess) {
        
    }
    
    func tealiumModuleRequests(module: TealiumModule, process: TealiumProcess) {

        // TODO: Info and error callback handling
        process.track?.completion?(true, nil, nil)
        requestProcess = process
        expectationRequest?.fulfill()
        
    }
    
    func tealiumModuleFinishedReport(fromModule: TealiumModule, module: TealiumModule, process: TealiumProcess) {
        
    }
}

extension TealiumAutotrackingModuleTests : TealiumAutotrackingDelegate {
    
    func tealiumAutotrackShouldTrack(data: [String : Any]) -> Bool {
        expectationShouldTrack?.fulfill()
        return true
    }
    
    func tealiumAutotrackCompleted(success: Bool, info: [String : Any]?, error: Error?) {
        expectationDidComplete?.fulfill()
    }
}

class TestObject: NSObject {
    
    
}
