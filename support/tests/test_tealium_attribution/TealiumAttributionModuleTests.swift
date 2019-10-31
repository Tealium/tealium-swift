//
//  TealiumAttributionModuleTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 11/16/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

//  Application Test do to UIKit not being available to Unit Test Bundle

@testable import TealiumAttribution
@testable import TealiumCore
import XCTest

class TealiumAttributionModuleTests: XCTestCase {

    var module: TealiumAttributionModule?
    var expectation: XCTestExpectation?
    var payload: [String: Any]?

    override func setUp() {
        super.setUp()

        module = TealiumAttributionModule(delegate: self)
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        module = nil
        payload = nil

        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testWithoutIDFA() {
        expectation = self.expectation(description: "attribution-disabled")
        let testTrack = TealiumTrackRequest(data: [String: AnyObject](),
                                            completion: { success, info, _ in

                                                XCTAssertTrue(success, "Test track call did not return success.")
                                                XCTAssertTrue((info?[TealiumAttributionKey.idfa] == nil), "IDFA was present unexpectedly")

        })

        module?.track(testTrack)
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }

    // note - test data is mocked to remove reliance on Apple API. Breakpoints in Apple code will not be hit.
    func testFullTrack() {
        expectation = self.expectation(description: "full track")
        testTealiumConfig.setSearchAdsEnabled(true)

        let attributionData = TealiumAttributionData(diskStorage: AttributionMockDiskStorage(), isSearchAdsEnabled: true, identifierManager: TealiumASIdentifierManagerAdTrackingEnabled.shared)
//        module?.enable(TealiumEnableRequest(config: testTealiumConfig, enableCompletion: nil), diskStorage: AttributionMockDiskStorage())
        module?.attributionData = attributionData
        module?.isEnabled = true
        let testTrack = TealiumTrackRequest(data: [String: AnyObject](),
                                            completion: { _, info, _ in
                                                guard let trackData = info else {
                                                    return
                                                }
                                                // test for expected keys
                                                let expectedKeys = TealiumAttributionKey.allCases

                                                for key in expectedKeys where trackData[key] == nil {
                                                    XCTFail("Missing expected key: \(key)")
                                                }

                                                if trackData[TealiumAttributionKey.isTrackingAllowed] as! String != "true" {
                                                    XCTFail("Expected tracking to be enabled. Check device settings")
                                                }
        })
        module?.track(testTrack)
        self.waitForExpectations(timeout: 15.0, handler: nil)

    }

    func testWithLimitTrackingEnabled() {
        let expectation = self.expectation(description: "testWithLimitTrackingEnabled")
        let attributionData = TealiumAttributionData(diskStorage: AttributionMockDiskStorage(), isSearchAdsEnabled: false, identifierManager: TealiumASIdentifierManagerAdTrackingDisabled.shared)
        module?.enable(TealiumEnableRequest(config: testTealiumConfig, enableCompletion: nil), diskStorage: AttributionMockDiskStorage())
        module?.attributionData = attributionData
        let testTrack = TealiumTrackRequest(data: [String: AnyObject](),
                                            completion: { _, info, _ in
                                                guard let trackData = info else {
                                                    return
                                                }
                                                // test for expected keys
                                                let expectedKeys = [
                                                    TealiumAttributionKey.idfv,
                                                    TealiumAttributionKey.idfa,
                                                    TealiumAttributionKey.isTrackingAllowed,
                                                ]

                                                for key in expectedKeys where trackData[key] == nil {
                                                        XCTFail("Missing expected key: \(key)")
                                                }
                                                guard let idfa = trackData[TealiumAttributionKey.idfa] as? String else {
                                                    XCTFail("IDFA missing from track call")
                                                    return
                                                }

                                                XCTAssertEqual(idfa, TealiumTestValue.testIDFAStringAdTrackingDisabled, "IDFA contained incorrect value")

                                                if trackData[TealiumAttributionKey.isTrackingAllowed] as! String == "true" {
                                                    XCTFail("Expected tracking to be disabled")
                                                }
                                                expectation.fulfill()
        })

        module?.track(testTrack)
        self.wait(for: [expectation], timeout: 5.0)
    }

    func testWithIDFA() {
        expectation = self.expectation(description: "attribution-enabled")
        let testID = TealiumTestValue.testIDFAString
        let attributionData = TealiumAttributionData(diskStorage: AttributionMockDiskStorage(), isSearchAdsEnabled: false, identifierManager: TealiumASIdentifierManagerAdTrackingEnabled.shared)
        testTealiumConfig.setSearchAdsEnabled(true)
        module?.enable(TealiumEnableRequest(config: testTealiumConfig, enableCompletion: nil), diskStorage: AttributionMockDiskStorage())
        module?.attributionData = attributionData
        let testTrack = TealiumTrackRequest(data: [String: AnyObject](),
                                            completion: { success, info, _ in

                                                XCTAssertTrue(success, "Test track call did not return success.")
                                                XCTAssertTrue((info?[TealiumAttributionKey.idfa] != nil), "IDFA was missing unexpectedly")
                                                XCTAssertTrue(info?[TealiumAttributionKey.idfa] as? String == testID, "Mismatch in IDFA")

        })

        module?.track(testTrack)
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testMinimumProtocolsReturn() {
        let expectation = self.expectation(description: "minimumProtocolsReturned")
        let helper = TestTealiumHelper()
        let module = TealiumAttributionModule(delegate: nil)
        helper.modulesReturnsMinimumProtocols(module: module) { success, failingProtocols in

            expectation.fulfill()
            XCTAssertTrue(success, "Not all protocols returned. Failing protocols: \(failingProtocols)")

        }

        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

}

extension TealiumAttributionModuleTests: TealiumModuleDelegate {

    func tealiumModuleFinished(module: TealiumModule, process: TealiumRequest) {
        if process is TealiumEnableRequest {
            return
        }

        guard let trackRequest = process as? TealiumTrackRequest else {
            XCTFail("Process not of track type.")
            return
        }

        // Look through responses for any errors
        for response in trackRequest.moduleResponses where response.error != nil {
            trackRequest.completion?(false, nil, response.error)
            return
        }
        payload = trackRequest.trackDictionary
        expectation?.fulfill()
        trackRequest.completion?(true, payload, nil)
    }

    func tealiumModuleFinishedReport(fromModule: TealiumModule, module: TealiumModule, process: TealiumRequest) {

    }

    func tealiumModuleRequests(module: TealiumModule?, process: TealiumRequest) {
        if let process = process as? TealiumLoadRequest {
            let mockData: [String: String] = Dictionary(uniqueKeysWithValues: TealiumAttributionKey.allCases.map { ($0, "mockdata") })
            process.completion?(true, mockData, nil)
        }
    }

}
