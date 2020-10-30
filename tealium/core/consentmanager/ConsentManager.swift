//
//  ConsentManager.swift
//  tealium-swift
//
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation

public class ConsentManager {

    private weak var delegate: ModuleDelegate?
    var config: TealiumConfig
    var consentPreferencesStorage: ConsentPreferencesStorage?
    var consentLoggingEnabled: Bool {
        config.consentLoggingEnabled
    }
    var diskStorage: TealiumDiskStorageProtocol?
    var currentPolicy: ConsentPolicy

    /// Returns current consent status
    public var userConsentStatus: TealiumConsentStatus {
        get {
            currentPolicy.preferences.consentStatus
        }

        set {
            let status = newValue
            var categories = [TealiumConsentCategories]()
            if status == .consented {
                categories = TealiumConsentCategories.all
            }
            setUserConsentStatusWithCategories(status: status, categories: categories)
        }
    }

    /// Returns current consent categories, if applicable
    public var userConsentCategories: [TealiumConsentCategories]? {
        get {
            currentPolicy.preferences.consentCategories
        }

        set {
            setUserConsentStatusWithCategories(status: .consented, categories: newValue)
        }
    }

    /// Used by the Consent Manager module to determine if tracking calls can be sent.
    var trackingStatus: TealiumConsentTrackAction {
        currentPolicy.trackAction
    }

    /// Initialize consent manager￼.
    ///
    /// - Parameters:
    ///     - config: `TealiumConfig`￼
    ///     - delegate: `ModuleDelegate?`￼
    ///     - diskStorage: `TealiumDiskStorageProtocol` instance to allow overriding for unit testing￼
    ///     - completion: Optional completion block, called when fully initialized
    public init(config: TealiumConfig,
                delegate: ModuleDelegate?,
                diskStorage: TealiumDiskStorageProtocol,
                dataLayer: DataLayerManagerProtocol?) {
        self.diskStorage = diskStorage
        consentPreferencesStorage = ConsentPreferencesStorage(diskStorage: diskStorage)
        self.config = config
        self.delegate = delegate
        // try to load config from persistent storage first
        if let dataLayer = dataLayer,
           let migratedConsentStatus = dataLayer.all[ConsentKey.consentStatus] as? Int,
           let migratedConsentCategories = dataLayer.all[ConsentKey.consentCategoriesKey] as? [String] {
            config.consentPolicy = .gdpr
            consentPreferencesStorage?.preferences = UserConsentPreferences(consentStatus: TealiumConsentStatus(integer: migratedConsentStatus),
                                                                            consentCategories: TealiumConsentCategories.consentCategoriesStringArrayToEnum(migratedConsentCategories))
            config.consentLoggingEnabled = dataLayer.all[ConsentKey.consentLoggingEnabled] as? Bool ?? false
            dataLayer.delete(for: [ConsentKey.consentStatus, ConsentKey.consentCategoriesKey, ConsentKey.consentLoggingEnabled])
        }

        let preferences = consentPreferencesStorage?.preferences ?? UserConsentPreferences(consentStatus: .unknown, consentCategories: nil)

        switch config.consentPolicy ?? .gdpr {
        case .ccpa:
            self.currentPolicy = CCPAConsentPolicy(preferences)
        case .gdpr:
            self.currentPolicy = GDPRConsentPolicy(preferences)
        }

        if preferences.consentStatus != .unknown {
            // always need to update the consent cookie in TiQ, so this will trigger update_consent_cookie
            trackUserConsentPreferences(preferences)
        }
    }

    /// Sends a track call containing the consent settings if consent logging is enabled￼.
    ///
    /// - Parameter preferences: `UserConsentPreferences?`
    func trackUserConsentPreferences(_ preferences: UserConsentPreferences?) {
        if var consentData = currentPolicy.consentPolicyStatusInfo {
            consentData[TealiumKey.event] = currentPolicy.consentTrackingEventName
            // this track call must only be sent if "Log Consent Changes" is enabled and user has consented
            if consentLoggingEnabled, currentPolicy.shouldLogConsentStatus {
                // call type must be set to override "link" or "view"
                consentData[TealiumKey.callType] = consentData[TealiumKey.event]
                delegate?.requestTrack(TealiumTrackRequest(data: consentData))
            }
            // in all cases, update the cookie data in TiQ/webview
            updateTIQCookie()
        }
    }

    /// Sends the track call to update TiQ cookie info. Ignored by Collect module.￼
    ///
    /// - Parameter consentData: `[String: Any]` containing the consent preferences
    func updateTIQCookie() {
        if currentPolicy.shouldUpdateConsentCookie {
            var consentData = [String: Any]()
            if let extraData = currentPolicy.consentPolicyStatusInfo {
                consentData += extraData
            }
            // collect module ignores this hit
            consentData[TealiumKey.event] = currentPolicy.updateConsentCookieEventName
            consentData[TealiumKey.callType] = currentPolicy.updateConsentCookieEventName
            delegate?.requestTrack(TealiumTrackRequest(data: consentData))
        }
    }

    /// Saves current consent preferences to persistent storage.
    func storeUserConsentPreferences(_ preferences: UserConsentPreferences) {
        currentPolicy.preferences = preferences
        // store data
        consentPreferencesStorage?.preferences = preferences
    }

    /// Can set both Consent Status and Consent Categories in a single call￼.
    ///
    /// - Parameters:
    ///     - status: `TealiumConsentStatus?`￼
    ///     - categories: `[TealiumConsentCategories]?`
    private func setUserConsentStatusWithCategories(status: TealiumConsentStatus?, categories: [TealiumConsentCategories]?) {
        if let status = status {
            currentPolicy.preferences.setConsentStatus(status)
        }
        if let categories = categories {
            currentPolicy.preferences.setConsentCategories(categories)
        }
        storeUserConsentPreferences(currentPolicy.preferences)
        trackUserConsentPreferences(currentPolicy.preferences)
    }

}

// MARK: Public API
public extension ConsentManager {

    /// Resets all consent preferences in memory and in persistent storage.
    func resetUserConsentPreferences() {
        consentPreferencesStorage?.preferences = nil
        currentPolicy.preferences.resetConsentCategories()
        currentPolicy.preferences.setConsentStatus(.unknown)
        trackUserConsentPreferences(currentPolicy.preferences)
    }
}
