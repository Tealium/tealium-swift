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
    @available(*, deprecated, message: "Please switch to config.consentLoggingEnabled")
    func setConsentLoggingEnabled(_ enabled: Bool) {
        consentLoggingEnabled = enabled
    }

    /// Checks if consent logging is currently enabled.
    ///
    /// - Returns: `Bool` true if enabled
    @available(*, deprecated, message: "Please switch to config.consentLoggingEnabled")
    func isConsentLoggingEnabled() -> Bool {
        consentLoggingEnabled
    }

    /// Determines whether consent logging events should be sent to Tealium UDH￼.
    var consentLoggingEnabled: Bool {
        get {
            optionalData[TealiumConsentConstants.consentLoggingEnabled] as? Bool ?? false
        }

        set {
            optionalData[TealiumConsentConstants.consentLoggingEnabled] = newValue
        }
    }

    /// Overrides the consent policy (default GDPR)￼.
    ///
    /// - Parameter policy: `String` containing the policy (e.g. "CCPA)
    @available(*, deprecated, message: "Please switch to config.consentPolicyOverride")
    func setOverrideConsentPolicy(_ policy: String) {
        consentPolicyOverride = policy
    }

    /// Retrieves the current overridden consent policy.
    ///
    /// - Returns: `String?` containing the consent policy
    @available(*, deprecated, message: "Please switch to config.consentPolicyOverride")
    func getOverrideConsentPolicy() -> String? {
        consentPolicyOverride
    }

    /// Overrides the consent policy (defaults to GDPR)￼. e.g. CCPA
    var consentPolicyOverride: String? {
        get {
            optionalData[TealiumConsentConstants.policyKey] as? String
        }

        set {
            optionalData[TealiumConsentConstants.policyKey] = newValue
        }
    }

    /// Sets the initial consent status to be used before the user has selected an option￼.
    ///
    /// - Parameter status: `TealiumConsentStatus`
    @available(*, deprecated, message: "Please switch to config.initialUserConsentStatus")
    func setInitialUserConsentStatus(_ status: TealiumConsentStatus) {
        initialUserConsentStatus = status
    }

    /// Gets the initial consent status to be used before the user has selected an option.
    ///
    /// - Returns: `TealiumConsentStatus?`
    @available(*, deprecated, message: "Please switch to config.initialUserConsentStatus")
    func getInitialUserConsentStatus() -> TealiumConsentStatus? {
        initialUserConsentStatus
    }

    /// Initial consent status to be used before the user has selected an option￼.
    var initialUserConsentStatus: TealiumConsentStatus? {
        get {
            optionalData[TealiumConsentConstants.consentStatus] as? TealiumConsentStatus
        }

        set {
            optionalData[TealiumConsentConstants.consentStatus] = newValue
        }
    }

    /// Sets the initial consent categories to be used before the user has selected an option￼.
    ///
    /// - Parameter categories: `[TealiumConsentCategories]`
    @available(*, deprecated, message: "Please switch to config.initialUserConsentCategories")
    func setInitialUserConsentCategories(_ categories: [TealiumConsentCategories]) {
        initialUserConsentCategories = categories
    }

    /// Gets the initial consent status to be used before the user has selected an option.
    /// 
    /// - Returns: `[TealiumConsentCategories]?`
    @available(*, deprecated, message: "Please switch to config.initialUserConsentCategories")
    func getInitialUserConsentCategories() -> [TealiumConsentCategories]? {
        initialUserConsentCategories
    }

    /// Initial consent categories to be used before the user has selected an option￼.
    var initialUserConsentCategories: [TealiumConsentCategories]? {
        get {
            optionalData[TealiumConsentConstants.consentCategoriesKey] as? [TealiumConsentCategories]
        }

        set {
            optionalData[TealiumConsentConstants.consentCategoriesKey] = newValue
        }
    }
}
