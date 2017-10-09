//
//  TealiumModules.swift
//  tealium-swift
//
//  Created by Jason Koo on 6/8/17.
//  Copyright © 2017 tealium. All rights reserved.
//
//  Build 2

import Foundation
import ObjectiveC

enum TealiumModulesListKey {
    static let config = "com.tealium.core.moduleslist"
}

extension TealiumConfig {


    /// Get the existing modules list assigned to this config object.
    ///
    /// - Returns: TealiumModulesList as an optional.
    public func getModulesList() -> TealiumModulesList? {

        guard let list = self.optionalData[TealiumModulesListKey.config] as? TealiumModulesList else {
            return nil
        }

        return list

    }


    /// Set a net modules list to this config object.
    ///
    /// - Parameter list: The TealiumModulesList to assign.
    public func setModulesList(_ list: TealiumModulesList ) {

        self.optionalData[TealiumModulesListKey.config] = list

    }

}

class TealiumModules {

    class func allModulesFor(_ list: TealiumModulesList?,
                             assigningDelegate: TealiumModuleDelegate) -> [TealiumModule] {

        let modules = allModules(delegate: assigningDelegate)

        // Default behavior
        guard let list = list else {
            return modules
        }

        // Whitelisting
        if list.isWhitelist == true {
            let whitelist = list.moduleNames.map{ $0.lowercased() }
            let result = modules.filter{ whitelist.contains(type(of:$0).moduleConfig().name.lowercased()) == true }
            return result
        }

        // Blacklisting
        let blacklist  = list.moduleNames.map { $0.lowercased() }
        let result = modules.filter{ blacklist.contains(type(of:$0).moduleConfig().name.lowercased()) == false }
        return result

    }

    class func allModules(delegate: TealiumModuleDelegate) -> [TealiumModule] {

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
    class func getTealiumClasses () -> [AnyClass] {
        let tealiumClasses = ["TealiumAutotrackingModule",
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
                              "TealiumVolatileDataModule"]
        var tealiumClassReferences: Array<AnyClass> = []
        let thisClass = String(reflecting: self)
        let moduleNamePrefix = thisClass.replacingOccurrences(of: "TealiumModules", with: "")
        
        for className in tealiumClasses {
            let fullName = moduleNamePrefix + className
            let cls = objc_getClass(fullName)
            if cls != nil {
                tealiumClassReferences.append(cls as! AnyClass)
            }
        }
        
        return tealiumClassReferences
    }

}
