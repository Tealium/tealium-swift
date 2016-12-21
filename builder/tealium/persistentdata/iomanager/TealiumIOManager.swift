//
//  TealiumIOManager.swift
//  SegueCatalog
//
//  Created by Jason Koo on 11/17/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 IO Management base class.
 */
class TealiumIOManager {
    
    class func dataExists(forUniqueId: String) -> Bool {
    
        return false
    }
    
    class func loadData(forUniqueId: String) -> [String:Any]? {
        
        return nil
    }
    
    class func save(data:[String:Any], forUniqueId: String) -> Bool {
        
        return false
    }
    
    class func deleteAllData(forUniqueId: String) -> Bool {
        
        return false
    }
    
}
