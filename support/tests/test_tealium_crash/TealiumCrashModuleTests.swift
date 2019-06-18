//
//  TealiumCrashModuleTests.swift
//  test-swift-tests-ios-crash
//
//  Created by Jonathan Wong on 2/12/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import TealiumCore
@testable import TealiumCrash

class TealiumCrashModuleTests: XCTestCase {

    var crashModule: TealiumCrashModule!
    var config: TealiumConfig!
    var mockCrashReporter: MockTealiumCrashReporter!
    var delegateModuleRequests = 0
    var delegateModuleFinished = 0

    override func setUp() {
        super.setUp()
        crashModule = TealiumCrashModule(delegate: self)
        config = TealiumConfig(account: "TestAccount", profile: "TestProfile", environment: "TestEnvironment")
        mockCrashReporter = MockTealiumCrashReporter()
        delegateModuleRequests = 0
        delegateModuleFinished = 0
    }

    override func tearDown() {
        crashModule = nil
        config = nil
        super.tearDown()
    }

    func testEnableSetsEnablePropertyToTrue() {
        XCTAssertFalse(crashModule.isEnabled)
        let request = TealiumEnableRequest(config: config, enableCompletion: nil)
        crashModule.handle(TealiumEnableRequest(config: config, enableCompletion: nil))
        XCTAssertTrue(crashModule.isEnabled)
    }

    func testDisableSetsEnablePropertyToFalse() {
        crashModule.handle(TealiumEnableRequest(config: config, enableCompletion: nil))
        XCTAssertTrue(crashModule.isEnabled)
        crashModule.handle(TealiumDisableRequest())
        XCTAssertFalse(crashModule.isEnabled)
    }

    func testDisablePurgesCrashReport() {
        crashModule.handle(TealiumEnableRequest(config: config, enableCompletion: nil))
        crashModule.crashReporter = mockCrashReporter
        crashModule.disable(TealiumDisableRequest())
        XCTAssertEqual(1, mockCrashReporter.purgePendingCrashReportCallCount)
    }

    func testCrashReporterEnabledOnEnableRequest() {
        let module = TealiumCrashModule(delegate: self, crashReporter: mockCrashReporter)
        module.handle(TealiumEnableRequest(config: config, enableCompletion: nil))
        XCTAssertEqual(1, mockCrashReporter.enableCallCount)
    }

    func testTrackFinishesWithNoResponseIfNotEnabled() {
        crashModule.crashReporter = mockCrashReporter
        crashModule.track(TealiumTrackRequest(data: ["a": "1"], completion: nil))

        XCTAssertEqual(1, delegateModuleFinished)
        XCTAssertEqual(0, mockCrashReporter.hasPendingCrashReportCalledCount)
    }

    func testTrackFinishesWithNoResponseWhenNoPendingCrashReport() {
        crashModule.handle(TealiumEnableRequest(config: config, enableCompletion: nil))
        crashModule.crashReporter = mockCrashReporter
        crashModule.track(TealiumTrackRequest(data: ["a": "1"], completion: nil))

        XCTAssertEqual(1, mockCrashReporter.hasPendingCrashReportCalledCount)
        XCTAssertEqual(0, mockCrashReporter.loadPendingCrashReportDataCalledCount)
        XCTAssertEqual(2, delegateModuleFinished)   // enable and track call
    }

    func testTrackGetsCrashDataIfAvailable() {
        crashModule.handle(TealiumEnableRequest(config: config, enableCompletion: nil))
        crashModule.crashReporter = mockCrashReporter
        mockCrashReporter.pendingCrashReport = true
        crashModule.track(TealiumTrackRequest(data: ["a": "1"], completion: nil))

        XCTAssertEqual(1, mockCrashReporter.hasPendingCrashReportCalledCount)
        XCTAssertEqual(1, mockCrashReporter.getDataCallCount)
    }
}

extension TealiumCrashModuleTests: TealiumModuleDelegate {

    func tealiumModuleFinished(module: TealiumModule, process: TealiumRequest) {
        delegateModuleFinished += 1
    }

    func tealiumModuleRequests(module: TealiumModule?, process: TealiumRequest) {
        delegateModuleRequests += 1
    }
}

class MockTealiumCrashReporter: TealiumCrashReporterType {

    var pendingCrashReport = false
    var isEnabled = false
    var hasPendingCrashReportCalledCount = 0
    var enableCallCount = 0
    var loadPendingCrashReportDataCalledCount = 0
    var purgePendingCrashReportCallCount = 0
    var getDataCallCount = 0

    func hasPendingCrashReport() -> Bool {
        hasPendingCrashReportCalledCount += 1
        return pendingCrashReport
    }

    func enable() -> Bool {
        enableCallCount += 1
        return isEnabled
    }

    func loadPendingCrashReportData() -> Data! {
        loadPendingCrashReportDataCalledCount += 1
        return Data()
    }

    func purgePendingCrashReport() -> Bool {
        purgePendingCrashReportCallCount += 1
        pendingCrashReport = false
        return pendingCrashReport
    }

    func disable() {
        purgePendingCrashReportCallCount += 1
        pendingCrashReport = false
    }

    func purgePendingCrashReport() {
        purgePendingCrashReportCallCount += 1
        pendingCrashReport = false
    }

    func getData() -> [String: Any]? {
        getDataCallCount += 1
        return ["a": "1"]
    }
}
