//
//  CollectModuleTests.swift
//  tealium-swift
//
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
        collectModule.collect = CollectEventDispatcher(config: testTealiumConfig, urlSession: MockURLSession(), completion: nil)
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
        collectModule.collect = CollectEventDispatcher(config: testTealiumConfig, urlSession: MockURLSession(), completion: nil)
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
            case .success:
                XCTFail("Unexpected success")
            }
        }
    }

    func testTrack() {
        let collectModule = CollectModule(config: testTealiumConfig, delegate: self, completion: nil)
        collectModule.collect = CollectEventDispatcher(config: testTealiumConfig, urlSession: MockURLSession(), completion: nil)
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
            case .success:
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
        collectModule.collect = CollectEventDispatcher(config: testTealiumConfig, urlSession: MockURLSession(), completion: nil)
        let track = TealiumTrackRequest(data: ["test_track": true])
        collectModule.dynamicTrack(track) { result in
            switch result.0 {
            case .failure:
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
        collectModule.collect = CollectEventDispatcher(config: testTealiumConfig, urlSession: MockURLSession(), completion: nil)
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
        collectModule.collect = CollectEventDispatcher(config: testTealiumConfig, urlSession: MockURLSession(), completion: nil)
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
        collectModule.collect = CollectEventDispatcher(config: testTealiumConfig, urlSession: MockURLSession(), completion: nil)
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

    func testOverrideCollectURL() {
        let config = testTealiumConfig.copy
        config.overrideCollectURL = "https://collect-eu-west-1.tealiumiq.com/event"
        XCTAssertTrue(config.options[CollectKey.overrideCollectUrl] as! String == "https://collect-eu-west-1.tealiumiq.com/event")
    }

    func testOverrideCollectProfile() {
        let config = testTealiumConfig.copy
        config.overrideCollectProfile = "testprofile"
        XCTAssertTrue(config.options[CollectKey.overrideCollectProfile] as! String == "testprofile")
        
    }

    func testPrepareTrackWithProfileOverride() {
        let config = testTealiumConfig.copy
        config.overrideCollectProfile = "testprofile"
        let collectModule = CollectModule(config: config, delegate: self, completion: nil)
        collectModule.collect = CollectEventDispatcher(config: config, urlSession: MockURLSession(), completion: nil)
        let track = TealiumTrackRequest(data: [TealiumKey.event: "testevent"])
        let newTrack = collectModule.prepareForDispatch(track).trackDictionary
        XCTAssertEqual(newTrack["tealium_profile"] as! String, "testprofile")
    }
    
    func testInvalidTrackRequest() {
        let config = testTealiumConfig.copy
        let collectModule = CollectModule(config: config, delegate: self, completion: nil)
        collectModule.collect = CollectEventDispatcher(config: config, urlSession: MockURLSession(), completion: nil)
        let request = TealiumRemoteCommandRequest(data: [:])
        collectModule.dynamicTrack(request) { response in
            switch response.0 {
            case .failure(let error):
                XCTAssertEqual(error as! CollectError, CollectError.trackNotApplicableForCollectModule)
            default:
                XCTFail("Unexpected success - module should not process this type of request")
            }
        }
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
