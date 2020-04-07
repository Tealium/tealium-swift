//
//  TealiumPersistentDataModuleTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 11/18/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
@testable import TealiumPersistentData
import XCTest

enum PersistentDataModuleTestKey {
    static let payload = "payload"
}

class TealiumPersistentDataModuleTests: XCTestCase {

    var delegateExpectationSuccess: XCTestExpectation?
    var delegateExpectationFail: XCTestExpectation?

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
        let helper = TestTealiumHelper()
        let module = TealiumPersistentDataModule(delegate: nil)
        helper.modulesReturnsMinimumProtocols(module: module) { success, failingProtocols in

            expectation.fulfill()
            XCTAssertTrue(success, "Not all protocols returned. Failing protocols: \(failingProtocols)")

        }

        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testEnableDisable() {
        let module = TealiumPersistentDataModule(delegate: nil)

        module.enable(TealiumEnableRequest(config: testTealiumConfig, enableCompletion: nil), diskStorage: PersistentDataMockDiskStorage())

        XCTAssertTrue(module.persistentData != nil, "Persistent Data did not init.")

        module.disable(TealiumDisableRequest())

        XCTAssertTrue(module.persistentData == nil, "Persistent Data did not nil out.")
    }

    func testBasicTrackCall() {
        delegateExpectationSuccess = self.expectation(description: "trackWhenEnabled")

        let module = TealiumPersistentDataModule(delegate: self)

        module.enable(TealiumEnableRequest(config: testTealiumConfig, enableCompletion: nil), diskStorage: PersistentDataMockDiskStorage())

        let testTrack = TealiumTrackRequest(data: testDataDictionary,
                                            completion: { success, info, _ in

                                                XCTAssertTrue(success, "Track mock did not return success.")

                                                guard let payload = info?[PersistentDataModuleTestKey.payload] as? [String: Any] else {
                                                    XCTFail("test failed")
                                                    return
                                                }

                                                let event = payload[TealiumKey.event] as! String

                                                XCTAssertTrue(event == TealiumTestValue.title)

        })

        module.track(testTrack)

        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

}

extension TealiumPersistentDataModuleTests: TealiumModuleDelegate {

    func tealiumModuleFinished(module: TealiumModule, process: TealiumRequest) {
        guard let trackRequest = process as? TealiumTrackRequest else {
            return
        }

        // Look through responses for any errors
        for response in trackRequest.moduleResponses where response.error != nil {
            delegateExpectationFail?.fulfill()
            trackRequest.completion?(false, nil, response.error)
            return
        }
        let payload = trackRequest.trackDictionary
        delegateExpectationSuccess?.fulfill()
        trackRequest.completion?(true, [PersistentDataModuleTestKey.payload: payload], nil)

    }

    func tealiumModuleFinishedReport(fromModule: TealiumModule, module: TealiumModule, process: TealiumRequest) {

    }

    func tealiumModuleRequests(module: TealiumModule?, process: TealiumRequest) {

    }

}
