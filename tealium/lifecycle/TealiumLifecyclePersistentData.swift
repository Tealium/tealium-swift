//
//  TealiumPersistentData.swift
//
//  Created by Jason Koo on 11/17/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

// TODO: Replace with new persistent request protocol

import Foundation

enum TealiumLifecyclePersistentDataError: Error {
    case couldNotArchiveAsData
    case couldNotUnarchiveData
    case archivedDataMismatchWithOriginalData
}

open class TealiumLifecyclePersistentData {

    class func dataExists(forUniqueId: String) -> Bool {
        guard UserDefaults.standard.object(forKey: forUniqueId) as? Data != nil else {
            return false
        }

        return true
    }

     class func load(uniqueId: String) -> TealiumLifecycle? {
        #if swift(>=4.0)
        guard let data = UserDefaults.standard.object(forKey: uniqueId) as? Data else {
            // No saved data
            return nil
        }
        #else
        guard let data = UserDefaults.standard.object(forKey: uniqueId) as? NSData else {
            // No saved data
            return nil
        }
        #endif

        do {
            guard let lifecycle = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? TealiumLifecycle else {
                return nil
            }
            return lifecycle
        } catch {
            // invalidArchiveOperationException
            return nil
        }
    }

    class func save(_ lifecycle: TealiumLifecycle, usingUniqueId: String) -> (success: Bool, error: Error?) {

        let data = NSKeyedArchiver.archivedData(withRootObject: lifecycle)

        UserDefaults.standard.set(data, forKey: usingUniqueId)
        #if swift(>=4.0)
        guard let defaultsCheckData = UserDefaults.standard.object(forKey: usingUniqueId) as? Data else {
            return (false, TealiumLifecyclePersistentDataError.couldNotArchiveAsData)
        }
        #else
        guard let defaultsCheckData = UserDefaults.standard.object(forKey: usingUniqueId) as? NSData else {
            return (false, TealiumLifecyclePersistentDataError.couldNotArchiveAsData)
        }
        #endif

        do {
            guard let defaultsCheck = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(defaultsCheckData) as? TealiumLifecycle else {
                return (false, TealiumLifecyclePersistentDataError.couldNotUnarchiveData)
            }

            let checkPassed = (defaultsCheck == lifecycle) ? true : false

            if checkPassed == true {
                return (true, nil)
            }

            return (false, TealiumLifecyclePersistentDataError.archivedDataMismatchWithOriginalData)
        } catch {
            return (false, TealiumLifecyclePersistentDataError.couldNotUnarchiveData)
        }
    }

    class func deleteAllData(forUniqueId: String) -> Bool {
        // False option not yet implemented
        if dataExists(forUniqueId: forUniqueId) == false {
            return true
        }

        UserDefaults.standard.removeObject(forKey: forUniqueId)

        if UserDefaults.standard.object(forKey: forUniqueId) == nil {
            return true
        }

        return false
    }

}
