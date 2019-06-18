//
//  TealiumModulesTest.swift
//  tealium-swift
//
//  Created by Jason Koo on 6/8/17.
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import Tealium

class TealiumModulesTest: XCTestCase {

    let numberOfCurrentModules = TestTealiumHelper.allTealiumModuleNames().count

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testNilModulesList() {
        // If nil assigned will return defaults
        let modules = TealiumModules.initializeModulesFor(nil, assigningDelegate: self)

        XCTAssert(modules.count == numberOfCurrentModules, "Count detected: \(modules.count)\nExpected:\(numberOfCurrentModules)")
    }

    func testBlacklistSingleModule() {
        let modulesList = TealiumModulesList(isWhitelist: false,
                                             moduleNames: ["LoGGer"])

        let config = TealiumConfig(account: "test",
                                   profile: "test",
                                   environment: "dev")

        config.setModulesList(modulesList)

        let modules = TealiumModules.initializeModulesFor(config.getModulesList(),
                                                          assigningDelegate: self)

        XCTAssert(modules.count == (numberOfCurrentModules - modulesList.moduleNames.count), "Modules contains incorrect number: \(modules)")

        for module in modules {
            XCTAssert(!(module is TealiumLoggerModule), "Logger module was found when shouldn't have been present.")
        }
    }

    func testBlacklistMultipleModules() {
        let modulesList = TealiumModulesList(isWhitelist: false,
                                             moduleNames: ["appdata", "LoGGer"])

        let config = TealiumConfig(account: "test",
                                   profile: "test",
                                   environment: "dev")

        config.setModulesList(modulesList)

        let modules = TealiumModules.initializeModulesFor(config.getModulesList(),
                                                          assigningDelegate: self)

        XCTAssert(modules.count == (numberOfCurrentModules - modulesList.moduleNames.count), "Modules contains incorrect number: \(modules)")

        for module in modules {
            if module is TealiumLoggerModule {
                XCTFail("Logger module was found when shouldn't have been present.")
            }
            if module is TealiumAppDataModule {
                XCTFail("AppData module was found when shouldn't have been present.")
            }
        }

    }

    func testEnableSingleModuleFromWhitelistConfig() {
        let config = TealiumConfig(account: "tealiummobile",
                                   profile: "demo",
                                   environment: "dev",
                                   optionalData: nil)

        let modulesList = TealiumModulesList(isWhitelist: true,
                                             moduleNames: ["Logger"])

        config.setModulesList(modulesList)

        let modules = TealiumModules.initializeModulesFor(config.getModulesList(),
                                                          assigningDelegate: self)

        XCTAssert(modules.count == modulesList.moduleNames.count, "Modules contains too many elements: \(modules)")

        let module = modules[0]

        if module is TealiumLoggerModule {
            // How in the world do we do a 'is not' in Swift?
        } else {
            XCTFail("Incorrect module loaded: \(module)")
            return
        }
    }

    func testEnableFromConfigWithWhitelistNoModulesListed() {
        // Should auto load - currently 15 modules
        let config = TealiumConfig(account: "tealiummobile",
                                   profile: "demo",
                                   environment: "dev",
                                   optionalData: nil)

        let list = config.getModulesList()

        let modules = TealiumModules.initializeModulesFor(list,
                                                          assigningDelegate: self)

        XCTAssert(modules.count == numberOfCurrentModules, "Modules contains incorrect number of modules: \(modules)")
    }

    func testEnableFromConfigWithWhitelistMultipleModulesListed() {
        let config = TealiumConfig(account: "tealiummobile",
                                   profile: "demo",
                                   environment: "dev",
                                   optionalData: nil)

        let modulesList = TealiumModulesList(isWhitelist: true,
                                             moduleNames: ["Logger", "lifecycle", "persistentData"])

        config.setModulesList(modulesList)

        let modules = TealiumModules.initializeModulesFor(config.getModulesList(),
                                                          assigningDelegate: self)

        XCTAssert(modules.count == modulesList.moduleNames.count, "Modules contains too many elements: \(modules)")
    }

    func testDisableOneModuleWithBlacklistAfterExitingConfigAlreadyActived() {
        // Initial setup
        let initialConfig = TealiumConfig(account: "tealiummobile",
                                          profile: "demo",
                                          environment: "dev",
                                          optionalData: nil)

        let modulesList = TealiumModulesList(isWhitelist: false,
                                             moduleNames: Set<String>())

        initialConfig.setModulesList(modulesList)

        let modulesManager = TealiumModulesManager()
        modulesManager.setupModulesFrom(config: initialConfig)
        modulesManager.enable(config: initialConfig, enableCompletion: nil)

        XCTAssert(modulesManager.modules.count == (numberOfCurrentModules - modulesList.moduleNames.count), "Incorrect number of enabled modules: \(modulesManager.modules)")

        // Updated setup
        let newModulesList = TealiumModulesList(isWhitelist: false,
                                                moduleNames: ["appdata"])

        let newConfig = TealiumConfig(account: "test",
                                      profile: "test",
                                      environment: "test")

        newConfig.setModulesList(newModulesList)

        modulesManager.update(config: newConfig)

        XCTAssert(modulesManager.modules.count == (numberOfCurrentModules - newModulesList.moduleNames.count), "Incorrect number of enabled modules: \(modulesManager.modules)")

        for module in modulesManager.modules where module is TealiumAppDataModule {
            XCTFail("Failed to disable the appData module.")
        }
    }

    func testEnableFewerModulesAfterExitingConfigAlreadyActived() {
        // Initial setup
        let initialConfig = TealiumConfig(account: "tealiummobile",
                                          profile: "demo",
                                          environment: "dev",
                                          optionalData: nil)

        let modulesList = TealiumModulesList(isWhitelist: true,
                                             moduleNames: ["Logger", "lifecycle", "persistentData"])

        initialConfig.setModulesList(modulesList)

        let modulesManager = TealiumModulesManager()
        modulesManager.setupModulesFrom(config: initialConfig)

        XCTAssert(modulesManager.modules.count == modulesList.moduleNames.count, "Incorrect number of enabled modules: \(modulesManager.modules)")

        // Updated setup
        let newModulesList = TealiumModulesList(isWhitelist: true,
                                                moduleNames: ["appdata"])

        let newConfig = TealiumConfig(account: "test",
                                      profile: "test",
                                      environment: "test")

        newConfig.setModulesList(newModulesList)

        modulesManager.update(config: newConfig)

        XCTAssert(modulesManager.modules.count == newModulesList.moduleNames.count, "Incorrect number of enabled modules: \(modulesManager.modules)")
    }

    func testEnableMoreModulesAfterExitingConfigAlreadyActived() {
        // Initial setup
        let initialConfig = TealiumConfig(account: "tealiummobile",
                                          profile: "demo",
                                          environment: "dev",
                                          optionalData: nil)

        let modulesList = TealiumModulesList(isWhitelist: true,
                                             moduleNames: ["Logger"])

        initialConfig.setModulesList(modulesList)

        let modulesManager = TealiumModulesManager()
        modulesManager.setupModulesFrom(config: initialConfig)

        XCTAssert(modulesManager.modules.count == modulesList.moduleNames.count, "Incorrect number of enabled modules: \(modulesManager.modules)")

        // Updated setup
        let newModulesList = TealiumModulesList(isWhitelist: true,
                                                moduleNames: ["appdata", "devicedata", "lifecycle"])

        let newConfig = TealiumConfig(account: "test",
                                      profile: "test",
                                      environment: "test")

        newConfig.setModulesList(newModulesList)

        modulesManager.update(config: newConfig)

        XCTAssert(modulesManager.modules.count == newModulesList.moduleNames.count, "Incorrect number of enabled modules: \(modulesManager.modules)")
    }

    func testEnableCompletelyDifferentModulesAfterExitingConfigAlreadyActived() {
        // Initial setup
        let initialConfig = TealiumConfig(account: "tealiummobile",
                                          profile: "demo",
                                          environment: "dev",
                                          optionalData: nil)

        let modulesList = TealiumModulesList(isWhitelist: true,
                                             moduleNames: ["delegate", "persistentData"])

        initialConfig.setModulesList(modulesList)

        let modulesManager = TealiumModulesManager()
        modulesManager.setupModulesFrom(config: initialConfig)

        XCTAssert(modulesManager.modules.count == modulesList.moduleNames.count, "Incorrect number of enabled modules: \(modulesManager.modules)")

        // Updated setup
        let newModulesList = TealiumModulesList(isWhitelist: true,
                                                moduleNames: ["appdata", "volatileData"])

        let newConfig = TealiumConfig(account: "test",
                                      profile: "test",
                                      environment: "test")

        newConfig.setModulesList(newModulesList)

        modulesManager.update(config: newConfig)

        XCTAssert(modulesManager.modules.count == modulesList.moduleNames.count, "Incorrect number of enabled modules: \(modulesManager.modules)")

        for module in modulesManager.modules {
            if module is TealiumDelegateModule {
                XCTFail("Logger module was found when shouldn't have been present.")
            }
            if module is TealiumPersistentDataModule {
                XCTFail("AppData module was found when shouldn't have been present.")
            }

        }
    }

}

extension TealiumModulesTest: TealiumModuleDelegate {

    func tealiumModuleFinished(module: TealiumModule, process: TealiumRequest) {

    }

    func tealiumModuleRequests(module: TealiumModule?, process: TealiumRequest) {

    }

    func tealiumModuleFinishedReport(fromModule: TealiumModule, module: TealiumModule, process: TealiumRequest) {

    }
}
