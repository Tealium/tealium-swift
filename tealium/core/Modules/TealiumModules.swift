//
//  TealiumModules.swift
//  tealium-swift
//
//  Created by Jason Koo on 6/8/17.
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//

import Foundation
import ObjectiveC

enum TealiumModulesListKey {
    static let config = "com.tealium.core.moduleslist"
}

class TealiumModules {

    var modulesList = Set<String>()

    /// Iniitializes modules from a list￼.
    ///
    /// - Parameters:
    ///     - list: `TealiumModulesList`￼
    ///     - assigningDelegate: `TealiumModuleDelegate`
    /// - Returns: `[TealiumModule]` list containing all initialized modules
    class func initializeModulesFor(_ list: TealiumModulesList?,
                                    assigningDelegate: TealiumModuleDelegate) -> [TealiumModule] {
        return initializeModules(modulesList: list,
                                        delegate: assigningDelegate)
    }

    /// Initializes each module for the current platform￼.
    ///
    /// - Parameter delegate: `TealiumModuleDelegate`
    class func initializeModules(modulesList: TealiumModulesList?,
                                 delegate: TealiumModuleDelegate) -> [TealiumModule] {
        var modules = Set<TealiumModule>()

        let newModules = getTealiumClasses()

        // Create instances of each module
        for klass in newModules {

            guard let type = klass as? TealiumModule.Type else {
                // Class not of type TealiumModule
                continue
            }

            let moduleConfig = type.moduleConfig()

            if moduleConfig.enabled == false {
                // Class module config set to disabled
                continue
            }

            var shouldInit = false
            
            if let modulesList = modulesList {
                if modulesList.isWhitelist {
                    shouldInit = modulesList.moduleNames.contains(moduleConfig.name)
                } else {
                    shouldInit = !modulesList.moduleNames.contains(moduleConfig.name)
                }
            } else {
                shouldInit = true
            }
            
            if shouldInit {
                let module = type.init(delegate: delegate)
                modules.insert(module)
            }
        }

        return Array(modules)
    }

    // swiftlint:disable function_body_length
    /// Gets all valid Tealium Module classes.
    ///
    /// - Returns: `[AnyClass]`
    class func getTealiumClasses() -> [AnyClass] {
        #if os(iOS)
        let tealiumClasses = [
            "TealiumAutotrackingModule",
            "TealiumAutotracking.TealiumAutotrackingModule",
            "TealiumAppDataModule",
            "TealiumAppData.TealiumAppDataModule",
            "TealiumAttributionModule",
            "TealiumAttribution.TealiumAttributionModule",
            "TealiumCollectModule",
            "TealiumCollect.TealiumCollectModule",
            "TealiumConnectivityModule",
            "TealiumConnectivity.TealiumConnectivityModule",
            "TealiumCrashModule",               // for Cocoapods
            "TealiumCrash.TealiumCrashModule",  // note: need to duplicate for Carthage
            "TealiumDelegateModule",
            "TealiumDelegate.TealiumDelegateModule",
            "TealiumDeviceDataModule",
            "TealiumDeviceData.TealiumDeviceDataModule",
            "TealiumLifecycleModule",
            "TealiumLifecycle.TealiumLifecycleModule",
            "TealiumLoggerModule",
            "TealiumLogger.TealiumLoggerModule",
            "TealiumPersistentData.TealiumPersistentDataModule",
            "TealiumPersistentDataModule",
            "TealiumRemoteCommandsModule",
            "TealiumRemoteCommands.TealiumRemoteCommandsModule",
            "TealiumTagManagementModule",
            "TealiumTagManagement.TealiumTagManagementModule",
            "TealiumVolatileDataModule",
            "TealiumVolatileData.TealiumVolatileDataModule",
            "TealiumConsentManagerModule",
            "TealiumConsentManager.TealiumConsentManagerModule",
            "TealiumDispatchQueueModule",
            "TealiumDispatchQueue.TealiumDispatchQueueModule",
            "TealiumVisitorServiceModule",
            "TealiumVisitorService.TealiumVisitorServiceModule",
        ]
        #else
        let tealiumClasses = [
            "TealiumAutotrackingModule",
            "TealiumAutotracking.TealiumAutotrackingModule",
            "TealiumAppDataModule",
            "TealiumAppData.TealiumAppDataModule",
            "TealiumCollectModule",
            "TealiumCollect.TealiumCollectModule",
            "TealiumConnectivityModule",
            "TealiumConnectivity.TealiumConnectivityModule",
            "TealiumDelegateModule",
            "TealiumDelegate.TealiumDelegateModule",
            "TealiumDeviceDataModule",
            "TealiumDeviceData.TealiumDeviceDataModule",
            "TealiumLifecycleModule",
            "TealiumLifecycle.TealiumLifecycleModule",
            "TealiumLoggerModule",
            "TealiumLogger.TealiumLoggerModule",
            "TealiumPersistentDataModule",
            "TealiumPersistentData.TealiumPersistentDataModule",
            "TealiumVolatileDataModule",
            "TealiumVolatileData.TealiumVolatileDataModule",
            "TealiumConsentManagerModule",
            "TealiumConsentManager.TealiumConsentManagerModule",
            "TealiumDispatchQueueModule",
            "TealiumDispatchQueue.TealiumDispatchQueueModule",
            "TealiumVisitorServiceModule",
            "TealiumVisitorService.TealiumVisitorServiceModule",
        ]
        #endif

        var tealiumClassReferences = [AnyClass]()
        let thisClass = String(reflecting: self)
        let moduleNamePrefix = thisClass.replacingOccurrences(of: "TealiumModules", with: "")

        tealiumClasses.forEach {
            let className = $0.contains(".") ? $0 : "\(moduleNamePrefix)\($0)"
            if let cls = objc_getClass(className) as? AnyClass {
                tealiumClassReferences.append(cls)
            }
        }

        return tealiumClassReferences
    }
    // swiftlint: enable function_body_length
}
