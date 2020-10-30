//
//  AttributionExtensions.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

#if os(iOS) && !targetEnvironment(macCatalyst)
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

    /// Enables (`true`) or disables (`false`) SKAdNetwork in the Attribution module￼.
    var skAdAttributionEnabled: Bool {
        get {
            options[AttributionKey.isSKAdAttributionEnabled] as? Bool ?? false
        }

        set {
            options[AttributionKey.isSKAdAttributionEnabled] = newValue
        }
    }

}

public extension Collectors {
    static let Attribution = AttributionModule.self
}

#endif
