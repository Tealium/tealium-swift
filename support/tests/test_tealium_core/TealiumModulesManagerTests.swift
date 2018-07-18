//
//  TealiumModulesManagerTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 10/11/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import Tealium

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

    func testInitPerformance() {
        let iterations = 100

        self.measure {

            for _ in 0..<iterations {

                let modulesManager = TealiumModulesManager()
                modulesManager.enable(config: defaultTealiumConfig)
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
        manager.enable(config: config)

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

        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

    // NOTE: This integration test will fail if no dispatch services enabled

    // TODO:
//    func testPublicTrackWithDefaultModules() {
//
//        let enableExpectation = self.expectation(description: "testEnable")
//
//        modulesManager = TealiumModulesManager()
//        modulesManager?.enable(config: testTealiumConfig) { [weak self] (responses) in
//        
//            enableExpectation.fulfill()
//            guard let modulesManager = self?.modulesManager else {
//                XCTFail("Modules manager deallocated before test completed.")
//                return
//            }
//            
//            XCTAssert(modulesManager.allModulesReady(),"All modules not ready: \(self?.modulesManager?.modules)")
//        }
//        
//        self.wait(for: [enableExpectation], timeout: 1.0)
//
//        let trackExpectation = self.expectation(description: "testPublicTrack")
//        let testTrack = TealiumTrackRequest(data: [:],
//                                            info: nil,
//                                            completion: {(success, info, error) in
//                        
//                if error != nil {
//                    XCTFail("Track error detected:\(String(describing: error))")
//                }
//                                        
//                trackExpectation.fulfill()
//
//        })
//        
//        modulesManager?.track(testTrack)
//        
//        // Only testing that the completion handler is called.
//        self.wait(for: [trackExpectation], timeout: 1.0)
//        
//    }

    func testPublicTrackWithFullBlackList() {
        let config = TealiumConfig(account: "test",
                                   profile: "test",
                                   environment: "test")
        let list = TealiumModulesList(isWhitelist: false,
                                      moduleNames: Set(TestTealiumHelper.allTealiumModuleNames()))
        config.setModulesList(list)

        let manager = TealiumModulesManager()
        manager.enable(config: config)

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

        self.waitForExpectations(timeout: 3.0, handler: nil)
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

//    func testDisableAll() {
//        
//        // initial state
//        let config = TealiumConfig(account: "test",
//                                   profile: "test",
//                                   environment: "test")
//        modulesManager = TealiumModulesManager()
//        modulesManager?.setupModulesFrom(config: config)
//
//        guard let manager = modulesManager else {
//            XCTFail("Unexpected error.")
//            return
//        }
//        manager.modules = TealiumModules.allModules(delegate: self).prioritized() // Route protocol handing to test class
//        manager.enable(config: config) { (responses) in
//            
//            // TODO:
//        }
//        
//        // test initial state
//        XCTAssert(manager.modules.count == numberOfCurrentModules, "Unexpected number of modules enabled: \(manager.modules)")
//        XCTAssert(manager.modules.first?.isEnabled == true, "First module unexpectedly disabled: \(String(describing: manager.modules.first))")
//        
//        // disable
//        let expectation = self.expectation(description: "disableAll")
//        var request = TealiumDisableRequest()
//        request.completion = ({(success, info, error) in
//        
//            expectation.fulfill()
//            
//        })
//        manager.disableAll(request)
//        self.waitForExpectations(timeout: 5.0, handler: nil)
//
//        // test disable state
//        let enabledModules = manager.modules.filter{ $0.isEnabled == true }
//        XCTAssert(enabledModules.count == 0, "Some modules still enabled: \(enabledModules)")
//        XCTAssert(modulesManager?.allModulesReady() == false, "Unexpected modules state: \(modulesManager!.modules)")
//
//    }

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
        modulesManager.enable(config: testTealiumConfig)
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

    // TODO: Lib currently designed to resubmit track request until all modules are ready

//    func testTrackWhenAModuleDisabled() {
//        
//        // Enable Setup
//        let setupExpectation = self.expectation(description: "enable")
//        let config = TealiumConfig(account: "test",
//                                   profile: "test",
//                                   environment: "test")
//        let modulesList = TealiumModulesList(isWhitelist: true,
//                                             moduleNames: ["logger"])
//        config.setModulesList(modulesList)
//        let modulesManager = TealiumModulesManager()
//        modulesManager.enable(config: config) { (responses) in
//            
//            setupExpectation.fulfill()
//            
//        }
//        self.wait(for: [setupExpectation],
//                  timeout: 1.0)
//        
//        // Track setup
//        modulesManager.getModule(forName: "logger")?.isEnabled = false
//        let trackExpectation = self.expectation(description: "track")
//        let track = TealiumTrackRequest(data: [:]) { (success, info, error) in
//            
//            XCTAssert(success == false, "Track succeeded unexpectedly.")
//            trackExpectation.fulfill()
//            
//        }
//        modulesManager.track(track)
//        self.wait(for: [trackExpectation],
//                  timeout: 1.0)
//        
//    }

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

    // TODO:
//    func testUpdate() {
//        
//        // Initial Setup
//        let setupExpectation = self.expectation(description: "enable")
//        let config = TealiumConfig(account: "test",
//                                   profile: "test",
//                                   environment: "test")
//        let modulesList = TealiumModulesList(isWhitelist: true,
//                                             moduleNames: ["logger"])
//        var modulesEnabled : [TealiumModuleResponse]?
//        config.setModulesList(modulesList)
//        let modulesManager = TealiumModulesManager()
//        
//        modulesManager.enable(config: config)
//        
//        self.wait(for: [setupExpectation],
//                  timeout: 1.0)
//        
//        // CHECK the initial setup to compare later with
//        let firstModule = modulesEnabled?[0].moduleName
//        XCTAssert(modulesEnabled!.count == 1, "Unexpected number of modules enabled: \(String(describing: modulesEnabled!.count))")
//        XCTAssert(firstModule == "logger", "Unexpected module enabled: \(String(describing: firstModule))")
//        
//        // Duplicate config setup
//        let duplicateExpectation = self.expectation(description: "duplicate")
//        let duplicateConfig = TealiumConfig(account: "test",
//                                            profile: "test",
//                                            environment: "test")
//        duplicateConfig.setModulesList(modulesList)
//        modulesManager.update(config: duplicateConfig) { (responses) in
//            
//            XCTAssert(responses.count == 0, "Unexpected responses returned: \(responses)")
//            duplicateExpectation.fulfill()
//        }
//        
//        // CHECK that a duplicate config does nothing
//        self.wait(for: [duplicateExpectation],
//                  timeout: 1.0)
//        XCTAssert(modulesEnabled!.count == 1, "Unexpected number of modules enabled: \(String(describing: modulesEnabled!.count))")
//        XCTAssert(firstModule == "logger", "Unexpected module enabled: \(String(describing: firstModule))")
//        
//        // Update
//        let newConfig = TealiumConfig(account: "a",
//                                      profile: "b",
//                                      environment: "c")
//        let newModulesList = TealiumModulesList(isWhitelist: true,
//                                                moduleNames: ["delegate",
//                                                              "queue"])
//        newConfig.setModulesList(newModulesList)
//        let updateExpectation = self.expectation(description: "update")
//        modulesManager.update(config: newConfig,
//                              completion: { (responses) in
//            modulesEnabled = responses
//            updateExpectation.fulfill()
//        })
//        
//        // CHECK that the update took
//        self.wait(for: [updateExpectation],
//                  timeout: 1.0)
//        let newFirstModule = modulesEnabled?[0].moduleName
//        XCTAssert(modulesEnabled?.count == 2, "Unexpected number of modules enabled: \(String(describing: modulesEnabled))")
//        XCTAssert(newFirstModule == "delegate", "Unexpected module enabled: \(String(describing: newFirstModule))")
//        
//    }

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
