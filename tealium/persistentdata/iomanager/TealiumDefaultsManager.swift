//
//  TealiumDefaultsManager.swift
//  SegueCatalog
//
//  Created by Jason Koo on 11/17/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation

class TealiumDefaultsManager : TealiumIOManager {
    
    override class func dataExists(forUniqueId: String) -> Bool {
        
        guard let _ = UserDefaults.standard.object(forKey: forUniqueId) as? [String:Any] else {
            return false
        }
        
        return true
    
    }
    
    override class func loadData(forUniqueId: String) -> [String:Any]? {
        
        guard let data = UserDefaults.standard.object(forKey: forUniqueId) as? [String:Any] else {
            // No saved data
            return nil
        }
        
        return data
    
    }
    
    override class func save(data:[String:Any], forUniqueId: String) -> Bool {
        
        UserDefaults.standard.set(data, forKey: forUniqueId)
        UserDefaults.standard.synchronize()
    
        guard let defaultsCheck = UserDefaults.standard.object(forKey: forUniqueId) as? [String:Any] else {
            return false
        }
        
        return defaultsCheck == data
    }
    
    override class func deleteAllData(forUniqueId: String) -> Bool {
        
        // False option not yet implemented
        if dataExists(forUniqueId: forUniqueId) == false {
            return true
        }
        
        UserDefaults.standard.removeObject(forKey: forUniqueId)
        UserDefaults.standard.synchronize()
        
        if UserDefaults.standard.object(forKey: forUniqueId) == nil {
            return true
        }
    
        return false
    }
}
