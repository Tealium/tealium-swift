//
//  AppData.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium. All rights reserved.
//

import Foundation

public class AppDataModule: Collector {

    public let id: String = ModuleNames.appdata
    private var bundle: Bundle
    private var appDataCollector: AppDataCollection
    var appData = AppData()
    public var onVisitorId: TealiumObservable<String> {
        visitorIdProvider.onVisitorId.asObservable()
    }

    /// Retrieves current appdata
    public var data: [String: Any]? {
        // If collectors are configured and AppData isn't present, only return mandatory Tealium data
        let requiredData = [TealiumDataKey.visitorId: visitorIdProvider.visitorIdStorage.visitorId]
        if !shouldCollectAllAppData {
            return requiredData
        } else {
            return appData.dictionary + requiredData
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
        visitorIdProvider = VisitorIdProvider(config: context.config,
                                              dataLayer: context.dataLayer,
                                              diskStorage: diskStorage,
                                              backupStorage: context.tealiumBackup)
        newVolatileData()
        completion((.success(true), nil))
    }

    /// - Returns: `Int` Count of total items in app data
    var count: Int {
        return appData.count
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
