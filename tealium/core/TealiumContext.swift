//
//  TealiumContext.swift
//  TealiumCore
//
//  Created by Craig Rouse on 25/08/2020.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public struct TealiumContext: Hashable {
    public static func == (lhs: TealiumContext, rhs: TealiumContext) -> Bool {
        guard let lhsConfig = lhs.config, let rhsConfig = rhs.config else {
            return false
        }
        return lhsConfig == rhsConfig
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(config)
    }

    weak var config: TealiumConfig?
    weak var dataLayer: DataLayerManagerProtocol?
    fileprivate weak var tealium: Tealium?

    public init(config: TealiumConfig,
                dataLayer: DataLayerManagerProtocol,
                tealium: Tealium) {
        self.config = config
        self.dataLayer = dataLayer
        self.tealium = tealium
    }

    public func track(_ dispatch: TealiumDispatch) {
        self.tealium?.track(dispatch)
    }

    public func handleDeepLink(_ url: URL) {
        self.tealium?.handleDeepLink(url)
    }
}
