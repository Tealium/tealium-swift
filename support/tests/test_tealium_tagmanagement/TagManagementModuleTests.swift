//
//  TagManagementModuleTests.swift
//  tealium-swift
//
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
@testable import TealiumTagManagement
import XCTest

class TagManagementModuleTests: XCTestCase {

    var expect: XCTestExpectation!
    var module: TagManagementModule!
    var config: TealiumConfig!
    var mockTagmanagement: MockTagManagementWebView!

    override func setUp() {
        super.setUp()
        config = TealiumConfig(account: "testAccount", profile: "testProfile", environment: "testEnv")
    }

    func testDynamicTrackWithErrorReloadsAndSucceeds() {
        expect = expectation(description: "dynamicTrackWithErrorReloadsAndSucceeds")
        mockTagmanagement = MockTagManagementWebView(success: true)
        module = TagManagementModule(config: config, delegate: self, tagManagement: mockTagmanagement)
        module?.errorState = AtomicInteger(value: 1)
        let track = TealiumTrackRequest(data: ["test_track": true])
        module?.dynamicTrack(track, completion: nil)
        XCTAssertEqual(mockTagmanagement.reloadCallCount, 1)
        XCTAssertEqual(module.errorState.value, 0)
        expect.fulfill()
        wait(for: [expect], timeout: 2.0)
    }

    func testDynamicTrackWithErrorReloadsAndFails() {
        expect = expectation(description: "dynamicTrackWithErrorReloadsAndFails")
        mockTagmanagement = MockTagManagementWebView(success: false)
        module = TagManagementModule(config: config, delegate: self, tagManagement: mockTagmanagement)
        module?.errorState = AtomicInteger(value: 1)
        let track = TealiumTrackRequest(data: ["test_track": true])
        module?.dynamicTrack(track, completion: nil)
        XCTAssertEqual(mockTagmanagement.reloadCallCount, 1)
        XCTAssertEqual(module.errorState.value, 2)
        expect.fulfill()
        wait(for: [expect], timeout: 2.0)
    }

    func testEnqueueWhenRequestIsAcceptable() {
        expect = expectation(description: "testEnqueueWhenRequestIsAcceptable")
        module = TagManagementModule(config: config, delegate: self, completion: nil)
        let track = TealiumTrackRequest(data: ["test": "track"])
        let batch = TealiumBatchTrackRequest(trackRequests: [track, track, track])
        let remote = TealiumRemoteAPIRequest(trackRequest: track)

        module.enqueue(track, completion: nil)
        XCTAssertEqual(module.pendingTrackRequests.count, 1)
        if let request = module.pendingTrackRequests[0].0 as? TealiumTrackRequest {
            XCTAssertEqual(request.trackDictionary["test"] as! String, "track")
        }

        module = TagManagementModule(config: config, delegate: self, completion: nil)

        module.enqueue(batch, completion: nil)
        XCTAssertEqual(module.pendingTrackRequests.count, 1)
        if let request = module.pendingTrackRequests[0].0 as? TealiumTrackRequest {
            XCTAssertEqual(request.trackDictionary["test"] as! String, "track")
        }

        module = TagManagementModule(config: config, delegate: self, completion: nil)

        module.enqueue(remote, completion: nil)
        XCTAssertEqual(module.pendingTrackRequests.count, 1)
        if let request = module.pendingTrackRequests[0].0 as? TealiumTrackRequest {
            XCTAssertEqual(request.trackDictionary["test"] as! String, "track")
        }
        expect.fulfill()
        wait(for: [expect], timeout: 2.0)
    }

    func testEnqueueWhenRequestIsNotAcceptable() {
        expect = expectation(description: "testEnqueueWhenRequestIsNotAcceptable")
        module = TagManagementModule(config: config, delegate: self, completion: nil)
        let req = TealiumEnqueueRequest(data: TealiumTrackRequest(data: ["test": "track"]))

        module.enqueue(req, completion: nil)
        XCTAssertEqual(module.pendingTrackRequests.count, 0)

        expect.fulfill()
        wait(for: [expect], timeout: 2.0)
    }

    func testflushQueueSuccess() {
        expect = expectation(description: "testflushQueueSuccess")
        mockTagmanagement = MockTagManagementWebView(success: true)
        module = TagManagementModule(config: config, delegate: self, tagManagement: mockTagmanagement)
        let track = TealiumTrackRequest(data: ["test": "track"])
        module.pendingTrackRequests.append((track, nil))
        module.webViewState = Atomic(value: .loadSuccess)
        module.flushQueue()

        XCTAssertEqual(module.pendingTrackRequests.count, 0)

        expect.fulfill()
        wait(for: [expect], timeout: 2.0)
    }

    func testflushQueueFail() {
        expect = expectation(description: "testflushQueueFail")
        mockTagmanagement = MockTagManagementWebView(success: false)
        module = TagManagementModule(config: config, delegate: self, tagManagement: mockTagmanagement)
        let track = TealiumTrackRequest(data: ["test": "track"])
        module.pendingTrackRequests.append((track, nil))
        module.webViewState = Atomic(value: .loadSuccess)
        module.flushQueue()

        XCTAssertEqual(module.pendingTrackRequests.count, 1)

        expect.fulfill()
        wait(for: [expect], timeout: 2.0)
    }

    func testPrepareforDispatchAddsModuleName() {
        let incomingTrack = TealiumTrackRequest(data: ["incoming": "track"])
        module = TagManagementModule(config: config, delegate: self, completion: nil)
        let result = module.prepareForDispatch(incomingTrack).trackDictionary
        XCTAssertEqual(result[TealiumKey.dispatchService] as! String, TagManagementKey.moduleName)
    }

}

extension TagManagementModuleTests: ModuleDelegate {
    func processRemoteCommandRequest(_ request: TealiumRequest) {

    }

    func requestDequeue(reason: String) {

    }

    func requestTrack(_ track: TealiumTrackRequest) {
    }
}
