//
//  Tealium.swift
//  tealium-swift
//
//  Created by Jason Koo, Merritt Tidwell, Chad Hartman, Karen Tamayo, Chris Anderberg  on 8/31/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//
//

import Foundation

public typealias TealiumEnableCompletion = ((_ result: Result<Bool, Error>) -> Void)

///  Public interface for the Tealium library.
public class Tealium {

    var enableCompletion: TealiumEnableCompletion?
    public static var lifecycleListeners = TealiumLifecycleListeners()
    public var dataLayer: DataLayerManagerProtocol
    // swiftlint:disable identifier_name
    public var zz_internal_modulesManager: ModulesManager?
    // swiftlint:enable identifier_name

    /// Initializer.
    ///
    /// - Parameter config: `TealiumConfig` Object created with Tealium account, profile, environment, optional loglevel)
    /// - Parameter enableCompletion: `TealiumEnableCompletion` block to be called when library has finished initializing
    public init(config: TealiumConfig,
                dataLayer: DataLayerManagerProtocol? = nil,
                modulesManager: ModulesManager? = nil,
                enableCompletion: TealiumEnableCompletion?) {
        defer {
            TealiumQueues.backgroundSerialQueue.async {
                enableCompletion?(.success(true))
            }
        }

        self.enableCompletion = enableCompletion
        self.dataLayer = dataLayer ?? DataLayer(config: config)
        #if os(iOS)
        if config.appDelegateProxyEnabled {
            let context = TealiumContext(config: config, dataLayer: self.dataLayer, tealium: self)
            TealiumAppDelegateProxy.setup(context: context)
        }
        #endif
        TealiumQueues.backgroundSerialQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.zz_internal_modulesManager = modulesManager ?? ModulesManager(config, dataLayer: self.dataLayer)
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

    deinit {
        #if os(iOS)
        TealiumAppDelegateProxy.tearDown()
        #endif
    }

}
