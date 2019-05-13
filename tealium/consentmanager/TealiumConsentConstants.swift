//
//  TealiumConsentConstants.swift
//  tealium-swift
//
//  Created by Craig Rouse on 4/20/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation

public enum TealiumConsentConstants {
    static let consentCategoriesKey = "consent_categories"
    static let trackingConsentedKey = "tracking_consented"
    static let consentGrantedEventName = "grant_full_consent"
    static let consentDeclinedEventName = "decline_consent"
    static let consentPartialEventName = "grant_partial_consent"
    static let moduleName = "consentmanager"
    static let consentLoggingEnabled = "consent_manager_enabled"
    static let consentStatus = "consent_status"
    static let policyKey = "policy"
    static let defaultPolicy = "gdpr"
}

public enum TealiumConsentCategories: String {
    case analytics = "analytics"
    case affiliates = "affiliates"
    case displayAds = "display_ads"
    case email = "email"
    case personalization = "personalization"
    case search = "search"
    case social = "social"
    case bigData = "big_data"
    case mobile = "mobile"
    case engagement = "engagement"
    case monitoring = "monitoring"
    case crm = "crm"
    case cdp = "cdp"
    case cookieMatch = "cookiematch"
    case misc = "misc"

    /// Converts a string array of consent categories to an array of TealiumConsentCategories
    ///
    /// - Parameter categories: [String] of consent categories
    /// - Returns: [TealiumConsentCategories]
    public static func consentCategoriesStringArrayToEnum(_ categories: [String]) -> [TealiumConsentCategories] {
        var converted = [TealiumConsentCategories]()
        categories.forEach { category in
            let lowercasedCategory = category.lowercased()
            if let categoryEnum = TealiumConsentCategories(rawValue: lowercasedCategory) {
                converted.append(categoryEnum)
            }
        }
        return converted
    }

    /// - Returns: An array of all currently-implemented consent categories
    public static func all() -> [TealiumConsentCategories] {
        return [
            .analytics,
            .affiliates,
            .displayAds,
            .email,
            .personalization,
            .search,
            .social,
            .bigData,
            .mobile,
            .engagement,
            .monitoring,
            .crm,
            .cdp,
            .cookieMatch,
            .misc,
        ]
    }
}

public enum TealiumConsentStatus: String {
    case unknown
    case consented
    case notConsented
}

public enum TealiumConsentTrackAction {
    case trackingAllowed
    case trackingForbidden
    case trackingQueued
}
