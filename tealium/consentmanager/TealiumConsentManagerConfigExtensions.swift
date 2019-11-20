//
//  TealiumConsentManagerConfigExtensions.swift
//  tealium-swift
//
//  Created by Craig Rouse on 20/03/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if consentmanager
import TealiumCore
#endif

public extension TealiumConfig {

    /// Determines whether consent logging events should be sent to Tealium UDH￼.
    ///
    /// - Parameter enabled: `Bool` `true` if enabled
    func setConsentLoggingEnabled(_ enabled: Bool) {
        optionalData[TealiumConsentConstants.consentLoggingEnabled] = enabled
    }

    /// Checks if consent logging is currently enabled.
    ///
    /// - Returns: `Bool` true if enabled
    func isConsentLoggingEnabled() -> Bool {
        if let enabled = optionalData[TealiumConsentConstants.consentLoggingEnabled] as? Bool {
            return enabled
        }
        return false
    }

    /// Overrides the consent policy (default GDPR)￼.
    ///
    /// - Parameter policy: `String` containing the policy (e.g. "CCPA)
    func setOverrideConsentPolicy(_ policy: String) {
        optionalData[TealiumConsentConstants.policyKey] = policy
    }

    /// Retrieves the current overridden consent policy.
    ///
    /// - Returns: `String?` containing the consent policy
    func getOverrideConsentPolicy() -> String? {
        return optionalData[TealiumConsentConstants.policyKey] as? String
    }

    /// Sets the initial consent status to be used before the user has selected an option￼.
    ///
    /// - Parameter status: `TealiumConsentStatus`
    func setInitialUserConsentStatus(_ status: TealiumConsentStatus) {
        optionalData[TealiumConsentConstants.consentStatus] = status
    }

    /// Sets the initial consent categories to be used before the user has selected an option￼.
    ///
    /// - Parameter categories: `[TealiumConsentCategories]`
    func setInitialUserConsentCategories(_ categories: [TealiumConsentCategories]) {
        optionalData[TealiumConsentConstants.consentCategoriesKey] = categories
    }

    /// Gets the initial consent status to be used before the user has selected an option.
    ///
    /// - Returns: `TealiumConsentStatus?`
    func getInitialUserConsentStatus() -> TealiumConsentStatus? {
        if let status = optionalData[TealiumConsentConstants.consentStatus] as? TealiumConsentStatus {
            return status
        }
        return nil
    }

    /// Gets the initial consent status to be used before the user has selected an option.
    /// 
    /// - Returns: `[TealiumConsentCategories]?`
    func getInitialUserConsentCategories() -> [TealiumConsentCategories]? {
        if let categories = optionalData[TealiumConsentConstants.consentCategoriesKey] as? [TealiumConsentCategories] {
            return categories
        }
        return nil
    }
}
