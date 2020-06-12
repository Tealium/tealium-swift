//
//  TealiumAppDataModuleTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 11/21/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

@testable import TealiumAppData
@testable import TealiumCore
import XCTest

class TealiumAppDataModuleTests: XCTestCase {

    var delegateExpectationSuccess: XCTestExpectation?
    var delegateExpectationFail: XCTestExpectation?
    var appDataModule: TealiumAppDataModule?
    var trackData: [String: Any]?
    var delegateModuleRequests = 0
    var delegateModuleFinished = 0
    var helper = TestTealiumHelper()
    var mockDiskStorage = MockDiskStorage()

    override func setUp() {
        super.setUp()
        appDataModule = TealiumAppDataModule(delegate: nil)
        appDataModule?.diskStorage = MockDiskStorage()
        delegateModuleRequests = 0
        delegateModuleFinished = 0
    }

    override func tearDown() {
        appDataModule = nil
        trackData = nil
        super.tearDown()
    }

    func testForFailingRequests() {
        let helper = TestTealiumHelper()
        guard let module = appDataModule else {
            XCTFail("AppData module not initialized")
            return
        }

        let failing = helper.failingRequestsFor(module: module)
        XCTAssert(failing.count == 0, "Unexpected failing requests: \(failing)")
    }

    func testMinimumProtocolsReturn() {
        let expectation = self.expectation(description: "allRequestsReturn")
        let helper = TestTealiumHelper()
        let module = TealiumAppDataModule(delegate: nil)

        helper.modulesReturnsMinimumProtocols(module: module) { _, failing in

            expectation.fulfill()
            XCTAssert(failing.count == 0, "Unexpected failing requests: \(failing)")
        }

        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testEnable() {
        let module = TealiumAppDataModule(delegate: nil)
        module.enable(testEnableRequest)
        XCTAssertTrue(module.isEnabled, "Enable request failed. Module not enabled")
    }

    func testTrack() {
        let expectation = self.expectation(description: "appDataTrack")
        let module = TealiumAppDataModule(delegate: self)
        module.diskStorage = mockDiskStorage
        module.enable(TealiumEnableRequest(config: helper.getConfig(), enableCompletion: nil))

        let track = TealiumTrackRequest(data: [:]) { success, _, _ in
            expectation.fulfill()

            guard let trackData = self.trackData else {
                XCTFail("No track data detected from test.")
                return
            }

            let isMissingKeys = TealiumAppData.isMissingPersistentKeys(data: trackData)
            XCTAssert(success)
            XCTAssertFalse(isMissingKeys, "Info missing from post track call: \(trackData)")
        }

        module.track(track)

        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testTrackWasQueued() {
        let expectation = self.expectation(description: "appDataTrack")
        let module = TealiumAppDataModule(delegate: self)
        module.diskStorage = mockDiskStorage
        module.enable(TealiumEnableRequest(config: helper.getConfig(), enableCompletion: nil))

        let track = TealiumTrackRequest(data: ["was_queued": "true"]) { success, _, _ in
            expectation.fulfill()

            guard let trackData = self.trackData else {
                XCTFail("No track data detected from test.")
                return
            }

            let isMissingKeys = TealiumAppData.isMissingPersistentKeys(data: trackData)
            XCTAssert(success)
            XCTAssertTrue(isMissingKeys, "Info missing from post track call: \(trackData)")
        }

        module.track(track)

        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testEnableCallsDelegateWhenDelegateNotNil() {
        XCTAssertEqual(0, delegateModuleFinished)
        appDataModule = TealiumAppDataModule(delegate: self)
        appDataModule?.handle(testEnableRequest)
        XCTAssertEqual(1, delegateModuleFinished)
    }

    func testEnableDoesNotCallDelegateWhenDelegateIsNil() {
        XCTAssertEqual(0, delegateModuleRequests)
        appDataModule?.handle(testEnableRequest)
        XCTAssertEqual(0, delegateModuleRequests)
    }

    func testEnableSetsEnablePropertyToTrue() {
        guard let appDataModule = appDataModule else {
            XCTFail("appDataModule is nil")
            return
        }
        XCTAssertFalse(appDataModule.isEnabled)
        appDataModule.handle(testEnableRequest)
        XCTAssertTrue(appDataModule.isEnabled)
    }

    func testDisableCallsDeleteAllData() {
        let mockAppData = MockTealiumAppData()
        appDataModule = TealiumAppDataModule(delegate: nil, appData: mockAppData)
        appDataModule?.enable(testEnableRequest, diskStorage: mockDiskStorage)
        XCTAssertEqual(0, mockAppData.deleteAllDataCalledCount, "method should not be called yet")
        appDataModule?.disable(testDisableRequest)
        XCTAssertEqual(1, mockAppData.deleteAllDataCalledCount, "method should be called once")
    }

    func testDisableSetsEnablePropertyToFalse() {
        guard let appDataModule = appDataModule else {
            XCTFail("appDataModule is nil")
            return
        }
        appDataModule.enable(testEnableRequest, diskStorage: mockDiskStorage)
        XCTAssertTrue(appDataModule.isEnabled)
        appDataModule.handle(testDisableRequest)
        XCTAssertFalse(appDataModule.isEnabled)
    }

    func testDisableCallsDelegate() {
        appDataModule = TealiumAppDataModule(delegate: self)
        XCTAssertEqual(0, delegateModuleFinished)
        appDataModule?.disable(testDisableRequest)
        XCTAssertEqual(1, delegateModuleFinished)
    }

    func testTrackReturnsIfDisabled() {
        guard let appDataModule = appDataModule else {
            XCTFail("appDataModule is nil")
            return
        }
        appDataModule.track(TealiumTrackRequest(data: ["a": "1"], completion: nil))
        XCTAssertNil(trackData)
    }

    func testTrackProcessesDataWhenEnabled() {
        let module = TealiumAppDataModule(delegate: self)
        let data = ["a": "1"]
        module.enable(testEnableRequest)
        module.track(TealiumTrackRequest(data: data, completion: nil))
        XCTAssertEqual(data["a"], trackData?["a"] as? String)
    }
}

extension TealiumAppDataModuleTests: TealiumModuleDelegate {

    func tealiumModuleFinished(module: TealiumModule, process: TealiumRequest) {
        delegateModuleFinished += 1
        if let process = process as? TealiumTrackRequest {
            trackData = process.trackDictionary
            process.completion?(true,
                                nil,
                                nil)
        }
    }

    func tealiumModuleRequests(module: TealiumModule?, process: TealiumRequest) {
        delegateModuleRequests += 1
    }
}

class MockTealiumAppData: TealiumAppDataProtocol {
    func setLoadedAppData(data: PersistentAppData) {

    }

    var deleteAllDataCalledCount = 0
    var setNewAppDataCalledCount = 0

    func add(data: [String: Any]) {
    }

    func getData() -> [String: Any] {
        return [String: Any]()
    }

    func setNewAppData() {
        setNewAppDataCalledCount += 1
    }

    func setLoadedAppData(data: [String: Any]) {}

    func deleteAllData() {
        deleteAllDataCalledCount += 1
    }
}
