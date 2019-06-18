//
//  TealiumConnectivityModuleTests.swift
//  tealium-swift
//
//  Created by Craig Rouse on 11/6/17.
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import Tealium

class TealiumConnectivityModuleTests: XCTestCase {

    var delegateExpectation: XCTestExpectation?
    var delegateExpectation2: XCTestExpectation?
    var trackData: [String: Any]?

    override func setUp() {
        super.setUp()
        self.delegateExpectation2 = nil
        self.delegateExpectation = nil
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        trackData = nil
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testForFailingRequests() {
        let helper = TestTealiumHelper()
        let module = TealiumConnectivityModule(delegate: nil)

        let failing = helper.failingRequestsFor(module: module)
        XCTAssert(failing.count == 0, "Unexpected failing requests: \(failing)")
    }

    func testMinimumProtocolsReturn() {
        let expectation = self.expectation(description: "allRequestsReturn")
        let helper = TestTealiumHelper()
        let module = TealiumConnectivityModule(delegate: nil)

        helper.modulesReturnsMinimumProtocols(module: module) { _, failing in

            expectation.fulfill()
            XCTAssert(failing.count == 0, "Unexpected failing requests: \(failing)")
        }

        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

    // Wifi and Cellular data should be disabled on the device/simulator before running the test or test will fail
    func testTrackWithNoConnection() {
        self.delegateExpectation = self.expectation(description: "connectivityTrack queue test")
        self.delegateExpectation2 = self.expectation(description: "expected 2nd track request")
        let module = TealiumConnectivityModule(delegate: self)
        let request = TealiumEnableRequest(config: TestTealiumHelper().getConfig(), enableCompletion: nil)
        module.enable(request)
        module.isEnabled = true

        TealiumConnectivityModule.setConnectionOverride(shouldOverride: false) // allow default state (offline since wifi disabled)
        let track = TealiumTrackRequest(data: ["test_track": "no connection"], completion: nil)

        module.track(track)
        // override actual connection status to allow track to complete successfully despite no connection
        TealiumConnectivityModule.setConnectionOverride(shouldOverride: true)
        // fire new track to allow the 1st queued track to complete (should flush the queue)
        let track2 = TealiumTrackRequest(data: [:], completion: nil)
        module.track(track2)

        self.waitForExpectations(timeout: 15, handler: nil)

    }

    // this test should be run twice: once with wifi + cellular data disabled, once with it enabled.
    // Both test runs should pass with no errors

    func testTrack() {
        self.delegateExpectation = self.expectation(description: "connectivityTrack")
        let module = TealiumConnectivityModule(delegate: self)
        let request = TealiumEnableRequest(config: TestTealiumHelper().getConfig(), enableCompletion: nil)
        module.enable(request)
        module.isEnabled = true

        let track = TealiumTrackRequest(data: [:]) { _, _, _ in
            guard let trackData = self.trackData else {
                XCTFail("No track data detected from test.")
                return
            }

            let expectedKeys = [
                "was_queued",
                "network_connection_type",
            ]

            for key in expectedKeys where trackData[key] != nil {
                if key == "network_connection_type" {
                    continue
                }
                XCTFail("\nKey:\(key) was unexpectedly included in tracking call. Tracking data: \(trackData)\n")
            }

            self.delegateExpectation?.fulfill()

        }

        module.track(track)

        self.waitForExpectations(timeout: 3.0, handler: nil)
    }

    func testDefaultConnectivityInterval() {
        let module = TealiumConnectivityModule(delegate: nil)
        let request = TealiumEnableRequest(config: TestTealiumHelper().getConfig(), enableCompletion: nil)
        module.enable(request)
        module.isEnabled = true
        XCTAssertTrue(module.connectivity.timer?.timeInterval == TimeInterval(exactly: TealiumConnectivityConstants.defaultInterval))
    }

    func testOverriddenConnectivityInterval() {
        let module = TealiumConnectivityModule(delegate: nil)
        let config = TestTealiumHelper().getConfig()
        let testInterval = 5
        config.setConnectivityRefreshInterval(interval: testInterval)
        let request = TealiumEnableRequest(config: TestTealiumHelper().getConfig(), enableCompletion: nil)
        module.enable(request)
        module.isEnabled = true
        XCTAssertTrue(module.connectivity.timer?.timeInterval == TimeInterval(exactly: testInterval))
    }

}

// delegate to handle callbacks from connectivity module
extension TealiumConnectivityModuleTests: TealiumModuleDelegate {

    func tealiumModuleFinished(module: TealiumModule, process: TealiumRequest) {
        if let process = process as? TealiumTrackRequest {
            trackData = process.data
            process.completion?(true,
                                nil,
                                nil)
        }
    }

    func tealiumModuleRequests(module: TealiumModule?, process: TealiumRequest) {
       // let expectation = self.delegateExpectationSuccess
        if let req = process as? TealiumReportRequest {
            if req.message.contains("Sending queued track") {
                print("\n\(req.message)\n")
                self.delegateExpectation2?.fulfill()
                return
            } else if req.message.contains("Queued track. No internet connection.") {
                print("\n\(req.message)\n")
                self.delegateExpectation?.fulfill()
            } else {
                // expectation will not be fulfilled
                XCTFail("test failed")
                print("Something went wrong in queuing module")
            }
        }
    }
}
