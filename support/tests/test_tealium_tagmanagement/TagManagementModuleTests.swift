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
    var module: TagManagementModule!
    var config: TealiumConfig!
    var mockTagmanagement: MockTagManagementWebView!

    override func setUp() {
        super.setUp()
        config = TealiumConfig(account: "testAccount", profile: "testProfile", environment: "testEnv")
    }

    func testDynamicTrackWithErrorReloadsAndSucceeds() {
        mockTagmanagement = MockTagManagementWebView(success: true)
        let context = TestTealiumHelper.context(with: config)
        module = TagManagementModule(context: context, delegate: self, tagManagement: mockTagmanagement)
        module?.errorCount = AtomicInteger(value: 1)
        let track = TealiumTrackRequest(data: ["test_track": true])
        module?.dynamicTrack(track, completion: nil)
        XCTAssertEqual(mockTagmanagement.reloadCallCount, 1)
        TealiumQueues.backgroundSerialQueue.sync {
            XCTAssertEqual(self.module.errorCount.value, 0)
        }
    }

    func testDynamicTrackWithErrorReloadsAndFails() {
        mockTagmanagement = MockTagManagementWebView(success: false)
        let context = TestTealiumHelper.context(with: config)
        module = TagManagementModule(context: context, delegate: self, tagManagement: mockTagmanagement)
        module?.errorCount = AtomicInteger(value: 1)
        let track = TealiumTrackRequest(data: ["test_track": true])
        module?.dynamicTrack(track, completion: nil)
        XCTAssertEqual(mockTagmanagement.reloadCallCount, 1)
        TealiumQueues.backgroundSerialQueue.sync {
            XCTAssertEqual(self.module.errorCount.value, 2)
        }
    }

    func testEnqueueWhenRequestIsAcceptable() {
        let context = TestTealiumHelper.context(with: config)
        module = TagManagementModule(context: context, delegate: self, completion: nil)
        let track = TealiumTrackRequest(data: ["test": "track"])
        let batch = TealiumBatchTrackRequest(trackRequests: [track, track, track])
        let remote = TealiumRemoteAPIRequest(trackRequest: track)

        module.enqueue(track, completion: nil)
        XCTAssertEqual(module.pendingTrackRequests.count, 1)
        if let request = module.pendingTrackRequests[0].0 as? TealiumTrackRequest {
            XCTAssertEqual(request.trackDictionary["test"] as! String, "track")
        }

        module = TagManagementModule(context: context, delegate: self, completion: nil)

        module.enqueue(batch, completion: nil)
        XCTAssertEqual(module.pendingTrackRequests.count, 1)
        if let request = module.pendingTrackRequests[0].0 as? TealiumTrackRequest {
            XCTAssertEqual(request.trackDictionary["test"] as! String, "track")
        }

        module = TagManagementModule(context: context, delegate: self, completion: nil)

        module.enqueue(remote, completion: nil)
        XCTAssertEqual(module.pendingTrackRequests.count, 1)
        if let request = module.pendingTrackRequests[0].0 as? TealiumTrackRequest {
            XCTAssertEqual(request.trackDictionary["test"] as! String, "track")
        }
    }

    func testEnqueueWhenRequestIsNotAcceptable() {
        let context = TestTealiumHelper.context(with: config)
        module = TagManagementModule(context: context, delegate: self, completion: nil)
        let req = TealiumEnqueueRequest(data: TealiumTrackRequest(data: ["test": "track"]))

        module.enqueue(req, completion: nil)
        XCTAssertEqual(module.pendingTrackRequests.count, 0)
    }

    func testflushQueueSuccess() {
        mockTagmanagement = MockTagManagementWebView(success: true)
        let context = TestTealiumHelper.context(with: config)
        module = TagManagementModule(context: context, delegate: self, tagManagement: mockTagmanagement)
        let track = TealiumTrackRequest(data: ["test": "track"])
        module.pendingTrackRequests.append((track, nil))
        module.webViewState = .loadSuccess
        module.flushQueue()

        XCTAssertEqual(module.pendingTrackRequests.count, 0)
    }

    func testflushQueueFail() {
        mockTagmanagement = MockTagManagementWebView(success: false)
        let context = TestTealiumHelper.context(with: config)
        module = TagManagementModule(context: context, delegate: self, tagManagement: mockTagmanagement)
        let track = TealiumTrackRequest(data: ["test": "track"])
        module.pendingTrackRequests.append((track, nil))
        module.webViewState = .loadSuccess
        module.flushQueue()

        XCTAssertEqual(module.pendingTrackRequests.count, 1)
    }

    func testPrepareforDispatchAddsModuleName() {
        let incomingTrack = TealiumTrackRequest(data: ["incoming": "track"])
        let context = TestTealiumHelper.context(with: config)
        module = TagManagementModule(context: context, delegate: self, completion: nil)
        let result = module.prepareForDispatch(incomingTrack).trackDictionary
        XCTAssertEqual(result[TealiumDataKey.dispatchService] as! String, TagManagementKey.moduleName)
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
