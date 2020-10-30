//
//  AppData.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium. All rights reserved.
//

import Foundation

public class AppDataModule: Collector {

    public let id: String = ModuleNames.appdata
    private(set) var uuid: String?
    private var diskStorage: TealiumDiskStorageProtocol!
    private var bundle: Bundle
    private var appDataCollector: AppDataCollection
    var appData = AppData()

    /// Retrieves current appdata
    public var data: [String: Any]? {
        // If collectors are configured and AppData isn't present, only return mandatory Tealium data
        if shouldCollectAllAppData {
            return appData.dictionary
        } else {
            return appData.persistentData?.dictionary
        }
    }

    var shouldCollectAllAppData: Bool {
        // If collector was included on the original config object, enable all data
        if let collectors = self.config.collectors {
            if collectors.contains(where: { $0 == AppDataModule.self }) {
                return true
            } else {
                return false
            }
        } else {
            // Default case - no collectors specified, so enable all data
            return true
        }

    }
    /// Optional override for visitor ID
    var existingVisitorId: String? {
        config.existingVisitorId
    }

    public var config: TealiumConfig

    /// Provided for testing - allows `Bundle` and `AppDataCollection` to be overridden
    ///
    /// - Parameter context: `TealiumContext` instance
    /// - Parameter delegate: `ModuleDelegate` instance
    /// - Parameter diskStorage: `TealiumDiskStorageProtocol` instance
    /// - Parameter bundle: `Bundle` for testing
    /// - Parameter appDataCollector: `AppDataCollection` for testing
    convenience init(context: TealiumContext,
                     delegate: ModuleDelegate,
                     diskStorage: TealiumDiskStorageProtocol?,
                     bundle: Bundle,
                     appDataCollector: AppDataCollection) {
        self.init(context: context, delegate: delegate, diskStorage: diskStorage) { _, _ in }
        self.appDataCollector = appDataCollector
        self.bundle = bundle
    }

    /// Initializes the module
    ///
    /// - Parameter context: `TealiumContext` instance
    /// - Parameter delegate: `ModuleDelegate` instance
    /// - Parameter diskStorage: `TealiumDiskStorageProtocol` instance
    /// - Parameter completion: `ModuleCompletion` block to be called when init is finished
    required public init(context: TealiumContext,
                         delegate: ModuleDelegate?,
                         diskStorage: TealiumDiskStorageProtocol?,
                         completion: ModuleCompletion) {
        self.config = context.config
        self.bundle = Bundle.main
        self.appDataCollector = AppDataCollector()
        self.diskStorage = diskStorage ?? TealiumDiskStorage(config: config, forModule: "appdata", isCritical: true)
        fillCache()
        if let dataLayer = context.dataLayer,
           let migratedUUID = dataLayer.all[TealiumKey.uuid] as? String,
           let migratedVisitorId = dataLayer.all[TealiumKey.visitorId] as? String {
            appData.persistentData?.uuid = migratedUUID
            appData.persistentData?.visitorId = migratedVisitorId
            diskStorage?.save(appData.persistentData, completion: nil)
            dataLayer.delete(for: [TealiumKey.uuid, TealiumKey.visitorId])
        }
        completion((.success(true), nil))
    }

    /// Retrieves existing data from persistent storage and stores in volatile memory.
    func fillCache() {
        guard let data = diskStorage.retrieve(as: PersistentAppData.self) else {
            storeNewAppData()
            return
        }
        self.loadPersistentAppData(data: data)
    }

    /// Deletes all app data, including persistent data.
    func deleteAll() {
        appData.removeAll()
        diskStorage.delete(completion: nil)
    }

    /// - Returns: `Int` Count of total items in app data
    var count: Int {
        return appData.count
    }

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

    /// Prepares new Tealium default App related data.
    ///
    /// - Parameter uuid: The uuid string to use for new persistent data.
    /// - Returns: `PersistentAppData`
    func newPersistentData(for uuid: String) -> PersistentAppData {
        let visitorId = existingVisitorId ?? self.visitorId(from: uuid)
        let persistentData = PersistentAppData(visitorId: visitorId, uuid: uuid)
        diskStorage.saveToDefaults(key: TealiumKey.visitorId, value: visitorId)
        diskStorage?.save(persistentData, completion: nil)
        return persistentData
    }

    /// Generates a new set of Volatile Data (usually once per app launch)
    func newVolatileData() {
        if let name = appDataCollector.name(bundle: bundle) {
            appData.name = name
        }

        if let rdns = appDataCollector.rdns(bundle: bundle) {
            appData.rdns = rdns
        }

        if let version = appDataCollector.version(bundle: bundle) {
            appData.version = version
        }

        if let build = appDataCollector.build(bundle: bundle) {
            appData.build = build
        }
    }

    /// Stores current AppData in memory
    func storeNewAppData() {
        let newUUID = UUID().uuidString
        appData.persistentData = newPersistentData(for: UUID().uuidString)
        newVolatileData()
        uuid = newUUID
    }

    /// Populates in-memory AppData with existing values from persistent storage, if present.
    ///
    /// - Parameter data: `PersistentAppData` instance  containing existing AppData variables
    func loadPersistentAppData(data: PersistentAppData) {
        guard !AppDataModule.isMissingPersistentKeys(data: data.dictionary) else {
            storeNewAppData()
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
