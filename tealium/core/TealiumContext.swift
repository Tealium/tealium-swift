//
//  TealiumContext.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol TealiumContextProtocol {
    var config: TealiumConfig { get }
    var dataLayer: DataLayerManagerProtocol? { get }
    var jsonLoader: JSONLoadable? { get }
    func track(_ dispatch: TealiumDispatch)
    func handleDeepLink(_ url: URL)
    func log(_ logRequest: TealiumLogRequest)
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
    public weak var jsonLoader: JSONLoadable?
    fileprivate weak var tealium: Tealium?

    public init(config: TealiumConfig,
                dataLayer: DataLayerManagerProtocol,
                jsonLoader: JSONLoadable,
                tealium: Tealium) {
        self.config = config
        self.dataLayer = dataLayer
        self.jsonLoader = jsonLoader
        self.tealium = tealium
    }

    public func track(_ dispatch: TealiumDispatch) {
        self.tealium?.track(dispatch)
    }
    
    public func log(_ logRequest: TealiumLogRequest) {
        self.config.logger?.log(logRequest)
    }

    public func handleDeepLink(_ url: URL) {
        self.tealium?.handleDeepLink(url)
    }

}
