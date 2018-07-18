//
//  TealiumConsentManager.swift
//  tealium-swift
//
//  Created by Craig Rouse on 29/03/2018.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation

public class TealiumConsentManager {

    private var consentDelegates = TealiumMulticastDelegate<TealiumConsentManagerDelegate>()
    private weak var moduleDelegate: TealiumModuleDelegate?
    private var tealiumConfig: TealiumConfig?
    private var consentUserPreferences: TealiumConsentUserPreferences?
    private let consentPreferencesStorage = TealiumConsentPreferencesStorage()
    var consentLoggingEnabled = false
    var consentManagerModuleInstance: TealiumConsentManagerModule?

    // MARK: initialize consent manager
    public func start(config: TealiumConfig, delegate: TealiumModuleDelegate?, _ completion: (() -> Void)?) {
        tealiumConfig = config
        consentLoggingEnabled = config.isConsentLoggingEnabled()
        moduleDelegate = delegate
        // try to load config from UserDefaults first
        if let preferences = getSavedPreferences() {
            consentUserPreferences = preferences
            // always need to update the consent cookie in TiQ, so this will trigger update_consent_cookie
            trackUserConsentPreferences(preferences: consentUserPreferences)
        } else if tealiumConfig?.getInitialUserConsentStatus() != nil || tealiumConfig?.getInitialUserConsentCategories() != nil {
            updateConsentPreferencesFromConfig(tealiumConfig)
        } else {
            // not yet determined state.
            consentUserPreferences = TealiumConsentUserPreferences(consentStatus: .unknown, consentCategories: nil)
        }
        completion?()
    }

    public func setModuleDelegate(delegate: TealiumModuleDelegate) {
        moduleDelegate = delegate
    }

    // update current consent preferences from config passed at init time
    func updateConsentPreferencesFromConfig(_ config: TealiumConfig?) {
        if let config = config {
            let status = config.getInitialUserConsentStatus(),
                    categories = config.getInitialUserConsentCategories()
            if let stat = status, let cat = categories {
                setUserConsentStatusWithCategories(status: stat, categories: cat)
            } else if let stat = status {
                setUserConsentStatus(stat)
            } else if let cat = categories {
                setUserConsentCategories(cat)
            }
        }
    }

    // send a track call containing the consent settings if consent logging is enabled
    func trackUserConsentPreferences(preferences: TealiumConsentUserPreferences?) {
        if let preferences = preferences, var consentData = preferences.toDictionary() {
            // we can't log a nil consent status
            if preferences.consentStatus == nil {
                return
            }

            let policy = tealiumConfig?.getOverrideConsentPolicy() ?? TealiumConsentConstants.defaultPolicy
            consentData[TealiumConsentConstants.policyKey] = policy

            let totalCategories = TealiumConsentCategories.all().count
            if preferences.consentStatus == .consented {
                if let currentCategories = preferences.consentCategories?.count, currentCategories < totalCategories {
                    consentData[TealiumKey.event] = TealiumConsentConstants.consentPartialEventName
                } else {
                    consentData[TealiumKey.event] = TealiumConsentConstants.consentGrantedEventName
                }
            }

            // this track call must only be sent if "Log Consent Changes" is enabled and user has consented
            if consentLoggingEnabled && preferences.consentStatus == .consented {
                // call type must be set to override "link" or "view"
                consentData[TealiumKey.callType] = consentData[TealiumKey.event]
                moduleDelegate?.tealiumModuleRequests(module: nil, process: TealiumTrackRequest(data: consentData, completion: nil))
            }
            // in all cases, update the cookie data in TiQ/webview
            updateTIQCookie(consentData)
        }
    }

    // Sends the track call to update TiQ cookie info. Ignored by Collect module.
    func updateTIQCookie(_ consentData: [String: Any]) {
        var consentData = consentData
        // may change: currently, a separate call is required to TiQ to set the relevant cookies in the webview
        // collect module ignores this hit
        consentData[TealiumKey.event] = TealiumConsentConstants.updateConsentCookieEventName
        consentData[TealiumKey.callType] = TealiumConsentConstants.updateConsentCookieEventName
        moduleDelegate?.tealiumModuleRequests(module: nil, process: TealiumTrackRequest(data: consentData, completion: nil))
    }

    // returns existing preferences from UserDefaults if they exist
    func getSavedPreferences() -> TealiumConsentUserPreferences? {
        if let existingPrefs = consentPreferencesStorage.retrieveConsentPreferences() {
            var newPrefs = TealiumConsentUserPreferences(consentStatus: nil, consentCategories: nil)
            newPrefs.initWithDictionary(preferencesDictionary: existingPrefs)
            return newPrefs
        }
        return nil
    }

    // saves current consent preferences to UserDefaults
    func storeConsentUserPreferences() {
        guard let consentUserPrefs = getUserConsentPreferences()?.toDictionary() else {
            return
        }
        // store data
        consentPreferencesStorage.storeConsentPreferences(consentUserPrefs)
    }

    func setConsentUserPreferences(_ prefs: TealiumConsentUserPreferences) {
        consentUserPreferences = prefs
    }

    // allows module to determine current tracking status
    public func getTrackingStatus() -> TealiumConsentTrackAction {
        if getUserConsentPreferences()?.consentStatus == .consented {
            return .trackingAllowed
        } else if getUserConsentPreferences()?.consentStatus == .notConsented {
            return .trackingForbidden
        }
        return .trackingQueued
    }

    // MARK: Delegate Methods
    func willDropTrackingCall(_ track: TealiumTrackRequest) {
        consentDelegates.invoke {
            $0.willDropTrackingCall(track)
        }
    }

    func willQueueTrackingCall(_ track: TealiumTrackRequest) {
        consentDelegates.invoke {
            $0.willQueueTrackingCall(track)
        }
    }

    func willSendTrackingCall(_ track: TealiumTrackRequest) {
        consentDelegates.invoke {
            $0.willSendTrackingCall(track)
        }
    }

    func consentStatusChanged(_ status: TealiumConsentStatus?) {
        guard let currentStat = status else {
            return
        }
        if currentStat == .consented {
            userConsentedToTracking()
        }
        if currentStat == .notConsented {
            userOptedOutOfTracking()
        }
        consentDelegates.invoke {
            $0.consentStatusChanged(currentStat)
        }
    }

    func userOptedOutOfTracking() {
        consentDelegates.invoke {
            $0.userOptedOutOfTracking()
        }
    }

    func userChangedConsentCategories(_ categories: [TealiumConsentCategories]) {
        consentDelegates.invoke {
            $0.userChangedConsentCategories(categories: categories)
        }
    }

    func userConsentedToTracking() {
        consentDelegates.invoke {
            $0.userConsentedToTracking()
        }
    }
}

// Mark: Public API
public extension TealiumConsentManager {

    func addConsentDelegate(_ delegate: TealiumConsentManagerDelegate) {
        if let delegate = delegate as? TealiumConsentManagerModule {
            consentManagerModuleInstance = delegate
        }
        consentDelegates.add(delegate)
    }

    func removeAllConsentDelegates() {
        consentDelegates.removeAll()
        // ensures that consent manager module is always maintained as a delegate if removeAll is invoked
        if let consentModule = consentManagerModuleInstance {
            consentDelegates.add(consentModule)
        }
    }

    func removeSingleDelegate(delegate: TealiumConsentManagerDelegate) {
        consentDelegates.remove(delegate)
    }

    func setUserConsentStatus(_ status: TealiumConsentStatus) {
        var categories = [TealiumConsentCategories]()
        if status == .consented {
            categories = TealiumConsentCategories.all()
        }
        setUserConsentStatusWithCategories(status: status, categories: categories)
    }

    func setUserConsentCategories(_ categories: [TealiumConsentCategories]) {
        setUserConsentStatusWithCategories(status: .consented, categories: categories)
    }

    func setUserConsentStatusWithCategories(status: TealiumConsentStatus?, categories: [TealiumConsentCategories]?) {
        // delegate method
        if let categories = categories, let previousCategories = consentUserPreferences?.consentCategories, !consentCategoriesEqual(categories, previousCategories) {
            userChangedConsentCategories(categories)
        }
        guard let _ = consentUserPreferences else {
            consentUserPreferences = TealiumConsentUserPreferences(consentStatus: status, consentCategories: categories)
            trackUserConsentPreferences(preferences: consentUserPreferences)
            storeConsentUserPreferences()
            return
        }

        if let status = status {
            consentUserPreferences?.setConsentStatus(status)
        }
        if let categories = categories {
            consentUserPreferences?.setConsentCategories(categories)
        }
        storeConsentUserPreferences()
        trackUserConsentPreferences(preferences: consentUserPreferences)
        consentStatusChanged(status)
    }

    func consentCategoriesEqual(_ lhs: [TealiumConsentCategories], _ rhs: [TealiumConsentCategories]) -> Bool {
        let lhs = lhs.sorted {$0.rawValue < $1.rawValue}
        let rhs = rhs.sorted {$0.rawValue < $1.rawValue}
        return lhs == rhs
    }

    func getUserConsentStatus() -> TealiumConsentStatus {
        return consentUserPreferences?.consentStatus ?? TealiumConsentStatus.unknown
    }

    func getUserConsentCategories() -> [TealiumConsentCategories]? {
        return consentUserPreferences?.consentCategories
    }

    func getUserConsentPreferences() -> TealiumConsentUserPreferences? {
        return consentUserPreferences
    }

    func resetUserConsentPreferences() {
        consentPreferencesStorage.clearStoredPreferences()
        consentUserPreferences?.resetConsentCategories()
        consentUserPreferences?.setConsentStatus(.unknown)
        consentStatusChanged(consentUserPreferences?.consentStatus)
        userChangedConsentCategories([TealiumConsentCategories]())
        trackUserConsentPreferences(preferences: consentUserPreferences)
    }
}

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
