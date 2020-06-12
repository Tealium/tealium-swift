//
//  TealiumLifecycleModuleTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 2/14/17.
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
@testable import TealiumLifecycle
import XCTest

class TealiumLifecycleModuleTests: XCTestCase {

    var expectationRequest: XCTestExpectation?
    var sleepExpectation: XCTestExpectation?
    var wakeExpectation: XCTestExpectation?
    var autotrackedRequest: XCTestExpectation?
    var requestProcess: TealiumRequest?
    let helper = TestTealiumHelper()
    var lifecycleModule: TealiumLifecycleModule!
    var config: TealiumConfig!
    var returnData: [String: Any]!

    override func setUp() {
        super.setUp()
        lifecycleModule = TealiumLifecycleModule(delegate: self)
        config = TealiumConfig(account: "testAccount", profile: "testProfile", environment: "testEnv")
        returnData = [String: Any]()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        expectationRequest = nil
        sleepExpectation = nil
        wakeExpectation = nil
        requestProcess = nil
        super.tearDown()
    }

    func testMinimumProtocolsReturn() {
        let expectation = self.expectation(description: "minimumProtocolsReturned")
        let helper = TestTealiumHelper()
        let module = TealiumLifecycleModule(delegate: nil)
        module.diskStorage = LifecycleMockDiskStorage()
        helper.modulesReturnsMinimumProtocols(module: module) { success, failingProtocols in

            expectation.fulfill()
            XCTAssertTrue(success, "Not all protocols returned. Failing protocols: \(failingProtocols)")

        }

        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testProcessAcceptable() {
        let lifecycleModule = TealiumLifecycleModule(delegate: nil)
        // Should only accept launch calls for first events
        XCTAssertTrue(lifecycleModule.processAcceptable(type: .launch))
        XCTAssertFalse(lifecycleModule.processAcceptable(type: .sleep))
        XCTAssertFalse(lifecycleModule.processAcceptable(type: .wake))

        lifecycleModule.lastProcess = .launch
        XCTAssertFalse(lifecycleModule.processAcceptable(type: .launch))
        XCTAssertTrue(lifecycleModule.processAcceptable(type: .sleep))
        XCTAssertFalse(lifecycleModule.processAcceptable(type: .wake))

        lifecycleModule.lastProcess = .sleep
        XCTAssertFalse(lifecycleModule.processAcceptable(type: .launch))
        XCTAssertFalse(lifecycleModule.processAcceptable(type: .sleep))
        XCTAssertTrue(lifecycleModule.processAcceptable(type: .wake))

        lifecycleModule.lastProcess = .wake
        XCTAssertFalse(lifecycleModule.processAcceptable(type: .launch))
        XCTAssertTrue(lifecycleModule.processAcceptable(type: .sleep))
        XCTAssertFalse(lifecycleModule.processAcceptable(type: .wake))
    }

    func testAllAdditionalKeysPresent() {
        expectationRequest = expectation(description: "allKeysPresent")

        let lifecycleModule = TealiumLifecycleModule(delegate: self)
        lifecycleModule.enable(TealiumEnableRequest(config: helper.getConfig(), enableCompletion: nil), diskStorage: LifecycleMockDiskStorage())
        self.waitForExpectations(timeout: 5.0, handler: nil)

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

        XCTAssertTrue(missingKeys.count == 0, "Unexpected keys missing:\(missingKeys)")
        
        XCTAssertTrue(missingDictKeys.count == 0, "Unexpected keys missing:\(missingDictKeys)")
    }

    func testManualLifecycleTrackingConfigSetting() {
        expectationRequest = expectation(description: "lifecycleKeysNotPresent")

        config.lifecycleAutoTrackingEnabled = false
        lifecycleModule.enable(TealiumEnableRequest(config: config, enableCompletion: nil), diskStorage: LifecycleMockDiskStorage())

        let track = TealiumTrackRequest(data: ["tealium_event": "testEvent"])
        lifecycleModule.track(track)

        if let request = requestProcess as? TealiumTrackRequest {
            returnData = request.trackDictionary
        }

        let expectedMissingKeys = ["lifecycle_type", "lifecycle_isfirstlaunch"]

        let missingKeys = TestTealiumHelper.missingKeys(fromDictionary: returnData, keys: expectedMissingKeys)

        XCTAssertTrue(missingKeys.count == 2, "Unexpected keys missing:\(missingKeys)")

        self.waitForExpectations(timeout: 10.0, handler: nil)

    }

    func testManualLaunchMethodCall() {
        expectationRequest = expectation(description: "manualLaunchProducesExpectedData")

        config.lifecycleAutoTrackingEnabled = false
        lifecycleModule.enable(TealiumEnableRequest(config: config, enableCompletion: nil), diskStorage: LifecycleMockDiskStorage())

        lifecycleModule.launch(at: Date())

        if let request = requestProcess as? TealiumTrackRequest {
            returnData = request.trackDictionary
        }

        let expectedKeys = ["lifecycle_type", "lifecycle_isfirstlaunch"]

        let expectedValues = ["launch", "true"]

        let missingKeys = TestTealiumHelper.missingKeys(fromDictionary: returnData, keys: expectedKeys)

        XCTAssertTrue(missingKeys.count == 0, "Unexpected keys missing:\(missingKeys)")

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
        lifecycleModule.enable(TealiumEnableRequest(config: config, enableCompletion: nil), diskStorage: LifecycleMockDiskStorage())

        lifecycleModule.launch(at: Date())
        lifecycleModule.sleep()

        if let request = requestProcess as? TealiumTrackRequest {
            returnData = request.trackDictionary
        }

        let expectedKeys = ["lifecycle_type", "lifecycle_sleepcount"]

        let expectedValues = ["sleep", "1"]

        let missingKeys = TestTealiumHelper.missingKeys(fromDictionary: returnData, keys: expectedKeys)

        XCTAssertTrue(missingKeys.count == 0, "Unexpected keys missing:\(missingKeys)")

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
        lifecycleModule.enable(TealiumEnableRequest(config: config, enableCompletion: nil), diskStorage: LifecycleMockDiskStorage())

        lifecycleModule.launch(at: Date())
        lifecycleModule.sleep()
        lifecycleModule.wake()

        if let request = requestProcess as? TealiumTrackRequest {
            returnData = request.trackDictionary
        }

        let expectedKeys = ["lifecycle_type", "lifecycle_wakecount"]

        let expectedValues = ["wake", "2"]

        let missingKeys = TestTealiumHelper.missingKeys(fromDictionary: returnData, keys: expectedKeys)

        XCTAssertTrue(missingKeys.count == 0, "Unexpected keys missing:\(missingKeys)")

        _ = expectedKeys.enumerated().map {
            if let value = returnData[$1] as? String {
                XCTAssertEqual(value, expectedValues[$0])
            }
        }

        self.waitForExpectations(timeout: 8.0, handler: nil)
    }
    
    func testAutotrackedTrue() {
        autotrackedRequest = expectation(description: "testAutotrackedTrue")

        lifecycleModule.enable(TealiumEnableRequest(config: config, enableCompletion: nil), diskStorage: LifecycleMockDiskStorage())
        Tealium.lifecycleListeners.addDelegate(delegate: self)
            
        lifecycleModule.processDetected(type: .launch)
        
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
    
    func testAutotrackedNil() {
        autotrackedRequest = expectation(description: "testAutotrackedNil")

        lifecycleModule.enable(TealiumEnableRequest(config: config, enableCompletion: nil), diskStorage: LifecycleMockDiskStorage())
        Tealium.lifecycleListeners.addDelegate(delegate: self)
            
        let track = TealiumTrackRequest(data: ["hello": "world"])
        
        lifecycleModule.track(track)
        
        if let request = requestProcess as? TealiumTrackRequest {
            returnData = request.trackDictionary
        }
        
        guard let _ = returnData["autotracked"] as? Bool else {
            autotrackedRequest?.fulfill()
            XCTAssert(true)
            self.waitForExpectations(timeout: 8.0, handler: nil)
            return
        }
        
        XCTFail("`autotracked` should be nil")
    }
    
    func testAutotrackedFalse() {
        autotrackedRequest = expectation(description: "testAutotrackedFalse")

        config.lifecycleAutoTrackingEnabled = false
        lifecycleModule.enable(TealiumEnableRequest(config: config, enableCompletion: nil), diskStorage: LifecycleMockDiskStorage())
        
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

extension TealiumLifecycleModuleTests: TealiumModuleDelegate {

    func tealiumModuleFinished(module: TealiumModule, process: TealiumRequest) {
        // Lifecycle listening for all modules to finish enabling, since we're testing, mock all modules ready.
        if process as? TealiumEnableRequest != nil {
            module.handleReport(testEnableRequest)
            return
        }

        if let process = process as? TealiumTrackRequest {
            expectationRequest?.fulfill()
            requestProcess = process
        }

    }

    func tealiumModuleRequests(module: TealiumModule?, process: TealiumRequest) {
        if let process = process as? TealiumTrackRequest {
            expectationRequest?.fulfill()
            if sleepExpectation?.description == "manualSleepProducesExpectedData" && (process.trackDictionary["lifecycle_type"] as! String) == "sleep" {
                sleepExpectation?.fulfill()
            }
            if wakeExpectation?.description == "manualWakeProducesExpectedData" && (process.trackDictionary["lifecycle_type"] as! String) == "wake" {
                wakeExpectation?.fulfill()
            }
            if autotrackedRequest?.description == "testAutotrackedTrue" ||
                autotrackedRequest?.description == "testAutotrackedFalse" {
                autotrackedRequest?.fulfill()
            }
            requestProcess = process
        }
    }

}

extension TealiumLifecycleModuleTests: TealiumLifecycleEvents {
    
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
