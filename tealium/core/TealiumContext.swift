//
//  TealiumContext.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol TealiumContextProtocol {
    var config: TealiumConfig { get }
    func track(_ dispatch: TealiumDispatch)
}

public struct TealiumContext: Hashable, TealiumContextProtocol {
    public static func == (lhs: TealiumContext, rhs: TealiumContext) -> Bool {
        lhs.config == rhs.config
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(config)
    }

    public unowned var config: TealiumConfig
    public weak var dataLayer: DataLayerManagerProtocol?
    fileprivate weak var tealium: Tealium?
    public var modules: [TealiumModule]? {
        tealium?.zz_internal_modulesManager?.modules
    }
    public var onVisitorId: TealiumObservable<String>? {
        return tealium?.onVisitorId
    }
    public let tealiumBackup: TealiumBackupStorage
    init(config: TealiumConfig,
         dataLayer: DataLayerManagerProtocol) {
        self.config = config
        self.dataLayer = dataLayer
        tealiumBackup = TealiumBackupStorage(account: config.account, profile: config.profile)
    }

    public init(config: TealiumConfig,
                dataLayer: DataLayerManagerProtocol,
                tealium: Tealium) {
        self.init(config: config,
                  dataLayer: dataLayer)
        self.tealium = tealium
    }

    public func track(_ dispatch: TealiumDispatch) {
        self.tealium?.track(dispatch)
    }

    public func log(_ logRequest: TealiumLogRequest) {
        self.config.logger?.log(logRequest)
    }

    public func handleDeepLink(_ url: URL, referrer: Tealium.DeepLinkReferrer? = nil) {
        self.tealium?.handleDeepLink(url, referrer: referrer)
    }

}
