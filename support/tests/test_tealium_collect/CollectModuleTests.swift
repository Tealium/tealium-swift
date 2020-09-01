//
//  CollectModuleTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 11/1/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

@testable import TealiumCollect
@testable import TealiumCore
import XCTest

class CollectModuleTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testBatchTrack() {
        let collectModule = CollectModule(config: testTealiumConfig, delegate: self, completion: nil)
        collectModule.collect = CollectEventDispatcher(dispatchURL: "https://collect.tealiumiq.com", urlSession: MockURLSession(), completion: nil)
        let track = TealiumTrackRequest(data: ["test_track": true])
        let batchTrack = TealiumBatchTrackRequest(trackRequests: [track, track, track])
        collectModule.batchTrack(batchTrack) { result in
            switch result.0 {
            case .failure(let error):
                XCTFail("Unexpected failure: \(error.localizedDescription)")
            case .success(let success):
                XCTAssertTrue(success)
            }
        }
    }

    func testBatchTrackInvalidRequest() {
        let collectModule = CollectModule(config: testTealiumConfig, delegate: self, completion: nil)
        collectModule.collect = CollectEventDispatcher(dispatchURL: "https://collect.tealiumiq.com", urlSession: MockURLSession(), completion: nil)
        let batchTrack = TealiumBatchTrackRequest(trackRequests: [])
        collectModule.batchTrack(batchTrack) { result in
            switch result.0 {
            case .failure(let error):
                XCTAssertEqual(error as! CollectError, CollectError.invalidBatchRequest)
            case .success:
                XCTFail("Unexpected success")
            }
        }
    }

    func testBatchTrackCollectNotInitialized() {
        let collectModule = CollectModule(config: testTealiumConfig, delegate: self, completion: nil)
        collectModule.collect = nil
        //        let track = TealiumTrackRequest(data: ["test_track": true])
        let batchTrack = TealiumBatchTrackRequest(trackRequests: [])
        collectModule.batchTrack(batchTrack) { result in
            switch result.0 {
            case .failure(let error):
                XCTAssertEqual(error as! CollectError, CollectError.collectNotInitialized)
            case .success(let success):
                XCTFail("Unexpected success")
            }
        }
    }

    func testTrack() {
        let collectModule = CollectModule(config: testTealiumConfig, delegate: self, completion: nil)
        collectModule.collect = CollectEventDispatcher(dispatchURL: "https://collect.tealiumiq.com", urlSession: MockURLSession(), completion: nil)
        let track = TealiumTrackRequest(data: ["test_track": true])
        collectModule.track(track) { result in
            switch result.0 {
            case .failure(let error):
                XCTFail("Unexpected failure: \(error.localizedDescription)")
            case .success(let success):
                XCTAssertTrue(success)
            }
        }
    }

    func testTrackCollectNotInitialized() {
        let collectModule = CollectModule(config: testTealiumConfig, delegate: self, completion: nil)
        collectModule.collect = nil
        let track = TealiumTrackRequest(data: ["test_track": true])
        collectModule.track(track) { result in
            switch result.0 {
            case .failure(let error):
                XCTAssertEqual(error as! CollectError, CollectError.collectNotInitialized)
            case .success(let success):
                XCTFail("Unexpected success")
            }
        }
    }

    func testCollectNil() {
        let expectation = self.expectation(description: "dynamic track")
        let collectModule = CollectModule(config: testTealiumConfig, delegate: self, completion: nil)
        collectModule.collect = nil
        let track = TealiumTrackRequest(data: ["test_track": true])
        collectModule.dynamicTrack(track) { result in
            switch result.0 {
            case .failure(let error):
                XCTAssertEqual(error as! CollectError, CollectError.collectNotInitialized)
                expectation.fulfill()
            case .success:
                XCTFail("Unexpected success")
            }
        }
        wait(for: [expectation], timeout: 4.0)
    }

    func testPrepareForDispatch() {
        let collectModule = CollectModule(config: testTealiumConfig, delegate: self, completion: nil)
        let track = TealiumTrackRequest(data: [String: Any]())
        let newTrack = collectModule.prepareForDispatch(track).trackDictionary
        XCTAssertNotNil(newTrack[TealiumKey.account])
        XCTAssertNotNil(newTrack[TealiumKey.profile])
    }

    func testDynamicDispatchSingleTrack() {
        let expectation = self.expectation(description: "dynamic track")
        let collectModule = CollectModule(config: testTealiumConfig, delegate: self, completion: nil)
        collectModule.collect = CollectEventDispatcher(dispatchURL: "https://collect.tealiumiq.com", urlSession: MockURLSession(), completion: nil)
        let track = TealiumTrackRequest(data: ["test_track": true])
        collectModule.dynamicTrack(track) { result in
            switch result.0 {
            case .failure(let error):
                return
            case .success(let success):
                XCTAssertTrue(success)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 4.0)
    }

    func testDynamicDispatchSingleTrackConsentCookie() {
        let expectation = self.expectation(description: "dynamic track")
        let collectModule = CollectModule(config: testTealiumConfig, delegate: self, completion: nil)
        collectModule.collect = CollectEventDispatcher(dispatchURL: "https://collect.tealiumiq.com", urlSession: MockURLSession(), completion: nil)
        let track = TealiumTrackRequest(data: [TealiumKey.event: "update_consent_cookie"])
        collectModule.dynamicTrack(track) { result in
            switch result.0 {
            case .failure(let error):
                XCTAssertEqual(error as! CollectError, CollectError.trackNotApplicableForCollectModule)
                expectation.fulfill()
            case .success:
                XCTFail("Unexpected success")
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 4.0)
    }

    func testDynamicDispatchBatchTrack() {
        let expectation = self.expectation(description: "dynamic track")
        let collectModule = CollectModule(config: testTealiumConfig, delegate: self, completion: nil)
        collectModule.collect = CollectEventDispatcher(dispatchURL: "https://collect.tealiumiq.com", urlSession: MockURLSession(), completion: nil)
        let track = TealiumTrackRequest(data: ["test_track": true])
        let batchRequest = TealiumBatchTrackRequest(trackRequests: [track])
        collectModule.dynamicTrack(batchRequest) { result in
            switch result.0 {
            case .failure(let error):
                XCTFail("Unexpected error: \(error.localizedDescription)")
            case .success(let success):
                XCTAssertTrue(success)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 4.0)
    }

    func testDynamicDispatchBatchTrackConsentCookie() {
        let expectation = self.expectation(description: "dynamic track")
        let collectModule = CollectModule(config: testTealiumConfig, delegate: self, completion: nil)
        collectModule.collect = CollectEventDispatcher(dispatchURL: "https://collect.tealiumiq.com", urlSession: MockURLSession(), completion: nil)
        let track = TealiumTrackRequest(data: [TealiumKey.event: "update_consent_cookie"])
        let batchRequest = TealiumBatchTrackRequest(trackRequests: [track])
        collectModule.dynamicTrack(batchRequest) { result in
            switch result.0 {
            case .failure(let error):
                XCTAssertEqual(error as! CollectError, CollectError.invalidBatchRequest)
                expectation.fulfill()
            case .success:
                XCTFail("Unexpected success")
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 4.0)
    }

    func testUpdateCollectDispatcher() {
        let config = TealiumConfig(account: "dummy", profile: "dummy", environment: "dummy")
        let collectModule = CollectModule(config: config, delegate: self, completion: nil)
        collectModule.updateCollectDispatcher(config: config) { result in
            switch result.0 {
            case .failure:
                XCTFail("Unexpected error")
            case .success(let success):
                XCTAssertTrue(success)
            }
        }
    }

    func testUpdateCollectDispatcherInvalidURL() {
        let config = testTealiumConfig.copy
        let collectModule = CollectModule(config: config, delegate: self, completion: nil)
        config.collectOverrideURL = "tealium"
        collectModule.updateCollectDispatcher(config: config) { result in
            switch result.0 {
            case .failure(let error):
                XCTAssertEqual(error as! CollectError, CollectError.invalidDispatchURL)
            case .success:
                XCTFail("Unexpected success")
            }
        }
    }

    func testOverrideCollectURL() {
        let config = testTealiumConfig.copy
        config.collectOverrideURL = "https://collect.tealiumiq.com/vdata/i.gif?tealium_account=tealiummobile&tealium_profile=someprofile"
        XCTAssertTrue(config.options[CollectKey.overrideCollectUrl] as! String == "https://collect.tealiumiq.com/vdata/i.gif?tealium_account=tealiummobile&tealium_profile=someprofile&")
    }

    func testOverrideCollectProfile() {
        let config = testTealiumConfig.copy
        config.collectOverrideProfile = "hello"
        XCTAssertTrue(config.options[CollectKey.overrideCollectProfile] as! String == "hello")
    }

}

extension CollectModuleTests: ModuleDelegate {
    func processRemoteCommandRequest(_ request: TealiumRequest) {

    }

    func requestTrack(_ track: TealiumTrackRequest) {

    }

    func requestDequeue(reason: String) {

    }

}
