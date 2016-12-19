//
//  TealiumFileManager.swift
//  SegueCatalog
//
//  Created by Jason Koo on 11/17/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation

class TealiumFileManager : TealiumIOManager {
    
    /// Gets path for unique id, if possible.
    ///
    /// - Parameter forUniqueId: Unique id key for data to be stored.
    /// - Returns: String if path can be created. Nil otherwise.
    class func path(forUniqueId: String) -> String? {
        
        let parentDir = "\(NSHomeDirectory())/.tealium/swift/"
        do {
            try FileManager.default.createDirectory(atPath: parentDir, withIntermediateDirectories: true, attributes: nil)
        } catch _ as NSError {
            
            return nil
            
        }
        
        return "\(parentDir)/\(forUniqueId).data"
    }
    
    
    /// Check to see if data exists for unique id.
    ///
    /// - Parameter forUniqueId: Full filepath from path(forUniqueId:), argument name left as forUniqueId for conformity.
    /// - Returns: True if data exists at uniqueId location, false otherwise
    override class func dataExists(forUniqueId: String) -> Bool {
        
        return FileManager.default.fileExists(atPath: forUniqueId)
        
    }

    override class func loadData(forUniqueId: String) -> [String:Any]? {
        
        if dataExists(forUniqueId: forUniqueId) {
            return NSKeyedUnarchiver.unarchiveObject(withFile: forUniqueId) as? [String:Any]
        }
        
        return nil
        
    }
    
    override class func save(data: [String:Any],
                             forUniqueId: String) -> Bool {
        
        return NSKeyedArchiver.archiveRootObject(data, toFile: forUniqueId)
        
    }

    override class func deleteAllData(forUniqueId: String) -> Bool {
        
        if dataExists(forUniqueId: forUniqueId) == false {
            return true
        }
        
        do {
            try FileManager.default.removeItem(atPath: forUniqueId)
            
        }
        catch _ as NSError {

            return false
        }
        
        return true
        
    }
    
    
}
