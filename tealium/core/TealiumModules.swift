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
        let tealiumClasses = ["Tealium.TealiumAutotrackingModule",
                              "Tealium.TealiumAppDataModule",
                              "Tealium.TealiumAttributionModule",
                              "Tealium.TealiumCollectModule",
                              "Tealium.TealiumConnectivityModule",
                              "TealiumCrash.TealiumCrashModule",
                              "Tealium.TealiumDatasourceModule",
                              "Tealium.TealiumDefaultsStorageModule",
                              "Tealium.TealiumDelegateModule",
                              "Tealium.TealiumDeviceDataModule",
                              "Tealium.TealiumFileStorageModule",
                              "Tealium.TealiumLifecycleModule",
                              "Tealium.TealiumLoggerModule",
                              "Tealium.TealiumPersistentDataModule",
                              "Tealium.TealiumRemoteCommandsModule",
                              "Tealium.TealiumTagManagementModule",
                              "Tealium.TealiumVolatileDataModule"]
        #else
        let tealiumClasses = ["Tealium.TealiumAutotrackingModule",
                              "Tealium.TealiumAppDataModule",
                              "Tealium.TealiumAttributionModule",
                              "Tealium.TealiumCollectModule",
                              "Tealium.TealiumConnectivityModule",
                              "Tealium.TealiumDatasourceModule",
                              "Tealium.TealiumDefaultsStorageModule",
                              "Tealium.TealiumDelegateModule",
                              "Tealium.TealiumDeviceDataModule",
                              "Tealium.TealiumFileStorageModule",
                              "Tealium.TealiumLifecycleModule",
                              "Tealium.TealiumLoggerModule",
                              "Tealium.TealiumPersistentDataModule",
                              "Tealium.TealiumRemoteCommandsModule",
                              "Tealium.TealiumTagManagementModule",
                              "Tealium.TealiumVolatileDataModule"]
        #endif
        // swiftlint:enable function_body_length
        // swiftlint:disable syntactic_sugar
        var tealiumClassReferences: Array<AnyClass> = []
        // swiftlint:enable syntactic_sugar

        for className in tealiumClasses {
            let cls = objc_getClass(className)

            if cls != nil {
                if let clazz = cls as? AnyClass {
                    tealiumClassReferences.append(clazz)
                }
            }
        }

        return tealiumClassReferences
    }
}
