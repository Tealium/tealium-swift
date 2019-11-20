//
//  TealiumLifecyclePersistentData.swift
//  tealium-swift
//
//  Created by Jason Koo on 11/17/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation
#if lifecycle
import TealiumCore
#endif

enum TealiumLifecyclePersistentDataError: Error {
    case couldNotArchiveAsData
    case couldNotUnarchiveData
    case archivedDataMismatchWithOriginalData
}

open class TealiumLifecyclePersistentData {

    let diskStorage: TealiumDiskStorageProtocol

    init(diskStorage: TealiumDiskStorageProtocol,
         uniqueId: String? = nil) {
        self.diskStorage = diskStorage
        // one-time migration
        if let uniqueId = uniqueId, let lifecycle = retrieveLegacyLifecycleData(uniqueId: uniqueId) {
            _ = self.save(lifecycle)
        }
    }

    func retrieveLegacyLifecycleData(uniqueId: String) -> TealiumLifecycle? {
        guard let data = UserDefaults.standard.object(forKey: uniqueId) as? Data else {
            // No saved data
            return nil
        }

        do {
            // CocoaPods & Carthage use different module names, so legacy storage requires different namespaces
            #if COCOAPODS
            NSKeyedUnarchiver.setClass(TealiumLifecycleLegacy.self, forClassName: "TealiumSwift.TealiumLifecycle")
            NSKeyedUnarchiver.setClass(TealiumLifecycleLegacySession.self, forClassName: "TealiumSwift.TealiumLifecycleSession")
            #elseif lifecycle
            // carthage - individual schemes
            NSKeyedUnarchiver.setClass(TealiumLifecycleLegacy.self, forClassName: "TealiumLifecycle.TealiumLifecycle")
            NSKeyedUnarchiver.setClass(TealiumLifecycleLegacySession.self, forClassName: "TealiumLifecycle.TealiumLifecycleSession")
            // For the "SwiftTestBed" app in 1.7.1 and below, the module namespace was "Tealium", but this shouldn't be the case in production apps.
            // If testing migration from 1.7.1 in the builder project, you will need to uncomment the following 2 lines
            // NSKeyedUnarchiver.setClass(TealiumLifecycleLegacy.self, forClassName: "Tealium.TealiumLifecycle")
            // NSKeyedUnarchiver.setClass(TealiumLifecycleLegacySession.self, forClassName: "Tealium.TealiumLifecycleSession")
            #endif
            guard let lifecycle = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? TealiumLifecycleLegacy else {
                return nil
            }
            let encoder = JSONEncoder()
            guard let encoded = try? encoder.encode(lifecycle) else {
                return nil
            }
            let decoder = JSONDecoder()
            guard let decoded = try? decoder.decode(TealiumLifecycle.self, from: encoded) else {
                return nil
            }
            UserDefaults.standard.removeObject(forKey: uniqueId)
            return decoded
        } catch {
            // invalidArchiveOperationException
            return nil
        }
    }

    class func dataExists(forUniqueId: String) -> Bool {
        guard UserDefaults.standard.object(forKey: forUniqueId) as? Data != nil else {
            return false
        }

        return true
    }

     func load() -> TealiumLifecycle? {
        var lifecycle: TealiumLifecycle?
        diskStorage.retrieve(as: TealiumLifecycle.self) { _, data, _ in
            lifecycle = data
        }
        return lifecycle
    }

    func save(_ lifecycle: TealiumLifecycle) -> (success: Bool, error: Error?) {
        diskStorage.save(lifecycle, completion: nil)
        return (true, nil)
    }

    class func deleteAllData(forUniqueId: String) -> Bool {
        if !dataExists(forUniqueId: forUniqueId) {
            return true
        }

        UserDefaults.standard.removeObject(forKey: forUniqueId)

        if UserDefaults.standard.object(forKey: forUniqueId) == nil {
            return true
        }

        return false
    }

}
