//
//  TealiumPersistentData.swift
//
//  Created by Jason Koo on 11/17/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation

enum TealiumLifecyclePersistentDataError : Error {
    case couldNotArchiveAsData
    case couldNotUnarchiveData
    case archivedDataMismatchWithOriginalData
}

open class TealiumLifecyclePersistentData {
    
    class func dataExists(forUniqueId: String) -> Bool {
        
        guard let _ = UserDefaults.standard.object(forKey: forUniqueId) as? Data else {
            return false
        }
        
        return true
        
    }
    
     class func load(uniqueId: String) -> TealiumLifecycle? {
        
        guard let data = UserDefaults.standard.object(forKey: uniqueId) as? Data else {
            // No saved data
            return nil
        }
        
        guard let lifecycle = NSKeyedUnarchiver.unarchiveObject(with: data) as? TealiumLifecycle else {
            return nil
        }
        
        return lifecycle
        
    }
    
    class func save(_ lifecycle: TealiumLifecycle, usingUniqueId: String) -> (success: Bool, error: Error?) {
        
        let data = NSKeyedArchiver.archivedData(withRootObject: lifecycle)
        
        UserDefaults.standard.set(data, forKey: usingUniqueId)
        UserDefaults.standard.synchronize()
        
        guard let defaultsCheckData = UserDefaults.standard.object(forKey: usingUniqueId) as? Data else {
            return (false, TealiumLifecyclePersistentDataError.couldNotArchiveAsData)
        }
        
        guard let defaultsCheck = NSKeyedUnarchiver.unarchiveObject(with: defaultsCheckData) as? TealiumLifecycle else {
            return (false, TealiumLifecyclePersistentDataError.couldNotUnarchiveData)
        }
        
        let checkPassed = (defaultsCheck == lifecycle) ? true : false
        
        if checkPassed == true {
            return (true, nil)
        }
        
        return (false, TealiumLifecyclePersistentDataError.archivedDataMismatchWithOriginalData)
    }
    
    class func deleteAllData(forUniqueId: String) -> Bool {
        
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

