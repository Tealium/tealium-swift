//
//  Tealium.swift
//  tealium-swift
//
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation

///  Public interface for the Tealium library.
public class Tealium {

    var enableCompletion: ((_ result: Result<Bool, Error>) -> Void)?
    public static let lifecycleListeners = TealiumLifecycleListeners()
    public var dataLayer: DataLayerManagerProtocol
    // swiftlint:disable identifier_name
    public var zz_internal_modulesManager: ModulesManager?
    // swiftlint:enable identifier_name
    public var migrator: Migratable
    private var disposeBag = TealiumDisposeBag()
    var context: TealiumContext?
    /// Initializer.
    ///
    /// - Parameter config: `TealiumConfig` Object created with Tealium account, profile, environment, optional loglevel)
    /// - Parameter enableCompletion: `((_ result: Result<Bool, Error>) -> Void)` block to be called when library has finished initializing
    public init(config: TealiumConfig,
                dataLayer: DataLayerManagerProtocol? = nil,
                modulesManager: ModulesManager? = nil,
                migrator: Migratable? = nil,
                enableCompletion: ((_ result: Result<Bool, Error>) -> Void)?) {
        defer {
            TealiumQueues.backgroundSerialQueue.async {
                enableCompletion?(.success(true))
            }
        }
        self.enableCompletion = enableCompletion
        self.dataLayer = dataLayer ?? DataLayer(config: config)
        self.migrator = migrator ?? Migrator(config: config)
        if config.shouldMigratePersistentData {
            self.migrator.migratePersistent(dataLayer: self.dataLayer)
        }
        let context = TealiumContext(config: config, dataLayer: self.dataLayer, tealium: self)
        self.context = context
        #if os(iOS)
        TealiumDelegateProxy.setup(context: context)
        #endif
        TealiumQueues.backgroundSerialQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.zz_internal_modulesManager = modulesManager ?? ModulesManager(context)
        }

        TealiumQueues.secureMainThreadExecution {
            TealiumInstanceManager.shared.onOpenUrl.subscribe { [weak self] url in
                self?.handleDeepLink(url)
            }.toDisposeBag(self.disposeBag)
        }

        TealiumQueues.secureMainThreadExecution {
            TealiumInstanceManager.shared.onOpenUrl.subscribe { [weak self] url in
                self?.handleDeepLink(url)
            }.toDisposeBag(self.disposeBag)
        }

        TealiumInstanceManager.shared.addInstance(self, config: config)
    }

    /// - Parameter config: `TealiumConfig` Object created with Tealium account, profile, environment, optional loglevel)
    public convenience init(config: TealiumConfig) {
        self.init(config: config, enableCompletion: nil)
    }

    /// Suspends all library activity, may release internal objects.
    public func disable() {
        TealiumQueues.backgroundSerialQueue.async {
            if let config = self.zz_internal_modulesManager?.config {
                TealiumInstanceManager.shared.removeInstance(config: config)
            }
            self.zz_internal_modulesManager = nil
        }
    }

    /// Sends all queued dispatches immediately. Requests may still be blocked by DispatchValidators such as Consent Manager
    public func flushQueue() {
        TealiumQueues.backgroundSerialQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.zz_internal_modulesManager?.requestDequeue(reason: "Flush Queue Called")
        }
    }

    /// Track an event
    ///
    /// - Parameter dispatch: `TealiumDispatch` containing the event/view name and the data layer object for this event
    public func track(_ dispatch: TealiumDispatch) {
        TealiumQueues.backgroundSerialQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.zz_internal_modulesManager?.sendTrack(dispatch.trackRequest)

        }
    }

    /// Gathers all the data from the DataLayer and the collectors
    ///
    /// - parameter retrieveCachedData: If true we don't gather new data but we return the last cached track or gather data
    /// - parameter completion: The block called with the gathered data
    public func gatherTrackData(retrieveCachedData: Bool = false, completion: @escaping ([String: Any]) -> Void) {
        TealiumQueues.backgroundSerialQueue.async { [weak self] in
            guard let self = self, let modulesManager = self.zz_internal_modulesManager else {
                completion([:])
                return
            }
            completion(modulesManager.allTrackData(retrieveCachedData: retrieveCachedData))
        }
    }

    deinit {
        #if os(iOS)
        TealiumDelegateProxy.removeContext(self.context)
        #endif
        let disposeBag = self.disposeBag
        TealiumQueues.secureMainThreadExecution { // disposeBag needs to be used from main thread
            disposeBag.dispose() // avoid capturing self in deinit
        }
    }

}
