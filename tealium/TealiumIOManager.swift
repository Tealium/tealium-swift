//
//  TealiumIOManager.swift
//  tealium-swift
//
//  Created by Chad Hartman on 9/2/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import Foundation

/**
    Internal persistent data handler.
 
 */
class TealiumIOManager {
    
    private let persistenceFilePath: String
    
    /**
     Initializer.
     
     - Parameters:
         - account: Tealium account name.
         - profile: Tealium profile name.
         - env: Tealium environment name (dev, qa, prod).
         - completion: Closure executed with init is complete. Nil returned if successful.
     */
    init?(account:String, profile:String, env: String) {
        
        let parentDir = "\(NSHomeDirectory())/.tealium/swift/"
        do {
            try NSFileManager.defaultManager().createDirectoryAtPath(parentDir, withIntermediateDirectories: true, attributes: nil)
        } catch _ as NSError {
            // Leaveing above as stub for more complex error handling if desired.
            return nil
        }
        
        persistenceFilePath = "\(parentDir)/\(account)_\(profile)_\(env).data"
    }
    
    /**
     Determine whether existing data is saved at ~/.tealium/swift/{account}_{profile}_{env}.data.
     
     - Returns: true if the file exists.
     */
    func persistedDataExists() -> Bool {
        return NSFileManager.defaultManager().fileExistsAtPath(persistenceFilePath)
    }
    
    /**
     Persists a [String:AnyObject] instance to ~/.tealium/swift/{account}_{profile}_{env}.data.
     
     - Parameters:
     - data: The desired data to persist, clobbers the previously saved file.
     */
    func saveData(data:[String:AnyObject]) {
        NSKeyedArchiver.archiveRootObject(data, toFile: persistenceFilePath)
    }
    
    /**
     Loads persisted data from ~/.tealium/swift/{account}_{profile}_{env}.data if it exists.
     
     - Returns: [String:AnyObject] data if exists, otherwise null if not present or corrupted.
     */
    func loadData() -> [String:AnyObject]? {
        if persistedDataExists() {
            return NSKeyedUnarchiver.unarchiveObjectWithFile(persistenceFilePath) as? [String:AnyObject]
        }
        
        return nil
    }
    
    /**
     Delete persisted data at ~/.tealium/swift/{account}_{profile}_{env}.data.
     
     - Paramaters:
        - completion: Closure called upon completion of delete request, no error returned if successful.
     */
    func deleteData() -> Bool {
        
        if !persistedDataExists() {
            return true
        }
        
        do {
            try NSFileManager.defaultManager().removeItemAtPath(persistenceFilePath)
        
        }
        catch _ as NSError {
            return false
        }
        
        return true
    }

    
}


