//
//  TealiumPersistentData.swift
//  ios
//
//  Created by Craig Rouse on 11/07/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

#if persistentdata
import TealiumCore
#endif

import Foundation

public class TealiumPersistentData {

    public var persistentDataCache = TealiumPersistentDataStorage()
    let diskStorage: TealiumDiskStorageProtocol
    var migrator: TealiumLegacyMigratorProtocol.Type

    /// - Parameters:
    ///     - diskStorage: `TealiumDiskStorageProtocol`
    ///     - legacyMigrator: `TealiumLegacyMigratorProtocol.Type`
    init(diskStorage: TealiumDiskStorageProtocol,
         legacyMigrator: TealiumLegacyMigratorProtocol.Type = TealiumLegacyMigrator.self) {
        self.migrator = legacyMigrator
        self.diskStorage = diskStorage
        self.setExistingPersistentData()

    }

    public var dictionary: [String: Any]? {
        persistentDataCache.data.value as? [String: Any]
    }

    /// Retrieves data from persistent storage and adds to cache.
    func setExistingPersistentData() {
        if let data = migrator.getLegacyData(forModule: TealiumPersistentKey.moduleName) {
            add(data: data)
        } else {
            guard let data = diskStorage.retrieve(as: TealiumPersistentDataStorage.self) else {
                    return
            }
            self.persistentDataCache = data
        }
    }

    /// Add additional persistent data that will be available to all track calls
    ///     for lifetime of app. Values will overwrite any pre-existing values
    ///     for a given key.
    ///￼
    /// - Parameter data: `[String:Any]` of additional data to add.
    public func add(data: [String: Any]) {
        persistentDataCache.add(data: data)
        diskStorage.save(persistentDataCache, completion: nil)
    }

    /// Delete a saved value for a given key.
    ///￼
    /// - Parameter forKeys: `[String]` Array of keys to remove.
    public func deleteData(forKeys: [String]) {
        var cacheCopy = persistentDataCache

        for key in forKeys {
            cacheCopy.delete(forKey: key)
        }

        persistentDataCache = cacheCopy
        diskStorage.save(persistentDataCache, completion: nil)
    }

    /// Delete all custom persisted data for current library instance.
    public func deleteAllData() {
        persistentDataCache = TealiumPersistentDataStorage()
        diskStorage.delete(completion: nil)
    }

}
