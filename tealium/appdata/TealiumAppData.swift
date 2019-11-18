//
//  TealiumAppData.swift
//  tealium-swift
//
//  Created by Jonathan Wong on 1/10/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation
#if appdata
import TealiumCore
#endif

public class TealiumAppData: TealiumAppDataProtocol, TealiumAppDataCollection {

    private(set) var uuid: String?
    private var diskStorage: TealiumDiskStorageProtocol!
    private var bundle: Bundle
    var appData = VolatileAppData()
    var migrator: TealiumLegacyMigratorProtocol.Type
    var existingVisitorId: String?

    init(diskStorage: TealiumDiskStorageProtocol,
         bundle: Bundle = Bundle.main,
         legacyMigrator: TealiumLegacyMigratorProtocol.Type = TealiumLegacyMigrator.self,
         existingVisitorId: String? = nil) {
        self.migrator = legacyMigrator
        self.bundle = bundle
        self.diskStorage = diskStorage
        self.existingVisitorId = existingVisitorId
        setExistingAppData()
    }

    /// Retrieves existing data from persistent storage and stores in volatile memory.
    func setExistingAppData() {
        if let data = migrator.getLegacyData(forModule: TealiumAppDataKey.moduleName),
            let persistentData = PersistentAppData.initFromDictionary(data) {
            self.setLoadedAppData(data: persistentData)
        } else {
            diskStorage.retrieve(as: PersistentAppData.self) {_, data, _ in
                guard let data = data else {
                    self.setNewAppData()
                    return
                }
                self.setLoadedAppData(data: data)
            }
        }
    }

    /// Retrieve a copy of app data used with dispatches.
    ///
    /// - Returns: `[String: Any]`
    public func getData() -> [String: Any] {
        return appData.toDictionary()
    }

    /// Deletes all app data, including persistent data.
    public func deleteAllData() {
        appData.removeAll()
        diskStorage.delete(completion: nil)
    }

    /// - Returns: Count of total items in app data
    var count: Int {
        return appData.count
    }

    // MARK: INTERNAL

    /// Checks if persistent keys are missing from the `data` dictionary.
    ///
    /// - Parameter data: `[String: Any]` dictionary to check
    /// - Returns: `Bool`
    class func isMissingPersistentKeys(data: [String: Any]) -> Bool {
        if data[TealiumKey.uuid] == nil { return true }
        if data[TealiumKey.visitorId] == nil { return true }
        return false
    }

    /// Converts UUID to Tealium Visitor ID format.
    ///
    /// - Parameter from: `String` containing a UUID
    /// - Returns: `String` containing Tealium Visitor ID
    func visitorId(from uuid: String) -> String {
        return uuid.replacingOccurrences(of: "-", with: "")
    }

    /// Prepares new Tealium default App related data. Legacy Visitor Id data
    /// is set here as it based off app_uuid.
    ///
    /// - Parameter uuid: The uuid string to use for new persistent data.
    /// - Returns: `[String:Any]`
    func newPersistentData(for uuid: String) -> PersistentAppData {
        let visitorId = existingVisitorId ?? self.visitorId(from: uuid)
        let persistentData = PersistentAppData(visitorId: visitorId, uuid: uuid)
        diskStorage.saveToDefaults(key: TealiumKey.visitorId, value: visitorId)
        diskStorage?.save(persistentData, completion: nil)
        return persistentData
    }

    /// Generates a new set of Volatile Data (usually once per app launch)
    func newVolatileData() {
        if let name = name(bundle: bundle) {
            appData.name = name
        }

        if let rdns = rdns(bundle: bundle) {
            appData.rdns = rdns
        }

        if let version = version(bundle: bundle) {
            appData.version = version
        }

        if let build = build(bundle: bundle) {
            appData.build = build
        }
    }

    /// Stores current AppData in memory
    public func setNewAppData() {
        let newUuid = UUID().uuidString
        appData.persistentData = newPersistentData(for: newUuid)
        newVolatileData()
        uuid = newUuid
    }

    /// Populates in-memory AppData with existing values from persistent storage, if present.
    ///
    /// - Parameter data: `PersistentAppData` instance  containing existing AppData variables
    public func setLoadedAppData(data: PersistentAppData) {
        guard !TealiumAppData.isMissingPersistentKeys(data: data.toDictionary()) else {
            setNewAppData()
            return
        }

        appData.persistentData = data
        if let existingVisitorId = self.existingVisitorId,
            let persistentData = appData.persistentData {
            let newPersistentData = PersistentAppData(visitorId: existingVisitorId, uuid: persistentData.uuid)
            diskStorage.saveToDefaults(key: TealiumKey.visitorId, value: existingVisitorId)
            diskStorage.save(newPersistentData, completion: nil)
            self.appData.persistentData = newPersistentData
        }
        newVolatileData()
    }
}
