//
//  LifecycleModuleTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 2/14/17.
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
@testable import TealiumLifecycle
import XCTest

class LifecycleModuleTests: XCTestCase {

    var expectationRequest: XCTestExpectation?
    var sleepExpectation: XCTestExpectation?
    var wakeExpectation: XCTestExpectation?
    var autotrackedRequest: XCTestExpectation?
    var requestProcess: TealiumRequest?
    let helper = TestTealiumHelper()
    var lifecycleModule: LifecycleModule!
    var config: TealiumConfig!
    var returnData: [String: Any]!

    override func setUp() {
        super.setUp()
        config = TealiumConfig(account: "testAccount", profile: "testProfile", environment: "testEnv")
        //lifecycleModule = LifecycleModule(config: config, delegate: self, diskStorage: LifecycleMockDiskStorage(), completion: {})
        returnData = [String: Any]()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        lifecycleModule = nil
        expectationRequest = nil
        sleepExpectation = nil
        wakeExpectation = nil
        requestProcess = nil
        super.tearDown()
    }

    func testLifecycleLoadedFromStorage() {
        lifecycleModule = LifecycleModule(config: config, delegate: self, diskStorage: LifecycleMockDiskStorage(), completion: { _ in })
        let stored = lifecycleModule.lifecycle
        XCTAssertNotNil(stored)
    }

    func testLifecycleSavedToStorage() {
        lifecycleModule = LifecycleModule(config: config, delegate: self, diskStorage: LifecycleMockDiskStorage(), completion: { _ in })
        let lifecycle = Lifecycle()
        lifecycleModule.lifecycle = lifecycle
        let stored = lifecycleModule.lifecycle
        XCTAssertNotNil(stored)
    }

    func testLifecycleAcceptable() {
        let lifecycleModule2 = LifecycleModule(config: config, delegate: self, diskStorage: LifecycleMockDiskStorage(), completion: { _ in })
        XCTAssertFalse(lifecycleModule2.lifecycleAcceptable(type: .wake))

        lifecycleModule2.lastLifecycleEvent = .launch
        XCTAssertFalse(lifecycleModule2.lifecycleAcceptable(type: .launch))
        XCTAssertTrue(lifecycleModule2.lifecycleAcceptable(type: .sleep))
        XCTAssertFalse(lifecycleModule2.lifecycleAcceptable(type: .wake))

        lifecycleModule2.lastLifecycleEvent = .sleep
        XCTAssertFalse(lifecycleModule2.lifecycleAcceptable(type: .launch))
        XCTAssertFalse(lifecycleModule2.lifecycleAcceptable(type: .sleep))
        XCTAssertTrue(lifecycleModule2.lifecycleAcceptable(type: .wake))

        lifecycleModule2.lastLifecycleEvent = .wake
        XCTAssertFalse(lifecycleModule2.lifecycleAcceptable(type: .launch))
        XCTAssertTrue(lifecycleModule2.lifecycleAcceptable(type: .sleep))
        XCTAssertFalse(lifecycleModule2.lifecycleAcceptable(type: .wake))
    }

    func testAllAdditionalKeysPresent() {
        lifecycleModule = LifecycleModule(config: config, delegate: self, diskStorage: LifecycleMockDiskStorage(), completion: { _ in })
        let actual = lifecycleModule.data

        guard let request = requestProcess as? TealiumTrackRequest else {
            XCTFail("\n\nFailure: Process not a track request.\n")
            return
        }
        returnData = request.trackDictionary
        let expectedKeys = ["tealium_event"]
        let expectedDictKeys = ["lifecycle_lastwakedate",
                                "lifecycle_firstlaunchdate_MMDDYYYY",
                                "lifecycle_launchcount",
                                "lifecycle_hourofday_local",
                                "autotracked",
                                "lifecycle_secondsawake",
                                "lifecycle_dayofweek_local",
                                "lifecycle_type",
                                "lifecycle_totalcrashcount",
                                "lifecycle_totallaunchcount",
                                "lifecycle_firstlaunchdate",
                                "lifecycle_sleepcount",
                                "lifecycle_totalsecondsawake",
                                "lifecycle_priorsecondsawake",
                                "lifecycle_lastlaunchdate",
                                "lifecycle_dayssincelastwake",
                                "lifecycle_dayssincelaunch",
                                "lifecycle_wakecount",
                                "lifecycle_totalsleepcount",
                                "lifecycle_totalwakecount"]

        let missingKeys = TestTealiumHelper.missingKeys(fromDictionary: returnData, keys: expectedKeys)

        let missingDictKeys = TestTealiumHelper.missingKeys(fromDictionary: returnData, keys: expectedDictKeys)

        XCTAssertTrue(missingKeys.isEmpty, "Unexpected keys missing:\(missingKeys)")

        XCTAssertTrue(missingDictKeys.isEmpty, "Unexpected keys missing:\(missingDictKeys)")
    }

    func testManualLifecycleTrackingConfigSetting() {
        config.lifecycleAutoTrackingEnabled = false
        lifecycleModule = LifecycleModule(config: config, delegate: self, diskStorage: LifecycleMockDiskStorage(), completion: { _ in })

        if let request = requestProcess as? TealiumTrackRequest {
            returnData = request.trackDictionary
        }

        let expectedMissingKeys = ["lifecycle_type", "lifecycle_isfirstlaunch"]

        let missingKeys = TestTealiumHelper.missingKeys(fromDictionary: returnData, keys: expectedMissingKeys)

        XCTAssertTrue(missingKeys.count == 2, "Unexpected keys missing:\(missingKeys)")

    }

    func testManualLaunchMethodCall() {
        expectationRequest = expectation(description: "manualLaunchProducesExpectedData")

        config.lifecycleAutoTrackingEnabled = false
        lifecycleModule = LifecycleModule(config: config, delegate: self, diskStorage: LifecycleMockDiskStorage(), completion: { _ in })
        _ = Tealium(config: config)

        lifecycleModule.launch(at: Date())

        if let request = requestProcess as? TealiumTrackRequest {
            returnData = request.trackDictionary
        }

        let expectedKeys = ["lifecycle_type", "lifecycle_isfirstlaunch"]

        let expectedValues = ["launch", "true"]

        let missingKeys = TestTealiumHelper.missingKeys(fromDictionary: returnData, keys: expectedKeys)

        XCTAssertTrue(missingKeys.isEmpty, "Unexpected keys missing:\(missingKeys)")

        _ = expectedKeys.enumerated().map {
            if let value = returnData[$1] as? String {
                XCTAssertEqual(value, expectedValues[$0])
            }
        }

        self.waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testManualSleepMethodCall() {
        sleepExpectation = expectation(description: "manualSleepProducesExpectedData")

        config.lifecycleAutoTrackingEnabled = false
        lifecycleModule = LifecycleModule(config: config, delegate: self, diskStorage: LifecycleMockDiskStorage(), completion: { _ in })
        _ = Tealium(config: config)

        lifecycleModule.launch(at: Date())
        lifecycleModule.sleep()

        if let request = requestProcess as? TealiumTrackRequest {
            returnData = request.trackDictionary
        }

        let expectedKeys = ["lifecycle_type", "lifecycle_sleepcount"]

        let expectedValues = ["sleep", "1"]

        let missingKeys = TestTealiumHelper.missingKeys(fromDictionary: returnData, keys: expectedKeys)

        XCTAssertTrue(missingKeys.isEmpty, "Unexpected keys missing:\(missingKeys)")

        _ = expectedKeys.enumerated().map {
            if let value = returnData[$1] as? String {
                XCTAssertEqual(value, expectedValues[$0])
            }
        }

        self.waitForExpectations(timeout: 8.0, handler: nil)
    }

    func testManualWakeMethodCall() {
        wakeExpectation = expectation(description: "manualWakeProducesExpectedData")

        config.lifecycleAutoTrackingEnabled = false
        lifecycleModule = LifecycleModule(config: config, delegate: self, diskStorage: LifecycleMockDiskStorage(), completion: { _ in })
        _ = Tealium(config: config)

        lifecycleModule.launch(at: Date())
        lifecycleModule.sleep()
        lifecycleModule.wake()

        if let request = requestProcess as? TealiumTrackRequest {
            returnData = request.trackDictionary
        }

        let expectedKeys = ["lifecycle_type", "lifecycle_wakecount"]

        let expectedValues = ["wake", "2"]

        let missingKeys = TestTealiumHelper.missingKeys(fromDictionary: returnData, keys: expectedKeys)

        XCTAssertTrue(missingKeys.isEmpty, "Unexpected keys missing:\(missingKeys)")

        _ = expectedKeys.enumerated().map {
            if let value = returnData[$1] as? String {
                XCTAssertEqual(value, expectedValues[$0])
            }
        }

        self.waitForExpectations(timeout: 8.0, handler: nil)
    }

    func testAutotrackedTrue() {
        autotrackedRequest = expectation(description: "testAutotrackedTrue")
        lifecycleModule = LifecycleModule(config: config, delegate: self, diskStorage: LifecycleMockDiskStorage(), completion: { _ in })
        _ = Tealium(config: config)
        Tealium.lifecycleListeners.addDelegate(delegate: self)

        lifecycleModule.lifecycleDetected(type: .launch)

        if let request = requestProcess as? TealiumTrackRequest {
            returnData = request.trackDictionary
        }

        guard let autotracked = returnData["autotracked"] as? Bool else {
            XCTFail("`autotracked` should not be nil")
            return
        }

        XCTAssertTrue(autotracked)

        self.waitForExpectations(timeout: 8.0, handler: nil)
    }

    func testAutotrackedFalse() {
        autotrackedRequest = expectation(description: "testAutotrackedFalse")

        config.lifecycleAutoTrackingEnabled = false
        lifecycleModule = LifecycleModule(config: config, delegate: self, diskStorage: LifecycleMockDiskStorage(), completion: { _ in })
        _ = Tealium(config: config)

        self.launch(at: Date())

        if let request = requestProcess as? TealiumTrackRequest {
            returnData = request.trackDictionary
        }

        guard let autotracked = returnData["autotracked"] as? Bool else {
            XCTFail("`autotracked` should not be nil")
            return
        }

        XCTAssertFalse(autotracked)

        self.waitForExpectations(timeout: 8.0, handler: nil)
    }

}

extension LifecycleModuleTests: ModuleDelegate {
    func processRemoteCommandRequest(_ request: TealiumRequest) {

    }

    func requestDequeue(reason: String) {

    }

    func requestTrack(_ track: TealiumTrackRequest) {
        expectationRequest?.fulfill()
        if sleepExpectation?.description == "manualSleepProducesExpectedData" &&
            (track.trackDictionary["lifecycle_type"] as! String) == "sleep" {
            sleepExpectation?.fulfill()
        }
        if wakeExpectation?.description == "manualWakeProducesExpectedData" &&
            (track.trackDictionary["lifecycle_type"] as! String) == "wake" {
            wakeExpectation?.fulfill()
        }
        if autotrackedRequest?.description == "testAutotrackedTrue" ||
            autotrackedRequest?.description == "testAutotrackedFalse" {
            autotrackedRequest?.fulfill()
        }
        requestProcess = track
    }

}

extension LifecycleModuleTests: TealiumLifecycleEvents {

    func sleep() {
        // ...
    }

    func wake() {
        // ...
    }

    func launch(at date: Date) {
        lifecycleModule.process(type: .launch, at: Date())
    }

}
