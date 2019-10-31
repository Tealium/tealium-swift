//
//  TealiumCollectModuleTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 11/1/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

@testable import TealiumCollect
@testable import TealiumCore
import XCTest

class TealiumCollectModuleTests: XCTestCase {

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
        let module = TealiumCollectModule(delegate: nil)
        helper.modulesReturnsMinimumProtocols(module: module) { success, failingProtocols in

            expectation.fulfill()
            XCTAssertTrue(success, "Not all protocols returned. Failing protocols: \(failingProtocols)")

        }

        self.waitForExpectations(timeout: 4.0, handler: nil)
    }

    func testEnableDisable() {
        // Need to know that the TealiumCollect instance was instantiated + that we have a base url.

        let collectModule = TealiumCollectModule(delegate: nil)

        let config = testTealiumConfig
        collectModule.enable(TealiumEnableRequest(config: config, enableCompletion: nil))

        XCTAssertTrue(collectModule.collect != nil, "TealiumCollect did not initialize.")

        if let collect = collectModule.collect as? TealiumCollectPostDispatcher {
            XCTAssertEqual(collect.bulkEventDispatchURL, "\(TealiumCollectPostDispatcher.defaultDispatchBaseURL)\(TealiumCollectPostDispatcher.bulkEventPath)")
            XCTAssertEqual(collect.singleEventDispatchURL, "\(TealiumCollectPostDispatcher.defaultDispatchBaseURL)\(TealiumCollectPostDispatcher.singleEventPath)")
            collectModule.disable(TealiumDisableRequest())
            let newCollect = collectModule.collect as? TealiumCollectPostDispatcher
            XCTAssertTrue(newCollect == nil, "TealiumCollect instance did not de-initialize properly")
        } else {
            XCTFail("Collect module did not initialize properly")
        }
    }

    func testBatchTrack() {
        let collectModule = TealiumCollectModule(delegate: self)
        collectModule.collect = TealiumCollectPostDispatcher(dispatchURL: "https://collect.tealiumiq.com", urlSession: MockURLSession(), completion: nil)
        let config = testTealiumConfig
        collectModule.enable(TealiumEnableRequest(config: config, enableCompletion: nil))
        let track = TealiumTrackRequest(data: ["test_track": true], completion: nil)
        let batchTrack = TealiumBatchTrackRequest(trackRequests: [track, track, track], completion: nil)
        collectModule.batchTrack(batchTrack)
    }

    func testTrack() {
        let collectModule = TealiumCollectModule(delegate: self)
        collectModule.collect = TealiumCollectPostDispatcher(dispatchURL: "https://collect.tealiumiq.com", urlSession: MockURLSession(), completion: nil)
        let config = testTealiumConfig
        collectModule.enable(TealiumEnableRequest(config: config, enableCompletion: nil))
        let track = TealiumTrackRequest(data: ["test_track": true], completion: nil)
        collectModule.track(track)
    }

    func testPrepareForDispatch() {
        let collectModule = TealiumCollectModule(delegate: nil)
        let config = testTealiumConfig
        collectModule.enable(TealiumEnableRequest(config: config, enableCompletion: nil))
        let track = TealiumTrackRequest(data: [String: Any](), completion: nil)
        let newTrack = collectModule.prepareForDispatch(track).trackDictionary
        XCTAssertNotNil(newTrack[TealiumKey.account])
        XCTAssertNotNil(newTrack[TealiumKey.profile])
    }

    func testDynamicDispatchSingleTrack() {
        let collectModule = TealiumCollectModule(delegate: self)
        collectModule.collect = TealiumCollectPostDispatcher(dispatchURL: "https://collect.tealiumiq.com", urlSession: MockURLSession(), completion: nil)
        let config = testTealiumConfig
        collectModule.enable(TealiumEnableRequest(config: config, enableCompletion: nil))
        let track = TealiumTrackRequest(data: ["test_track": true], completion: nil)
        collectModule.dynamicTrack(track)
    }

    func testDynamicDispatchBatchTrack() {
        let collectModule = TealiumCollectModule(delegate: self)
        collectModule.collect = TealiumCollectPostDispatcher(dispatchURL: "https://collect.tealiumiq.com", urlSession: MockURLSession(), completion: nil)
        let config = testTealiumConfig
        collectModule.enable(TealiumEnableRequest(config: config, enableCompletion: nil))
        let track = TealiumTrackRequest(data: ["test_track": true], completion: nil)
        let batchTrack = TealiumBatchTrackRequest(trackRequests: [track, track, track], completion: nil)
        collectModule.dynamicTrack(batchTrack)
    }

    func testOverrideCollectURL() {
        testTealiumConfig.setCollectOverrideURL(url: "https://collect.tealiumiq.com/vdata/i.gif?tealium_account=tealiummobile&tealium_profile=someprofile")
        XCTAssertTrue(testTealiumConfig.optionalData[TealiumCollectKey.overrideCollectUrl] as! String == "https://collect.tealiumiq.com/vdata/i.gif?tealium_account=tealiummobile&tealium_profile=someprofile&")
    }

    func testOverrideCollectProfile() {
        testTealiumConfig.setCollectOverrideProfile(profile: "hello")
        XCTAssertTrue(testTealiumConfig.optionalData[TealiumCollectKey.overrideCollectProfile] as! String == "hello")
    }

}

extension TealiumCollectModuleTests: TealiumModuleDelegate {
    func tealiumModuleFinished(module: TealiumModule, process: TealiumRequest) {
        if let process = process as? TealiumTrackRequest {
            XCTAssertEqual(process.trackDictionary["test_track"] as! Bool, true)
        } else if let process = process as? TealiumBatchTrackRequest {
            process.trackRequests.forEach {
                XCTAssertEqual($0.trackDictionary["test_track"] as! Bool, true)
            }
        }
    }

    func tealiumModuleRequests(module: TealiumModule?, process: TealiumRequest) {
        XCTFail("Should not be called")
    }

}
