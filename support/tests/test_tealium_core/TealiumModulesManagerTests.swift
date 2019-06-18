//
//  TealiumModulesManagerTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 10/11/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import Tealium
#if os(iOS)
@testable import TealiumCrashReporteriOS
#endif
let defaultTealiumConfig = TealiumConfig(account: "tealiummobile",
                                         profile: "demo",
                                         environment: "dev",
                                         optionalData: nil)

class TealiumTestModule: TealiumModule {

    override func enable(_ request: TealiumEnableRequest) {
        super.enable(request)
    }
}

class TealiumModulesManagerTests: XCTestCase {

    let numberOfCurrentModules = 16
    var modulesManager: TealiumModulesManager?

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        modulesManager = nil
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    // Note: Set baseline of 0.5s in Xcode before running this test
    func testInitPerformance() {
        let iterations = 100

        self.measure {

            for _ in 0..<iterations {

                let modulesManager = TealiumModulesManager()
                modulesManager.enable(config: defaultTealiumConfig, enableCompletion: nil)
            }
        }
    }

    func testPublicTrackWithEmptyWhitelist() {
        let config = TealiumConfig(account: "test",
                                   profile: "test",
                                   environment: "test")
        let list = TealiumModulesList(isWhitelist: true,
                                      moduleNames: Set<String>())
        config.setModulesList(list)

        let manager = TealiumModulesManager()
        manager.enable(config: config, enableCompletion: nil)

        let expectation = self.expectation(description: "testPublicTrack")

        let testTrack = TealiumTrackRequest(data: [:],
                                            completion: { success, _, error in
                guard let error = error else {
                    XCTFail("Error should have returned")
                    return
                }

                XCTAssertFalse(success, "Track did not fail as expected. Error: \(error)")

                expectation.fulfill()
        })

        manager.track(testTrack)

        self.waitForExpectations(timeout: 5.0, handler: nil)
    }

    // NOTE: This integration test will fail if no dispatch services enabled
    func testPublicTrackWithDefaultModules() {

        let enableExpectation = self.expectation(description: "testEnable")

        modulesManager = TealiumModulesManager()
        testTealiumConfig.setInitialUserConsentStatus(.consented)
        // tag management cannot work properly in tests due to UIKit dependency
        let list = TealiumModulesList(isWhitelist: false, moduleNames: ["tagmanagement"])
        testTealiumConfig.setModulesList(list)
        // Tealium must be initialized in order for callback to work
        _ = Tealium(config: testTealiumConfig)
        sleep(2)
        modulesManager?.enable(config: testTealiumConfig) { _ in

            enableExpectation.fulfill()
            guard let modulesManager = self.modulesManager else {
                XCTFail("Modules manager deallocated before test completed.")
                return
            }

            XCTAssert(modulesManager.allModulesReady(), "All modules not ready: \(String(describing: self.modulesManager?.modules))")
        }

        self.wait(for: [enableExpectation], timeout: 5.0)

        let trackExpectation = self.expectation(description: "testPublicTrack")
        let testTrack = TealiumTrackRequest(data: [:],
                                            completion: { _, _, error in

                if let error = error {
                    switch error {
                    case TealiumCollectError.xErrorDetected:
                        XCTAssertTrue(true, "Error is expected due to invalid account/profile")
                    default:
                        XCTFail("Track error detected:\(String(describing: error))")
                    }
                }

                trackExpectation.fulfill()

        })

        modulesManager?.track(testTrack)

        // Only testing that the completion handler is called.
        self.wait(for: [trackExpectation], timeout: 15.0)

    }

    func testPublicTrackWithFullBlackList() {
        let config = TealiumConfig(account: "test",
                                   profile: "test",
                                   environment: "test")
        let list = TealiumModulesList(isWhitelist: false,
                                      moduleNames: Set(TestTealiumHelper.allTealiumModuleNames()))
        config.setModulesList(list)

        let manager = TealiumModulesManager()
        manager.enable(config: config, enableCompletion: nil)

        XCTAssert(manager.modules.count == 0, "Unexpected number of modules initialized: \(manager.modules)")

        let expectation = self.expectation(description: "testPublicTrackOneModule")

        let testTrack = TealiumTrackRequest(data: [:],
                                            completion: { success, _, error in

                guard let error = error else {
                    XCTFail("Error should have returned")
                    return
                }

                XCTAssertFalse(success, "Track did not fail as expected. Error: \(error)")

                expectation.fulfill()

        })

        manager.track(testTrack)

        self.waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testStringToBool() {
        // Not entirely necessary as long as we're using NSString.boolValue
        // ...but just in case it gets swapped out

        let stringTrue = "true"
        let stringYes = "yes"
        let stringFalse = "false"
        let stringFALSE = "FALSE"
        let stringNo = "no"
        let stringOtherTrue = "35a"
        let stringOtherFalse = "xyz"

        XCTAssertTrue(stringTrue.boolValue)
        XCTAssertTrue(stringYes.boolValue)
        XCTAssertFalse(stringFalse.boolValue)
        XCTAssertFalse(stringFALSE.boolValue)
        XCTAssertFalse(stringNo.boolValue)
        XCTAssertTrue(stringOtherTrue.boolValue, "String other converted to \(stringOtherTrue.boolValue)")
        XCTAssertFalse(stringOtherFalse.boolValue, "String other converted to \(stringOtherFalse.boolValue)")
    }

    func testGetModuleForName() {
        let config = TealiumConfig(account: "test",
                                   profile: "test",
                                   environment: "test")

        let manager = TealiumModulesManager()
        manager.setupModulesFrom(config: config)

        let module = manager.getModule(forName: "logger")

        XCTAssert((module is TealiumLoggerModule), "Incorrect module received: \(String(describing: module))")
    }

    func testTrackWhenDisabled() {
        let modulesManager = TealiumModulesManager()
        modulesManager.enable(config: testTealiumConfig, enableCompletion: nil)
        modulesManager.disable()
        let trackExpectation = self.expectation(description: "track")

        let track = TealiumTrackRequest(data: [:]) { success, _, _ in

            XCTAssert(success == false, "Track succeeded unexpectedly.")
            trackExpectation.fulfill()

        }

        modulesManager.track(track)
        self.wait(for: [trackExpectation],
                  timeout: 1.0)

    }

    func testAllModulesReady() {
        // Assign
        let moduleA = TealiumModule(delegate: nil)
        moduleA.isEnabled = true
        let moduleB = TealiumModule(delegate: nil)
        moduleB.isEnabled = true
        let manager = TealiumModulesManager()
        manager.modules = [moduleA, moduleB]

        // Act
        let result = manager.allModulesReady()

        // Assert
        XCTAssert(result == true, "Unexpected result from modules: \(manager.modules)")
    }

    func testTrackAllModulesNotYetReady() {
        // Assign
        let moduleA = TealiumModule(delegate: nil)
        moduleA.isEnabled = true
        let moduleB = TealiumModule(delegate: nil)
        moduleB.isEnabled = false
        let manager = TealiumModulesManager()
        manager.modules = [moduleA, moduleB]

        // Act
        let result = manager.allModulesReady()

        // Assert
        XCTAssert(result == false, "Unexpected result from modules: \(manager.modules)")
    }

    func testTealiumModulesArray_ModuleNames() {
        let allModules = TealiumModules.initializeModules(delegate: self)

        // Alphabetically instead of by priority
        let result = allModules.moduleNames().sorted()

        let expected = TestTealiumHelper.allTealiumModuleNames().sorted()

        let missing = TestTealiumHelper.missingStrings(fromArray: expected,
                                                       anotherArray: result)

        XCTAssert(result == expected, "Mismatch in module names returned: \(missing)")
    }

}

extension TealiumModulesManagerTests: TealiumModuleDelegate {

    func tealiumModuleFinished(module: TealiumModule, process: TealiumRequest) {
        if module == modulesManager?.modules.last {
            process.completion?(true, nil, nil)
        }

        let nextModule = modulesManager?.modules.next(after: module)

        nextModule?.handle(process)
    }

    func tealiumModuleRequests(module: TealiumModule?, process: TealiumRequest) {

    }

    func tealiumModuleFinishedReport(fromModule: TealiumModule, module: TealiumModule, process: TealiumRequest) {

    }
}
