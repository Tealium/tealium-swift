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

    class func initializeModulesFor(_ list: TealiumModulesList?,
                                    assigningDelegate: TealiumModuleDelegate) -> [TealiumModule] {
        let modules = initializeModules(delegate: assigningDelegate)

        // Default behavior
        guard let list = list else {
            return modules
        }

        // Whitelisting
        if list.isWhitelist == true {
            let whitelist = list.moduleNames.map { $0.lowercased() }
            let result = modules.filter { whitelist.contains(type(of: $0).moduleConfig().name.lowercased()) == true }

            return result
        }

        // Blacklisting
        let blacklist = list.moduleNames.map { $0.lowercased() }
        let result = modules.filter { blacklist.contains(type(of: $0).moduleConfig().name.lowercased()) == false }

        return result
    }

    class func initializeModules(delegate: TealiumModuleDelegate) -> [TealiumModule] {
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

            let module = type.init(delegate: delegate)

            modules.insert(module)
        }

        return Array(modules)
    }

    // 1.3.3: Changed to explicitly specify modules and avoid iterating through all classes in the app
    // swiftlint:disable function_body_length
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
            "TealiumDatasourceModule",
            "TealiumDataSource.TealiumDatasourceModule",
            "TealiumDefaultsStorageModule",
            "TealiumDefaultsStorage.TealiumDefaultsStorageModule",
            "TealiumDelegateModule",
            "TealiumDelegate.TealiumDelegateModule",
            "TealiumDeviceDataModule",
            "TealiumDeviceData.TealiumDeviceDataModule",
            "TealiumFileStorageModule",
            "TealiumFileStorage.TealiumFileStorageModule",
            "TealiumLifecycleModule",
            "TealiumLifecycle.TealiumLifecycleModule",
            "TealiumLoggerModule",
            "TealiumLogger.TealiumLoggerModule",
            "TealiumPersistentDataModule",
            // bundled with file storage/defaults storage
            "TealiumFileStorage.TealiumPersistentDataModule",
            "TealiumDefaultsStorage.TealiumPersistentDataModule",
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
            "TealiumDatasourceModule",
            "TealiumDataSource.TealiumDatasourceModule",
            "TealiumDefaultsStorageModule",
            "TealiumDefaultsStorage.TealiumDefaultsStorageModule",
            "TealiumDelegateModule",
            "TealiumDelegate.TealiumDelegateModule",
            "TealiumDeviceDataModule",
            "TealiumDeviceData.TealiumDeviceDataModule",
            "TealiumFileStorageModule",
            "TealiumFileStorage.TealiumFileStorageModule",
            "TealiumLifecycleModule",
            "TealiumLifecycle.TealiumLifecycleModule",
            "TealiumLoggerModule",
            "TealiumLogger.TealiumLoggerModule",
            "TealiumPersistentDataModule",
            // bundled with file storage/defaults storage
            "TealiumFileStorage.TealiumPersistentDataModule",
            "TealiumDefaultsStorage.TealiumPersistentDataModule",
            "TealiumVolatileDataModule",
            "TealiumVolatileData.TealiumVolatileDataModule",
            "TealiumConsentManagerModule",
            "TealiumConsentManager.TealiumConsentManagerModule",
            "TealiumDispatchQueueModule",
            "TealiumDispatchQueue.TealiumDispatchQueueModule",
        ]
        #endif
        // swiftlint:enable function_body_length
        var tealiumClassReferences = [AnyClass]()
        let thisClass = String(reflecting: self)
        let moduleNamePrefix = thisClass.replacingOccurrences(of: "TealiumModules", with: "")

        for className in tealiumClasses {
            var fullName: String

            if className.contains(".") {
                fullName = className
            } else {
                fullName = moduleNamePrefix + className
            }

            let cls = objc_getClass(fullName)

            if cls != nil {
                if let clz = cls as? AnyClass {
                    tealiumClassReferences.append(clz)
                }
            }
        }

        return tealiumClassReferences
    }
}
