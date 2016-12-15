//
//  TealiumPersistentData.swift
//  SegueCatalog
//
//  Created by Jason Koo on 11/17/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation

open class TealiumPersistentData {
    
    var persistenceMode = TealiumPersistentMode.file
    var uniqueId : String?
    var persistentDataCache = [String:Any]()
    
    // MARK:
    // MARK: PUBLIC
    
    /// Retrieve an auto-assigned unique identifier for modules.
    ///
    /// - Parameters:
    ///   - forConfig: TealiumConfig for Tealium instance.
    ///   - module: Module that will be using Persistence.
    ///   - additionalIdentifier: Suffix string to differentiate 2 of the same
    ///         modules, if used.
    /// - Returns: String of unique id.
    class func uniqueId(forConfig: TealiumConfig,
                        module: TealiumModule,
                        additionalIdentifier: String?) -> String {
        
        var uid = "\(forConfig.account).\(forConfig.profile).\(forConfig.environment).\(module.moduleConfig().name)"
        
        if let additionalIdentifier = additionalIdentifier {
            uid += ".\(additionalIdentifier)"
        }
        
        return uid
        
    }
    
    /**
     Initializer.
     
     - parameters:
         - account: Tealium account name.
         - profile: Tealium profile name.
         - env: Tealium environment name (dev, qa, prod).
         - completion: Closure executed with init is complete. Nil returned if successful.
     */
    init(uniqueId: String) {
        
        if let path = TealiumFileManager.path(forUniqueId: uniqueId) {
            // Using file persistence
            
            self.uniqueId = path
            return
            
        }
        
        // Using user defaults
        
        self.uniqueId = uniqueId
        
        persistenceMode = TealiumPersistentMode.defaults
        
    }
    
    /// Add additional volatile data that will be available to all track calls
    /// until app termination.
    ///
    /// - Parameter data: [String:Any] of additional data to add.
    public func add(data: [String:Any]) {
        
        persistentDataCache += data
        
        let _ = save(data: persistentDataCache)
    }
    

    public func deleteData(forKeys:[String]) {
     
        var cacheCopy = persistentDataCache
        
        for key in forKeys {
            cacheCopy.removeValue(forKey: key)
        }
        
        persistentDataCache = cacheCopy
        
        let _ = save(data: persistentDataCache)
    }
    
    /**
     Delete persisted data at ~/.tealium/swift/{account}_{profile}_{env}.data.
     
     - Paramaters:
     - completion: Closure called upon completion of delete request, no error returned if successful.
     */
    public func deleteAllData() -> Bool {
        
        guard let uniqueId = self.uniqueId else {
            // Unique Id has gone missing.
            return false
        }
        
        if persistenceMode == .file {
            return TealiumFileManager.deleteAllData(forUniqueId: uniqueId)
        } else {
            return TealiumDefaultsManager.deleteAllData(forUniqueId: uniqueId)
        }
    }
    
    /**
     Returns persistent data.
     
     - returns: [String:Any] dictionary of saved data.
     */
    public func getData() -> [String:Any] {
        
        // Use cache if available.
        if persistentDataCache.isEmpty == false {
            return persistentDataCache
        }
        
        // Attempt to load from memory.
        guard let data = loadData() else {
            // No saved data - return empty cache created at init time.
            return persistentDataCache
        }
        
        // Return loaded persistent data.
        persistentDataCache = data
        return persistentDataCache
        
    }
    
    // MARK:
    // MARK: INTERNAL
    
    /**
     Persists a [String:Any].
     
     - parameters:
     - data: The desired data to persist, clobbers the previously saved file.
     - returns:
     */
    internal func save(data:[String:Any]) -> Bool {
        
        guard let uniqueId = self.uniqueId else {
            // Unique Id has gone missing.
            return false
        }
        
        if persistenceMode == .file {
            return TealiumFileManager.save(data: data, forUniqueId: uniqueId)
        } else {
            return TealiumDefaultsManager.save(data: data, forUniqueId: uniqueId)
        }
    }
    
    /**
     Loads persisted data from ~/.tealium/swift/{account}_{profile}_{env}.data if it exists.
     
     - Returns: [String:Any] data if exists, otherwise null if not present or corrupted.
     */
    internal func loadData() -> [String:Any]? {
        
        guard let uniqueId = self.uniqueId else {
            // Unique Id has gone missing.
            return nil
        }
        
        if persistenceMode == .file {
            
            return TealiumFileManager.loadData(forUniqueId: uniqueId)
            
        } else {
            
            return TealiumDefaultsManager.loadData(forUniqueId: uniqueId)
        }
        
    }
    
}

extension TealiumPersistentData : CustomStringConvertible {
    
    public var description : String {
        return "\(type(of: self)).persistentMode.\(self.persistenceMode.description)"
    }
}
