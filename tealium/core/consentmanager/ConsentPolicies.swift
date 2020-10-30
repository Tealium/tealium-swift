//
//  ConsentPolicies.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

protocol ConsentPolicy {
    init (_ preferences: UserConsentPreferences)
    var shouldUpdateConsentCookie: Bool { get }
    var updateConsentCookieEventName: String { get }
    var consentPolicyStatusInfo: [String: Any]? { get }
    var preferences: UserConsentPreferences { get set }
    var trackAction: TealiumConsentTrackAction { get }
    var consentTrackingEventName: String { get }
    var shouldLogConsentStatus: Bool { get }
}

struct CCPAConsentPolicy: ConsentPolicy {

    init(_ preferences: UserConsentPreferences) {
        self.preferences = preferences
    }

    // Currently only supported by TiQ and no way to figure out which tags are in scope for consent logging
    var shouldLogConsentStatus = false

    var consentTrackingEventName: String {
        return self.currentStatus == .consented ? ConsentKey.consentGrantedEventName : ConsentKey.consentPartialEventName
    }

    var preferences: UserConsentPreferences

    var currentStatus: TealiumConsentStatus {
        preferences.consentStatus
    }

    var shouldUpdateConsentCookie: Bool = true

    var updateConsentCookieEventName = ConsentKey.ccpaCookieEventName

    var trackAction: TealiumConsentTrackAction {
        return .trackingAllowed
    }

    var consentPolicyStatusInfo: [String: Any]? {
        let doNotSell = currentStatus == .notConsented ? true : false
        return [ConsentKey.doNotSellKey: doNotSell,
                ConsentKey.policyKey: TealiumConsentPolicy.ccpa.rawValue]
    }
}

struct GDPRConsentPolicy: ConsentPolicy {

    init(_ preferences: UserConsentPreferences) {
        self.preferences = preferences
    }

    var shouldLogConsentStatus = true

    var consentTrackingEventName: String {
        if preferences.consentStatus == .notConsented {
            return ConsentKey.consentDeclinedEventName
        }
        if let currentCategories = preferences.consentCategories?.count, currentCategories < TealiumConsentCategories.all.count {
            return ConsentKey.consentPartialEventName
        } else {
            return ConsentKey.consentGrantedEventName
        }
    }

    var preferences: UserConsentPreferences

    var shouldUpdateConsentCookie = true

    var updateConsentCookieEventName = ConsentKey.gdprConsentCookieEventName

    var currentStatus: TealiumConsentStatus {
        preferences.consentStatus
    }

    var currentCategories: [TealiumConsentCategories]? {
        preferences.consentCategories
    }

    var consentPolicyStatusInfo: [String: Any]? {
        var params = preferences.dictionary ?? [String: Any]()
        params[ConsentKey.policyKey] = TealiumConsentPolicy.gdpr.rawValue
        return params
    }

    var trackAction: TealiumConsentTrackAction {
        switch currentStatus {
        case .consented:
            return .trackingAllowed
        case .notConsented:
            return .trackingForbidden
        case .unknown:
            return .trackingQueued
        }
    }
}
