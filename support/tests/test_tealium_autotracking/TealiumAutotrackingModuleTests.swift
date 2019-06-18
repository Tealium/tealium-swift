//
//  TealiumAutotrackingModuleTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 12/22/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import Tealium

class TealiumAutotrackingModuleTests: XCTestCase {

    var module: TealiumAutotrackingModule?
    var expectationRequest: XCTestExpectation?
    var expectationShouldTrack: XCTestExpectation?
    var expectationDidComplete: XCTestExpectation?
    var requestProcess: TealiumRequest?

    override func setUp() {
        super.setUp()
        module = TealiumAutotrackingModule(delegate: self)
        module?.enable(TealiumEnableRequest(config: testTealiumConfig, enableCompletion: nil))
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
        let expectation = self.expectation(description: "minimumProtocolsReturned")
        let helper = TestTealiumHelper()
        let module = TealiumAutotrackingModule(delegate: nil)
        helper.modulesReturnsMinimumProtocols(module: module) { success, failingProtocols in

            expectation.fulfill()
            XCTAssertTrue(success, "Not all protocols returned. Failing protocols: \(failingProtocols)")

        }

        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testEnableDisable() {
        XCTAssertTrue(module!.notificationsEnabled)

        module!.disable(TealiumDisableRequest())

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

        let data: [String: Any] = ["tealium_event": "TestObject",
                                    "autotracked": "true",
        ]

        guard let process = requestProcess as? TealiumTrackRequest else {
            XCTFail("Process was unavailable or of wrong type: \(String(describing: requestProcess))")
            return
        }
        let receivedData = process.data

        XCTAssertTrue(receivedData == data, "Mismatch between data expected: \n \(data as AnyObject) and data received post processing: \n \(receivedData as AnyObject)")
    }

    func testRequestEmptyEventTrackWhenDisabled() {

        module?.disable(TealiumDisableRequest())

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

        let data: [String: Any] = ["tealium_event": "TestObject",
                                    "autotracked": "true",
        ]

        guard let request = requestProcess as? TealiumTrackRequest else {
            XCTFail("Process not of track type.")
            return
        }

        let receivedData = request.data

        XCTAssertTrue(receivedData == data, "Mismatch between data expected: \n \(data as AnyObject) and data received post processing: \n \(receivedData as AnyObject)")
    }

    func testRequestEventTrackDelegate() {
        module?.delegate = self

        let testObject = TestObject()

        let notification = Notification(name: Notification.Name(rawValue: "com.tealium.autotracking.event"),
                                        object: testObject,
                                        userInfo: nil)

        expectationRequest = expectation(description: "NotificationBasedTrack")

        module?.requestEventTrack(sender: notification)

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testAddCustomData() {
        let testObject = TestObject()

        let customData = ["a": "b",
                          "c": "d"]

        TealiumAutotracking.addCustom(data: customData,
                                      toObject: testObject)

        let notification = Notification(name: Notification.Name(rawValue: "com.tealium.autotracking.event"),
                                        object: testObject,
                                        userInfo: nil)

        expectationRequest = expectation(description: "customDataRequest")

        module?.requestEventTrack(sender: notification)

        waitForExpectations(timeout: 1.0, handler: nil)

        guard let request = requestProcess as? TealiumTrackRequest else {
            XCTFail("Request not a track type.")
            return
        }

        let receivedData = request.data

        XCTAssertTrue(customData.contains(otherDictionary: receivedData), "Custom data: \(customData) missing from track payload: \(receivedData)")
    }

    func testRemoveCustomData() {
        let testObject = TestObject()

        let customData = ["a": "b",
                          "c": "d"]

        TealiumAutotracking.addCustom(data: customData,
                                      toObject: testObject)

        TealiumAutotracking.removeCustomData(fromObject: testObject)

        let notification = Notification(name: Notification.Name(rawValue: "com.tealium.autotracking.event"),
                                        object: testObject,
                                        userInfo: nil)

        expectationRequest = expectation(description: "customDataRequest")

        module?.requestEventTrack(sender: notification)

        waitForExpectations(timeout: 1.0, handler: nil)

        guard let request = requestProcess as? TealiumTrackRequest else {
            XCTFail("Request of incorrect type.")
            return
        }
        let receivedData = request.data

        XCTAssertFalse(receivedData.contains(otherDictionary: customData), "Custom data: \(customData) was unexpectedly found in track payload: \(receivedData)")
    }

    // Cannot unit test requestViewTrack

    // Cannot unit test swizzling

}

extension TealiumAutotrackingModuleTests: TealiumModuleDelegate {

    func tealiumModuleFinished(module: TealiumModule, process: TealiumRequest) {

    }

    func tealiumModuleRequests(module: TealiumModule?, process: TealiumRequest) {
        // TODO: Info and error callback handling
        process.completion?(true, nil, nil)
        requestProcess = process
        expectationRequest?.fulfill()
    }

    func tealiumModuleFinishedReport(fromModule: TealiumModule, module: TealiumModule, process: TealiumRequest) {

    }
}

//extension TealiumAutotrackingModuleTests : TealiumAutotrackingDelegate {
//    
//    func tealiumAutotrackShouldTrack(data: [String : Any]) -> Bool {
//        expectationShouldTrack?.fulfill()
//        return true
//    }
//    
//    func tealiumAutotrackCompleted(success: Bool, info: [String : Any]?, error: Error?) {
//        expectationDidComplete?.fulfill()
//    }
//}

class TestObject: NSObject {

}
