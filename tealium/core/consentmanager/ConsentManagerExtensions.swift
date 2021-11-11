//
//  ConsentManagerExtensions.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

// public interface for consent manager
public extension Tealium {

    /// - Returns: `ConsentManager` instance
    var consentManager: ConsentManager? {
        let module = zz_internal_modulesManager?.dispatchValidators.first {
            $0 is ConsentManagerModule
        }
        return (module as? ConsentManagerModule)?.consentManager
    }

}

extension TealiumConfigKey {
    static let consentLoggingEnabled = "consent_logging_enabled"
    static let policyKey = "policy"
}

public extension TealiumConfig {

    /// Determines whether consent logging events should be sent to Tealium UDH￼.
    var consentLoggingEnabled: Bool {
        get {
            options[TealiumConfigKey.consentLoggingEnabled] as? Bool ?? false
        }

        set {
            options[TealiumConfigKey.consentLoggingEnabled] = newValue
        }
    }

    /// Sets the consent policy (defaults to GDPR)￼. e.g. CCPA
    var consentPolicy: TealiumConsentPolicy? {
        get {
            options[TealiumConfigKey.policyKey] as? TealiumConsentPolicy
        }

        set {
            options[TealiumConfigKey.policyKey] = newValue
        }
    }

}
