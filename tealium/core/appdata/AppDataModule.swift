//
//  AppData.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium. All rights reserved.
//

import Foundation

public class AppDataModule: Collector {

    public let id: String = ModuleNames.appdata
    var uuid: String? {
        appData.persistentData?.uuid
    }
    let diskStorage: TealiumDiskStorageProtocol!
    private var bundle: Bundle
    private var appDataCollector: AppDataCollection
    var appData = AppData()
    public var onVisitorId: TealiumObservable<String> {
        visitorIdProvider.onVisitorId.asObservable()
    }

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
    let visitorIdProvider: VisitorIdProvider
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
        self.diskStorage = diskStorage ?? TealiumDiskStorage(config: config, forModule: ModuleNames.appdata.lowercased(), isCritical: true)
        let onVisitorId = TealiumReplaySubject<String>()
        visitorIdProvider = VisitorIdProvider(context: context, onVisitorId: onVisitorId)
        fillCache(context: context)
        onVisitorId.subscribe { [weak self] visitorId in
            guard let self = self,
                  var persistentData = self.appData.persistentData, // Always present at this point
                  persistentData.visitorId != visitorId else {
                return
            }
            persistentData.visitorId = visitorId
            self.savePersistentData(persistentData)
        }

        if let id = appData.persistentData?.visitorId {
            onVisitorId.publish(id)
        }
        completion((.success(true), nil))
    }

    /// Retrieves existing data from persistent storage and stores in volatile memory.
    func fillCache(context: TealiumContext) {
        newVolatileData()
        let (persistentData, shouldBePersisted) = getInitialPersistentData(context: context)
        if shouldBePersisted {
            savePersistentData(persistentData)
        } else {
            appData.persistentData = persistentData
        }
    }

    func getInitialPersistentData(context: TealiumContext) -> (PersistentAppData, Bool) {
        var persistentData: PersistentAppData
        var shouldBePersisted = true
        if let dataLayer = context.dataLayer,
           let migratedUUID = dataLayer.all[TealiumDataKey.uuid] as? String,
           let migratedVisitorId = dataLayer.all[TealiumDataKey.visitorId] as? String {
            dataLayer.delete(for: [TealiumDataKey.uuid, TealiumDataKey.visitorId])
            persistentData = PersistentAppData(visitorId: migratedVisitorId, uuid: migratedUUID)
        } else if let data = diskStorage.retrieve(as: PersistentAppData.self),
                  !AppDataModule.isMissingPersistentKeys(data: data.dictionary) {
            persistentData = data
            shouldBePersisted = false
        } else {
            persistentData = newPersistentData(for: UUID().uuidString)
        }
        return (persistentData, shouldBePersisted)
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
        if data[TealiumDataKey.uuid] == nil { return true }
        if data[TealiumDataKey.visitorId] == nil { return true }
        return false
    }

    /// Prepares new Tealium default App related data.
    ///
    /// - Returns: `PersistentAppData`
    func newPersistentData(for uuid: String) -> PersistentAppData {
        let visitorId = existingVisitorId ?? VisitorIdProvider.visitorId(from: uuid)
        let persistentData = PersistentAppData(visitorId: visitorId, uuid: uuid)
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

    private func savePersistentData(_ data: PersistentAppData) {
        self.appData.persistentData = data
        diskStorage.save(data, completion: nil)
    }

    /// Resets Tealium Visitor Id
    func resetVisitorId() {
        TealiumQueues.backgroundSerialQueue.async { [weak self] in
            self?.visitorIdProvider.resetVisitorId()
        }
    }
    
    func clearStoredVisitorIds() {
        TealiumQueues.backgroundSerialQueue.async { [weak self] in
            self?.visitorIdProvider.clearStoredVisitorIds()
        }
    }
}
