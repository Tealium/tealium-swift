//
//  AttributionExtensions.swift
//  tealium-swift
//
//  Created by Craig Rouse on 14/03/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//
#if os(iOS)
import Foundation
#if attribution
import TealiumCore
#endif

public extension TealiumConfig {

    /// Enables (`true`) or disables (`false`) Apple Search Ads API in the Attribution module￼.
    var searchAdsEnabled: Bool {
        get {
            options[AttributionKey.isSearchAdsEnabled] as? Bool ?? false
        }

        set {
            options[AttributionKey.isSearchAdsEnabled] = newValue
        }
    }
}

public extension Collectors {
    static let Attribution = AttributionModule.self
}

#endif
