//
//  TealiumModule_DataManagerTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 11/1/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import XCTest

class TealiumDataManagerModuleTests: XCTestCase {

    var delegateExpectationSuccess: XCTestExpectation?
    var delegateExpectationFail: XCTestExpectation?

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        delegateExpectationSuccess = nil

        super.tearDown()
    }

    func testMinimumProtocolsReturn() {
        let helper = test_tealium_helper()
        let module = TealiumDataManagerModule(delegate: nil)
        let tuple = helper.modulesReturnsMinimumProtocols(module: module)
        XCTAssertTrue(tuple.success, "Not all protocols returned. Failing protocols: \(tuple.protocolsFailing)")
    }

    func testEnableDisable() {
        let module = TealiumDataManagerModule(delegate: nil)

        module.enable(config: testTealiumConfig)

        XCTAssertTrue(module.dataManager != nil, "Data Manager did not init.")

        module.disable()

        XCTAssertTrue(module.dataManager == nil, "Data Manager did not nil out.")
    }

    func testTrackWhileEnabledDisabled() {
        delegateExpectationSuccess = self.expectation(description: "trackWhenEnabled")

        let module = TealiumDataManagerModule(delegate: self)

        module.enable(config: testTealiumConfig)

        module.track(data: [:],
                     info: nil) { success, _, _ in

                XCTAssertTrue(success, "Track mock did not return success.")

        }

        delegateExpectationFail = self.expectation(description: "trackWhenDisabled")

        module.disable()

        module.track(data: [:],
                     info: nil) { success, _, _ in

                        XCTAssertFalse(success, "Track mock did unexpectedly returned success.")
        }

        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testBasicTrackCall() {
        // Double check that the typeless convenience track correctly converts the title arg to the expected data variables
        delegateExpectationSuccess = self.expectation(description: "trackWhenEnabled")

        let module = TealiumDataManagerModule(delegate: self)

        module.enable(config: testTealiumConfig)

        module.track(data: testDataDictionary,
                     info: nil) { success, info, _ in

                        XCTAssertTrue(success, "Track mock did not return success.")

                        guard let payload = info?[TealiumCollectKey.payload] as? [String: AnyObject] else {
                            XCTFail("test failed")
                            return
                        }

                        let event = payload[TealiumKey.event] as! String
                        let eventName = payload[TealiumKey.eventName] as! String
                        let eventType = payload[TealiumKey.eventType] as! String

                        XCTAssertTrue(event == TealiumTestValue.title)
                        XCTAssertTrue(eventName == TealiumTestValue.title)
                        XCTAssertTrue(eventType == TealiumTestValue.eventType)

        }

        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

}

extension TealiumDataManagerModuleTests: TealiumModuleDelegate {

    func tealiumModuleDidEnable(module: TealiumModule) {

    }

    func tealiumModuleDidDisable(module: TealiumModule) {

    }

    func tealiumModuleFailedToDisable(module: TealiumModule) {

    }

    func tealiumModuleFailedToEnable(module: TealiumModule, error: Error?) {

    }

    func tealiumModuleEncounteredError(module: TealiumModule, error: Error) {

    }

    func tealiumModuleRequestsProcessing(module: TealiumModule, message: String) {

    }

    func tealiumModuleDidProcess(module: TealiumModule, originatingModule: TealiumModule, message: String) {

    }

    func tealiumModuleRequestsTrackCall(module: TealiumModule, data: [String: AnyObject], info: [String: AnyObject]?) {

    }

    func tealiumModuleDidTrack(module: TealiumModule,
                               data: [String: AnyObject],
                               info: [String: AnyObject]?,
                               completion: ((Bool, [String: AnyObject]?, Error?) -> Void)?) {
        let payload = testDataDictionary
        completion?(true, [TealiumCollectKey.payload: payload as AnyObject], nil)
        delegateExpectationSuccess?.fulfill()
    }

    func tealiumModuleFailedToTrack(module: TealiumModule, data: [String: AnyObject], info: [String: AnyObject]?, error: Error?, completion: ((Bool, [String: AnyObject]?, Error?) -> Void)?) {
        completion?(false, nil, nil)
        delegateExpectationFail?.fulfill()
    }
}
