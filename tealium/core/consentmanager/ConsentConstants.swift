//
//  ConsentConstants.swift
//  tealium-swift
//
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation

public enum ConsentKey {
    static let consentCategoriesKey = "consent_categories"
    static let doNotSellKey = "do_not_sell"
    static let trackingConsentedKey = "tracking_consented"
    static let consentGrantedEventName = "grant_full_consent"
    static let consentDeclinedEventName = "decline_consent"
    static let consentPartialEventName = "grant_partial_consent"
    static let moduleName = "consentmanager"
    static let consentLoggingEnabled = "consent_logging_enabled"
    static let consentStatus = "consent_status"
    static let policyKey = "policy"
    static let defaultPolicy = "gdpr"
    static let consentManagerDelegate = "consent_manager_delegate"
    static let gdprConsentCookieEventName = "update_consent_cookie"
    static let ccpaCookieEventName = "set_dns_state"
}

public enum TealiumConsentCategories: String, Codable {
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

    /// Converts a string array of consent categories to an array of TealiumConsentCategories.
    ///￼
    /// - Parameter categories: `[String]` of consent categories
    /// - Returns: `[TealiumConsentCategories]`
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

    /// - Returns: `[TealiumConsentCategories]` -  all currently-implemented consent categories
    public static var all: [TealiumConsentCategories] {
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
            .misc
        ]
    }
}

public enum TealiumConsentPolicy: String {
    case ccpa
    case gdpr
}

public enum TealiumConsentStatus: String, Codable {
    case unknown
    case consented
    case notConsented
}

public enum TealiumConsentTrackAction: Equatable {
    case trackingAllowed
    case trackingForbidden
    case trackingQueued
}

public extension TealiumConsentStatus {
    init(integer: Int) {
        switch integer {
        case 0:
            self = .unknown
        case 1:
            self = .consented
        case 2:
            self = .notConsented
        default:
            self = .unknown
        }
    }
}
