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

extension TealiumConfigKey {
    static let isSearchAdsEnabled = "com.tealium.attribution.searchads.enable"
    static let isSKAdAttributionEnabled = "com.tealium.attribution.skadattribution.enable"
}

public extension TealiumConfig {

    /// Enables (`true`) or disables (`false`) Apple Search Ads API in the Attribution module￼.
    var searchAdsEnabled: Bool {
        get {
            options[TealiumConfigKey.isSearchAdsEnabled] as? Bool ?? false
        }

        set {
            options[TealiumConfigKey.isSearchAdsEnabled] = newValue
        }
    }

    /// Enables (`true`) or disables (`false`) SKAdNetwork in the Attribution module￼.
    var skAdAttributionEnabled: Bool {
        get {
            options[TealiumConfigKey.isSKAdAttributionEnabled] as? Bool ?? false
        }

        set {
            options[TealiumConfigKey.isSKAdAttributionEnabled] = newValue
        }
    }

}

public extension Collectors {
    static let Attribution = AttributionModule.self
}

#endif
