//
//  TealiumAttributionExtensions.swift
//  tealium-swift
//
//  Created by Craig Rouse on 14/03/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if attribution
import TealiumCore
#endif

public extension TealiumConfig {

    /// Checks if Apple Search Ads API was enabled in the TealiumConfig object
    ///
    /// - Returns: Bool - `true` if enabled
    func isSearchAdsEnabled() -> Bool {

        if let enabled = self.optionalData[TealiumAttributionKey.isSearchAdsEnabled] as? Bool {
            return enabled
        }

        // Default
        return false

    }

    /// Enables (`true`) or disables (`false`) Apple Search Ads API in the Attribution module
    ///
    /// - Parameter enabled: Bool - `true` if search ads should be enabled
    func setSearchAdsEnabled(_ enabled: Bool) {
        self.optionalData[TealiumAttributionKey.isSearchAdsEnabled] = enabled
    }
}
