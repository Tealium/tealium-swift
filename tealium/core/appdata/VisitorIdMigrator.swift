//
//  VisitorIdMigrator.swift
//  TealiumCore
//
//  Created by Enrico Zannini on 03/10/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation

protocol VisitorIdMigratorProtocol {
    func getOldPersistentData() -> PersistentAppData?
    func deleteOldPersistentData()
}

class VisitorIdMigrator: VisitorIdMigratorProtocol {
    let dataLayer: DataLayerManagerProtocol
    let diskStorage: TealiumDiskStorageProtocol
    let backupStorage: TealiumBackupStorage
    init(dataLayer: DataLayerManagerProtocol, config: TealiumConfig, diskStorage: TealiumDiskStorageProtocol? = nil, backupStorage: TealiumBackupStorage) {
        self.dataLayer = dataLayer
        self.diskStorage = diskStorage ?? TealiumDiskStorage(config: config,
                                                             forModule: ModuleNames.appdata.lowercased(),
                                                             isCritical: true)
        self.backupStorage = backupStorage
    }

    func getOldPersistentData() -> PersistentAppData? {
        var persistentData: PersistentAppData?
        let allData = dataLayer.all
        if let migratedUUID = allData[TealiumDataKey.uuid] as? String,
           let migratedVisitorId = allData[TealiumDataKey.visitorId] as? String {
            persistentData = PersistentAppData(visitorId: migratedVisitorId, uuid: migratedUUID)
        } else if let data = diskStorage.retrieve(as: PersistentAppData.self) {
            persistentData = data
        } else if let visitorId = backupStorage.visitorId,
                  let appId = backupStorage.appId {
            persistentData = PersistentAppData(visitorId: visitorId, uuid: appId)
        }
        return persistentData
    }

    func deleteOldPersistentData() {
        diskStorage.delete(completion: nil)
        dataLayer.delete(for: [TealiumDataKey.visitorId]) // Only delete visitorId, UUID we can keep there
    }
}
