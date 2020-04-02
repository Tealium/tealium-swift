//
//  TealiumAttributionExtensions.swift
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

    /// Checks if Apple Search Ads API was enabled in the TealiumConfig object.
    ///
    /// - Returns: Bool - `true` if enabled
    @available(*, deprecated, message: "Please switch to config.searchAdsEnabled")
    func isSearchAdsEnabled() -> Bool {
        searchAdsEnabled
    }

    /// Enables (`true`) or disables (`false`) Apple Search Ads API in the Attribution module￼.
    ///
    /// - Parameter enabled: `Bool` - `true` if search ads should be enabled
    @available(*, deprecated, message: "Please switch to config.searchAdsEnabled")
    func setSearchAdsEnabled(_ enabled: Bool) {
        searchAdsEnabled = enabled
    }

    var searchAdsEnabled: Bool {
        get {
            optionalData[TealiumAttributionKey.isSearchAdsEnabled] as? Bool ?? false
        }

        set {
            optionalData[TealiumAttributionKey.isSearchAdsEnabled] = newValue
        }
    }
}
#endif
