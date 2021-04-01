//
//  ConsentPolicies.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol ConsentPolicy {
    
    /// The name of the `ConsentPolicy`
    var name: String { get }
    
    /// Sets the default expiry time for this `ConsentPolicy`. This is also overridable
    /// from `TealiumConfig.consentExpiry`
    var defaultConsentExpiry: (time: Int, unit: TimeUnit) { get }
    
    /// Sets whether or not to update a cookie in the TagManagement module's webview.
    var shouldUpdateConsentCookie: Bool { get }
    
    /// Sets the event name to use when `shouldUpdateConsentCookie` is set to true.
    var updateConsentCookieEventName: String { get }
    
    /// - Returns:`[String: Any]` of key value data to be added to the payload of each `TealiumDispatch`
    /// `["consent_policy": "ccpa", "consent_status": "consented"]`
    var consentPolicyStatusInfo: [String: Any]? { get }
    
    /// The current `UserConsentPreferences`
    /// This will be automatically updated by the `ConsentManager`when the preferences change.
    var preferences: UserConsentPreferences { get set }
    
    /// The tracking action based on the consent status (allowed, forbidden, queued)
    var trackAction: TealiumConsentTrackAction { get }
    
    /// Sets the event name (key: tealium_event) to use when logging a change in consent.
    var consentTrackingEventName: String { get }
    
    /// Sets whether or not logging of consent changes are required
    var shouldLogConsentStatus: Bool { get }
}

public class ConsentPolicyFactory {
    public static func create(_ policy: TealiumConsentPolicy,
                       preferences: UserConsentPreferences) -> ConsentPolicy {
        switch policy {
        case .ccpa:
            return CCPAConsentPolicy(preferences)
        case .gdpr:
            return GDPRConsentPolicy(preferences)
        case .custom(let customPolicy):
            return customPolicy
        }
    }
}

class CCPAConsentPolicy: ConsentPolicy {

    init(_ preferences: UserConsentPreferences) {
        self.preferences = preferences
    }
    
    var name = "ccpa"
    
    var defaultConsentExpiry: (time: Int, unit: TimeUnit) = (395, .days)

    // Currently only supported by TiQ and no way to figure out which tags are in scope for consent logging
    var shouldLogConsentStatus = false

    var consentTrackingEventName: String {
        return self.currentStatus == .consented ? ConsentKey.consentGrantedEventName : ConsentKey.consentPartialEventName
    }

    var preferences: UserConsentPreferences

    var currentStatus: TealiumConsentStatus {
        preferences.consentStatus
    }

    var shouldUpdateConsentCookie = true

    var updateConsentCookieEventName = ConsentKey.ccpaCookieEventName

    var trackAction: TealiumConsentTrackAction {
        return .trackingAllowed
    }

    var consentPolicyStatusInfo: [String: Any]? {
        let doNotSell = currentStatus == .notConsented ? true : false
        return [ConsentKey.doNotSellKey: doNotSell,
                ConsentKey.policyKey: name]
    }
}

class GDPRConsentPolicy: ConsentPolicy {

    init(_ preferences: UserConsentPreferences) {
        self.preferences = preferences
    }
    
    var name = "gdpr"
    
    var defaultConsentExpiry: (time: Int, unit: TimeUnit) = (365, .days)

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
        params[ConsentKey.policyKey] = name
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
