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

    var crashModuleReference: AnyClass?

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
            "TealiumAppDataModule",
            "TealiumAttributionModule",
            "TealiumCollectModule",
            "TealiumConnectivityModule",
            "TealiumCrashModule",               // for Cocoapods
            "TealiumCrash.TealiumCrashModule",  // note: need to duplicate for Carthage
            "TealiumDatasourceModule",
            "TealiumDefaultsStorageModule",
            "TealiumDelegateModule",
            "TealiumDeviceDataModule",
            "TealiumFileStorageModule",
            "TealiumLifecycleModule",
            "TealiumLoggerModule",
            "TealiumPersistentDataModule",
            "TealiumRemoteCommandsModule",
            "TealiumTagManagementModule",
            "TealiumVolatileDataModule",
            "TealiumConsentManagerModule",
            "TealiumDispatchQueueModule"
        ]
        #else
        let tealiumClasses = [
            "TealiumAutotrackingModule",
            "TealiumAppDataModule",
            "TealiumAttributionModule",
            "TealiumCollectModule",
            "TealiumConnectivityModule",
            "TealiumDatasourceModule",
            "TealiumDefaultsStorageModule",
            "TealiumDelegateModule",
            "TealiumDeviceDataModule",
            "TealiumFileStorageModule",
            "TealiumLifecycleModule",
            "TealiumLoggerModule",
            "TealiumPersistentDataModule",
            "TealiumRemoteCommandsModule",
            "TealiumTagManagementModule",
            "TealiumVolatileDataModule",
            "TealiumConsentManagerModule",
            "TealiumDispatchQueueModule"
        ]
        #endif
        // swiftlint:enable function_body_length
        // swiftlint:disable syntactic_sugar
        var tealiumClassReferences: Array<AnyClass> = []
        // swiftlint:enable syntactic_sugar
        let thisClass = String(reflecting: self)
        let moduleNamePrefix = thisClass.replacingOccurrences(of: "TealiumModules", with: "")

        for className in tealiumClasses {
            var fullName: String

            if className == "TealiumCrash.TealiumCrashModule" {
                fullName = "TealiumCrash.TealiumCrashModule"
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
