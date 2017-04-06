//
//  TealiumModulesManager.swift
//  tealium-swift
//
//  Created by Jason Koo on 10/5/16.
//  Copyright © 2016 tealium. All rights reserved.
//
//  Build 2

import Foundation
import ObjectiveC

/**
    Coordinates optional modules with primary Tealium class.
 
 */
class TealiumModulesManager : NSObject {
    
    var config : TealiumConfig
    var modules = [TealiumModule]()
    var isEnabled = true

    init(config:TealiumConfig) {
        
        self.config = config
        
    }
    
    // MARK:
    // MARK: PUBLIC
    func updateAll() {
        
        if self.modules.isEmpty {
            let newModules = getClassesOfType(c: TealiumModule.self)
            
            // Create instances of each module
            for module in newModules {
                addModule(klass: module)
            }
            
        }
        self.modules = self.modules.prioritized()
        
        // Check for duplicate module configs which would result in runtime crash later.
        let duplicates = self.modules.duplicateModuleConfigs()
        if duplicates.count > 0 {
            // Implementation Error
            assertionFailure("*** Tealium-swift SDK ***: Modules with duplicate TealiumModuleConfigs found: \(duplicates). Continuing would result in eventual crash. Check to make sure all ModuleConfigs are using unique priority values and/or names.")
        }
        
        // Enable first module to start chain enabling
        isEnabled = true
        self.modules.first?.update(config:self.config)
        
    }
    
    
    func disableAll() {
        isEnabled = false
        self.modules.prioritized()[0].disable()
    }

    
    func getModule(forName: String) -> TealiumModule? {
        
        return modules.first(where: {$0.moduleConfig().name == forName})

    }
    
    func allModulesReady() -> Bool {
        
        for module in modules {
            if module.isEnabled == false {
                return false
            }
        }
        return true
    }

    // MARK:
    // MARK: INTERNAL AUTO MODULE DETECTION
    
    /// Retrieve an array of all subclasses of a given class.
    ///
    /// - Parameter c: Target parent class.
    /// - Returns: Array of subclass types.
    func getClassesOfType(c: AnyClass) -> [AnyClass] {
        let classes = getClassList()
        var ret = [AnyClass]()
        
        for cls in classes {
            if (class_getSuperclass(cls) == c) {
                ret.append(cls)
            }
        }
        return ret
    }
    
    func getClassList() -> [AnyClass] {
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
    
    
    /// Inits and adds an instance of a given type.
    ///
    /// - Parameter klass: Given class type.
    func addModule(klass: AnyClass){
    
        // TODO: Break this method up and use type checking in argument.
        guard let type = klass as? TealiumModule.Type else {
            // Type does not exist - skip
            return
        }
        
        let module = type.init(delegate: self)
       
        if module.moduleConfig().enabled == false {
            return
        }
        
        if module.moduleConfig().enabled == false {
            return
        }
        modules.append(module)
        
    }
    
    // MARK:
    // MARK: INTERNAL TRACK HANDLING
    
    func track(_ track: TealiumTrack) {
        
        if isEnabled == false {
            track.completion?(false, nil, TealiumModulesManagerError.isDisabled)
            return
        }
        
        // Modules still spinning up, delay track call
        if self.allModulesReady() == false {
            DispatchQueue.main.async {
                self.track(track)
            }
            return
        }
        
        guard let firstModule = modules.first else {
            track.completion?(false, nil, TealiumModulesManagerError.noModules)
            return
        }
        
        firstModule.track(track)
        
    }

}

// MARK:
// MARK: TEALIUM MODULE DELEGATE

extension TealiumModulesManager : TealiumModuleDelegate {
    
    func tealiumModuleFinished(module: TealiumModule,
                               process: TealiumProcess) {
        
        modules.first?.handleReport(fromModule: module,
                                    process: process)
        
        modules.next(after: module)?.auto(process,
                                          config: self.config)
    }
    
    func tealiumModuleRequests(module: TealiumModule,
                               process: TealiumProcess) {
        
        switch process.type {
        case .enable:
            // Module requests entire library enable
            updateAll()
        case .disable:
            // Module requests entire library disable
            disableAll()
        case .track:
            guard let track = process.track else {
                // Request made with no track info
                return
            }
            // Send track request to front of chain.
            modules.first?.track(track)
        }
    }
    
    func tealiumModuleFinishedReport(fromModule: TealiumModule,
                                     module: TealiumModule,
                                     process: TealiumProcess) {
        
        modules.next(after: module)?.handleReport(fromModule: fromModule,
                                                  process: process)
        
    }
    
}

// MARK: 
// MARK: MODULEMANAGER EXTENSIONS
extension Array where Element : TealiumModule {
    
    /**
     Convenience for sorting Arrays of TealiumModules by priority number: Lower numbers going first.
     */
    func prioritized() -> [TealiumModule] {
        return self.sorted{
            $0.moduleConfig().priority < $1.moduleConfig().priority
        }
        
    }
    
    func duplicateModuleConfigs() -> [TealiumModuleConfig] {
        var duplicateModuleConfigs = [TealiumModuleConfig]()
        var checkArray = [TealiumModuleConfig]()
        
        for module in self {
            let moduleConfig = module.moduleConfig()
            if checkArray.contains(moduleConfig) {
                duplicateModuleConfigs.append(moduleConfig)
                continue
            }
            checkArray.append(moduleConfig)
        }
        return duplicateModuleConfigs
    }
    
}

extension Array where Element: Equatable {

    /**
     Convenience for getting the next object in a given array.
     */
    func next(after:Element) -> Element? {
        
        for i in 0..<self.count {
            let object = self[i]
            if object == after {
                
                if i + 1 < self.count {
                    return self[i+1]
                }
            }
        }
        
        return nil
        
    }
    
}
