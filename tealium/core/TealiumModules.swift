//
//  TealiumModules.swift
//  tealium-swift
//
//  Created by Jason Koo on 6/8/17.
//  Copyright © 2017 tealium. All rights reserved.
//

import Foundation
import ObjectiveC

enum TealiumModulesListKey {
    static let config = "com.tealium.core.moduleslist"
}

extension TealiumConfig {
    
    
    /// Get the existing modules list assigned to this config object.
    ///
    /// - Returns: TealiumModulesList as an optional.
    func getModulesList() -> TealiumModulesList? {
        
        guard let list = self.optionalData[TealiumModulesListKey.config] as? TealiumModulesList else {
            return nil
        }
        
        return list
        
    }
    
    
    /// Set a net modules list to this config object.
    ///
    /// - Parameter list: The TealiumModulesList to assign.
    func setModulesList(_ list: TealiumModulesList ) {
        
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
        
        let newModules = getClassesOfType(c: TealiumModule.self)
        
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
    
    /// Retrieve an array of all subclasses of a given class.
    ///
    /// - Parameter c: Target parent class.
    /// - Returns: Array of subclass types.
    class func getClassesOfType(c: AnyClass) -> [AnyClass] {
        let classes = getClassList()
        var ret = [AnyClass]()
        
        for cls in classes {
            if (class_getSuperclass(cls) == c) {
                ret.append(cls)
            }
        }
        return ret
    }
    
    class func getClassList() -> [AnyClass] {
        let expectedClassCount = objc_getClassList(nil, 0)
        
        if expectedClassCount == 0 {
            // No classes found to initialize
            return []
        }
        
        let allClasses = UnsafeMutablePointer<AnyClass?>.allocate(capacity: Int(expectedClassCount))
        defer {
            allClasses.deinitialize()
            allClasses.deallocate(capacity: Int(expectedClassCount))
        }
        
        let autoreleasingAllClasses = AutoreleasingUnsafeMutablePointer<AnyClass?>(allClasses)
        let actualClassCount:Int32 = objc_getClassList(autoreleasingAllClasses, expectedClassCount)
        
        var classes = [AnyClass]()
        for i in 0 ..< actualClassCount {
            if let currentClass: AnyClass = allClasses[Int(i)] {
                classes.append(currentClass)
            }
        }
        
        return classes
    }
    
}
