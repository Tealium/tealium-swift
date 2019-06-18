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

    func setConsentLoggingEnabled(_ enabled: Bool) {
        optionalData[TealiumConsentConstants.consentLoggingEnabled] = enabled
    }

    func isConsentLoggingEnabled() -> Bool {
        if let enabled = optionalData[TealiumConsentConstants.consentLoggingEnabled] as? Bool {
            return enabled
        }
        return false
    }

    func setOverrideConsentPolicy(_ policy: String) {
        optionalData[TealiumConsentConstants.policyKey] = policy
    }

    func getOverrideConsentPolicy() -> String? {
        return optionalData[TealiumConsentConstants.policyKey] as? String
    }

    func setInitialUserConsentStatus(_ status: TealiumConsentStatus) {
        optionalData[TealiumConsentConstants.consentStatus] = status
    }

    func setInitialUserConsentCategories(_ categories: [TealiumConsentCategories]) {
        optionalData[TealiumConsentConstants.consentCategoriesKey] = categories
    }

    func getInitialUserConsentStatus() -> TealiumConsentStatus? {
        if let status = optionalData[TealiumConsentConstants.consentStatus] as? TealiumConsentStatus {
            return status
        }
        return nil
    }

    func getInitialUserConsentCategories() -> [TealiumConsentCategories]? {
        if let categories = optionalData[TealiumConsentConstants.consentCategoriesKey] as? [TealiumConsentCategories] {
            return categories
        }
        return nil
    }
}
